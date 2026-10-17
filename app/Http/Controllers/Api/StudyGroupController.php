<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\StudyGroup;
use App\Models\StudyGroupMessage;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

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
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'category' => 'sometimes|string|max:100',
            'description' => 'sometimes|nullable|string|max:2000',
        ]);
        $user = $request->user();
        $creatorId = $user->uid;
        $group = StudyGroup::create([
            'group_uid' => 'group_' . time() . '_' . Str::lower(Str::random(6)),
            'name' => $validated['name'],
            'category' => $validated['category'] ?? 'Informatique',
            'description' => $validated['description'] ?? '',
            'creator_id' => $creatorId,
            'creator_name' => $user->name,
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
        $userId = $request->user()->uid;
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

    public function messages(Request $request, string $id): JsonResponse
    {
        $this->memberGroup($request, $id);
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
        $this->memberGroup($request, $id);
        $validated = $request->validate([
            'content' => 'nullable|string|max:5000',
            'type' => 'sometimes|string|in:text,audio,file,image',
            'fileUrl' => 'sometimes|nullable|url|max:2048',
            'audioDuration' => 'sometimes|nullable',
        ]);
        $user = $request->user();

        $msg = StudyGroupMessage::create([
            'group_id' => $id,
            'sender_id' => $user->uid,
            'sender_name' => $user->name,
            'content' => $validated['content'] ?? '',
            'message_type' => $validated['type'] ?? 'text',
            'file_url' => $validated['fileUrl'] ?? null,
            'audio_duration' => $validated['audioDuration'] ?? null,
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

    /** Les messages d'un groupe ne sont visibles et ecrits que par ses membres. */
    private function memberGroup(Request $request, string $id): StudyGroup
    {
        $group = StudyGroup::where('group_uid', $id)->firstOrFail();
        $user = $request->user();

        if (!in_array($user->uid, $group->member_ids ?? [], true)
            && !in_array($user->role, ['admin', 'super_admin'], true)) {
            abort(403, 'Accès refusé');
        }

        return $group;
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
