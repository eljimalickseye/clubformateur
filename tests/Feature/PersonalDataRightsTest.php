<?php

namespace Tests\Feature;

use App\Models\Transaction;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PersonalDataRightsTest extends TestCase
{
    use RefreshDatabase;

    private function makeUser(int $balance = 0): User
    {
        return User::create([
            'uid' => 'user_a',
            'name' => 'Awa Diop',
            'email' => 'awa@example.com',
            'phone' => '221771234567',
            'password' => 'motdepasse-solide',
            'role' => 'student',
            'balance_fcfa' => $balance,
            'api_token' => hash('sha256', 'token-a'),
        ]);
    }

    public function test_export_contains_only_the_callers_data(): void
    {
        $this->makeUser();
        User::create(['uid' => 'user_b', 'name' => 'Autre', 'email' => 'b@example.com', 'password' => 'x-motdepasse', 'role' => 'student']);
        Transaction::create(['user_id' => 'user_b', 'external_transaction_id' => 'T_B', 'type' => 'withdrawal', 'provider_code' => 'W', 'provider_name' => 'Wave', 'phone' => '221', 'amount_fcfa' => 1000, 'status' => 'SUCCESS']);

        $this->withToken('token-a')->getJson('/api/v1/auth/export')
            ->assertOk()
            ->assertJsonPath('user.email', 'awa@example.com')
            ->assertJsonCount(0, 'transactions');
        $this->flushHeaders()->getJson('/api/v1/auth/export')->assertStatus(401);
    }

    public function test_account_deletion_requires_the_password_and_anonymises(): void
    {
        $user = $this->makeUser();

        $this->withToken('token-a')->deleteJson('/api/v1/auth/account', ['password' => 'faux'])->assertStatus(403);
        $this->withToken('token-a')->deleteJson('/api/v1/auth/account', ['password' => 'motdepasse-solide'])->assertOk();

        $user->refresh();
        $this->assertSame('Compte supprimé', $user->name);
        $this->assertNull($user->phone);
        $this->assertStringNotContainsString('awa', $user->email);
        $this->withToken('token-a')->getJson('/api/v1/auth/me')->assertStatus(401);
        $this->postJson('/api/v1/auth/login', ['email' => 'awa@example.com', 'password' => 'motdepasse-solide'])->assertStatus(401);
    }

    public function test_account_with_remaining_balance_cannot_be_deleted(): void
    {
        $this->makeUser(5000);

        $this->withToken('token-a')->deleteJson('/api/v1/auth/account', ['password' => 'motdepasse-solide'])->assertStatus(409);
        $this->assertSame('Awa Diop', User::first()->name);
    }
}
