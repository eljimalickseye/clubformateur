import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course_model.dart';
import '../models/enrollment_model.dart';
import '../models/teacher_registration_model.dart';
import 'app_notification_service.dart';
import 'chat_service.dart';
import 'course_service.dart';
import 'laravel_api_service.dart';
import 'student_payment_service.dart';
import 'system_log_service.dart';
import 'class_service.dart';
import 'teacher_registration_service.dart';

class EnrollmentService {
  static final EnrollmentService _instance = EnrollmentService._internal();
  factory EnrollmentService() => _instance;
  EnrollmentService._internal();

  final LaravelApiService _api = LaravelApiService();
  final Map<String, StreamController<List<EnrollmentModel>>> _controllers = {};

  FirebaseFirestore? get _firestore {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
    } catch (e) {
      debugPrint('Firestore not ready in EnrollmentService: $e');
    }
    return null;
  }

  /// Enroll or purchase a course (Local Cache + Laravel API + Firestore)
  Future<void> enrollUser({
    required String userId,
    required String userName,
    String? studentEmail,
    String? studentPhone,
    String? studentPhoto,
    required CourseModel course,
    String paymentMethod = 'Wave',
  }) async {
    final enrollmentId = '${userId}_${course.id}';
    final enrollment = EnrollmentModel(
      id: enrollmentId,
      studentId: userId,
      studentName: userName,
      courseId: course.id,
      courseTitle: course.title,
      courseImage: course.image,
      trainerName: course.trainerName,
      category: course.category,
      price: course.price,
      paymentMethod: paymentMethod,
      status: 'active',
      enrolledAt: DateTime.now(),
    );

    // 1. Save in local cache first & broadcast immediately
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'user_enrollments_$userId';
      final existingRaw = prefs.getStringList(key) ?? [];
      final list = existingRaw
          .map((e) => jsonDecode(e) as Map<String, dynamic>)
          .toList();

      final alreadyInList = list.any((e) => e['courseId'] == course.id);
      if (!alreadyInList) {
        list.insert(0, {
          'id': enrollmentId,
          'studentId': userId,
          'studentName': userName,
          'courseId': course.id,
          'courseTitle': course.title,
          'courseImage': course.image,
          'trainerName': course.trainerName,
          'category': course.category,
          'price': course.price,
          'paymentMethod': paymentMethod,
          'status': 'active',
          'enrolledAt': DateTime.now().toIso8601String(),
        });
        await prefs.setStringList(key, list.map((e) => jsonEncode(e)).toList());
      }
      final updatedList = await getUserEnrollments(userId);
      _controllers[userId]?.add(updatedList);
    } catch (e) {
      debugPrint('Local enroll cache error: $e');
    }

    // 2. Record payment in StudentPaymentService (creates official receipt & syncs to Firestore payments)
    try {
      await StudentPaymentService().recordPayment(
        studentId: userId,
        studentName: userName,
        courseId: course.id,
        courseTitle: course.title,
        monthLabel: 'Formation Complète',
        amount: course.price,
        paymentMethod: paymentMethod,
        isMonthlyFee: false,
      );
    } catch (e) {
      debugPrint('StudentPaymentService record error: $e');
    }

    // 3. Increment student count reactively in CourseService
    try {
      await CourseService().incrementStudentCount(course.id);
    } catch (e) {
      debugPrint('CourseService increment error: $e');
    }

    // 4. Sync with Laravel API (/api/v1/enrollments)
    unawaited(_api.post('/enrollments', {
      'user_id': userId,
      'student_name': userName,
      'course_id': course.id,
      'course_title': course.title,
      'amount_paid': course.price,
      'payment_method': paymentMethod,
    }));

    // 5. Save to Firestore (enrollments & courses count)
    try {
      final db = _firestore;
      if (db != null) {
        await db.collection('enrollments').doc(enrollmentId).set(
          enrollment.toMap(),
          SetOptions(merge: true),
        ).timeout(const Duration(seconds: 4));

        await db.collection('courses').doc(course.id).set({
          'studentsCount': FieldValue.increment(1),
        }, SetOptions(merge: true)).timeout(const Duration(seconds: 4));
      }
    } catch (e) {
      debugPrint('Firestore enroll fallback: $e');
    }

    // 6. Enregistrer la fiche d'inscription prof pour visibilité dans le Dashboard Formateur
    final teacherId = course.teacherId.isNotEmpty ? course.teacherId : 'demo_teacher_cheikh';
    final regId = 'reg_${DateTime.now().millisecondsSinceEpoch}_${course.id}';
    final regModel = TeacherStudentRegistrationModel(
      id: regId,
      registrationNumber: 'INS-${DateTime.now().year}-${1000 + (DateTime.now().millisecond * 9 % 8999)}',
      teacherId: teacherId,
      teacherName: course.trainerName,
      teacherPhoto: course.trainerAvatar ?? '',
      subject: course.category,
      studentId: userId,
      studentLastName: userName,
      studentFirstName: '',
      birthDate: '01/01/2000',
      birthPlace: 'Dakar',
      phone: studentPhone ?? '',
      email: studentEmail ?? '',
      studyLevel: course.level,
      fieldOfStudy: course.category,
      academicYear: '2026-2027',
      proposedSchedule: 'Accès illimité 24/7',
      fee: course.price,
      paymentMethod: paymentMethod,
      paymentStatus: 'Paiement confirmé',
      status: 'Inscription confirmée',
      createdAt: DateTime.now(),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final teacherKey = 'teacher_received_registrations_$teacherId';
      final existingTeacher = prefs.getStringList(teacherKey) ?? [];
      final teacherList = existingTeacher.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
      teacherList.insert(0, regModel.toMap());
      await prefs.setStringList(teacherKey, teacherList.map((e) => jsonEncode(e)).toList());
      TeacherRegistrationService().notifyTeacherStream(teacherId);

      final db = _firestore;
      if (db != null) {
        unawaited(
          db.collection('teacher_registrations').doc(regId).set(
            regModel.toMap(),
            SetOptions(merge: true),
          ).catchError((_) {}),
        );
      }
    } catch (e) {
      debugPrint('Teacher registration sync error: $e');
    }

    // 6b. Rattachement automatique et dynamique à la Classe / Promotion de la Formation
    try {
      final cohort = await ClassService().getOrCreateClassForCourse(
        courseId: course.id,
        courseName: course.title,
        teacherId: teacherId,
        teacherName: course.trainerName,
      );
      await ClassService().enrollStudent(
        classId: cohort.id,
        studentId: userId,
        studentName: userName,
        studentEmail: studentEmail ?? '',
        studentPhone: studentPhone ?? '',
      );
    } catch (e) {
      debugPrint('Class auto-enrollment error: $e');
    }

    // 7. Envoi des notifications temps réel
    // A) Au Professeur
    unawaited(
      AppNotificationService().notifyTeacher(
        teacherId: teacherId,
        title: 'Nouvel étudiant inscrit ! 🎓',
        message: '$userName s\'est inscrit à votre formation "${course.title}".',
        type: 'enrollment',
        actionRoute: '/students',
        data: {
          'studentId': userId,
          'studentName': userName,
          'courseId': course.id,
          'courseTitle': course.title,
          'amount': course.price,
        },
      ),
    );

    // B) Au Correcteur lié au Professeur
    unawaited(
      AppNotificationService().notifyLinkedCorrector(
        teacherId: teacherId,
        title: 'Nouvel étudiant à suivre 👤',
        message: '$userName a rejoint la formation "${course.title}" du formateur ${course.trainerName}.',
        type: 'enrollment',
        actionRoute: '/homeworks',
        data: {
          'studentId': userId,
          'courseId': course.id,
          'teacherId': teacherId,
        },
      ),
    );

    // C) À l'Étudiant
    unawaited(
      AppNotificationService().sendNotification(
        userId: userId,
        title: 'Inscription confirmée ! 🎉',
        message: 'Bienvenue dans "${course.title}". Vous avez accès immédiat à tous vos modules et leçons vidéo.',
        type: 'enrollment',
        actionRoute: '/courses',
        data: {'courseId': course.id},
      ),
    );

    // 8. Initialisation automatique de la conversation de messagerie Formateur <-> Étudiant
    try {
      final convId = await ChatService().getOrCreateConversation(
        currentUserId: userId,
        currentUserName: userName,
        targetUserId: teacherId,
        targetUserName: course.trainerName,
        targetUserPhoto: course.trainerAvatar ?? '',
        courseName: course.title,
      );

      // Message d'accueil automatique du formateur
      unawaited(
        ChatService().sendMessage(
          conversationId: convId,
          senderId: teacherId,
          senderName: course.trainerName,
          senderRole: 'teacher',
          content: 'Bienvenue dans la formation "${course.title}" ! 👋\nJe suis votre formateur ${course.trainerName}. N\'hésitez pas à poser vos questions ici sur les leçons ou vos exercices.',
        ),
      );
    } catch (e) {
      debugPrint('Chat auto-init error: $e');
    }

    // 9. Traçabilité d'audit
    unawaited(
      SystemLogService().logEvent(
        action: 'Inscription confirmée',
        details: 'L\'étudiant $userName a rejoint "${course.title}" (${course.price} FCFA via $paymentMethod).',
        category: 'course',
        level: 'success',
        actorName: userName,
        actorRole: 'Étudiant',
        metadata: {
          'courseId': course.id,
          'teacherId': teacherId,
          'studentId': userId,
          'price': '${course.price} FCFA',
        },
      ),
    );
  }

  /// Check if user is enrolled in a course
  Future<bool> isUserEnrolled(String userId, String courseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'user_enrollments_$userId';
      final existingRaw = prefs.getStringList(key) ?? [];
      for (final raw in existingRaw) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        if (data['courseId'] == courseId) return true;
      }

      final db = _firestore;
      if (db != null) {
        final doc = await db
            .collection('enrollments')
            .doc('${userId}_$courseId')
            .get()
            .timeout(const Duration(seconds: 3));
        if (doc.exists) return true;
      }
    } catch (e) {
      debugPrint('isUserEnrolled error: $e');
    }

    return false;
  }

  /// Real-time stream checking if user is enrolled
  Stream<bool> isUserEnrolledStream(String userId, String courseId) {
    return getUserEnrollmentsStream(userId).map(
      (list) => list.any((e) => e.courseId == courseId),
    );
  }

  /// Real-time stream of all enrolled/purchased courses for this student
  Stream<List<EnrollmentModel>> getUserEnrollmentsStream(String userId) async* {
    _controllers.putIfAbsent(
      userId,
      () => StreamController<List<EnrollmentModel>>.broadcast(),
    );

    final initial = await getUserEnrollments(userId);
    yield initial;

    yield* _controllers[userId]!.stream;
  }

  /// Fetch user enrollments once (Local + Laravel API + Firestore)
  Future<List<EnrollmentModel>> getUserEnrollments(String userId) async {
    final List<EnrollmentModel> list = [];
    final Set<String> existingIds = {};

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'user_enrollments_$userId';
      final cached = prefs.getStringList(key) ?? [];

      for (final raw in cached) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final cId = data['courseId']?.toString() ?? '';
        if (cId.isNotEmpty && !existingIds.contains(cId)) {
          list.add(EnrollmentModel(
            id: data['id']?.toString() ?? '${userId}_$cId',
            studentId: userId,
            studentName: data['studentName']?.toString() ?? 'Apprenant',
            courseId: cId,
            courseTitle: data['courseTitle']?.toString() ?? 'Formation',
            courseImage: data['courseImage']?.toString() ?? '',
            trainerName: data['trainerName']?.toString() ?? 'Formateur',
            category: data['category']?.toString() ?? 'Formation',
            price: (data['price'] as num?)?.toInt() ?? 25000,
            paymentMethod: data['paymentMethod']?.toString() ?? 'Wave',
            status: 'active',
            enrolledAt: DateTime.tryParse(data['enrolledAt']?.toString() ?? '') ?? DateTime.now(),
          ));
          existingIds.add(cId);
        }
      }
    } catch (_) {}

    // Firestore enrollments
    try {
      final db = _firestore;
      if (db != null) {
        final snap = await db
            .collection('enrollments')
            .where('studentId', isEqualTo: userId)
            .get()
            .timeout(const Duration(seconds: 4));
        for (final doc in snap.docs) {
          final data = doc.data();
          final cId = data['courseId']?.toString() ?? '';
          if (cId.isNotEmpty && !existingIds.contains(cId)) {
            list.add(EnrollmentModel.fromMap(data, doc.id));
            existingIds.add(cId);
          }
        }
      }
    } catch (e) {
      debugPrint('Firestore getUserEnrollments error: $e');
    }

    list.sort((a, b) => b.enrolledAt.compareTo(a.enrolledAt));
    return list;
  }

  /// Get all enrollments for a given course (e.g. to notify students)
  Future<List<EnrollmentModel>> getCourseEnrollments(String courseId) async {
    final List<EnrollmentModel> list = [];
    try {
      final db = _firestore;
      if (db != null) {
        final snap = await db
            .collection('enrollments')
            .where('courseId', isEqualTo: courseId)
            .get()
            .timeout(const Duration(seconds: 4));
        for (final doc in snap.docs) {
          list.add(EnrollmentModel.fromMap(doc.data(), doc.id));
        }
      }
    } catch (e) {
      debugPrint('getCourseEnrollments error: $e');
    }
    return list;
  }
}
