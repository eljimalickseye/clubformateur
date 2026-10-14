<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class GoogleLoginTest extends TestCase
{
    use RefreshDatabase;

    public function test_email_in_body_without_a_google_token_is_refused(): void
    {
        config(['services.google.client_id' => 'client-test']);
        User::create([
            'uid' => 'user_victime',
            'name' => 'Victime',
            'email' => 'victime@example.com',
            'password' => 'motdepasse-solide',
            'role' => 'student',
            'api_token' => 'token-victime',
        ]);

        $this->postJson('/api/v1/auth/google', ['email' => 'victime@example.com'])->assertStatus(422);
    }

    public function test_token_with_wrong_audience_or_unverified_email_is_refused(): void
    {
        config(['services.google.client_id' => 'client-test']);
        Http::fake(['oauth2.googleapis.com/*' => Http::response(['aud' => 'autre-app', 'email' => 'a@example.com', 'email_verified' => 'true'])]);
        $this->postJson('/api/v1/auth/google', ['idToken' => 'x'])->assertStatus(401);

        Http::fake(['oauth2.googleapis.com/*' => Http::response(['aud' => 'client-test', 'email' => 'a@example.com', 'email_verified' => 'false'])]);
        $this->postJson('/api/v1/auth/google', ['idToken' => 'x'])->assertStatus(401);
    }

    public function test_valid_token_creates_a_student_account(): void
    {
        config(['services.google.client_id' => 'client-test']);
        Http::fake(['oauth2.googleapis.com/*' => Http::response([
            'aud' => 'client-test', 'email' => 'Nouveau@Example.com', 'email_verified' => 'true', 'name' => 'Nouveau',
        ])]);

        $this->postJson('/api/v1/auth/google', ['idToken' => 'x', 'role' => 'super_admin'])
            ->assertOk()
            ->assertJsonPath('user.email', 'nouveau@example.com')
            ->assertJsonPath('user.role', 'student');
    }

    public function test_missing_server_configuration_refuses_every_token(): void
    {
        config(['services.google.client_id' => null]);
        Http::fake();

        $this->postJson('/api/v1/auth/google', ['idToken' => 'x'])->assertStatus(401);
        Http::assertNothingSent();
    }
}
