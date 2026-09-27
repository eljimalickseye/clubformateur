<?php

use App\Http\Controllers\Api\AdminController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ChatController;
use App\Http\Controllers\Api\CourseController;
use App\Http\Controllers\Api\EnrollmentController;
use App\Http\Controllers\Api\HomeworkController;
use App\Http\Controllers\Api\LiveSessionController;
use App\Http\Controllers\Api\PaymentController;
use App\Http\Controllers\Api\StudyGroupController;
use App\Http\Controllers\Api\TrainerController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Club des Formateurs - API Routes (/api/v1 & /api)
|--------------------------------------------------------------------------
| Toutes les routes backend de l'application (Authentification, Formations,
| Vidéos de présentation, Leçons, Sessions Live LiveKit Cloud, Paiements &
| Retraits Intech Wave/Orange Money, Messagerie & Notes vocales, Devoirs,
| Groupes d'étude, Formateurs, et Administration).
*/

$registerRoutes = function () {
    // ─── 0. SANTÉ & HEALTHCHECK ──────────────────────────────────────────
    Route::get('/health', function () {
        $dbStatus = 'connected';
        try {
            \Illuminate\Support\Facades\DB::connection()->getPdo();
        } catch (\Throwable $e) {
            $dbStatus = 'error: ' . $e->getMessage();
        }

        return response()->json([
            'status' => $dbStatus === 'connected' ? 'ok' : 'degraded',
            'app' => 'Club des Formateurs API',
            'version' => '1.0.0',
            'database' => $dbStatus,
            'timestamp' => now()->toIso8601String(),
        ]);
    });

    // ─── 1. AUTHENTIFICATION & PROFILS ────────────────────────────────────
    Route::prefix('auth')->group(function () {
        Route::post('/register', [AuthController::class, 'register']);
        Route::post('/login', [AuthController::class, 'login']);
        Route::post('/google', [AuthController::class, 'googleLogin']);
        Route::get('/me', [AuthController::class, 'me']);
        Route::put('/profile', [AuthController::class, 'updateProfile']);
        Route::post('/logout', [AuthController::class, 'logout']);
    });

    // ─── 2. FORMATIONS, VIDÉOS DE PRÉSENTATION, LEÇONS & REPLAYS ─────────
    Route::get('/courses', [CourseController::class, 'index']);
    Route::get('/courses/{id}', [CourseController::class, 'show']);
    Route::get('/teachers/{teacherId}/courses', [CourseController::class, 'teacherCourses']);
    Route::post('/courses', [CourseController::class, 'store']);
    Route::put('/courses/{id}', [CourseController::class, 'update']);
    Route::patch('/courses/{id}/toggle-publish', [CourseController::class, 'togglePublish']);
    Route::delete('/courses/{id}', [CourseController::class, 'destroy']);
    Route::get('/courses/{id}/lessons', [CourseController::class, 'lessons']);
    Route::post('/courses/{id}/lessons', [CourseController::class, 'addLesson']);
    Route::post('/courses/{id}/replays', [CourseController::class, 'addReplay']);

    // ─── 3. SESSIONS LIVE & LIVEKIT CLOUD (wss://anour-rv83fs3g.livekit.cloud) ─
    Route::get('/live-sessions', [LiveSessionController::class, 'index']);
    Route::get('/live-sessions/active', [LiveSessionController::class, 'active']);
    Route::get('/courses/{courseId}/live-sessions', [LiveSessionController::class, 'courseSessions']);
    Route::get('/teachers/{teacherId}/live-sessions', [LiveSessionController::class, 'teacherSessions']);
    Route::post('/live-sessions', [LiveSessionController::class, 'store']);
    Route::patch('/live-sessions/{id}/phase', [LiveSessionController::class, 'switchPhase']);
    Route::post('/live-sessions/{id}/join', [LiveSessionController::class, 'join']);
    Route::post('/live-sessions/{id}/leave', [LiveSessionController::class, 'leave']);
    Route::post('/live-sessions/{id}/raise-hand', [LiveSessionController::class, 'toggleRaiseHand']);
    Route::post('/live-sessions/{id}/end', [LiveSessionController::class, 'end']);
    Route::post('/livekit/token', [LiveSessionController::class, 'generateLiveKitToken']);

    // ─── 4. INSCRIPTIONS & PROGRESSION DES APPRENANTS ────────────────────
    Route::get('/enrollments', [EnrollmentController::class, 'index']);
    Route::get('/students/{studentId}/enrollments', [EnrollmentController::class, 'studentEnrollments']);
    Route::get('/students/{studentId}/enrollments/{courseId}/check', [EnrollmentController::class, 'checkEnrollment']);
    Route::post('/enrollments', [EnrollmentController::class, 'store']);
    Route::patch('/enrollments/{id}/status', [EnrollmentController::class, 'updateStatus']);
    Route::put('/students/{studentId}/progress/{courseId}', [EnrollmentController::class, 'updateProgress']);

    // ─── 5. MESSAGERIE TEMPS RÉEL & NOTES VOCALES ────────────────────────
    Route::get('/conversations', [ChatController::class, 'conversations']);
    Route::post('/conversations', [ChatController::class, 'createOrGetConversation']);
    Route::get('/conversations/{conversationId}/messages', [ChatController::class, 'messages']);
    Route::post('/conversations/{conversationId}/messages', [ChatController::class, 'sendMessage']);
    Route::patch('/conversations/{conversationId}/read', [ChatController::class, 'markAsRead']);

    // ─── 6. PAIEMENTS & RETRAITS INTECH (WAVE & ORANGE MONEY SÉNÉGAL) ────
    Route::get('/teachers/{teacherId}/wallet', [PaymentController::class, 'wallet']);
    Route::get('/payments/transactions', [PaymentController::class, 'transactions']);
    Route::post('/payments/withdraw', [PaymentController::class, 'withdraw']);
    Route::post('/payments/status', [PaymentController::class, 'checkStatus']);

    // ─── 7. DEVOIRS & ESPACE CORRECTEUR ──────────────────────────────────
    Route::get('/homeworks', [HomeworkController::class, 'index']);
    Route::get('/students/{studentId}/homeworks', [HomeworkController::class, 'studentHomeworks']);
    Route::post('/homeworks', [HomeworkController::class, 'store']);
    Route::patch('/homeworks/{id}/grade', [HomeworkController::class, 'grade']);

    // ─── 8. GROUPES D'ÉTUDE COLLABORATIFS ────────────────────────────────
    Route::get('/study-groups', [StudyGroupController::class, 'index']);
    Route::post('/study-groups', [StudyGroupController::class, 'store']);
    Route::post('/study-groups/{id}/join', [StudyGroupController::class, 'join']);
    Route::get('/study-groups/{id}/messages', [StudyGroupController::class, 'messages']);
    Route::post('/study-groups/{id}/messages', [StudyGroupController::class, 'sendMessage']);

    // ─── 9. ANNUAIRE DES FORMATEURS ──────────────────────────────────────
    Route::get('/trainers', [TrainerController::class, 'index']);
    Route::get('/trainers/{id}', [TrainerController::class, 'show']);

    // ─── 10. ADMINISTRATION, STATISTIQUES, DOCUMENTS LÉGAUX & CERTIFICATS ─
    Route::prefix('admin')->group(function () {
        Route::get('/stats', [AdminController::class, 'stats']);
        Route::get('/users', [AdminController::class, 'users']);
        Route::patch('/users/{uid}/role', [AdminController::class, 'updateUserRole']);
        Route::post('/assign-corrector', [AdminController::class, 'assignCorrector']);
    });
    Route::get('/legal-documents', [AdminController::class, 'legalDocuments']);
    Route::post('/legal-documents/{id}/accept', [AdminController::class, 'acceptLegalDocument']);
    Route::get('/certificates/{code}/verify', [AdminController::class, 'verifyCertificate']);
};

Route::prefix('v1')->group($registerRoutes);
$registerRoutes();
