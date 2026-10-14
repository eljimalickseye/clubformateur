<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    public function register(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'displayName' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|string|min:8|max:128',
            'role' => 'nullable|string|in:student,teacher',
            'phoneNumber' => 'nullable|string|max:30',
            'specialite' => 'nullable|string|max:255',
            'bio' => 'nullable|string',
        ]);

        $uid = 'user_' . Str::lower(Str::random(12));
        $token = Str::random(80);

        $user = User::create([
            'uid' => $uid,
            'name' => $validated['displayName'],
            'email' => strtolower(trim($validated['email'])),
            'password' => Hash::make($validated['password']),
            'role' => $validated['role'] ?? 'student',
            'phone' => $validated['phoneNumber'] ?? null,
            'specialite' => $validated['specialite'] ?? null,
            'bio' => $validated['bio'] ?? null,
            'is_verified' => true,
            'onboarding_step' => 3,
            'balance_fcfa' => 0,
            'api_token' => $token,
        ]);

        return response()->json([
            'success' => true,
            'token' => $token,
            'user' => $this->formatUser($user),
        ], 201);
    }

    public function login(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        $user = User::where('email', strtolower(trim($validated['email'])))->first();

        if (!$user || !Hash::check($validated['password'], $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Identifiants invalides.',
            ], 401);
        }

        if (!$user->api_token) {
            $user->api_token = Str::random(80);
            $user->save();
        }

        return response()->json([
            'success' => true,
            'token' => $user->api_token,
            'user' => $this->formatUser($user),
        ]);
    }

    public function googleLogin(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'idToken' => 'required|string|max:4096',
        ]);

        // L'identite vient du jeton signe par Google, jamais du corps de la requete.
        $clientId = config('services.google.client_id');
        $google = null;
        if ($clientId) {
            try {
                $response = Http::timeout(6)->get('https://oauth2.googleapis.com/tokeninfo', [
                    'id_token' => $validated['idToken'],
                ]);
                $google = $response->successful() ? $response->json() : null;
            } catch (\Throwable $e) {
                report($e);
            }
        }

        $valid = $google
            && ($google['aud'] ?? null) === $clientId
            && filter_var($google['email_verified'] ?? false, FILTER_VALIDATE_BOOLEAN)
            && !empty($google['email']);
        if (!$valid) {
            return response()->json(['success' => false, 'message' => 'Jeton Google invalide.'], 401);
        }

        $validated['displayName'] = $google['name'] ?? null;
        $validated['photoUrl'] = $google['picture'] ?? null;
        $email = strtolower(trim($google['email']));
        $user = User::where('email', $email)->first();

        if (!$user) {
            $token = Str::random(80);
            $user = User::create([
                'uid' => 'user_' . Str::lower(Str::random(12)),
                'name' => $validated['displayName'] ?? explode('@', $email)[0],
                'email' => $email,
                'password' => Hash::make(Str::random(32)),
                'role' => 'student',
                'phone' => null,
                'photo_url' => $validated['photoUrl'] ?? null,
                'is_verified' => true,
                'onboarding_step' => 3,
                'balance_fcfa' => 0,
                'api_token' => $token,
            ]);
        } else {
            if (!$user->api_token) {
                $user->api_token = Str::random(80);
            }
            if (!empty($validated['photoUrl']) && empty($user->photo_url)) {
                $user->photo_url = $validated['photoUrl'];
            }
            $user->save();
        }

        return response()->json([
            'success' => true,
            'token' => $user->api_token,
            'user' => $this->formatUser($user),
        ]);
    }

    public function me(Request $request): JsonResponse
    {
        $user = $this->resolveUser($request);
        if (!$user) {
            return response()->json(['success' => false, 'message' => 'Non authentifié'], 401);
        }

        return response()->json([
            'success' => true,
            'user' => $this->formatUser($user),
        ]);
    }

    public function updateProfile(Request $request): JsonResponse
    {
        $user = $this->resolveUser($request);
        if (!$user) {
            return response()->json(['success' => false, 'message' => 'Non authentifié'], 401);
        }

        $validated = $request->validate([
            'displayName' => 'sometimes|string|max:255',
            'phoneNumber' => 'sometimes|nullable|string|max:30',
            'specialite' => 'sometimes|nullable|string|max:255',
            'bio' => 'sometimes|nullable|string|max:5000',
            'photoUrl' => 'sometimes|nullable|url|max:2048',
        ]);

        $map = [
            'displayName' => 'name',
            'phoneNumber' => 'phone',
            'specialite' => 'specialite',
            'bio' => 'bio',
            'photoUrl' => 'photo_url',
        ];
        foreach ($map as $input => $column) {
            if (array_key_exists($input, $validated)) {
                $user->{$column} = $validated[$input];
            }
        }
        $user->save();

        return response()->json([
            'success' => true,
            'user' => $this->formatUser($user),
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $user = $this->resolveUser($request);
        if ($user) {
            $user->api_token = null;
            $user->save();
        }

        return response()->json(['success' => true, 'message' => 'Déconnecté avec succès']);
    }

    private function resolveUser(Request $request): ?User
    {
        $bearer = $request->bearerToken();

        return $bearer ? User::where('api_token', $bearer)->first() : null;
    }

    private function formatUser(User $user): array
    {
        return [
            'uid' => $user->uid ?? (string) $user->id,
            'displayName' => $user->name,
            'email' => $user->email,
            'role' => $user->role,
            'phoneNumber' => $user->phone,
            'specialite' => $user->specialite,
            'bio' => $user->bio,
            'photoUrl' => $user->photo_url,
            'isEmailVerified' => $user->is_verified,
            'onboardingStep' => $user->onboarding_step,
            'balanceFcfa' => $user->balance_fcfa,
            'linkedTeacherId' => $user->linked_teacher_id,
        ];
    }
}
