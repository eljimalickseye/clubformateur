<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CourseReplay;
use App\Models\LiveSession;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class LiveSessionController extends Controller
{
    public function index(): JsonResponse
    {
        $sessions = LiveSession::orderByDesc('created_at')->get();
        return response()->json([
            'success' => true,
            'sessions' => $sessions->map(fn (LiveSession $s) => $this->formatSession($s)),
        ]);
    }

    public function active(): JsonResponse
    {
        $sessions = LiveSession::where('status', 'live')->orderByDesc('started_at')->get();
        return response()->json([
            'success' => true,
            'sessions' => $sessions->map(fn (LiveSession $s) => $this->formatSession($s)),
        ]);
    }

    public function courseSessions(string $courseId): JsonResponse
    {
        $sessions = LiveSession::where('course_id', $courseId)->orderByDesc('created_at')->get();
        return response()->json([
            'success' => true,
            'sessions' => $sessions->map(fn (LiveSession $s) => $this->formatSession($s)),
        ]);
    }

    public function teacherSessions(string $teacherId): JsonResponse
    {
        $sessions = LiveSession::where('teacher_id', $teacherId)->orderByDesc('created_at')->get();
        return response()->json([
            'success' => true,
            'sessions' => $sessions->map(fn (LiveSession $s) => $this->formatSession($s)),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $user = $request->user();
        if (!$this->isStaff($user)) {
            return response()->json(['success' => false, 'message' => 'Accès refusé'], 403);
        }

        $validated = $request->validate([
            'courseId' => 'required|string|max:100',
            'courseName' => 'sometimes|nullable|string|max:255',
            'title' => 'required|string|max:255',
            'sessionType' => 'sometimes|string|max:50',
            'phase' => 'sometimes|string|in:interactive,exercises,presentation',
        ]);

        $sessionUid = 'live_' . time() . '_' . Str::lower(Str::random(6));
        $roomName = 'club_live_' . $validated['courseId'] . '_' . Str::lower(Str::random(8));

        $session = LiveSession::create([
            'session_uid' => $sessionUid,
            'course_id' => $validated['courseId'],
            'course_name' => $validated['courseName'] ?? $validated['title'],
            'title' => $validated['title'],
            'teacher_id' => $user->uid,
            'teacher_name' => $user->name,
            'teacher_photo_url' => $user->photo_url ?? '',
            'status' => 'live',
            'room_name' => $roomName,
            'session_type' => $validated['sessionType'] ?? 'teacher_live',
            'host_role' => $user->role,
            'phase' => $validated['phase'] ?? 'interactive',
            'participant_count' => 1,
            'connected_participants' => [$user->uid],
            'raised_hands' => [],
            'scheduled_at' => now(),
            'started_at' => now(),
        ]);

        $token = $this->createLiveKitJwt($roomName, $user->uid, $user->name, true);

        return response()->json([
            'success' => true,
            'session' => $this->formatSession($session),
            'livekit' => [
                'serverUrl' => config('services.livekit.url'),
                'roomName' => $roomName,
                'token' => $token,
            ],
        ], 201);
    }

    public function switchPhase(Request $request, string $id): JsonResponse
    {
        $session = $this->hostedSession($request, $id);
        $session->phase = $request->validate(['phase' => 'required|string|in:interactive,exercises,presentation'])['phase'];
        $session->save();

        return response()->json([
            'success' => true,
            'session' => $this->formatSession($session),
        ]);
    }

    public function join(Request $request, string $id): JsonResponse
    {
        $user = $request->user();
        $session = LiveSession::where('session_uid', $id)->firstOrFail();
        if ($session->status !== 'live') {
            return response()->json(['success' => false, 'message' => 'Session terminée'], 409);
        }

        $participants = $session->connected_participants ?? [];
        if (!in_array($user->uid, $participants, true)) {
            $participants[] = $user->uid;
        }
        $session->connected_participants = $participants;
        $session->participant_count = count($participants);
        $session->save();

        $token = $this->createLiveKitJwt($session->room_name, $user->uid, $user->name, $this->canHost($user, $session));

        return response()->json([
            'success' => true,
            'session' => $this->formatSession($session),
            'livekit' => [
                'serverUrl' => config('services.livekit.url'),
                'roomName' => $session->room_name,
                'token' => $token,
            ],
        ]);
    }

    public function leave(Request $request, string $id): JsonResponse
    {
        $session = LiveSession::where('session_uid', $id)->first();
        if ($session) {
            $participants = array_values(array_diff($session->connected_participants ?? [], [$request->user()->uid]));
            $session->connected_participants = $participants;
            $session->participant_count = max(1, count($participants));
            $session->save();
        }

        return response()->json(['success' => true]);
    }

    public function toggleRaiseHand(Request $request, string $id): JsonResponse
    {
        $user = $request->user();
        $session = LiveSession::where('session_uid', $id)->firstOrFail();
        $hands = $session->raised_hands ?? [];

        $exists = false;
        foreach ($hands as $k => $h) {
            if (($h['uid'] ?? '') === $user->uid) {
                unset($hands[$k]);
                $exists = true;
            }
        }

        if (!$exists) {
            $hands[] = [
                'uid' => $user->uid,
                'displayName' => $user->name,
                'raisedAt' => now()->toIso8601String(),
            ];
        }

        $session->raised_hands = array_values($hands);
        $session->save();

        return response()->json([
            'success' => true,
            'handRaised' => !$exists,
            'session' => $this->formatSession($session),
        ]);
    }

    public function end(Request $request, string $id): JsonResponse
    {
        $session = $this->hostedSession($request, $id);
        $validated = $request->validate([
            'replayUrl' => 'sometimes|nullable|url|max:2048',
            'replayDuration' => 'sometimes|nullable|string|max:20',
        ]);
        $replayUrl = $validated['replayUrl'] ?? null;
        $replayDuration = $validated['replayDuration'] ?? null;

        $session->status = 'ended';
        $session->has_replay = $replayUrl !== null;
        $session->replay_url = $replayUrl;
        $session->replay_duration = $replayDuration;
        $session->ended_at = now();
        $session->save();

        if ($replayUrl !== null) {
            CourseReplay::create([
                'course_id' => $session->course_id,
                'replay_uid' => $session->session_uid,
                'title' => 'Replay : ' . $session->title,
                'replay_url' => $replayUrl,
                'duration' => $replayDuration ?? '',
                'recorded_at' => now(),
            ]);
        }

        return response()->json([
            'success' => true,
            'session' => $this->formatSession($session),
        ]);
    }

    public function generateLiveKitToken(Request $request): JsonResponse
    {
        $validated = $request->validate(['roomName' => 'required|string|max:255']);
        $user = $request->user();

        $session = LiveSession::where('room_name', $validated['roomName'])->where('status', 'live')->firstOrFail();
        $token = $this->createLiveKitJwt($session->room_name, $user->uid, $user->name, $this->canHost($user, $session));

        return response()->json([
            'success' => true,
            'serverUrl' => config('services.livekit.url'),
            'roomName' => $session->room_name,
            'token' => $token,
        ]);
    }

    private function isStaff(User $user): bool
    {
        return in_array($user->role, ['teacher', 'admin', 'super_admin'], true);
    }

    /** Droit de publier audio/video : l'animateur de la session ou un administrateur. */
    private function canHost(User $user, LiveSession $session): bool
    {
        return in_array($user->role, ['admin', 'super_admin'], true)
            || ($user->role === 'teacher' && $session->teacher_id === $user->uid);
    }

    private function hostedSession(Request $request, string $id): LiveSession
    {
        $session = LiveSession::where('session_uid', $id)->firstOrFail();
        if (!$this->canHost($request->user(), $session)) {
            abort(403, 'Accès refusé');
        }

        return $session;
    }

    private function createLiveKitJwt(string $roomName, string $identity, string $name, bool $isTeacher): string
    {
        $apiKey = config('services.livekit.key');
        $apiSecret = config('services.livekit.secret');
        if (!$apiKey || !$apiSecret) {
            abort(503, 'LiveKit non configuré');
        }

        $header = ['alg' => 'HS256', 'typ' => 'JWT'];
        $now = time();
        $payload = [
            'iss' => $apiKey,
            'sub' => $identity,
            'name' => $name,
            'nbf' => $now - 10,
            'exp' => $now + (4 * 3600),
            'metadata' => $isTeacher ? 'teacher' : 'student',
            'video' => [
                'room' => $roomName,
                'roomJoin' => true,
                'canPublish' => $isTeacher,
                'canSubscribe' => true,
                'canPublishData' => true,
            ],
        ];

        $base64UrlHeader = rtrim(strtr(base64_encode(json_encode($header)), '+/', '-_'), '=');
        $base64UrlPayload = rtrim(strtr(base64_encode(json_encode($payload)), '+/', '-_'), '=');
        $signature = hash_hmac('sha256', $base64UrlHeader . '.' . $base64UrlPayload, $apiSecret, true);
        $base64UrlSignature = rtrim(strtr(base64_encode($signature), '+/', '-_'), '=');

        return $base64UrlHeader . '.' . $base64UrlPayload . '.' . $base64UrlSignature;
    }

    private function formatSession(LiveSession $s): array
    {
        return [
            'id' => $s->session_uid,
            'courseId' => $s->course_id,
            'courseName' => $s->course_name,
            'title' => $s->title,
            'teacherId' => $s->teacher_id,
            'teacherName' => $s->teacher_name,
            'teacherPhotoUrl' => $s->teacher_photo_url ?? '',
            'status' => $s->status,
            'roomName' => $s->room_name,
            'sessionType' => $s->session_type,
            'hostRole' => $s->host_role,
            'phase' => $s->phase,
            'participantCount' => $s->participant_count,
            'connectedParticipants' => $s->connected_participants ?? [],
            'raisedHands' => $s->raised_hands ?? [],
            'hasReplay' => $s->has_replay,
            'replayUrl' => $s->replay_url,
            'replayDuration' => $s->replay_duration,
            'scheduledAt' => ($s->scheduled_at ?? $s->created_at)?->toIso8601String(),
            'startedAt' => $s->started_at?->toIso8601String(),
            'endedAt' => $s->ended_at?->toIso8601String(),
        ];
    }
}
