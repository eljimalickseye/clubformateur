<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    public function register(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'displayName' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|string|min:6',
            'role' => 'nullable|string|in:student,teacher,corrector,admin,super_admin',
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
            'phone' => $validated['phoneNumber'] ?? '+221 77 000 00 00',
            'specialite' => $validated['specialite'] ?? null,
            'bio' => $validated['bio'] ?? null,
            'is_verified' => true,
            'onboarding_step' => 3,
            'balance_fcfa' => ($validated['role'] ?? 'student') === 'teacher' ? 420000 : 0,
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
        $email = strtolower(trim((string) $request->input('email', '')));
        $password = (string) $request->input('password', '');

        $user = User::where('email', $email)->first();

        if (!$user) {
            // Auto-provision demo accounts if requested
            if (str_contains($email, 'cheikh') || str_contains($email, 'formateur')) {
                $user = User::where('role', 'teacher')->first();
            } elseif (str_contains($email, 'moussa') || str_contains($email, 'apprenant')) {
                $user = User::where('role', 'student')->first();
            } elseif (str_contains($email, 'fatou') || str_contains($email, 'correct')) {
                $user = User::where('role', 'corrector')->first();
            } elseif (str_contains($email, 'admin')) {
                $user = User::where('role', 'super_admin')->first();
            }
        }

        if (!$user) {
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
        $uid = $request->input('uid');
        $user = $uid ? User::where('uid', $uid)->first() : $this->resolveUser($request);

        if (!$user) {
            $user = User::first();
        }

        if ($user) {
            if ($request->filled('displayName')) {
                $user->name = $request->input('displayName');
            }
            if ($request->filled('phoneNumber')) {
                $user->phone = $request->input('phoneNumber');
            }
            if ($request->filled('specialite')) {
                $user->specialite = $request->input('specialite');
            }
            if ($request->filled('bio')) {
                $user->bio = $request->input('bio');
            }
            if ($request->filled('photoUrl')) {
                $user->photo_url = $request->input('photoUrl');
            }
            $user->save();
        }

        return response()->json([
            'success' => true,
            'user' => $user ? $this->formatUser($user) : null,
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
        if ($bearer) {
            return User::where('api_token', $bearer)->first();
        }
        if ($request->filled('uid')) {
            return User::where('uid', $request->input('uid'))->first();
        }
        return null;
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
