<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Certificate;
use App\Models\Course;
use App\Models\Enrollment;
use App\Models\Homework;
use App\Models\LegalDocument;
use App\Models\LiveSession;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminController extends Controller
{
    public function stats(): JsonResponse
    {
        return response()->json([
            'success' => true,
            'stats' => [
                'totalUsers' => User::count(),
                'totalStudents' => User::where('role', 'student')->count(),
                'totalTeachers' => User::where('role', 'teacher')->count(),
                'totalCorrectors' => User::where('role', 'corrector')->count(),
                'totalCourses' => Course::count(),
                'publishedCourses' => Course::where('is_published', true)->count(),
                'totalEnrollments' => Enrollment::count(),
                'activeLives' => LiveSession::where('status', 'live')->count(),
                'pendingHomeworks' => Homework::where('status', 'pending')->count(),
                'totalRevenueFcfa' => Enrollment::sum('price_cfa'),
                'totalWithdrawalsFcfa' => Transaction::where('type', 'withdrawal')->sum('amount_fcfa'),
            ],
        ]);
    }

    public function users(Request $request): JsonResponse
    {
        $query = User::orderByDesc('created_at');
        if ($request->filled('role') && $request->input('role') !== 'all') {
            $query->where('role', $request->input('role'));
        }

        return response()->json([
            'success' => true,
            'users' => $query->get()->map(fn (User $u) => [
                'uid' => $u->uid ?? (string) $u->id,
                'displayName' => $u->name,
                'email' => $u->email,
                'role' => $u->role,
                'phoneNumber' => $u->phone,
                'specialite' => $u->specialite,
                'isVerified' => $u->is_verified,
                'linkedTeacherId' => $u->linked_teacher_id,
                'balanceFcfa' => $u->balance_fcfa,
            ]),
        ]);
    }

    public function updateUserRole(Request $request, string $uid): JsonResponse
    {
        $user = User::where('uid', $uid)->orWhere('id', $uid)->firstOrFail();
        if ($request->filled('role')) {
            $user->role = $request->input('role');
        }
        if ($request->has('isVerified')) {
            $user->is_verified = (bool) $request->input('isVerified');
        }
        $user->save();

        return response()->json(['success' => true, 'user' => $user]);
    }

    public function assignCorrector(Request $request): JsonResponse
    {
        $correctorId = $request->input('correctorId');
        $teacherId = $request->input('teacherId');

        $corrector = User::where('uid', $correctorId)->orWhere('id', $correctorId)->firstOrFail();
        $corrector->linked_teacher_id = $teacherId;
        $corrector->save();

        return response()->json([
            'success' => true,
            'message' => 'Correcteur assigné au formateur avec succès.',
        ]);
    }

    public function legalDocuments(): JsonResponse
    {
        return response()->json([
            'success' => true,
            'documents' => LegalDocument::all(),
        ]);
    }

    public function acceptLegalDocument(Request $request, string $id): JsonResponse
    {
        $doc = LegalDocument::where('doc_uid', $id)->orWhere('id', $id)->firstOrFail();
        $userId = $request->input('userId', 'user');
        $accepted = $doc->accepted_by ?? [];
        if (!in_array($userId, $accepted, true)) {
            $accepted[] = $userId;
        }
        $doc->accepted_by = $accepted;
        $doc->save();

        return response()->json(['success' => true]);
    }

    public function verifyCertificate(string $code): JsonResponse
    {
        $cert = Certificate::where('certificate_code', $code)->first();
        if (!$cert) {
            return response()->json(['success' => false, 'valid' => false, 'message' => 'Certificat introuvable'], 404);
        }

        return response()->json([
            'success' => true,
            'valid' => true,
            'certificate' => $cert,
        ]);
    }
}
