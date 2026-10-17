<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AccessControlTest extends TestCase
{
    use RefreshDatabase;

    private function makeUser(string $role, string $email): User
    {
        return User::create([
            'uid' => 'user_' . $role,
            'name' => ucfirst($role),
            'email' => $email,
            'password' => 'motdepasse-solide',
            'role' => $role,
            'api_token' => hash('sha256', 'token-' . $role),
        ]);
    }

    public function test_protected_routes_reject_anonymous_requests(): void
    {
        $this->getJson('/api/v1/admin/users')->assertStatus(401);
        $this->postJson('/api/v1/payments/withdraw', ['amount' => 1000])->assertStatus(401);
        $this->getJson('/api/v1/conversations')->assertStatus(401);
    }

    public function test_public_catalogue_and_health_stay_open(): void
    {
        $this->getJson('/api/v1/courses')->assertOk();
        $this->getJson('/api/v1/health')->assertOk();
    }

    public function test_admin_routes_reject_non_admin_roles(): void
    {
        $this->makeUser('student', 'eleve@example.com');

        $this->withToken('token-student')->getJson('/api/v1/admin/users')->assertStatus(403);
        $this->withToken('token-student')
            ->patchJson('/api/v1/admin/users/user_student/role', ['role' => 'super_admin'])
            ->assertStatus(403);
    }

    public function test_admin_can_list_users(): void
    {
        $this->makeUser('admin', 'admin@example.com');

        $this->withToken('token-admin')->getJson('/api/v1/admin/users')->assertOk();
    }

    public function test_login_requires_the_right_password(): void
    {
        $this->makeUser('admin', 'admin@example.com');

        $this->postJson('/api/v1/auth/login', ['email' => 'admin@example.com', 'password' => 'faux'])
            ->assertStatus(401);
        $this->postJson('/api/v1/auth/login', ['email' => 'admin@example.com', 'password' => 'motdepasse-solide'])
            ->assertOk()
            ->assertJsonStructure(['token']);
    }

    public function test_login_does_not_provision_demo_accounts_from_email_keywords(): void
    {
        $this->makeUser('super_admin', 'root@example.com');

        $this->postJson('/api/v1/auth/login', ['email' => 'admin@inconnu.com', 'password' => 'x'])
            ->assertStatus(401);
    }

    public function test_register_cannot_choose_a_privileged_role(): void
    {
        $this->postJson('/api/v1/auth/register', [
            'displayName' => 'Pirate',
            'email' => 'pirate@example.com',
            'password' => 'motdepasse-solide',
            'role' => 'super_admin',
        ])->assertStatus(422);

        $this->postJson('/api/v1/auth/register', [
            'displayName' => 'Formateur',
            'email' => 'formateur@example.com',
            'password' => 'motdepasse-solide',
            'role' => 'teacher',
        ])->assertStatus(201)->assertJsonPath('user.balanceFcfa', 0);
    }

    public function test_profile_update_ignores_role_and_requires_token(): void
    {
        $user = $this->makeUser('student', 'eleve@example.com');

        $this->putJson('/api/v1/auth/profile', ['displayName' => 'X'])->assertStatus(401);

        $this->withToken('token-student')
            ->putJson('/api/v1/auth/profile', ['displayName' => 'Nouveau', 'role' => 'super_admin'])
            ->assertOk();

        $user->refresh();
        $this->assertSame('student', $user->role);
        $this->assertSame('Nouveau', $user->name);
    }
}
