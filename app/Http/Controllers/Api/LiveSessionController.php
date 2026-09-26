<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CourseReplay;
use App\Models\LiveSession;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

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
        $sessionUid = $request->input('id') ?: ('live_' . time());
        $courseId = $request->input('courseId', 'general');
        $roomName = $request->input('roomName') ?: ('club_live_' . $courseId . '_' . time());
        $teacherId = $request->input('teacherId', 'demo_teacher_cheikh');
        $teacherName = $request->input('teacherName', 'Cheikh Abdoulaye Diop');

        $session = LiveSession::updateOrCreate(
            ['session_uid' => $sessionUid],
            [
                'course_id' => $courseId,
                'course_name' => $request->input('courseName', 'Formation Générale'),
                'title' => $request->input('title', 'Session Live Interactive'),
                'teacher_id' => $teacherId,
                'teacher_name' => $teacherName,
                'teacher_photo_url' => $request->input('teacherPhotoUrl', ''),
                'status' => $request->input('status', 'live'),
                'room_name' => $roomName,
                'session_type' => $request->input('sessionType', 'teacher_live'),
                'host_role' => $request->input('hostRole', 'teacher'),
                'phase' => $request->input('phase', 'interactive'),
                'participant_count' => 1,
                'connected_participants' => [$teacherId],
                'raised_hands' => [],
                'scheduled_at' => now(),
                'started_at' => now(),
            ]
        );

        $token = $this->createLiveKitJwt($roomName, $teacherId, $teacherName, true);

        return response()->json([
            'success' => true,
            'session' => $this->formatSession($session),
            'livekit' => [
                'serverUrl' => env('LIVEKIT_URL', 'wss://anour-rv83fs3g.livekit.cloud'),
                'roomName' => $roomName,
                'token' => $token,
            ],
        ], 201);
    }

    public function switchPhase(Request $request, string $id): JsonResponse
    {
        $session = LiveSession::where('session_uid', $id)->orWhere('id', $id)->firstOrFail();
        $session->phase = $request->input('phase', 'exercises');
        $session->save();

        return response()->json([
            'success' => true,
            'session' => $this->formatSession($session),
        ]);
    }

    public function join(Request $request, string $id): JsonResponse
    {
        $session = LiveSession::where('session_uid', $id)->orWhere('id', $id)->firstOrFail();
        $userId = $request->input('userId', 'student_' . time());
        $userName = $request->input('userName', 'Apprenant');

        $participants = $session->connected_participants ?? [];
        if (!in_array($userId, $participants, true)) {
            $participants[] = $userId;
        }
        $session->connected_participants = $participants;
        $session->participant_count = count($participants);
        $session->save();

        $token = $this->createLiveKitJwt($session->room_name, $userId, $userName, false);

        return response()->json([
            'success' => true,
            'session' => $this->formatSession($session),
            'livekit' => [
                'serverUrl' => env('LIVEKIT_URL', 'wss://anour-rv83fs3g.livekit.cloud'),
                'roomName' => $session->room_name,
                'token' => $token,
            ],
        ]);
    }

    public function leave(Request $request, string $id): JsonResponse
    {
        $session = LiveSession::where('session_uid', $id)->orWhere('id', $id)->first();
        if ($session) {
            $userId = $request->input('userId');
            $participants = array_values(array_diff($session->connected_participants ?? [], [$userId]));
            $session->connected_participants = $participants;
            $session->participant_count = max(1, count($participants));
            $session->save();
        }

        return response()->json(['success' => true]);
    }

    public function toggleRaiseHand(Request $request, string $id): JsonResponse
    {
        $session = LiveSession::where('session_uid', $id)->orWhere('id', $id)->firstOrFail();
        $userId = $request->input('userId', 'student');
        $userName = $request->input('userName', 'Apprenant');
        $hands = $session->raised_hands ?? [];

        $exists = false;
        foreach ($hands as $k => $h) {
            if (($h['uid'] ?? '') === $userId) {
                unset($hands[$k]);
                $exists = true;
            }
        }

        if (!$exists) {
            $hands[] = [
                'uid' => $userId,
                'displayName' => $userName,
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
        $session = LiveSession::where('session_uid', $id)->orWhere('id', $id)->first();
        $replayUrl = $request->input('replayUrl', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4');
        $replayDuration = $request->input('replayDuration', '1:30:00');

        if ($session) {
            $session->status = 'ended';
            $session->has_replay = true;
            $session->replay_url = $replayUrl;
            $session->replay_duration = $replayDuration;
            $session->ended_at = now();
            $session->save();

            CourseReplay::create([
                'course_id' => $session->course_id,
                'replay_uid' => $session->session_uid,
                'title' => 'Replay : ' . $session->title,
                'replay_url' => $replayUrl,
                'duration' => $replayDuration,
                'recorded_at' => now(),
            ]);
        }

        return response()->json([
            'success' => true,
            'session' => $session ? $this->formatSession($session) : null,
        ]);
    }

    public function generateLiveKitToken(Request $request): JsonResponse
    {
        $roomName = $request->input('roomName', 'club_live_default');
        $identity = $request->input('participantIdentity', 'user_' . time());
        $name = $request->input('participantName', 'Participant');
        $isTeacher = (bool) $request->input('isTeacher', false);

        $token = $this->createLiveKitJwt($roomName, $identity, $name, $isTeacher);

        return response()->json([
            'success' => true,
            'serverUrl' => env('LIVEKIT_URL', 'wss://anour-rv83fs3g.livekit.cloud'),
            'roomName' => $roomName,
            'token' => $token,
        ]);
    }

    private function createLiveKitJwt(string $roomName, string $identity, string $name, bool $isTeacher): string
    {
        $apiKey = env('LIVEKIT_API_KEY', 'APIsCo9dSx9D6VC');
        $apiSecret = env('LIVEKIT_API_SECRET', 'uOfP2sDQQjFe3dREQazqQq3fLWkv5JPfMVnikLAoCPAB');

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
