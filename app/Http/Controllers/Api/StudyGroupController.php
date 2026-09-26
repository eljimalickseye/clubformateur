<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\StudyGroup;
use App\Models\StudyGroupMessage;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class StudyGroupController extends Controller
{
    public function index(): JsonResponse
    {
        $groups = StudyGroup::orderByDesc('members_count')->get();
        return response()->json([
            'success' => true,
            'groups' => $groups->map(fn (StudyGroup $g) => $this->formatGroup($g)),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $creatorId = $request->input('creatorId', 'demo_student_moussa');
        $group = StudyGroup::create([
            'group_uid' => $request->input('id') ?: ('group_' . time()),
            'name' => $request->input('name', 'Groupe d\'étude'),
            'category' => $request->input('category', 'Informatique'),
            'description' => $request->input('description', ''),
            'creator_id' => $creatorId,
            'creator_name' => $request->input('creatorName', 'Moussa Ndiaye'),
            'members_count' => 1,
            'member_ids' => [$creatorId],
        ]);

        return response()->json([
            'success' => true,
            'group' => $this->formatGroup($group),
        ], 201);
    }

    public function join(Request $request, string $id): JsonResponse
    {
        $group = StudyGroup::where('group_uid', $id)->orWhere('id', $id)->firstOrFail();
        $userId = $request->input('userId', 'student');
        $members = $group->member_ids ?? [];
        if (!in_array($userId, $members, true)) {
            $members[] = $userId;
        }
        $group->member_ids = $members;
        $group->members_count = count($members);
        $group->save();

        return response()->json([
            'success' => true,
            'group' => $this->formatGroup($group),
        ]);
    }

    public function messages(string $id): JsonResponse
    {
        $msgs = StudyGroupMessage::where('group_id', $id)->orderBy('created_at')->get();
        return response()->json([
            'success' => true,
            'messages' => $msgs->map(fn (StudyGroupMessage $m) => [
                'id' => (string) $m->id,
                'groupId' => $m->group_id,
                'senderId' => $m->sender_id,
                'senderName' => $m->sender_name,
                'content' => $m->content,
                'type' => $m->message_type,
                'fileUrl' => $m->file_url,
                'audioDuration' => $m->audio_duration,
                'createdAt' => $m->created_at?->toIso8601String(),
            ]),
        ]);
    }

    public function sendMessage(Request $request, string $id): JsonResponse
    {
        $msg = StudyGroupMessage::create([
            'group_id' => $id,
            'sender_id' => $request->input('senderId', 'student'),
            'sender_name' => $request->input('senderName', 'Membre'),
            'content' => $request->input('content', ''),
            'message_type' => $request->input('type', 'text'),
            'file_url' => $request->input('fileUrl'),
            'audio_duration' => $request->input('audioDuration'),
        ]);

        return response()->json([
            'success' => true,
            'message' => [
                'id' => (string) $msg->id,
                'groupId' => $msg->group_id,
                'senderId' => $msg->sender_id,
                'senderName' => $msg->sender_name,
                'content' => $msg->content,
                'type' => $msg->message_type,
                'fileUrl' => $msg->file_url,
                'audioDuration' => $msg->audio_duration,
                'createdAt' => $msg->created_at?->toIso8601String(),
            ],
        ], 201);
    }

    private function formatGroup(StudyGroup $g): array
    {
        return [
            'id' => $g->group_uid,
            'name' => $g->name,
            'category' => $g->category,
            'description' => $g->description ?? '',
            'creatorId' => $g->creator_id,
            'creatorName' => $g->creator_name,
            'membersCount' => $g->members_count,
            'memberIds' => $g->member_ids ?? [],
            'createdAt' => $g->created_at?->toIso8601String(),
        ];
    }
}
