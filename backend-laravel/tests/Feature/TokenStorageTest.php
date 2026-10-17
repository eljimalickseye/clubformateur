<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TokenStorageTest extends TestCase
{
    use RefreshDatabase;

    private function register(): string
    {
        return $this->postJson('/api/v1/auth/register', [
            'displayName' => 'Eleve',
            'email' => 'eleve@example.com',
            'password' => 'motdepasse-solide',
        ])->assertCreated()->json('token');
    }

    public function test_only_a_hash_of_the_token_is_stored_and_the_token_works(): void
    {
        $token = $this->register();

        $stored = User::first()->getRawOriginal('api_token');
        $this->assertNotSame($token, $stored);
        $this->assertSame(hash('sha256', $token), $stored);
        $this->withToken($token)->getJson('/api/v1/auth/me')->assertOk();
    }

    public function test_the_stored_hash_cannot_be_used_as_a_token(): void
    {
        $this->register();
        $stored = User::first()->getRawOriginal('api_token');

        $this->withToken($stored)->getJson('/api/v1/auth/me')->assertStatus(401);
    }

    public function test_expired_token_is_refused(): void
    {
        $token = $this->register();
        User::first()->forceFill(['api_token_expires_at' => now()->subMinute()])->save();

        $this->withToken($token)->getJson('/api/v1/auth/me')->assertStatus(401);
    }

    public function test_login_issues_a_new_token_and_invalidates_the_previous_one(): void
    {
        $first = $this->register();

        $second = $this->postJson('/api/v1/auth/login', ['email' => 'eleve@example.com', 'password' => 'motdepasse-solide'])
            ->assertOk()->json('token');

        $this->assertNotSame($first, $second);
        $this->withToken($first)->getJson('/api/v1/auth/me')->assertStatus(401);
        $this->withToken($second)->getJson('/api/v1/auth/me')->assertOk();
    }

    public function test_logout_revokes_the_token(): void
    {
        $token = $this->register();

        $this->withToken($token)->postJson('/api/v1/auth/logout')->assertOk();
        $this->withToken($token)->getJson('/api/v1/auth/me')->assertStatus(401);
    }

    public function test_api_token_is_never_serialised(): void
    {
        $this->register();

        $this->assertArrayNotHasKey('api_token', User::first()->toArray());
    }
}
