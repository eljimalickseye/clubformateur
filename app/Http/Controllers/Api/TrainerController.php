<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Course;
use App\Models\User;
use Illuminate\Http\JsonResponse;

class TrainerController extends Controller
{
    public function index(): JsonResponse
    {
        $teachers = User::where('role', 'teacher')->get();

        return response()->json([
            'success' => true,
            'trainers' => $teachers->map(function (User $t) {
                $coursesCount = Course::where('teacher_id', $t->uid)->count();
                return [
                    'id' => $t->uid ?? (string) $t->id,
                    'name' => $t->name,
                    'role' => $t->specialite ?? 'Formateur Expert',
                    'bio' => $t->bio ?? 'Formateur certifié au Club des Formateurs.',
                    'image' => $t->photo_url ?? 'assets/images/teacher-studio.jpeg',
                    'rating' => 4.9,
                    'coursesCount' => max(1, $coursesCount),
                    'studentsCount' => 420,
                    'isVerified' => $t->is_verified,
                ];
            }),
        ]);
    }

    public function show(string $id): JsonResponse
    {
        $teacher = User::where('uid', $id)->orWhere('id', $id)->first();
        if (!$teacher) {
            return response()->json(['success' => false, 'message' => 'Formateur introuvable'], 404);
        }

        $courses = Course::where('teacher_id', $teacher->uid)->get();

        return response()->json([
            'success' => true,
            'trainer' => [
                'id' => $teacher->uid ?? (string) $teacher->id,
                'name' => $teacher->name,
                'role' => $teacher->specialite ?? 'Formateur Expert',
                'bio' => $teacher->bio ?? '',
                'image' => $teacher->photo_url ?? 'assets/images/teacher-studio.jpeg',
                'rating' => 4.9,
                'coursesCount' => $courses->count(),
                'studentsCount' => $courses->sum('students_count'),
            ],
        ]);
    }
}
