<?php

namespace Tests\Feature;

use App\Models\Course;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CourseOwnershipTest extends TestCase
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

    public function test_student_cannot_create_a_course(): void
    {
        $this->makeUser('eleve', 'student');

        $this->withToken('token-eleve')->postJson('/api/v1/courses', ['title' => 'X'])->assertStatus(403);
    }

    public function test_teacher_owns_created_course_whatever_the_body_says(): void
    {
        $this->makeUser('prof', 'teacher');

        $this->withToken('token-prof')
            ->postJson('/api/v1/courses', ['title' => 'Laravel', 'teacherId' => 'autre', 'price' => 5000])
            ->assertCreated();

        $this->assertSame('prof', Course::first()->teacher_id);
    }

    public function test_another_teacher_cannot_modify_or_delete_the_course(): void
    {
        $this->makeUser('prof', 'teacher');
        $this->makeUser('rival', 'teacher');
        $this->withToken('token-prof')->postJson('/api/v1/courses', ['title' => 'Laravel'])->assertCreated();
        $uid = Course::first()->course_uid;

        $this->withToken('token-rival')->putJson("/api/v1/courses/$uid", ['title' => 'Piraté'])->assertStatus(403);
        $this->withToken('token-rival')->deleteJson("/api/v1/courses/$uid")->assertStatus(403);
        $this->assertSame('Laravel', Course::first()->title);
    }
}
