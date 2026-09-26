<?php

namespace Database\Seeders;

use App\Models\Category;
use App\Models\Certificate;
use App\Models\Conversation;
use App\Models\Course;
use App\Models\CourseLesson;
use App\Models\Enrollment;
use App\Models\Homework;
use App\Models\LegalDocument;
use App\Models\LiveSession;
use App\Models\Message;
use App\Models\StudyGroup;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Seed Users
        User::updateOrCreate(
            ['email' => 'cheikh.diop@club-des-formateurs.sn'],
            [
                'uid' => 'demo_teacher_cheikh',
                'name' => 'Cheikh Abdoulaye Diop',
                'password' => Hash::make('password123'),
                'role' => 'teacher',
                'phone' => '+221 77 450 12 34',
                'specialite' => 'Architecte Cloud & Développeur Fullstack',
                'bio' => 'Ingénieur logiciel senior avec plus de 10 ans d\'expérience dans le développement web et mobile en Afrique de l\'Ouest.',
                'photo_url' => 'assets/images/teacher-studio.jpeg',
                'is_verified' => true,
                'onboarding_step' => 3,
                'balance_fcfa' => 420000,
            ]
        );

        User::updateOrCreate(
            ['email' => 'moussa.ndiaye@gmail.com'],
            [
                'uid' => 'demo_student_moussa',
                'name' => 'Moussa Ndiaye',
                'password' => Hash::make('password123'),
                'role' => 'student',
                'phone' => '+221 77 123 45 67',
                'photo_url' => 'assets/images/student-library.jpeg',
                'is_verified' => true,
                'onboarding_step' => 3,
                'balance_fcfa' => 0,
            ]
        );

        User::updateOrCreate(
            ['email' => 'fatou.sow@club-des-formateurs.sn'],
            [
                'uid' => 'demo_corrector_fatou',
                'name' => 'Fatou Sow',
                'password' => Hash::make('password123'),
                'role' => 'corrector',
                'phone' => '+221 78 300 11 22',
                'specialite' => 'Correctrice Pédagogique & Mentor Code',
                'linked_teacher_id' => 'demo_teacher_cheikh',
                'is_verified' => true,
                'onboarding_step' => 3,
                'balance_fcfa' => 115000,
            ]
        );

        User::updateOrCreate(
            ['email' => 'admin@club-des-formateurs.sn'],
            [
                'uid' => 'demo_super_admin',
                'name' => 'Super Administrateur',
                'password' => Hash::make('admin123'),
                'role' => 'super_admin',
                'phone' => '+221 33 800 00 00',
                'is_verified' => true,
                'onboarding_step' => 3,
                'balance_fcfa' => 0,
            ]
        );

        // 2. Categories
        $categories = [
            ['name' => 'Informatique', 'slug' => 'informatique', 'icon' => 'code', 'courses_count' => 12],
            ['name' => 'Marketing', 'slug' => 'marketing', 'icon' => 'campaign', 'courses_count' => 8],
            ['name' => 'Finance & Comptabilité', 'slug' => 'finance', 'icon' => 'account_balance', 'courses_count' => 6],
            ['name' => 'Design & UI/UX', 'slug' => 'design', 'icon' => 'palette', 'courses_count' => 5],
            ['name' => 'Entrepreneuriat', 'slug' => 'entrepreneuriat', 'icon' => 'business_center', 'courses_count' => 9],
        ];
        foreach ($categories as $cat) {
            Category::updateOrCreate(['slug' => $cat['slug']], $cat);
        }

        // 3. Courses with presentation_video_url & lessons
        $courses = [
            [
                'course_uid' => 'react',
                'title' => 'Développement Web Fullstack : React, Node.js & Cloud',
                'category' => 'Informatique',
                'description' => 'Maîtrisez la création d\'applications web modernes de A à Z avec exercices pratiques et projets réels.',
                'price_cfa' => 25000,
                'level' => 'Intermédiaire',
                'duration' => '24h 30m',
                'lessons_count' => 4,
                'rating' => 4.9,
                'students_count' => 340,
                'image_url' => 'assets/images/student-library.jpeg',
                'presentation_video_url' => 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
                'teacher_id' => 'demo_teacher_cheikh',
                'teacher_name' => 'Cheikh Abdoulaye Diop',
                'status' => 'Publiée',
                'is_published' => true,
            ],
            [
                'course_uid' => 'marketing',
                'title' => 'Marketing Digital & Acquisition Clients en Afrique',
                'category' => 'Marketing',
                'description' => 'Stratégies concrètes de croissance sur les réseaux sociaux, publicité ciblée et conversion mobile.',
                'price_cfa' => 20000,
                'level' => 'Débutant',
                'duration' => '16h 00m',
                'lessons_count' => 3,
                'rating' => 4.8,
                'students_count' => 285,
                'image_url' => 'assets/images/teacher-studio.jpeg',
                'presentation_video_url' => 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
                'teacher_id' => 'demo_teacher_cheikh',
                'teacher_name' => 'Cheikh Abdoulaye Diop',
                'status' => 'Publiée',
                'is_published' => true,
            ],
            [
                'course_uid' => 'flutter_mobile',
                'title' => 'Création d\'Applications Mobiles iOS & Android avec Flutter',
                'category' => 'Informatique',
                'description' => 'Développez des applications mobiles performantes connectées à une API Laravel et aux paiements Wave & Orange Money.',
                'price_cfa' => 30000,
                'level' => 'Tous niveaux',
                'duration' => '28h 15m',
                'lessons_count' => 4,
                'rating' => 4.95,
                'students_count' => 410,
                'image_url' => 'assets/images/student-library.jpeg',
                'presentation_video_url' => 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
                'teacher_id' => 'demo_teacher_cheikh',
                'teacher_name' => 'Cheikh Abdoulaye Diop',
                'status' => 'Publiée',
                'is_published' => true,
            ],
        ];

        foreach ($courses as $c) {
            Course::updateOrCreate(['course_uid' => $c['course_uid']], $c);

            CourseLesson::updateOrCreate(
                ['course_id' => $c['course_uid'], 'sort_order' => 1],
                [
                    'lesson_uid' => $c['course_uid'] . '_l1',
                    'title' => '1. Introduction & Architecture du projet',
                    'duration' => '10:30',
                    'video_url' => 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
                    'is_free_preview' => true,
                ]
            );
            CourseLesson::updateOrCreate(
                ['course_id' => $c['course_uid'], 'sort_order' => 2],
                [
                    'lesson_uid' => $c['course_uid'] . '_l2',
                    'title' => '2. Configuration de l\'environnement & Outils',
                    'duration' => '15:45',
                    'video_url' => 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
                    'is_free_preview' => false,
                ]
            );
            CourseLesson::updateOrCreate(
                ['course_id' => $c['course_uid'], 'sort_order' => 3],
                [
                    'lesson_uid' => $c['course_uid'] . '_l3',
                    'title' => '3. Mise en pratique et déploiement',
                    'duration' => '22:10',
                    'video_url' => 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
                    'is_free_preview' => false,
                ]
            );
        }

        // 4. Enrollments
        Enrollment::updateOrCreate(
            ['enrollment_uid' => 'demo_student_moussa_react'],
            [
                'student_id' => 'demo_student_moussa',
                'student_name' => 'Moussa Ndiaye',
                'course_id' => 'react',
                'course_title' => 'Développement Web Fullstack : React, Node.js & Cloud',
                'course_image' => 'assets/images/student-library.jpeg',
                'trainer_name' => 'Cheikh Abdoulaye Diop',
                'category' => 'Informatique',
                'price_cfa' => 25000,
                'payment_method' => 'Wave',
                'status' => 'active',
                'progress_percent' => 65,
                'completed_lessons' => ['react_l1', 'react_l2'],
            ]
        );

        // 5. Conversations & Messages
        $conv = Conversation::updateOrCreate(
            ['conversation_uid' => 'conv_moussa_cheikh'],
            [
                'student_id' => 'demo_student_moussa',
                'student_name' => 'Moussa Ndiaye',
                'teacher_id' => 'demo_teacher_cheikh',
                'teacher_name' => 'Cheikh Abdoulaye Diop',
                'course_id' => 'react',
                'course_title' => 'Développement Web Fullstack',
                'last_message' => 'Merci professeur, j\'ai bien compris le chapitre sur les API REST !',
                'last_message_at' => now(),
                'unread_count' => 1,
            ]
        );

        Message::updateOrCreate(
            ['conversation_id' => $conv->conversation_uid, 'content' => 'Bonjour M. Diop, j\'ai une question sur le déploiement Cloud.'],
            [
                'sender_id' => 'demo_student_moussa',
                'sender_name' => 'Moussa Ndiaye',
                'sender_role' => 'student',
                'message_type' => 'text',
            ]
        );

        Message::updateOrCreate(
            ['conversation_id' => $conv->conversation_uid, 'content' => 'Bonjour Moussa ! Nous allons voir cela en détail pendant le Live de tout à l\'heure.'],
            [
                'sender_id' => 'demo_teacher_cheikh',
                'sender_name' => 'Cheikh Abdoulaye Diop',
                'sender_role' => 'teacher',
                'message_type' => 'text',
            ]
        );

        // 6. Transactions (Intech Wave & Orange Money)
        Transaction::updateOrCreate(
            ['external_transaction_id' => 'ANOUR_CASH_OUT_SEED_01'],
            [
                'user_id' => 'demo_teacher_cheikh',
                'type' => 'withdrawal',
                'provider_code' => 'WAVE_SN_API_CASH_OUT',
                'provider_name' => 'Wave Sénégal',
                'phone' => '221774501234',
                'amount_fcfa' => 150000,
                'status' => 'SUCCESS',
            ]
        );

        // 7. Study Groups & Homeworks & Legal Documents
        StudyGroup::updateOrCreate(
            ['group_uid' => 'group_fullstack_sn'],
            [
                'name' => 'Communauté Développeurs Fullstack Dakar',
                'category' => 'Informatique',
                'description' => 'Entraide sur React, Flutter, Laravel et révisions des exercices en direct.',
                'creator_id' => 'demo_student_moussa',
                'creator_name' => 'Moussa Ndiaye',
                'members_count' => 28,
                'member_ids' => ['demo_student_moussa', 'demo_teacher_cheikh'],
            ]
        );

        Homework::updateOrCreate(
            ['homework_uid' => 'hw_seed_01'],
            [
                'course_id' => 'react',
                'course_title' => 'Développement Web Fullstack : React, Node.js & Cloud',
                'student_id' => 'demo_student_moussa',
                'student_name' => 'Moussa Ndiaye',
                'teacher_id' => 'demo_teacher_cheikh',
                'corrector_id' => 'demo_corrector_fatou',
                'title' => 'Création d\'une API REST sécurisée',
                'instructions' => 'Implémentez les routes CRUD et l\'authentification.',
                'submission_text' => 'Lien GitHub du projet soumis avec tests fonctionnels.',
                'status' => 'pending',
            ]
        );

        LegalDocument::updateOrCreate(
            ['doc_uid' => 'cgu_formateurs_v1'],
            [
                'title' => 'Charte Pédagogique & CGU du Club des Formateurs',
                'category' => 'CGU',
                'version' => '1.0',
                'content' => 'Conditions générales d\'utilisation, répartition des revenus et engagement qualité.',
                'accepted_by' => ['demo_teacher_cheikh', 'demo_student_moussa'],
            ]
        );

        Certificate::updateOrCreate(
            ['certificate_code' => 'CDF-2026-SN-001'],
            [
                'student_id' => 'demo_student_moussa',
                'student_name' => 'Moussa Ndiaye',
                'course_id' => 'react',
                'course_title' => 'Développement Web Fullstack : React, Node.js & Cloud',
                'teacher_name' => 'Cheikh Abdoulaye Diop',
                'issued_at' => now(),
            ]
        );
    }
}
