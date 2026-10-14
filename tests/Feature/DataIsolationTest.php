<?php

namespace Tests\Feature;

use App\Models\Conversation;
use App\Models\Course;
use App\Models\Enrollment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DataIsolationTest extends TestCase
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
            'api_token' => 'token-' . $uid,
        ]);
    }

    private function makeCourse(int $price): Course
    {
        return Course::create([
            'course_uid' => 'course_1',
            'title' => 'Laravel',
            'category' => 'Informatique',
            'description' => '',
            'price_cfa' => $price,
            'level' => 'Tous niveaux',
            'duration' => '1h',
            'lessons_count' => 0,
            'rating' => 0,
            'students_count' => 0,
            'image_url' => 'x',
            'teacher_id' => 'prof',
            'teacher_name' => 'Prof',
            'status' => 'Publiée',
            'is_published' => true,
        ]);
    }

    public function test_enrollment_price_and_status_come_from_the_server(): void
    {
        $this->makeUser('eleve', 'student');
        $this->makeCourse(25000);

        $this->withToken('token-eleve')
            ->postJson('/api/v1/enrollments', [
                'courseId' => 'course_1',
                'price' => 0,
                'status' => 'active',
                'studentId' => 'quelquun_d_autre',
            ])
            ->assertCreated()
            ->assertJsonPath('enrollment.price', 25000)
            ->assertJsonPath('enrollment.status', 'pending')
            ->assertJsonPath('enrollment.studentId', 'eleve');
    }

    public function test_free_course_enrollment_is_active_and_not_counted_twice(): void
    {
        $this->makeUser('eleve', 'student');
        $this->makeCourse(0);

        $this->withToken('token-eleve')->postJson('/api/v1/enrollments', ['courseId' => 'course_1'])
            ->assertCreated()->assertJsonPath('enrollment.status', 'active');
        $this->withToken('token-eleve')->postJson('/api/v1/enrollments', ['courseId' => 'course_1'])->assertOk();

        $this->assertSame(1, Course::first()->students_count);
    }

    public function test_student_cannot_read_or_alter_another_students_enrollments(): void
    {
        $this->makeUser('eleve', 'student');
        $this->makeUser('voisin', 'student');
        Enrollment::create([
            'enrollment_uid' => 'voisin_course_1',
            'student_id' => 'voisin',
            'student_name' => 'voisin',
            'course_id' => 'course_1',
            'course_title' => 'Laravel',
            'course_image' => 'x',
            'trainer_name' => 'Prof',
            'category' => 'Informatique',
            'price_cfa' => 0,
            'payment_method' => 'Wave',
            'status' => 'active',
            'progress_percent' => 0,
            'completed_lessons' => [],
        ]);

        $this->withToken('token-eleve')->getJson('/api/v1/students/voisin/enrollments')->assertStatus(403);
        $this->withToken('token-eleve')->getJson('/api/v1/enrollments')->assertStatus(403);
        $this->withToken('token-eleve')
            ->putJson('/api/v1/students/voisin/progress/course_1', ['progressPercent' => 100])
            ->assertStatus(403);
        $this->withToken('token-eleve')
            ->patchJson('/api/v1/enrollments/voisin_course_1/status', ['status' => 'completed'])
            ->assertStatus(403);
    }

    public function test_conversation_is_private_to_its_participants(): void
    {
        $this->makeUser('eleve', 'student');
        $this->makeUser('prof', 'teacher');
        $this->makeUser('intrus', 'student');

        $this->withToken('token-eleve')
            ->postJson('/api/v1/conversations', ['studentId' => 'eleve', 'teacherId' => 'prof'])
            ->assertOk();
        $uid = Conversation::first()->conversation_uid;

        $this->withToken('token-eleve')
            ->postJson("/api/v1/conversations/$uid/messages", ['content' => 'Bonjour', 'senderId' => 'prof'])
            ->assertCreated()
            ->assertJsonPath('message.senderId', 'eleve');

        $this->withToken('token-intrus')->getJson("/api/v1/conversations/$uid/messages")->assertStatus(403);
        $this->withToken('token-intrus')
            ->postJson("/api/v1/conversations/$uid/messages", ['content' => 'Intrusion'])
            ->assertStatus(403);
        $this->withToken('token-intrus')->postJson('/api/v1/conversations', ['studentId' => 'eleve', 'teacherId' => 'prof'])
            ->assertStatus(403);
        $this->withToken('token-intrus')->getJson('/api/v1/conversations')
            ->assertOk()->assertJsonCount(0, 'conversations');
    }

    public function test_only_staff_can_grade_and_grade_is_bounded(): void
    {
        $this->makeUser('eleve', 'student');
        $this->makeUser('corr', 'corrector');
        $this->makeCourse(0);

        $this->withToken('token-eleve')
            ->postJson('/api/v1/homeworks', ['courseId' => 'course_1', 'title' => 'TP1'])
            ->assertCreated();
        $id = \App\Models\Homework::first()->homework_uid;

        $this->withToken('token-eleve')->patchJson("/api/v1/homeworks/$id/grade", ['grade' => 20])->assertStatus(403);
        $this->withToken('token-corr')->patchJson("/api/v1/homeworks/$id/grade", ['grade' => 25])->assertStatus(422);
        $this->withToken('token-corr')->patchJson("/api/v1/homeworks/$id/grade", ['grade' => 15])->assertOk();
    }

    public function test_only_super_admin_can_grant_an_admin_role(): void
    {
        $this->makeUser('adm', 'admin');
        $this->makeUser('root', 'super_admin');
        $this->makeUser('eleve', 'student');

        $this->withToken('token-adm')->patchJson('/api/v1/admin/users/eleve/role', ['role' => 'super_admin'])->assertStatus(403);
        $this->withToken('token-adm')->patchJson('/api/v1/admin/users/eleve/role', ['role' => 'corrector'])
            ->assertOk()->assertJsonMissingPath('user.api_token');
        $this->withToken('token-root')->patchJson('/api/v1/admin/users/eleve/role', ['role' => 'admin'])->assertOk();
    }
}
