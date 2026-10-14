<?php

namespace Tests\Feature;

use App\Models\Transaction;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class WithdrawalTest extends TestCase
{
    use RefreshDatabase;

    private function makeTeacher(int $balance = 50000): User
    {
        return User::create([
            'uid' => 'user_teacher',
            'name' => 'Formateur',
            'email' => 'formateur@example.com',
            'password' => 'motdepasse-solide',
            'role' => 'teacher',
            'balance_fcfa' => $balance,
            'api_token' => 'token-teacher',
        ]);
    }

    private function payload(array $override = []): array
    {
        return array_merge(['amount' => 10000, 'phone' => '771234567', 'method' => 'wave'], $override);
    }

    public function test_withdrawal_debits_balance_and_records_pending_transaction(): void
    {
        config(['services.intech.pay_url' => 'https://intech.test/pay']);
        Http::fake(['intech.test/*' => Http::response(['status' => 'PENDING'], 200)]);
        $teacher = $this->makeTeacher();

        $this->withToken('token-teacher')->postJson('/api/v1/payments/withdraw', $this->payload())
            ->assertCreated()
            ->assertJsonPath('newBalanceFcfa', 40000);

        $this->assertSame(40000, $teacher->fresh()->balance_fcfa);
        $this->assertDatabaseHas('transactions', ['user_id' => 'user_teacher', 'status' => 'PENDING']);
    }

    public function test_failed_provider_call_refunds_and_is_not_reported_as_success(): void
    {
        config(['services.intech.pay_url' => 'https://intech.test/pay']);
        Http::fake(['intech.test/*' => Http::response([], 500)]);
        $teacher = $this->makeTeacher();

        $this->withToken('token-teacher')->postJson('/api/v1/payments/withdraw', $this->payload())
            ->assertStatus(502)
            ->assertJsonPath('success', false);

        $this->assertSame(50000, $teacher->fresh()->balance_fcfa);
        $this->assertSame('FAILED', Transaction::first()->status);
    }

    public function test_withdrawal_above_balance_is_refused(): void
    {
        Http::fake();
        $this->makeTeacher(5000);

        $this->withToken('token-teacher')->postJson('/api/v1/payments/withdraw', $this->payload())
            ->assertStatus(422);

        Http::assertNothingSent();
        $this->assertSame(0, Transaction::count());
    }

    public function test_students_cannot_withdraw_and_body_user_is_ignored(): void
    {
        Http::fake();
        $this->makeTeacher();
        User::create([
            'uid' => 'user_student',
            'name' => 'Eleve',
            'email' => 'eleve@example.com',
            'password' => 'motdepasse-solide',
            'role' => 'student',
            'api_token' => 'token-student',
        ]);

        $this->withToken('token-student')
            ->postJson('/api/v1/payments/withdraw', $this->payload(['userId' => 'user_teacher']))
            ->assertStatus(403);

        Http::assertNothingSent();
    }

    public function test_wallet_of_another_user_is_forbidden(): void
    {
        $this->makeTeacher();
        User::create([
            'uid' => 'user_other',
            'name' => 'Autre',
            'email' => 'autre@example.com',
            'password' => 'motdepasse-solide',
            'role' => 'teacher',
            'api_token' => 'token-other',
        ]);

        $this->withToken('token-other')->getJson('/api/v1/teachers/user_teacher/wallet')->assertStatus(403);
        $this->withToken('token-teacher')->getJson('/api/v1/teachers/user_teacher/wallet')->assertOk();
    }
}
