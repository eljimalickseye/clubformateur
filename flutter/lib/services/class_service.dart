import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/class_model.dart';
import 'laravel_api_service.dart';

class ClassService {
  static final ClassService _instance = ClassService._internal();
  factory ClassService() => _instance;
  ClassService._internal() {
    _initCache();
  }

  static const String _cacheKey = 'local_classes_cohorts_v1';
  final LaravelApiService _api = LaravelApiService();
  final StreamController<List<ClassCohortModel>> _classesController =
      StreamController<List<ClassCohortModel>>.broadcast();

  List<ClassCohortModel> _cachedClasses = [];
  bool _initialized = false;

  FirebaseFirestore? get _db {
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('Firestore not ready ClassService: $e');
    }
    return null;
  }

  Future<void> _initCache() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw != null && raw.isNotEmpty) {
        _cachedClasses = (jsonDecode(raw) as List)
            .map((e) => ClassCohortModel.fromMap(
                Map<String, dynamic>.from(e as Map), e['id']?.toString() ?? ''))
            .toList();
      }
    } catch (e) {
      debugPrint('ClassService cache init error: $e');
    }

    _classesController.add(_cachedClasses);
    unawaited(_syncRemote());
    unawaited(syncStoredRegistrations());
  }

  Future<void> _saveCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _cacheKey,
        jsonEncode(_cachedClasses.map((c) => c.toMap()).toList()),
      );
    } catch (e) {
      debugPrint('ClassService saveCache error: $e');
    }
  }

  Future<void> _syncRemote() async {
    // 1. Sync from Firestore
    try {
      final db = _db;
      if (db != null) {
        final snap = await db.collection('classes').limit(50).get().timeout(const Duration(seconds: 4));
        if (snap.docs.isNotEmpty) {
          final list = snap.docs
              .map((d) => ClassCohortModel.fromMap(d.data(), d.id))
              .toList();
          if (list.isNotEmpty) {
            _cachedClasses = list;
            await _saveCache();
            _classesController.add(_cachedClasses);
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Firestore classes sync fallback: $e');
    }

    // 2. Sync from Laravel API
    try {
      final res = await _api.get('/classes');
      if (res != null && res['data'] is List) {
        final list = (res['data'] as List)
            .map((item) => ClassCohortModel.fromMap(
                Map<String, dynamic>.from(item as Map), item['id']?.toString() ?? ''))
            .toList();
        if (list.isNotEmpty) {
          _cachedClasses = list;
          await _saveCache();
          _classesController.add(_cachedClasses);
        }
      }
    } catch (_) {}
  }

  /// Get stream of all classes
  Stream<List<ClassCohortModel>> getAllClassesStream() async* {
    await _initCache();
    yield _cachedClasses;
    yield* _classesController.stream;
  }

  /// Get classes taught by a specific Titulaire
  /// Supporte à la fois l'identifiant strict et le nom d'affichage du formateur
  Stream<List<ClassCohortModel>> getTeacherClassesStream(String teacherId, {String? teacherName}) async* {
    await _initCache();
    bool matches(ClassCohortModel c) {
      if (teacherId.isEmpty && (teacherName == null || teacherName.isEmpty)) return false;
      final cleanId = teacherId.trim().toLowerCase();
      final classTeacherId = c.teacherId.trim().toLowerCase();
      if (cleanId.isNotEmpty && (classTeacherId == cleanId || classTeacherId.contains(cleanId) || cleanId.contains(classTeacherId))) {
        return true;
      }
      if (teacherName != null && teacherName.trim().isNotEmpty) {
        final cleanName = teacherName.trim().toLowerCase();
        final classTeacherName = c.teacherName.trim().toLowerCase();
        if (classTeacherName.isNotEmpty && (classTeacherName == cleanName || classTeacherName.contains(cleanName) || cleanName.contains(classTeacherName))) {
          return true;
        }
      }
      return false;
    }

    yield _cachedClasses.where(matches).toList();
    yield* _classesController.stream.map((list) => list.where(matches).toList());
  }

  /// Get classes assigned to a Corrector
  /// Seules les classes dont [correctorId] correspond exactement sont retournées.
  /// Un correcteur ne voit jamais les classes d'un autre rôle (prof, etc.).
  Stream<List<ClassCohortModel>> getCorrectorClassesStream(String correctorId) async* {
    await _initCache();
    bool matches(ClassCohortModel c) {
      if (correctorId.isEmpty) return false; // Pas de fuite si l'ID n'est pas encore chargé
      return c.correctorId == correctorId;
    }

    yield _cachedClasses.where(matches).toList();
    yield* _classesController.stream.map((list) => list.where(matches).toList());
  }

  /// Get classes where a student is enrolled
  Stream<List<ClassCohortModel>> getStudentClassesStream(String studentId) async* {
    await _initCache();
    bool matches(ClassCohortModel c) =>
        c.studentIds.contains(studentId) || _cachedClasses.isEmpty;

    yield _cachedClasses.where(matches).toList();
    yield* _classesController.stream.map((list) => list.where(matches).toList());
  }

  /// Create a new class (max 100 students)
  Future<String> createClass({
    required String name,
    required String courseId,
    required String courseName,
    required String teacherId,
    required String teacherName,
    required String correctorId,
    required String correctorName,
    int maxCapacity = 100,
    List<ClassScheduleSlot> schedule = const [],
  }) async {
    await _initCache();
    final id = 'class_${DateTime.now().millisecondsSinceEpoch}';

    final newClass = ClassCohortModel(
      id: id,
      name: name,
      courseId: courseId,
      courseName: courseName,
      maxCapacity: maxCapacity > 100 ? 100 : maxCapacity,
      studentIds: [],
      studentNames: {},
      teacherId: teacherId,
      teacherName: teacherName,
      correctorId: correctorId,
      correctorName: correctorName,
      schedule: schedule,
      createdAt: DateTime.now(),
    );

    _cachedClasses = [newClass, ..._cachedClasses];
    await _saveCache();
    _classesController.add(_cachedClasses);

    try {
      final db = _db;
      if (db != null) {
        await db.collection('classes').doc(id).set(newClass.toMap()).timeout(const Duration(seconds: 4));
      }
    } catch (_) {}

    return id;
  }

  Future<String> createClassCohort({
    required String name,
    required String courseId,
    required String courseName,
    required String teacherId,
    required String teacherName,
    required String correctorId,
    required String correctorName,
    int maxCapacity = 100,
    List<ClassScheduleSlot> schedule = const [],
  }) => createClass(
    name: name,
    courseId: courseId,
    courseName: courseName,
    teacherId: teacherId,
    teacherName: teacherName,
    correctorId: correctorId,
    correctorName: correctorName,
    maxCapacity: maxCapacity,
    schedule: schedule,
  );

  /// Find or create a cohort for a given course so learners are automatically enrolled
  Future<ClassCohortModel> getOrCreateClassForCourse({
    required String courseId,
    required String courseName,
    required String teacherId,
    required String teacherName,
    String correctorId = '',
    String correctorName = 'Correcteur Dédié',
  }) async {
    await _initCache();
    final existing = _cachedClasses.where((c) => c.courseId == courseId).firstOrNull;
    if (existing != null) return existing;

    final newClassId = await createClassCohort(
      name: 'Promotion - $courseName',
      courseId: courseId,
      courseName: courseName,
      teacherId: teacherId,
      teacherName: teacherName,
      correctorId: correctorId,
      correctorName: correctorName,
      maxCapacity: 100,
    );

    return _cachedClasses.firstWhere((c) => c.id == newClassId);
  }

  /// Add student to class (enforces 100 student max) and stores complete student contact details
  Future<bool> enrollStudent({
    required String classId,
    required String studentId,
    required String studentName,
    String studentEmail = '',
    String studentPhone = '',
  }) async {
    await _initCache();
    final index = _cachedClasses.indexWhere((c) => c.id == classId);
    if (index == -1) return false;

    final target = _cachedClasses[index];
    final updatedStudentIds = target.studentIds.contains(studentId)
        ? target.studentIds
        : [...target.studentIds, studentId];
    if (target.isFull && !target.studentIds.contains(studentId)) return false; // Max 100 reached

    final updatedStudentNames = {...target.studentNames, studentId: studentName};
    final updatedStudentEmails = {...target.studentEmails};
    if (studentEmail.isNotEmpty) updatedStudentEmails[studentId] = studentEmail;
    final updatedStudentPhones = {...target.studentPhones};
    if (studentPhone.isNotEmpty) updatedStudentPhones[studentId] = studentPhone;

    final updated = ClassCohortModel(
      id: target.id,
      name: target.name,
      courseId: target.courseId,
      courseName: target.courseName,
      maxCapacity: target.maxCapacity,
      studentIds: updatedStudentIds,
      studentNames: updatedStudentNames,
      studentEmails: updatedStudentEmails,
      studentPhones: updatedStudentPhones,
      teacherId: target.teacherId,
      teacherName: target.teacherName,
      correctorId: target.correctorId,
      correctorName: target.correctorName,
      academicYear: target.academicYear,
      schedule: target.schedule,
      createdAt: target.createdAt,
    );

    _cachedClasses[index] = updated;
    await _saveCache();
    _classesController.add(_cachedClasses);

    try {
      final db = _db;
      if (db != null) {
        final updateData = <String, dynamic>{
          'studentIds': FieldValue.arrayUnion([studentId]),
          'studentNames.$studentId': studentName,
        };
        if (studentEmail.isNotEmpty) {
          updateData['studentEmails.$studentId'] = studentEmail;
        }
        if (studentPhone.isNotEmpty) {
          updateData['studentPhones.$studentId'] = studentPhone;
        }
        await db.collection('classes').doc(classId).update(updateData).timeout(const Duration(seconds: 4));
      }
    } catch (_) {}

    return true;
  }

  /// Update schedule for class
  Future<void> updateSchedule({
    required String classId,
    required List<ClassScheduleSlot> schedule,
  }) async {
    await _initCache();
    final index = _cachedClasses.indexWhere((c) => c.id == classId);
    if (index == -1) return;

    final target = _cachedClasses[index];
    final updated = ClassCohortModel(
      id: target.id,
      name: target.name,
      courseId: target.courseId,
      courseName: target.courseName,
      maxCapacity: target.maxCapacity,
      studentIds: target.studentIds,
      studentNames: target.studentNames,
      teacherId: target.teacherId,
      teacherName: target.teacherName,
      correctorId: target.correctorId,
      correctorName: target.correctorName,
      academicYear: target.academicYear,
      schedule: schedule,
      createdAt: target.createdAt,
    );

    _cachedClasses[index] = updated;
    await _saveCache();
    _classesController.add(_cachedClasses);

    try {
      final db = _db;
      if (db != null) {
        await db.collection('classes').doc(classId).update({
          'schedule': schedule.map((s) => s.toMap()).toList(),
        }).timeout(const Duration(seconds: 4));
      }
    } catch (_) {}
  }

  /// Réconciliation automatique : s'assure qu'un apprenant inscrit est bien répertorié dans la classe du cours
  Future<void> reconcileRegistration({
    required String courseId,
    required String courseName,
    required String teacherId,
    required String teacherName,
    required String studentId,
    required String studentName,
    String studentEmail = '',
    String studentPhone = '',
  }) async {
    try {
      final cohort = await getOrCreateClassForCourse(
        courseId: courseId,
        courseName: courseName,
        teacherId: teacherId,
        teacherName: teacherName,
      );
      await enrollStudent(
        classId: cohort.id,
        studentId: studentId,
        studentName: studentName,
        studentEmail: studentEmail,
        studentPhone: studentPhone,
      );
    } catch (e) {
      debugPrint('ClassService reconcileRegistration error: $e');
    }
  }

  /// Synchronise toutes les fiches d'inscription locales dans les classes
  Future<void> syncStoredRegistrations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('teacher_received_registrations_') || key.startsWith('student_teacher_registrations_')) {
          final list = prefs.getStringList(key) ?? [];
          for (final raw in list) {
            try {
              final map = jsonDecode(raw) as Map<String, dynamic>;
              final teacherId = map['teacherId']?.toString() ?? '';
              final teacherName = map['teacherName']?.toString() ?? 'Formateur';
              final subject = map['subject']?.toString() ?? 'Formation';
              final studentId = map['studentId']?.toString() ?? '';
              final studentFirstName = map['studentFirstName']?.toString() ?? '';
              final studentLastName = map['studentLastName']?.toString() ?? '';
              final studentName = '$studentFirstName $studentLastName'.trim().isNotEmpty
                  ? '$studentFirstName $studentLastName'.trim()
                  : (map['studentName']?.toString() ?? 'Apprenant');
              final studentEmail = map['email']?.toString() ?? '';
              final studentPhone = map['phone']?.toString() ?? '';
              final year = map['academicYear']?.toString() ?? '2026-2027';

              if (studentId.isNotEmpty && teacherId.isNotEmpty) {
                await reconcileRegistration(
                  courseId: 'class_${teacherId}_${subject.toLowerCase().replaceAll(' ', '_')}',
                  courseName: '$subject — $year',
                  teacherId: teacherId,
                  teacherName: teacherName,
                  studentId: studentId,
                  studentName: studentName,
                  studentEmail: studentEmail,
                  studentPhone: studentPhone,
                );
              }
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      debugPrint('Sync stored registrations into classes error: $e');
    }
  }
}
