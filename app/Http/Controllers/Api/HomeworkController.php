<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Course;
use App\Models\Homework;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class HomeworkController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = Homework::orderByDesc('created_at');
        if ($request->filled('courseId')) {
            $query->where('course_id', $request->input('courseId'));
        }
        if ($request->filled('status')) {
            $query->where('status', $request->input('status'));
        }

        return response()->json([
            'success' => true,
            'homeworks' => $query->get()->map(fn (Homework $h) => $this->formatHomework($h)),
        ]);
    }

    public function studentHomeworks(Request $request, string $studentId): JsonResponse
    {
        $user = $request->user();
        if ($user->uid !== $studentId && !in_array($user->role, ['teacher', 'corrector', 'admin', 'super_admin'], true)) {
            return response()->json(['success' => false, 'message' => 'Accès refusé'], 403);
        }

        $homeworks = Homework::where('student_id', $studentId)->orderByDesc('created_at')->get();
        return response()->json([
            'success' => true,
            'homeworks' => $homeworks->map(fn (Homework $h) => $this->formatHomework($h)),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'courseId' => 'required|string|max:100',
            'lessonId' => 'sometimes|nullable|string|max:100',
            'correctorId' => 'sometimes|nullable|string|max:100',
            'title' => 'required|string|max:255',
            'instructions' => 'sometimes|nullable|string|max:5000',
            'submissionText' => 'sometimes|nullable|string|max:20000',
            'attachmentUrl' => 'sometimes|nullable|url|max:2048',
        ]);
        $user = $request->user();
        $course = Course::where('course_uid', $validated['courseId'])->firstOrFail();

        $hw = Homework::create([
            'homework_uid' => 'hw_' . time() . '_' . Str::lower(Str::random(6)),
            'course_id' => $validated['courseId'],
            'course_title' => $course->title,
            'lesson_id' => $validated['lessonId'] ?? null,
            'student_id' => $user->uid,
            'student_name' => $user->name,
            'teacher_id' => $course->teacher_id,
            'corrector_id' => $validated['correctorId'] ?? null,
            'title' => $validated['title'],
            'instructions' => $validated['instructions'] ?? null,
            'submission_text' => $validated['submissionText'] ?? null,
            'attachment_url' => $validated['attachmentUrl'] ?? null,
            'status' => 'pending',
        ]);

        return response()->json([
            'success' => true,
            'homework' => $this->formatHomework($hw),
        ], 201);
    }

    public function grade(Request $request, string $id): JsonResponse
    {
        $user = $request->user();
        if (!in_array($user->role, ['teacher', 'corrector', 'admin', 'super_admin'], true)) {
            return response()->json(['success' => false, 'message' => 'Accès refusé'], 403);
        }

        $validated = $request->validate([
            'grade' => 'required|numeric|min:0|max:20',
            'feedback' => 'sometimes|nullable|string|max:5000',
        ]);

        $hw = Homework::where('homework_uid', $id)->orWhere('id', $id)->firstOrFail();
        $hw->grade = (float) $validated['grade'];
        $hw->feedback = $validated['feedback'] ?? null;
        $hw->corrector_id = $user->uid;
        $hw->status = 'corrected';
        $hw->save();

        return response()->json([
            'success' => true,
            'homework' => $this->formatHomework($hw),
        ]);
    }

    private function formatHomework(Homework $h): array
    {
        return [
            'id' => $h->homework_uid,
            'courseId' => $h->course_id,
            'courseTitle' => $h->course_title,
            'lessonId' => $h->lesson_id,
            'studentId' => $h->student_id,
            'studentName' => $h->student_name,
            'teacherId' => $h->teacher_id,
            'correctorId' => $h->corrector_id,
            'title' => $h->title,
            'instructions' => $h->instructions,
            'submissionText' => $h->submission_text,
            'attachmentUrl' => $h->attachment_url,
            'status' => $h->status,
            'grade' => $h->grade,
            'feedback' => $h->feedback,
            'submittedAt' => $h->created_at?->toIso8601String(),
        ];
    }
}
