<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // 1. Enrich Users table
        Schema::table('users', function (Blueprint $table) {
            $table->string('uid')->unique()->nullable()->after('id');
            $table->string('role')->default('student')->after('email'); // student, teacher, corrector, admin, super_admin
            $table->string('phone')->nullable()->after('role');
            $table->string('specialite')->nullable()->after('phone');
            $table->text('bio')->nullable()->after('specialite');
            $table->string('photo_url')->nullable()->after('bio');
            $table->boolean('is_verified')->default(true)->after('photo_url');
            $table->integer('onboarding_step')->default(3)->after('is_verified');
            $table->bigInteger('balance_fcfa')->default(0)->after('onboarding_step');
            $table->string('linked_teacher_id')->nullable()->after('balance_fcfa');
            $table->string('api_token', 100)->unique()->nullable()->after('remember_token');
        });

        // 2. Categories
        Schema::create('categories', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('slug')->unique();
            $table->string('icon')->nullable();
            $table->integer('courses_count')->default(0);
            $table->timestamps();
        });

        // 3. Courses (with presentation_video_url)
        Schema::create('courses', function (Blueprint $table) {
            $table->id();
            $table->string('course_uid')->unique();
            $table->string('title');
            $table->string('category')->default('Informatique');
            $table->text('description')->nullable();
            $table->integer('price_cfa')->default(25000);
            $table->string('level')->default('Tous niveaux');
            $table->string('duration')->default('12h 30m');
            $table->integer('lessons_count')->default(0);
            $table->decimal('rating', 3, 2)->default(4.80);
            $table->integer('students_count')->default(0);
            $table->string('image_url')->nullable();
            $table->string('presentation_video_url')->nullable();
            $table->string('teacher_id');
            $table->string('teacher_name');
            $table->string('status')->default('Publiée');
            $table->boolean('is_published')->default(true);
            $table->timestamps();
        });

        // 4. Course Lessons
        Schema::create('course_lessons', function (Blueprint $table) {
            $table->id();
            $table->string('course_id');
            $table->string('lesson_uid')->nullable();
            $table->string('title');
            $table->string('duration')->default('10:00');
            $table->string('video_url')->nullable();
            $table->boolean('is_free_preview')->default(false);
            $table->integer('sort_order')->default(1);
            $table->timestamps();
        });

        // 5. Course Live Replays
        Schema::create('course_replays', function (Blueprint $table) {
            $table->id();
            $table->string('course_id');
            $table->string('replay_uid')->nullable();
            $table->string('title');
            $table->string('replay_url');
            $table->string('duration')->default('1:30:00');
            $table->timestamp('recorded_at')->nullable();
            $table->timestamps();
        });

        // 6. Enrollments & Student Progress
        Schema::create('enrollments', function (Blueprint $table) {
            $table->id();
            $table->string('enrollment_uid')->unique();
            $table->string('student_id');
            $table->string('student_name');
            $table->string('course_id');
            $table->string('course_title');
            $table->string('course_image')->nullable();
            $table->string('trainer_name')->nullable();
            $table->string('category')->default('Informatique');
            $table->integer('price_cfa')->default(0);
            $table->string('payment_method')->default('Wave');
            $table->string('status')->default('active'); // pending, active, completed, rejected
            $table->integer('progress_percent')->default(0);
            $table->json('completed_lessons')->nullable();
            $table->timestamps();
        });

        // 7. Live Sessions (LiveKit Cloud)
        Schema::create('live_sessions', function (Blueprint $table) {
            $table->id();
            $table->string('session_uid')->unique();
            $table->string('course_id');
            $table->string('course_name');
            $table->string('title');
            $table->string('teacher_id');
            $table->string('teacher_name');
            $table->string('teacher_photo_url')->nullable();
            $table->string('status')->default('live'); // scheduled, live, ended
            $table->string('room_name');
            $table->string('session_type')->default('teacher_live');
            $table->string('host_role')->default('teacher');
            $table->string('phase')->default('interactive'); // interactive (1h), exercises (30m)
            $table->integer('participant_count')->default(1);
            $table->json('connected_participants')->nullable();
            $table->json('raised_hands')->nullable();
            $table->boolean('has_replay')->default(false);
            $table->string('replay_url')->nullable();
            $table->string('replay_duration')->nullable();
            $table->timestamp('scheduled_at')->nullable();
            $table->timestamp('started_at')->nullable();
            $table->timestamp('ended_at')->nullable();
            $table->timestamps();
        });

        // 8. Conversations
        Schema::create('conversations', function (Blueprint $table) {
            $table->id();
            $table->string('conversation_uid')->unique();
            $table->string('student_id');
            $table->string('student_name');
            $table->string('student_photo_url')->nullable();
            $table->string('teacher_id');
            $table->string('teacher_name');
            $table->string('teacher_photo_url')->nullable();
            $table->string('course_id')->nullable();
            $table->string('course_title')->nullable();
            $table->text('last_message')->nullable();
            $table->timestamp('last_message_at')->nullable();
            $table->integer('unread_count')->default(0);
            $table->timestamps();
        });

        // 9. Messages (Direct & Live Chat & Voice Notes)
        Schema::create('messages', function (Blueprint $table) {
            $table->id();
            $table->string('conversation_id')->index();
            $table->string('sender_id');
            $table->string('sender_name');
            $table->string('sender_role')->default('student');
            $table->text('content');
            $table->string('message_type')->default('text'); // text, audio, image, file, link
            $table->string('file_url')->nullable();
            $table->string('file_name')->nullable();
            $table->integer('audio_duration')->nullable();
            $table->timestamps();
        });

        // 10. Homeworks & Submissions (Corrector flow)
        Schema::create('homeworks', function (Blueprint $table) {
            $table->id();
            $table->string('homework_uid')->unique();
            $table->string('course_id');
            $table->string('course_title');
            $table->string('lesson_id')->nullable();
            $table->string('student_id');
            $table->string('student_name');
            $table->string('teacher_id')->nullable();
            $table->string('corrector_id')->nullable();
            $table->string('title');
            $table->text('instructions')->nullable();
            $table->text('submission_text')->nullable();
            $table->string('attachment_url')->nullable();
            $table->string('status')->default('pending'); // pending, corrected
            $table->decimal('grade', 5, 2)->nullable();
            $table->text('feedback')->nullable();
            $table->timestamps();
        });

        // 11. Study Groups & Group Messages
        Schema::create('study_groups', function (Blueprint $table) {
            $table->id();
            $table->string('group_uid')->unique();
            $table->string('name');
            $table->string('category')->default('Informatique');
            $table->text('description')->nullable();
            $table->string('creator_id');
            $table->string('creator_name');
            $table->integer('members_count')->default(1);
            $table->json('member_ids')->nullable();
            $table->timestamps();
        });

        Schema::create('study_group_messages', function (Blueprint $table) {
            $table->id();
            $table->string('group_id')->index();
            $table->string('sender_id');
            $table->string('sender_name');
            $table->text('content');
            $table->string('message_type')->default('text');
            $table->string('file_url')->nullable();
            $table->integer('audio_duration')->nullable();
            $table->timestamps();
        });

        // 12. Financial Transactions & Intech Cash-Out Withdrawals
        Schema::create('transactions', function (Blueprint $table) {
            $table->id();
            $table->string('user_id')->index();
            $table->string('external_transaction_id')->unique();
            $table->string('type')->default('withdrawal'); // withdrawal, course_payment
            $table->string('provider_code')->default('WAVE_SN_API_CASH_OUT');
            $table->string('provider_name')->default('Wave Sénégal');
            $table->string('phone');
            $table->bigInteger('amount_fcfa');
            $table->string('status')->default('SUCCESS'); // PENDING, SUCCESS, FAILED
            $table->timestamps();
        });

        // 13. Legal Documents & Certificates
        Schema::create('legal_documents', function (Blueprint $table) {
            $table->id();
            $table->string('doc_uid')->unique();
            $table->string('title');
            $table->string('category')->default('CGU');
            $table->string('version')->default('1.0');
            $table->text('content');
            $table->json('accepted_by')->nullable();
            $table->timestamps();
        });

        Schema::create('certificates', function (Blueprint $table) {
            $table->id();
            $table->string('certificate_code')->unique();
            $table->string('student_id');
            $table->string('student_name');
            $table->string('course_id');
            $table->string('course_title');
            $table->string('teacher_name');
            $table->timestamp('issued_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('certificates');
        Schema::dropIfExists('legal_documents');
        Schema::dropIfExists('transactions');
        Schema::dropIfExists('study_group_messages');
        Schema::dropIfExists('study_groups');
        Schema::dropIfExists('homeworks');
        Schema::dropIfExists('messages');
        Schema::dropIfExists('conversations');
        Schema::dropIfExists('live_sessions');
        Schema::dropIfExists('enrollments');
        Schema::dropIfExists('course_replays');
        Schema::dropIfExists('course_lessons');
        Schema::dropIfExists('courses');
        Schema::dropIfExists('categories');
    }
};
