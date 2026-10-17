<?php

namespace Tests\Feature;

use App\Models\Course;
use App\Models\Enrollment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class LessonAccessTest extends TestCase
{
    use RefreshDatabase;

    private function makeUser(string $uid, string $role): User
    {
        return User::create([
            'uid' => $uid,
            'name' => $uid,
            'email' => $uid . '@example.com',
            'password' => 'motdepasse-solide',
            'role' => $role,
            'api_token' => hash('sha256', 'token-' . $uid),
        ]);
    }

    private function urls($response): array
    {
        return collect($response->json('lessons'))->pluck('videoUrl', 'title')->all();
    }

    public function test_paid_lesson_video_is_hidden_until_enrollment_is_active(): void
    {
        $this->makeUser('prof', 'teacher');
        $this->makeUser('eleve', 'student');
        $this->withToken('token-prof')->postJson('/api/v1/courses', ['title' => 'Laravel', 'price' => 5000])->assertCreated();
        $courseId = Course::first()->course_uid;
        $this->withToken('token-prof')->postJson("/api/v1/courses/$courseId/lessons", ['title' => 'L1', 'videoUrl' => 'https://cdn.example.com/l1.mp4'])->assertCreated();
        $this->withToken('token-prof')->postJson("/api/v1/courses/$courseId/lessons", ['title' => 'Apercu', 'videoUrl' => 'https://cdn.example.com/p.mp4', 'isFreePreview' => true])->assertCreated();

        $this->assertSame(
            ['L1' => null, 'Apercu' => 'https://cdn.example.com/p.mp4'],
            $this->urls($this->withToken('token-eleve')->getJson("/api/v1/courses/$courseId/lessons"))
        );

        $this->withToken('token-eleve')->postJson('/api/v1/enrollments', ['courseId' => $courseId])->assertCreated();
        $this->assertNull($this->urls($this->withToken('token-eleve')->getJson("/api/v1/courses/$courseId/lessons"))['L1']);

        Enrollment::first()->update(['status' => 'active']);
        $this->assertSame(
            'https://cdn.example.com/l1.mp4',
            $this->urls($this->withToken('token-eleve')->getJson("/api/v1/courses/$courseId/lessons"))['L1']
        );
        $this->assertSame(
            'https://cdn.example.com/l1.mp4',
            $this->urls($this->withToken('token-prof')->getJson("/api/v1/courses/$courseId/lessons"))['L1']
        );
    }
}
