import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/appointment_model.dart';

class AppointmentService {
  static final AppointmentService _instance = AppointmentService._internal();
  factory AppointmentService() => _instance;
  AppointmentService._internal() {
    _initCache();
  }

  static const String _cacheKey = 'olivia_appointments_cache_v1';
  final StreamController<List<AppointmentModel>> _streamController =
      StreamController<List<AppointmentModel>>.broadcast();

  List<AppointmentModel> _cachedAppointments = [];
  bool _initialized = false;

  FirebaseFirestore? get _firestore {
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('Firestore not ready in AppointmentService: $e');
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
        final decoded = jsonDecode(raw) as List<dynamic>;
        _cachedAppointments = decoded
            .map((item) => AppointmentModel.fromMap(
                Map<String, dynamic>.from(item as Map), item['id']?.toString() ?? ''))
            .toList();
        _streamController.add(_cachedAppointments);
      }
    } catch (e) {
      debugPrint('AppointmentService cache error: $e');
    }

    _syncRemote();
  }

  Future<void> _saveCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_cachedAppointments.map((a) => a.toMap()).toList());
      await prefs.setString(_cacheKey, encoded);
    } catch (e) {
      debugPrint('AppointmentService saveCache error: $e');
    }
  }

  Future<void> _syncRemote() async {
    try {
      final db = _firestore;
      if (db != null) {
        final snap = await db
            .collection('appointments')
            .orderBy('createdAt', descending: true)
            .limit(100)
            .get()
            .timeout(const Duration(seconds: 4));

        if (snap.docs.isNotEmpty) {
          final list = snap.docs
              .map((d) => AppointmentModel.fromMap(d.data(), d.id))
              .toList();
          _cachedAppointments = list;
          await _saveCache();
          _streamController.add(_cachedAppointments);
        }
      }
    } catch (e) {
      debugPrint('Firestore sync appointments fallback: $e');
    }
  }

  /// Get real-time stream of appointments for a teacher
  Stream<List<AppointmentModel>> getTeacherAppointmentsStream(String teacherId) async* {
    await _initCache();
    yield _cachedAppointments.where((a) => a.teacherId == teacherId).toList();
    yield* _streamController.stream.map(
      (list) => list.where((a) => a.teacherId == teacherId).toList(),
    );
  }

  /// Get real-time stream of appointments for a student
  Stream<List<AppointmentModel>> getStudentAppointmentsStream(String studentId) async* {
    await _initCache();
    yield _cachedAppointments.where((a) => a.studentId == studentId).toList();
    yield* _streamController.stream.map(
      (list) => list.where((a) => a.studentId == studentId).toList(),
    );
  }

  /// Book an appointment dynamically
  Future<String> bookAppointment({
    required String teacherId,
    required String teacherName,
    String? teacherPhoto,
    required String studentId,
    required String studentName,
    String? studentEmail,
    String? studentPhone,
    required DateTime date,
    required String timeSlot,
    required String sessionType,
    String notes = '',
  }) async {
    await _initCache();
    final aptId = 'apt_${DateTime.now().millisecondsSinceEpoch}';

    final appointment = AppointmentModel(
      id: aptId,
      teacherId: teacherId,
      teacherName: teacherName,
      teacherPhoto: teacherPhoto,
      studentId: studentId,
      studentName: studentName,
      studentEmail: studentEmail,
      studentPhone: studentPhone,
      date: date,
      timeSlot: timeSlot,
      sessionType: sessionType,
      notes: notes,
      status: 'CONFIRMED',
      createdAt: DateTime.now(),
    );

    // 1. Update local cache and notify streams immediately
    _cachedAppointments = [appointment, ..._cachedAppointments];
    await _saveCache();
    _streamController.add(_cachedAppointments);

    // 2. Persist to Firestore
    try {
      final db = _firestore;
      if (db != null) {
        await db
            .collection('appointments')
            .doc(aptId)
            .set(appointment.toMap())
            .timeout(const Duration(seconds: 4));
      }
    } catch (e) {
      debugPrint('Firestore save appointment fallback: $e');
    }

    return aptId;
  }
}
