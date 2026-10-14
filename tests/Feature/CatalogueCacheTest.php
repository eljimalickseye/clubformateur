<?php

namespace Tests\Feature;

use App\Models\Course;
use App\Models\Enrollment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class CatalogueCacheTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Cache::flush();
    }

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

    private function publishCourse(string $title = 'Laravel', int $price = 5000): string
    {
        $this->withToken('token-prof')->postJson('/api/v1/courses', ['title' => $title, 'price' => $price])->assertCreated();
        $uid = Course::where('title', $title)->first()->course_uid;
        $this->withToken('token-prof')->postJson("/api/v1/courses/$uid/lessons", [
            'title' => 'Lecon payante', 'videoUrl' => 'https://cdn.example.com/payante.mp4',
        ])->assertCreated();
        $this->withToken('token-prof')->postJson("/api/v1/courses/$uid/lessons", [
            'title' => 'Apercu', 'videoUrl' => 'https://cdn.example.com/apercu.mp4', 'isFreePreview' => true,
        ])->assertCreated();

        return $uid;
    }

    public function test_public_catalogue_never_exposes_paid_videos_or_drafts(): void
    {
        $this->makeUser('prof', 'teacher');
        $uid = $this->publishCourse();
        $this->withToken('token-prof')->postJson('/api/v1/courses', ['title' => 'Brouillon', 'isPublished' => false])->assertCreated();

        $body = $this->flushHeaders()->getJson('/api/v1/courses')->assertOk()->getContent();

        $this->assertStringNotContainsString('payante.mp4', $body);
        $this->assertStringContainsString('apercu.mp4', $body);
        $this->assertStringNotContainsString('Brouillon', $body);
        $this->flushHeaders()->getJson("/api/v1/courses/$uid")->assertOk()
            ->assertJsonMissing(['videoUrl' => 'https://cdn.example.com/payante.mp4']);
    }

    public function test_second_catalogue_read_is_served_from_cache(): void
    {
        $this->makeUser('prof', 'teacher');
        $this->publishCourse();
        $this->getJson('/api/v1/courses')->assertOk();

        DB::enableQueryLog();
        DB::flushQueryLog();
        $this->getJson('/api/v1/courses')->assertOk();

        $this->assertSame([], DB::getQueryLog());
    }

    public function test_writes_invalidate_the_catalogue(): void
    {
        $this->makeUser('prof', 'teacher');
        $uid = $this->publishCourse('Ancien titre');
        $this->getJson('/api/v1/courses')->assertJsonFragment(['title' => 'Ancien titre']);

        $this->withToken('token-prof')->putJson("/api/v1/courses/$uid", ['title' => 'Nouveau titre'])->assertOk();
        $this->getJson('/api/v1/courses')->assertJsonFragment(['title' => 'Nouveau titre'])
            ->assertJsonMissing(['title' => 'Ancien titre']);

        $this->withToken('token-prof')->patchJson("/api/v1/courses/$uid/toggle-publish")->assertOk();
        $this->getJson('/api/v1/courses')->assertJsonMissing(['title' => 'Nouveau titre']);
        $this->getJson("/api/v1/courses/$uid")->assertStatus(404);
    }

    public function test_enrollment_refreshes_the_students_counter(): void
    {
        $this->makeUser('prof', 'teacher');
        $this->makeUser('eleve', 'student');
        $uid = $this->publishCourse('Gratuit', 0);
        $this->getJson('/api/v1/courses')->assertJsonFragment(['studentsCount' => 0]);

        $this->withToken('token-eleve')->postJson('/api/v1/enrollments', ['courseId' => $uid])->assertCreated();

        $this->getJson('/api/v1/courses')->assertJsonFragment(['studentsCount' => 1]);
    }

    public function test_conditional_request_returns_304_with_cache_headers(): void
    {
        $this->makeUser('prof', 'teacher');
        $this->publishCourse();

        $first = $this->getJson('/api/v1/courses')->assertOk();
        $etag = $first->headers->get('ETag');
        $this->assertNotEmpty($etag);
        $this->assertStringContainsString('public', $first->headers->get('Cache-Control'));
        $this->assertStringContainsString('max-age=60', $first->headers->get('Cache-Control'));

        $this->withHeaders(['If-None-Match' => $etag])->getJson('/api/v1/courses')->assertStatus(304);
    }

    public function test_cached_lessons_still_respect_per_user_access(): void
    {
        $this->makeUser('prof', 'teacher');
        $this->makeUser('eleve', 'student');
        $uid = $this->publishCourse();

        // Le formateur remplit le cache avec la liste complete...
        $this->withToken('token-prof')->getJson("/api/v1/courses/$uid/lessons")->assertOk();

        // ...l'eleve non inscrit ne doit pas en beneficier.
        $response = $this->withToken('token-eleve')->getJson("/api/v1/courses/$uid/lessons")->assertOk();
        $this->assertStringNotContainsString('payante.mp4', $response->getContent());
        $this->assertStringContainsString('private', $response->headers->get('Cache-Control'));

        Enrollment::create([
            'enrollment_uid' => 'eleve_' . $uid, 'student_id' => 'eleve', 'student_name' => 'eleve', 'course_id' => $uid,
            'course_title' => 'Laravel', 'course_image' => 'x', 'trainer_name' => 'prof', 'category' => 'Informatique',
            'price_cfa' => 5000, 'payment_method' => 'Wave', 'status' => 'active', 'progress_percent' => 0, 'completed_lessons' => [],
        ]);
        $this->assertStringContainsString(
            'payante.mp4',
            $this->withToken('token-eleve')->getJson("/api/v1/courses/$uid/lessons")->getContent()
        );
    }
}
