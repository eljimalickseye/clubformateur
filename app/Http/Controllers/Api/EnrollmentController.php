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

    public function studentEnrollments(Request $request, string $studentId): JsonResponse
    {
        if (!$this->isSelfOrAdmin($request, $studentId)) {
            return response()->json(['success' => false, 'message' => 'Accès refusé'], 403);
        }

        $enrollments = Enrollment::where('student_id', $studentId)
            ->orderByDesc('created_at')
            ->get();

        return response()->json([
            'success' => true,
            'enrollments' => $enrollments->map(fn (Enrollment $e) => $this->formatEnrollment($e)),
        ]);
    }

    public function checkEnrollment(Request $request, string $studentId, string $courseId): JsonResponse
    {
        if (!$this->isSelfOrAdmin($request, $studentId)) {
            return response()->json(['success' => false, 'message' => 'Accès refusé'], 403);
        }

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
        $validated = $request->validate([
            'courseId' => 'required|string|max:100',
            'paymentMethod' => 'sometimes|string|max:50',
        ]);

        $auth = $request->user();
        $course = Course::where('course_uid', $validated['courseId'])->firstOrFail();
        $studentId = $auth->uid;
        $enrollmentUid = $studentId . '_' . $course->course_uid;

        // Le prix et le statut viennent du serveur : un apprenant ne peut pas
        // s'inscrire gratuitement a une formation payante.
        $price = (int) $course->price_cfa;
        $existing = Enrollment::where('enrollment_uid', $enrollmentUid)->first();

        $enrollment = $existing ?? Enrollment::create([
            'enrollment_uid' => $enrollmentUid,
            'student_id' => $studentId,
            'student_name' => $auth->name,
            'course_id' => $course->course_uid,
            'course_title' => $course->title,
            'course_image' => $course->image_url,
            'trainer_name' => $course->teacher_name,
            'category' => $course->category,
            'price_cfa' => $price,
            'payment_method' => $validated['paymentMethod'] ?? 'Wave',
            'status' => $price === 0 ? 'active' : 'pending',
            'progress_percent' => 0,
            'completed_lessons' => [],
        ]);

        if (!$existing) {
            Course::where('course_uid', $course->course_uid)->increment('students_count');
        }

        return response()->json([
            'success' => true,
            'enrollment' => $this->formatEnrollment($enrollment),
        ], $existing ? 200 : 201);
    }

    public function updateStatus(Request $request, string $id): JsonResponse
    {
        $enrollment = Enrollment::where('enrollment_uid', $id)->orWhere('id', $id)->firstOrFail();
        $enrollment->status = $request->validate(['status' => 'required|string|in:pending,active,cancelled,completed'])['status'];
        $enrollment->save();

        return response()->json([
            'success' => true,
            'enrollment' => $this->formatEnrollment($enrollment),
        ]);
    }

    public function updateProgress(Request $request, string $studentId, string $courseId): JsonResponse
    {
        if ($request->user()->uid !== $studentId) {
            return response()->json(['success' => false, 'message' => 'Accès refusé'], 403);
        }

        $validated = $request->validate([
            'progressPercent' => 'sometimes|integer|min:0|max:100',
            'completedLessons' => 'sometimes|array',
            'completedLessons.*' => 'string|max:100',
        ]);

        $enrollment = Enrollment::where('student_id', $studentId)
            ->where('course_id', $courseId)
            ->firstOrFail();

        if (array_key_exists('progressPercent', $validated)) {
            $enrollment->progress_percent = $validated['progressPercent'];
        }
        if (array_key_exists('completedLessons', $validated)) {
            $enrollment->completed_lessons = $validated['completedLessons'];
        }
        $enrollment->save();

        return response()->json([
            'success' => true,
            'enrollment' => $this->formatEnrollment($enrollment),
        ]);
    }

    private function isSelfOrAdmin(Request $request, string $studentId): bool
    {
        $user = $request->user();

        return $user->uid === $studentId || in_array($user->role, ['admin', 'super_admin'], true);
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
