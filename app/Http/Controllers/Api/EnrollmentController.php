<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Course;
use App\Models\Enrollment;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class EnrollmentController extends Controller
{
    public function index(): JsonResponse
    {
        $enrollments = Enrollment::orderByDesc('created_at')->get();
        return response()->json([
            'success' => true,
            'enrollments' => $enrollments->map(fn (Enrollment $e) => $this->formatEnrollment($e)),
        ]);
    }

    public function studentEnrollments(string $studentId): JsonResponse
    {
        $enrollments = Enrollment::where('student_id', $studentId)
            ->orderByDesc('created_at')
            ->get();

        return response()->json([
            'success' => true,
            'enrollments' => $enrollments->map(fn (Enrollment $e) => $this->formatEnrollment($e)),
        ]);
    }

    public function checkEnrollment(string $studentId, string $courseId): JsonResponse
    {
        $enrolled = Enrollment::where('student_id', $studentId)
            ->where('course_id', $courseId)
            ->exists();

        return response()->json([
            'success' => true,
            'isEnrolled' => $enrolled,
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $studentId = $request->input('studentId', 'demo_student_moussa');
        $courseId = $request->input('courseId', 'react');
        $enrollmentUid = $studentId . '_' . $courseId;

        $enrollment = Enrollment::updateOrCreate(
            ['enrollment_uid' => $enrollmentUid],
            [
                'student_id' => $studentId,
                'student_name' => $request->input('studentName', 'Moussa Ndiaye'),
                'course_id' => $courseId,
                'course_title' => $request->input('courseTitle', 'Formation'),
                'course_image' => $request->input('courseImage', 'assets/images/student-library.jpeg'),
                'trainer_name' => $request->input('trainerName', 'Cheikh Abdoulaye Diop'),
                'category' => $request->input('category', 'Informatique'),
                'price_cfa' => (int) $request->input('price', 25000),
                'payment_method' => $request->input('paymentMethod', 'Wave'),
                'status' => $request->input('status', 'active'),
                'progress_percent' => 0,
                'completed_lessons' => [],
            ]
        );

        Course::where('course_uid', $courseId)->increment('students_count');

        return response()->json([
            'success' => true,
            'enrollment' => $this->formatEnrollment($enrollment),
        ], 201);
    }

    public function updateStatus(Request $request, string $id): JsonResponse
    {
        $enrollment = Enrollment::where('enrollment_uid', $id)->orWhere('id', $id)->firstOrFail();
        $enrollment->status = $request->input('status', 'active');
        $enrollment->save();

        return response()->json([
            'success' => true,
            'enrollment' => $this->formatEnrollment($enrollment),
        ]);
    }

    public function updateProgress(Request $request, string $studentId, string $courseId): JsonResponse
    {
        $enrollment = Enrollment::where('student_id', $studentId)
            ->where('course_id', $courseId)
            ->first();

        if ($enrollment) {
            if ($request->has('progressPercent')) {
                $enrollment->progress_percent = (int) $request->input('progressPercent');
            }
            if ($request->has('completedLessons')) {
                $enrollment->completed_lessons = (array) $request->input('completedLessons');
            }
            $enrollment->save();
        }

        return response()->json([
            'success' => true,
            'enrollment' => $enrollment ? $this->formatEnrollment($enrollment) : null,
        ]);
    }

    private function formatEnrollment(Enrollment $e): array
    {
        return [
            'id' => $e->enrollment_uid,
            'studentId' => $e->student_id,
            'studentName' => $e->student_name,
            'courseId' => $e->course_id,
            'courseTitle' => $e->course_title,
            'courseImage' => $e->course_image,
            'trainerName' => $e->trainer_name,
            'category' => $e->category,
            'price' => $e->price_cfa,
            'paymentMethod' => $e->payment_method,
            'status' => $e->status,
            'progressPercent' => $e->progress_percent,
            'completedLessons' => $e->completed_lessons ?? [],
            'enrolledAt' => $e->created_at?->toIso8601String(),
        ];
    }
}
