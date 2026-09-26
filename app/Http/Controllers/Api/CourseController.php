<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Course;
use App\Models\CourseLesson;
use App\Models\CourseReplay;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class CourseController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = Course::with(['lessons', 'replays']);

        if ($request->filled('category') && $request->input('category') !== 'Toutes les catégories') {
            $query->where('category', $request->input('category'));
        }

        if ($request->filled('search')) {
            $search = $request->input('search');
            $query->where(function ($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                  ->orWhere('teacher_name', 'like', "%{$search}%")
                  ->orWhere('category', 'like', "%{$search}%");
            });
        }

        if ($request->boolean('published_only', false)) {
            $query->where('is_published', true);
        }

        $courses = $query->orderByDesc('created_at')->get();

        return response()->json([
            'success' => true,
            'courses' => $courses->map(fn (Course $c) => $this->formatCourse($c)),
        ]);
    }

    public function show(string $id): JsonResponse
    {
        $course = Course::with(['lessons', 'replays'])
            ->where('course_uid', $id)
            ->orWhere('id', $id)
            ->first();

        if (!$course) {
            return response()->json(['success' => false, 'message' => 'Formation introuvable'], 404);
        }

        return response()->json([
            'success' => true,
            'course' => $this->formatCourse($course),
        ]);
    }

    public function teacherCourses(string $teacherId): JsonResponse
    {
        $courses = Course::with(['lessons', 'replays'])
            ->where('teacher_id', $teacherId)
            ->orderByDesc('created_at')
            ->get();

        if ($courses->isEmpty()) {
            $courses = Course::with(['lessons', 'replays'])->orderByDesc('created_at')->get();
        }

        return response()->json([
            'success' => true,
            'courses' => $courses->map(fn (Course $c) => $this->formatCourse($c)),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $courseUid = $request->input('id') ?: ('course_' . time() . '_' . Str::lower(Str::random(4)));
        $isPublished = (bool) $request->input('isPublished', true);

        $course = Course::updateOrCreate(
            ['course_uid' => $courseUid],
            [
                'title' => $request->input('title', 'Nouvelle Formation'),
                'category' => $request->input('category', 'Informatique'),
                'description' => $request->input('description', ''),
                'price_cfa' => (int) $request->input('price', 25000),
                'level' => $request->input('level', 'Tous niveaux'),
                'duration' => $request->input('duration', '12h 30m'),
                'lessons_count' => (int) $request->input('lessonsCount', 0),
                'rating' => (float) $request->input('rating', 4.9),
                'students_count' => (int) $request->input('studentsCount', 0),
                'image_url' => $request->input('image', 'assets/images/student-library.jpeg'),
                'presentation_video_url' => $request->input('presentationVideoUrl'),
                'teacher_id' => $request->input('teacherId', 'demo_teacher_cheikh'),
                'teacher_name' => $request->input('trainerName', 'Cheikh Abdoulaye Diop'),
                'status' => $isPublished ? 'Publiée' : 'Brouillon',
                'is_published' => $isPublished,
            ]
        );

        return response()->json([
            'success' => true,
            'id' => $course->course_uid,
            'course' => $this->formatCourse($course->load(['lessons', 'replays'])),
        ], 201);
    }

    public function update(Request $request, string $id): JsonResponse
    {
        $course = Course::where('course_uid', $id)->orWhere('id', $id)->first();
        if (!$course) {
            return $this->store($request);
        }

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

        return response()->json([
            'success' => true,
            'course' => $this->formatCourse($course->fresh(['lessons', 'replays'])),
        ]);
    }

    public function togglePublish(string $id): JsonResponse
    {
        $course = Course::where('course_uid', $id)->orWhere('id', $id)->firstOrFail();
        $course->is_published = !$course->is_published;
        $course->status = $course->is_published ? 'Publiée' : 'Brouillon';
        $course->save();

        return response()->json([
            'success' => true,
            'isPublished' => $course->is_published,
            'status' => $course->status,
            'course' => $this->formatCourse($course->load(['lessons', 'replays'])),
        ]);
    }

    public function destroy(string $id): JsonResponse
    {
        $course = Course::where('course_uid', $id)->orWhere('id', $id)->first();
        if ($course) {
            CourseLesson::where('course_id', $course->course_uid)->delete();
            CourseReplay::where('course_id', $course->course_uid)->delete();
            $course->delete();
        }

        return response()->json([
            'success' => true,
            'message' => 'Formation supprimée avec succès',
        ]);
    }

    public function lessons(string $id): JsonResponse
    {
        $lessons = CourseLesson::where('course_id', $id)
            ->orderBy('sort_order')
            ->get();

        return response()->json([
            'success' => true,
            'lessons' => $lessons->map(fn (CourseLesson $l) => [
                'id' => $l->lesson_uid ?: (string) $l->id,
                'title' => $l->title,
                'duration' => $l->duration,
                'videoUrl' => $l->video_url,
                'isFreePreview' => $l->is_free_preview,
                'order' => $l->sort_order,
            ]),
        ]);
    }

    public function addLesson(Request $request, string $id): JsonResponse
    {
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
        $replay = CourseReplay::create([
            'course_id' => $id,
            'replay_uid' => $request->input('id') ?: ('replay_' . time()),
            'title' => $request->input('title', 'Replay session live'),
            'replay_url' => $request->input('replayUrl', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4'),
            'duration' => $request->input('duration', '1:30:00'),
            'recorded_at' => now(),
        ]);

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

    private function formatCourse(Course $course): array
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
                'videoUrl' => $l->video_url,
                'isFreePreview' => $l->is_free_preview,
                'order' => $l->sort_order,
            ])->values()->all(),
            'replays' => $course->replays->map(fn (CourseReplay $r) => [
                'id' => $r->replay_uid ?: (string) $r->id,
                'title' => $r->title,
                'replayUrl' => $r->replay_url,
                'duration' => $r->duration,
                'date' => ($r->recorded_at ?? $r->created_at)?->toIso8601String(),
            ])->values()->all(),
        ];
    }
}
