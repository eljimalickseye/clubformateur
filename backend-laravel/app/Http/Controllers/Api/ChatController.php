<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ChatController extends Controller
{
    public function conversations(Request $request): JsonResponse
    {
        $user = $request->user();
        $query = Conversation::query();

        if (!$this->isAdmin($user)) {
            $query->where(function ($q) use ($user) {
                $q->where('student_id', $user->uid)->orWhere('teacher_id', $user->uid);
            });
        }

        $conversations = $query->orderByDesc('last_message_at')->orderByDesc('updated_at')->get();

        return response()->json([
            'success' => true,
            'conversations' => $conversations->map(fn (Conversation $c) => $this->formatConversation($c)),
        ]);
    }

    public function createOrGetConversation(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'studentId' => 'required|string|max:100',
            'teacherId' => 'required|string|max:100',
            'courseId' => 'sometimes|nullable|string|max:100',
            'courseTitle' => 'sometimes|nullable|string|max:255',
        ]);

        $user = $request->user();
        if (!in_array($user->uid, [$validated['studentId'], $validated['teacherId']], true)) {
            return response()->json(['success' => false, 'message' => 'Accès refusé'], 403);
        }

        $student = User::where('uid', $validated['studentId'])->firstOrFail();
        $teacher = User::where('uid', $validated['teacherId'])->firstOrFail();
        $conversationUid = $student->uid . '_' . $teacher->uid;

        $conversation = Conversation::firstOrCreate(
            ['conversation_uid' => $conversationUid],
            [
                'student_id' => $student->uid,
                'student_name' => $student->name,
                'student_photo_url' => $student->photo_url ?? '',
                'teacher_id' => $teacher->uid,
                'teacher_name' => $teacher->name,
                'teacher_photo_url' => $teacher->photo_url ?? '',
                'course_id' => $validated['courseId'] ?? null,
                'course_title' => $validated['courseTitle'] ?? null,
                'last_message' => 'Conversation démarrée',
                'last_message_at' => now(),
            ]
        );

        return response()->json([
            'success' => true,
            'conversation' => $this->formatConversation($conversation),
        ]);
    }

    public function messages(Request $request, string $conversationId): JsonResponse
    {
        $this->participantConversation($request, $conversationId);

        $messages = Message::where('conversation_id', $conversationId)
            ->orderBy('created_at')
            ->get();

        return response()->json([
            'success' => true,
            'messages' => $messages->map(fn (Message $m) => $this->formatMessage($m)),
        ]);
    }

    public function sendMessage(Request $request, string $conversationId): JsonResponse
    {
        $this->participantConversation($request, $conversationId);
        $validated = $request->validate([
            'content' => 'nullable|string|max:5000',
            'type' => 'sometimes|string|in:text,audio,file,image',
            'fileUrl' => 'sometimes|nullable|url|max:2048',
            'fileName' => 'sometimes|nullable|string|max:255',
            'audioDuration' => 'sometimes|nullable',
        ]);
        $user = $request->user();

        $message = Message::create([
            'conversation_id' => $conversationId,
            'sender_id' => $user->uid,
            'sender_name' => $user->name,
            'sender_role' => $user->role,
            'content' => $validated['content'] ?? '',
            'message_type' => $validated['type'] ?? 'text',
            'file_url' => $validated['fileUrl'] ?? null,
            'file_name' => $validated['fileName'] ?? null,
            'audio_duration' => $validated['audioDuration'] ?? null,
        ]);

        Conversation::where('conversation_uid', $conversationId)->update([
            'last_message' => $message->message_type === 'audio' ? 'Note vocale' : $message->content,
            'last_message_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => $this->formatMessage($message),
        ], 201);
    }

    public function markAsRead(Request $request, string $conversationId): JsonResponse
    {
        $this->participantConversation($request, $conversationId);
        Conversation::where('conversation_uid', $conversationId)->update(['unread_count' => 0]);

        return response()->json(['success' => true]);
    }

    private function isAdmin(User $user): bool
    {
        return in_array($user->role, ['admin', 'super_admin'], true);
    }

    private function participantConversation(Request $request, string $conversationId): Conversation
    {
        $conversation = Conversation::where('conversation_uid', $conversationId)->firstOrFail();
        $user = $request->user();

        if (!$this->isAdmin($user) && !in_array($user->uid, [$conversation->student_id, $conversation->teacher_id], true)) {
            abort(403, 'Accès refusé');
        }

        return $conversation;
    }

    private function formatConversation(Conversation $c): array
    {
        return [
            'id' => $c->conversation_uid,
            'studentId' => $c->student_id,
            'studentName' => $c->student_name,
            'studentPhotoUrl' => $c->student_photo_url ?? '',
            'teacherId' => $c->teacher_id,
            'teacherName' => $c->teacher_name,
            'teacherPhotoUrl' => $c->teacher_photo_url ?? '',
            'courseId' => $c->course_id ?? '',
            'courseTitle' => $c->course_title ?? '',
            'lastMessage' => $c->last_message ?? '',
            'lastMessageAt' => ($c->last_message_at ?? $c->updated_at)?->toIso8601String(),
            'unreadCount' => $c->unread_count,
        ];
    }

    private function formatMessage(Message $m): array
    {
        return [
            'id' => (string) $m->id,
            'conversationId' => $m->conversation_id,
            'senderId' => $m->sender_id,
            'senderName' => $m->sender_name,
            'senderRole' => $m->sender_role,
            'content' => $m->content,
            'type' => $m->message_type,
            'fileUrl' => $m->file_url,
            'fileName' => $m->file_name,
            'audioDuration' => $m->audio_duration,
            'createdAt' => $m->created_at?->toIso8601String(),
        ];
    }
}
