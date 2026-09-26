<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Homework;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

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

    public function studentHomeworks(string $studentId): JsonResponse
    {
        $homeworks = Homework::where('student_id', $studentId)->orderByDesc('created_at')->get();
        return response()->json([
            'success' => true,
            'homeworks' => $homeworks->map(fn (Homework $h) => $this->formatHomework($h)),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $hw = Homework::create([
            'homework_uid' => $request->input('id') ?: ('hw_' . time()),
            'course_id' => $request->input('courseId', 'react'),
            'course_title' => $request->input('courseTitle', 'Formation'),
            'lesson_id' => $request->input('lessonId'),
            'student_id' => $request->input('studentId', 'demo_student_moussa'),
            'student_name' => $request->input('studentName', 'Moussa Ndiaye'),
            'teacher_id' => $request->input('teacherId', 'demo_teacher_cheikh'),
            'corrector_id' => $request->input('correctorId', 'demo_corrector_fatou'),
            'title' => $request->input('title', 'Devoir pratique'),
            'instructions' => $request->input('instructions'),
            'submission_text' => $request->input('submissionText'),
            'attachment_url' => $request->input('attachmentUrl'),
            'status' => 'pending',
        ]);

        return response()->json([
            'success' => true,
            'homework' => $this->formatHomework($hw),
        ], 201);
    }

    public function grade(Request $request, string $id): JsonResponse
    {
        $hw = Homework::where('homework_uid', $id)->orWhere('id', $id)->firstOrFail();
        $hw->grade = (float) $request->input('grade', 16.0);
        $hw->feedback = $request->input('feedback', 'Excellent travail !');
        $hw->corrector_id = $request->input('correctorId', $hw->corrector_id);
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
