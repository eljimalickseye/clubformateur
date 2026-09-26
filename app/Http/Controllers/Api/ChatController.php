<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Conversation;
use App\Models\Message;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ChatController extends Controller
{
    public function conversations(Request $request): JsonResponse
    {
        $query = Conversation::query();

        if ($request->filled('userId')) {
            $uid = $request->input('userId');
            $query->where(function ($q) use ($uid) {
                $q->where('student_id', $uid)->orWhere('teacher_id', $uid);
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
        $studentId = $request->input('studentId', 'demo_student_moussa');
        $teacherId = $request->input('teacherId', 'demo_teacher_cheikh');
        $conversationUid = $request->input('id') ?: ($studentId . '_' . $teacherId);

        $conversation = Conversation::updateOrCreate(
            ['conversation_uid' => $conversationUid],
            [
                'student_id' => $studentId,
                'student_name' => $request->input('studentName', 'Moussa Ndiaye'),
                'student_photo_url' => $request->input('studentPhotoUrl', ''),
                'teacher_id' => $teacherId,
                'teacher_name' => $request->input('teacherName', 'Cheikh Abdoulaye Diop'),
                'teacher_photo_url' => $request->input('teacherPhotoUrl', ''),
                'course_id' => $request->input('courseId', 'react'),
                'course_title' => $request->input('courseTitle', 'Formation'),
                'last_message' => $request->input('lastMessage', 'Conversation démarrée'),
                'last_message_at' => now(),
            ]
        );

        return response()->json([
            'success' => true,
            'conversation' => $this->formatConversation($conversation),
        ]);
    }

    public function messages(string $conversationId): JsonResponse
    {
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
        $message = Message::create([
            'conversation_id' => $conversationId,
            'sender_id' => $request->input('senderId', 'user'),
            'sender_name' => $request->input('senderName', 'Utilisateur'),
            'sender_role' => $request->input('senderRole', 'student'),
            'content' => $request->input('content', ''),
            'message_type' => $request->input('type', 'text'),
            'file_url' => $request->input('fileUrl'),
            'file_name' => $request->input('fileName'),
            'audio_duration' => $request->input('audioDuration'),
        ]);

        Conversation::where('conversation_uid', $conversationId)->update([
            'last_message' => $message->message_type === 'audio' ? '🎤 Note vocale' : $message->content,
            'last_message_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => $this->formatMessage($message),
        ], 201);
    }

    public function markAsRead(string $conversationId): JsonResponse
    {
        Conversation::where('conversation_uid', $conversationId)->update(['unread_count' => 0]);
        return response()->json(['success' => true]);
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
