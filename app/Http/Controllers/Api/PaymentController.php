<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class PaymentController extends Controller
{
    public function wallet(Request $request, string $teacherId): JsonResponse
    {
        $auth = $request->user();
        if ($auth->uid !== $teacherId && !$this->isAdmin($auth)) {
            return response()->json(['success' => false, 'message' => 'Accès refusé'], 403);
        }

        $user = User::where('uid', $teacherId)->firstOrFail();
        $transactions = Transaction::where('user_id', $teacherId)
            ->orderByDesc('created_at')
            ->get();

        return response()->json([
            'success' => true,
            'balanceFcfa' => $user->balance_fcfa,
            'transactions' => $transactions->map(fn (Transaction $t) => $this->formatTransaction($t)),
        ]);
    }

    public function transactions(Request $request): JsonResponse
    {
        $auth = $request->user();
        $query = Transaction::orderByDesc('created_at');

        if ($this->isAdmin($auth)) {
            if ($request->filled('userId')) {
                $query->where('user_id', $request->input('userId'));
            }
        } else {
            $query->where('user_id', $auth->uid);
        }

        return response()->json([
            'success' => true,
            'transactions' => $query->get()->map(fn (Transaction $t) => $this->formatTransaction($t)),
        ]);
    }

    public function withdraw(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'amount' => 'required|integer|min:1000|max:1000000',
            'phone' => ['required', 'string', 'regex:/^(\+?221|00221)?\s?7[0-9\s]{8,12}$/'],
            'method' => 'required|string|in:wave,orange,orange_money,om',
        ]);

        $auth = $request->user();
        if (!in_array($auth->role, ['teacher', 'admin', 'super_admin'], true)) {
            return response()->json(['success' => false, 'message' => 'Accès refusé'], 403);
        }

        $amount = (int) $validated['amount'];
        $rawPhone = preg_replace('/\D+/', '', $validated['phone']);
        if (str_starts_with($rawPhone, '00221')) {
            $rawPhone = substr($rawPhone, 5);
        }
        if (!str_starts_with($rawPhone, '221')) {
            $rawPhone = '221' . $rawPhone;
        }

        $isOrange = $validated['method'] !== 'wave';
        $serviceCode = $isOrange
            ? config('services.intech.om_code')
            : config('services.intech.wave_code');
        $providerName = $isOrange ? 'Orange Money Sénégal' : 'Wave Sénégal';
        $externalId = 'ANOUR_CASH_OUT_' . time() . '_' . Str::upper(Str::random(8));

        // Debit et creation de la transaction sous verrou : pas de retrait
        // au-dela du solde, pas de double debit concurrent.
        $tx = DB::transaction(function () use ($auth, $amount, $rawPhone, $serviceCode, $providerName, $externalId) {
            $user = User::whereKey($auth->getKey())->lockForUpdate()->first();
            if ($user->balance_fcfa < $amount) {
                return null;
            }
            $user->balance_fcfa -= $amount;
            $user->save();

            return Transaction::create([
                'user_id' => $user->uid,
                'external_transaction_id' => $externalId,
                'type' => 'withdrawal',
                'provider_code' => $serviceCode,
                'provider_name' => $providerName,
                'phone' => $rawPhone,
                'amount_fcfa' => $amount,
                'status' => 'PENDING',
            ]);
        });

        if (!$tx) {
            return response()->json(['success' => false, 'message' => 'Solde insuffisant.'], 422);
        }

        $apiKey = config('services.intech.key');
        $status = 'FAILED';
        try {
            $response = Http::timeout(6)->withHeaders([
                'Secretkey' => $apiKey,
                'API-KEY' => $apiKey,
            ])->post(config('services.intech.pay_url'), [
                'phone' => $rawPhone,
                'amount' => $amount,
                'codeService' => $serviceCode,
                'externalTransactionId' => $externalId,
                'apiKey' => $apiKey,
                'data' => [
                    'platform' => 'Club des Formateurs',
                    'userId' => $auth->uid,
                ],
            ]);

            $remote = strtoupper((string) $response->json('status'));
            if ($response->successful() && in_array($remote, ['PENDING', 'SUCCESS'], true)) {
                $status = $remote;
            } else {
                Log::warning('Intech: retrait refuse', ['external_id' => $externalId, 'http' => $response->status()]);
            }
        } catch (\Throwable $e) {
            Log::error('Intech: appel de retrait en echec', ['external_id' => $externalId, 'error' => $e->getMessage()]);
        }

        if ($status === 'FAILED') {
            // L'argent n'est pas parti : restitution du solde.
            DB::transaction(function () use ($auth, $amount) {
                User::whereKey($auth->getKey())->lockForUpdate()->first()->increment('balance_fcfa', $amount);
            });
        }

        $tx->status = $status;
        $tx->save();

        return response()->json([
            'success' => $status !== 'FAILED',
            'transaction' => $this->formatTransaction($tx),
            'newBalanceFcfa' => (int) $auth->fresh()->balance_fcfa,
        ], $status === 'FAILED' ? 502 : 201);
    }

    public function checkStatus(Request $request): JsonResponse
    {
        $validated = $request->validate(['externalTransactionId' => 'required|string|max:100']);
        $auth = $request->user();

        $query = Transaction::where('external_transaction_id', $validated['externalTransactionId']);
        if (!$this->isAdmin($auth)) {
            $query->where('user_id', $auth->uid);
        }
        $tx = $query->firstOrFail();

        try {
            $response = Http::timeout(5)->post(config('services.intech.status_url'), [
                'externalTransactionId' => $tx->external_transaction_id,
                'apiKey' => config('services.intech.key'),
            ]);
            if ($response->successful() && $response->json('status')) {
                $tx->status = strtoupper((string) $response->json('status'));
                $tx->save();
            }
        } catch (\Throwable $e) {
            Log::warning('Intech: statut indisponible', ['external_id' => $tx->external_transaction_id, 'error' => $e->getMessage()]);
        }

        return response()->json([
            'success' => true,
            'status' => $tx->status,
            'transaction' => $this->formatTransaction($tx),
        ]);
    }

    private function isAdmin(User $user): bool
    {
        return in_array($user->role, ['admin', 'super_admin'], true);
    }

    private function formatTransaction(Transaction $t): array
    {
        return [
            'id' => (string) $t->id,
            'userId' => $t->user_id,
            'externalTransactionId' => $t->external_transaction_id,
            'type' => $t->type,
            'serviceCode' => $t->provider_code,
            'providerName' => $t->provider_name,
            'phone' => $t->phone,
            'amount' => $t->amount_fcfa,
            'status' => $t->status,
            'createdAt' => $t->created_at?->toIso8601String(),
        ];
    }
}
