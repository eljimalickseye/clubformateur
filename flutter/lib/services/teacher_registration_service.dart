import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/teacher_registration_model.dart';
import '../models/trainer_model.dart';
import 'student_payment_service.dart';
import 'class_service.dart';

class TeacherRegistrationService {
  static final TeacherRegistrationService _instance = TeacherRegistrationService._internal();
  factory TeacherRegistrationService() => _instance;
  TeacherRegistrationService._internal();

  final Map<String, StreamController<List<TeacherStudentRegistrationModel>>> _studentControllers = {};
  final Map<String, StreamController<List<TeacherStudentRegistrationModel>>> _teacherControllers = {};

  FirebaseFirestore? get _firestore {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
    } catch (e) {
      debugPrint('Firestore not ready in TeacherRegistrationService: $e');
    }
    return null;
  }

  String _generateRegistrationNumber() {
    final year = DateTime.now().year;
    final rand = 1000 + Random().nextInt(9000);
    return 'INS-$year-$rand';
  }

  /// Create and process a student registration directly linked to a teacher
  Future<TeacherStudentRegistrationModel> registerStudent({
    required TrainerModel teacher,
    required String studentId,
    required String studentLastName,
    required String studentFirstName,
    required String birthDate,
    required String birthPlace,
    required String phone,
    required String email,
    required String studyLevel,
    required String fieldOfStudy,
    String? subject,
    String academicYear = '2026-2027',
    String? proposedSchedule,
    int? fee,
    String paymentMethod = 'Wave',
  }) async {
    final now = DateTime.now();
    final regId = 'reg_${now.millisecondsSinceEpoch}_${Random().nextInt(999)}';
    final regNumber = _generateRegistrationNumber();
    final chosenSubject = subject ?? teacher.subject;
    final finalSchedule = proposedSchedule ?? teacher.schedule;
    final finalFee = fee ?? teacher.registrationFee;

    final registration = TeacherStudentRegistrationModel(
      id: regId,
      registrationNumber: regNumber,
      teacherId: teacher.id,
      teacherName: teacher.name,
      teacherPhoto: teacher.image,
      subject: chosenSubject,
      studentId: studentId,
      studentLastName: studentLastName.trim(),
      studentFirstName: studentFirstName.trim(),
      birthDate: birthDate.trim(),
      birthPlace: birthPlace.trim(),
      phone: phone.trim(),
      email: email.trim(),
      studyLevel: studyLevel,
      fieldOfStudy: fieldOfStudy.trim(),
      academicYear: academicYear,
      proposedSchedule: finalSchedule,
      fee: finalFee,
      paymentMethod: paymentMethod,
      paymentStatus: 'Paiement confirmé',
      status: 'Inscription confirmée',
      createdAt: now,
    );

    // 1. Save to local cache for instant offline responsiveness
    try {
      final prefs = await SharedPreferences.getInstance();

      // Student cache
      final studentKey = 'student_teacher_registrations_$studentId';
      final existingStudent = prefs.getStringList(studentKey) ?? [];
      final studentList = existingStudent.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
      studentList.insert(0, registration.toMap());
      await prefs.setStringList(studentKey, studentList.map((e) => jsonEncode(e)).toList());

      // Teacher cache
      final teacherKey = 'teacher_received_registrations_${teacher.id}';
      final existingTeacher = prefs.getStringList(teacherKey) ?? [];
      final teacherList = existingTeacher.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
      teacherList.insert(0, registration.toMap());
      await prefs.setStringList(teacherKey, teacherList.map((e) => jsonEncode(e)).toList());

      // Broadcast to local streams
      _notifyStudentStream(studentId);
      _notifyTeacherStream(teacher.id);
    } catch (e) {
      debugPrint('Local registration cache error: $e');
    }

    // 2. Record payment in StudentPaymentService (creates official receipt & invoice)
    try {
      await StudentPaymentService().recordPayment(
        studentId: studentId,
        studentName: registration.studentFullName,
        courseId: 'teacher_${teacher.id}',
        courseTitle: 'Inscription ${registration.subject} — ${teacher.name} ($studyLevel)',
        monthLabel: 'Frais d\'inscription $academicYear',
        amount: finalFee,
        paymentMethod: paymentMethod,
        isMonthlyFee: false,
      );
    } catch (e) {
      debugPrint('StudentPaymentService record error: $e');
    }

    // 3. Save to Firestore `teacher_registrations`
    try {
      final db = _firestore;
      if (db != null) {
        await db.collection('teacher_registrations').doc(regId).set(
          registration.toMap(),
          SetOptions(merge: true),
        ).timeout(const Duration(seconds: 4));

        // 4. Send official notification to the teacher
        await db.collection('notifications').add({
          'userId': teacher.id,
          'targetRole': 'teacher',
          'type': 'new_student_enrollment',
          'title': 'Nouvel étudiant inscrit ! 🎓',
          'message': '${registration.studentFullName} s\'est inscrit à vos cours de $chosenSubject ($studyLevel).',
          'registrationId': regId,
          'registrationNumber': regNumber,
          'studentName': registration.studentFullName,
          'subject': chosenSubject,
          'studyLevel': studyLevel,
          'proposedSchedule': finalSchedule,
          'fee': finalFee,
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        }).timeout(const Duration(seconds: 4));
      }
    } catch (e) {
      debugPrint('Firestore teacher registration save fallback: $e');
    }

    // 5. Rattachement automatique et dynamique à la Classe / Promotion du Formateur
    try {
      final cohort = await ClassService().getOrCreateClassForCourse(
        courseId: 'class_${teacher.id}_${chosenSubject.toLowerCase().replaceAll(' ', '_')}',
        courseName: '$chosenSubject — $academicYear',
        teacherId: teacher.id,
        teacherName: teacher.name,
      );
      await ClassService().enrollStudent(
        classId: cohort.id,
        studentId: studentId,
        studentName: registration.studentFullName,
        studentEmail: email.trim(),
        studentPhone: phone.trim(),
      );
    } catch (e) {
      debugPrint('Class auto-enrollment for teacher error: $e');
    }

    return registration;
  }

  /// Get real-time stream of registrations for a student
  Stream<List<TeacherStudentRegistrationModel>> getStudentRegistrationsStream(String studentId) async* {
    _studentControllers.putIfAbsent(
      studentId,
      () => StreamController<List<TeacherStudentRegistrationModel>>.broadcast(),
    );

    final initial = await getStudentRegistrations(studentId);
    yield initial;

    yield* _studentControllers[studentId]!.stream;
  }

  /// Get real-time stream of registrations received by a teacher
  Stream<List<TeacherStudentRegistrationModel>> getTeacherRegistrationsStream(String teacherId) async* {
    _teacherControllers.putIfAbsent(
      teacherId,
      () => StreamController<List<TeacherStudentRegistrationModel>>.broadcast(),
    );

    final initial = await getTeacherRegistrations(teacherId);
    yield initial;

    yield* _teacherControllers[teacherId]!.stream;
  }

  Future<void> _notifyStudentStream(String studentId) async {
    final list = await getStudentRegistrations(studentId);
    _studentControllers[studentId]?.add(list);
  }

  Future<void> _notifyTeacherStream(String teacherId) async {
    final list = await getTeacherRegistrations(teacherId);
    _teacherControllers[teacherId]?.add(list);
  }

  void notifyTeacherStream(String teacherId) {
    _notifyTeacherStream(teacherId);
  }

  /// Fetch all registrations for a student
  Future<List<TeacherStudentRegistrationModel>> getStudentRegistrations(String studentId) async {
    final List<TeacherStudentRegistrationModel> list = [];
    final Set<String> ids = {};

    // 1. From local cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList('student_teacher_registrations_$studentId') ?? [];
      for (final s in raw) {
        final data = jsonDecode(s) as Map<String, dynamic>;
        final m = TeacherStudentRegistrationModel.fromMap(data, data['id'] ?? '');
        if (m.id.isNotEmpty && !ids.contains(m.id)) {
          list.add(m);
          ids.add(m.id);
        }
      }
    } catch (_) {}

    // 2. From Firestore
    try {
      final db = _firestore;
      if (db != null) {
        final snap = await db
            .collection('teacher_registrations')
            .where('studentId', isEqualTo: studentId)
            .get()
            .timeout(const Duration(seconds: 4));

        for (final doc in snap.docs) {
          if (!ids.contains(doc.id)) {
            list.add(TeacherStudentRegistrationModel.fromFirestore(doc));
            ids.add(doc.id);
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting student registrations from firestore: $e');
    }

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Fetch all registrations received by a teacher
  Future<List<TeacherStudentRegistrationModel>> getTeacherRegistrations(String teacherId) async {
    final List<TeacherStudentRegistrationModel> list = [];
    final Set<String> ids = {};

    // 1. From local cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList('teacher_received_registrations_$teacherId') ?? [];
      for (final s in raw) {
        final data = jsonDecode(s) as Map<String, dynamic>;
        final m = TeacherStudentRegistrationModel.fromMap(data, data['id'] ?? '');
        if (m.id.isNotEmpty && !ids.contains(m.id)) {
          list.add(m);
          ids.add(m.id);
        }
      }
    } catch (_) {}

    // 2. From Firestore
    try {
      final db = _firestore;
      if (db != null) {
        final snap = await db
            .collection('teacher_registrations')
            .where('teacherId', isEqualTo: teacherId)
            .get()
            .timeout(const Duration(seconds: 4));

        for (final doc in snap.docs) {
          if (!ids.contains(doc.id)) {
            list.add(TeacherStudentRegistrationModel.fromFirestore(doc));
            ids.add(doc.id);
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting teacher registrations from firestore: $e');
    }

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }
}
