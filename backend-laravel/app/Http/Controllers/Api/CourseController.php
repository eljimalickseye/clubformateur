<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Course;
use App\Models\CourseLesson;
use App\Models\CourseReplay;
use App\Models\Enrollment;
use App\Models\User;
use App\Support\CourseCache;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class CourseController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $category = $request->filled('category') && $request->input('category') !== 'Toutes les catégories'
            ? (string) $request->input('category')
            : null;
        $search = $request->filled('search') ? (string) $request->input('search') : null;

        // Catalogue public : identique pour tous les visiteurs, donc partageable
        // en cache. Seules les formations publiees sont exposees, sans video payante.
        $courses = CourseCache::remember('index:' . md5(json_encode([$category, $search])), function () use ($category, $search) {
            $query = Course::with(['lessons', 'replays'])->where('is_published', true);

            if ($category) {
                $query->where('category', $category);
            }
            if ($search) {
                $query->where(function ($q) use ($search) {
                    $q->where('title', 'like', "%{$search}%")
                      ->orWhere('teacher_name', 'like', "%{$search}%")
                      ->orWhere('category', 'like', "%{$search}%");
                });
            }

            return $query->orderByDesc('created_at')->get()
                ->map(fn (Course $c) => $this->formatCourse($c, true))
                ->all();
        });

        return $this->publiclyCached($request, ['success' => true, 'courses' => $courses]);
    }

    public function show(Request $request, string $id): JsonResponse
    {
        $course = CourseCache::remember('show:' . $id, function () use ($id) {
            $course = Course::with(['lessons', 'replays'])
                ->where('is_published', true)
                ->where(function ($q) use ($id) {
                    $q->where('course_uid', $id)->orWhere('id', $id);
                })
                ->first();

            return $course ? $this->formatCourse($course, true) : null;
        });

        if (!$course) {
            return response()->json(['success' => false, 'message' => 'Formation introuvable'], 404);
        }

        return $this->publiclyCached($request, ['success' => true, 'course' => $course]);
    }

    public function teacherCourses(string $teacherId): JsonResponse
    {
        $courses = Course::with(['lessons', 'replays'])
            ->where('teacher_id', $teacherId)
            ->orderByDesc('created_at')
            ->get();


        return response()->json([
            'success' => true,
            'courses' => $courses->map(fn (Course $c) => $this->formatCourse($c)),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'title' => 'required|string|max:255',
            'price' => 'sometimes|integer|min:0|max:10000000',
            'presentationVideoUrl' => 'sometimes|nullable|url|max:2048',
        ]);
        $auth = $request->user();
        if (!$this->canManageCourses($auth)) {
            return response()->json(['success' => false, 'message' => 'Accès refusé'], 403);
        }

        $courseUid = 'course_' . time() . '_' . Str::lower(Str::random(6));
        $isPublished = (bool) $request->input('isPublished', true);

        $course = Course::create(
            [
                'course_uid' => $courseUid,
                'title' => $request->input('title'),
                'category' => $request->input('category', 'Informatique'),
                'description' => $request->input('description', ''),
                'price_cfa' => (int) $request->input('price', 25000),
                'level' => $request->input('level', 'Tous niveaux'),
                'duration' => $request->input('duration', '12h 30m'),
                'lessons_count' => (int) $request->input('lessonsCount', 0),
                'rating' => 0,
                'students_count' => 0,
                'image_url' => $request->input('image', 'assets/images/student-library.jpeg'),
                'presentation_video_url' => $request->input('presentationVideoUrl'),
                'teacher_id' => $auth->uid,
                'teacher_name' => $auth->name,
                'status' => $isPublished ? 'Publiée' : 'Brouillon',
                'is_published' => $isPublished,
            ]
        );

        CourseCache::flush();

        return response()->json([
            'success' => true,
            'id' => $course->course_uid,
            'course' => $this->formatCourse($course->load(['lessons', 'replays'])),
        ], 201);
    }

    public function update(Request $request, string $id): JsonResponse
    {
        $course = $this->ownedCourse($request, $id);

        $course->update(array_filter([
            'title' => $request->input('title'),
            'category' => $request->input('category'),
            'description' => $request->input('description'),
            'price_cfa' => $request->has('price') ? (int) $request->input('price') : null,
            'level' => $request->input('level'),
            'duration' => $request->input('duration'),
            'image_url' => $request->input('image'),
            'presentation_video_url' => $request->input('presentationVideoUrl', $course->presentation_video_url),
            'status' => $request->input('status'),
            'is_published' => $request->has('isPublished') ? (bool) $request->input('isPublished') : null,
        ], fn ($v) => !is_null($v)));

        CourseCache::flush();

        return response()->json([
            'success' => true,
            'course' => $this->formatCourse($course->fresh(['lessons', 'replays'])),
        ]);
    }

    public function togglePublish(Request $request, string $id): JsonResponse
    {
        $course = $this->ownedCourse($request, $id);
        $course->is_published = !$course->is_published;
        $course->status = $course->is_published ? 'Publiée' : 'Brouillon';
        $course->save();
        CourseCache::flush();

        return response()->json([
            'success' => true,
            'isPublished' => $course->is_published,
            'status' => $course->status,
            'course' => $this->formatCourse($course->load(['lessons', 'replays'])),
        ]);
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $course = $this->ownedCourse($request, $id);
        CourseLesson::where('course_id', $course->course_uid)->delete();
        CourseReplay::where('course_id', $course->course_uid)->delete();
        $course->delete();
        CourseCache::flush();

        return response()->json([
            'success' => true,
            'message' => 'Formation supprimée avec succès',
        ]);
    }

    public function lessons(Request $request, string $id): JsonResponse
    {
        $hasAccess = $this->hasFullAccess($request->user(), $id);
        $lessons = CourseCache::remember('lessons:' . $id, fn () => CourseLesson::where('course_id', $id)
            ->orderBy('sort_order')
            ->get());

        return response()->json([
            'success' => true,
            'lessons' => $lessons->map(fn (CourseLesson $l) => [
                'id' => $l->lesson_uid ?: (string) $l->id,
                'title' => $l->title,
                'duration' => $l->duration,
                // Les videos payantes ne sont revelees qu'aux inscrits, au proprietaire et aux admins.
                'videoUrl' => ($hasAccess || $l->is_free_preview) ? $l->video_url : null,
                'isFreePreview' => $l->is_free_preview,
                'order' => $l->sort_order,
            ]),
        ])->header('Cache-Control', 'private, no-cache');
    }

    public function addLesson(Request $request, string $id): JsonResponse
    {
        $this->ownedCourse($request, $id);
        $request->validate([
            'title' => 'sometimes|string|max:255',
            'videoUrl' => 'sometimes|nullable|url|max:2048',
        ]);
        $lessonUid = $request->input('id') ?: ('lesson_' . time() . '_' . Str::lower(Str::random(4)));
        $order = CourseLesson::where('course_id', $id)->count() + 1;

        $lesson = CourseLesson::create([
            'course_id' => $id,
            'lesson_uid' => $lessonUid,
            'title' => $request->input('title', 'Nouvelle leçon vidéo'),
            'duration' => $request->input('duration', '12:00'),
            'video_url' => $request->input('videoUrl'),
            'is_free_preview' => (bool) $request->input('isFreePreview', false),
            'sort_order' => (int) $request->input('order', $order),
        ]);

        Course::where('course_uid', $id)->increment('lessons_count');
        CourseCache::flush();

        return response()->json([
            'success' => true,
            'lesson' => [
                'id' => $lesson->lesson_uid,
                'title' => $lesson->title,
                'duration' => $lesson->duration,
                'videoUrl' => $lesson->video_url,
                'isFreePreview' => $lesson->is_free_preview,
                'order' => $lesson->sort_order,
            ],
        ], 201);
    }

    public function addReplay(Request $request, string $id): JsonResponse
    {
        $this->ownedCourse($request, $id);
        $request->validate([
            'title' => 'sometimes|string|max:255',
            'replayUrl' => 'required|url|max:2048',
        ]);
        $replay = CourseReplay::create([
            'course_id' => $id,
            'replay_uid' => $request->input('id') ?: ('replay_' . time()),
            'title' => $request->input('title', 'Replay session live'),
            'replay_url' => $request->input('replayUrl'),
            'duration' => $request->input('duration', '1:30:00'),
            'recorded_at' => now(),
        ]);
        CourseCache::flush();

        return response()->json([
            'success' => true,
            'replay' => [
                'id' => $replay->replay_uid,
                'title' => $replay->title,
                'replayUrl' => $replay->replay_url,
                'duration' => $replay->duration,
                'date' => $replay->recorded_at?->toIso8601String(),
            ],
        ], 201);
    }

    private function hasFullAccess(User $user, string $courseId): bool
    {
        $course = Course::where('course_uid', $courseId)->first();
        if (!$course) {
            return false;
        }
        if (in_array($user->role, ['admin', 'super_admin'], true) || $course->teacher_id === $user->uid) {
            return true;
        }
        if ((int) $course->price_cfa === 0) {
            return true;
        }

        return Enrollment::where('student_id', $user->uid)
            ->where('course_id', $course->course_uid)
            ->where('status', 'active')
            ->exists();
    }

    /**
     * Reponse publique avec validation conditionnelle : le navigateur ou le
     * service worker de la PWA revalide avec If-None-Match et recoit un 304
     * sans corps tant que le catalogue n'a pas change.
     */
    private function publiclyCached(Request $request, array $payload): JsonResponse
    {
        $response = response()->json($payload);
        $response->setEtag(md5($response->getContent()));
        $response->setPublic();
        $response->setMaxAge(60);
        $response->headers->addCacheControlDirective('stale-while-revalidate', '300');
        $response->isNotModified($request);

        return $response;
    }

    private function canManageCourses(User $user): bool
    {
        return in_array($user->role, ['teacher', 'admin', 'super_admin'], true);
    }

    private function ownedCourse(Request $request, string $id): Course
    {
        $course = Course::where('course_uid', $id)->orWhere('id', $id)->firstOrFail();
        $user = $request->user();

        $isOwner = $this->canManageCourses($user) && $course->teacher_id === $user->uid;
        $isAdmin = in_array($user->role, ['admin', 'super_admin'], true);
        if (!$isOwner && !$isAdmin) {
            abort(403, 'Accès refusé');
        }

        return $course;
    }

    private function formatCourse(Course $course, bool $public = false): array
    {
        return [
            'id' => $course->course_uid,
            'title' => $course->title,
            'category' => $course->category,
            'description' => $course->description,
            'price' => $course->price_cfa,
            'level' => $course->level,
            'duration' => $course->duration,
            'lessonsCount' => max($course->lessons_count, $course->lessons->count()),
            'rating' => $course->rating,
            'studentsCount' => $course->students_count,
            'image' => $course->image_url,
            'presentationVideoUrl' => $course->presentation_video_url,
            'teacherId' => $course->teacher_id,
            'trainerName' => $course->teacher_name,
            'status' => $course->status,
            'isPublished' => $course->is_published,
            'lessons' => $course->lessons->map(fn (CourseLesson $l) => [
                'id' => $l->lesson_uid ?: (string) $l->id,
                'title' => $l->title,
                'duration' => $l->duration,
                'videoUrl' => (!$public || $l->is_free_preview) ? $l->video_url : null,
                'isFreePreview' => $l->is_free_preview,
                'order' => $l->sort_order,
            ])->values()->all(),
            'replays' => $course->replays->map(fn (CourseReplay $r) => [
                'id' => $r->replay_uid ?: (string) $r->id,
                'title' => $r->title,
                'replayUrl' => $public ? null : $r->replay_url,
                'duration' => $r->duration,
                'date' => ($r->recorded_at ?? $r->created_at)?->toIso8601String(),
            ])->values()->all(),
        ];
    }
}
