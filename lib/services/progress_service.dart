import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/progress_model.dart';
import 'laravel_api_service.dart';

class ProgressService {
  static final ProgressService _instance = ProgressService._internal();
  factory ProgressService() => _instance;
  ProgressService._internal();

  final LaravelApiService _api = LaravelApiService();
  final Map<String, StreamController<StudentProgressModel?>> _controllers = {};

  FirebaseFirestore? get _firestore {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
    } catch (e) {
      debugPrint('Firestore error in ProgressService: $e');
    }
    return null;
  }

  /// Get progress stream for a specific course and user
  Stream<StudentProgressModel?> getCourseProgressStream(String userId, String courseId) async* {
    final key = '${userId}_$courseId';
    _controllers.putIfAbsent(
      key,
      () => StreamController<StudentProgressModel?>.broadcast(),
    );

    final initial = await getCourseProgress(userId, courseId);
    yield initial;

    yield* _controllers[key]!.stream;
  }

  /// Get course progress once
  Future<StudentProgressModel?> getCourseProgress(String userId, String courseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'progress_${userId}_$courseId';
      final jsonStr = prefs.getString(key);
      if (jsonStr != null) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        return StudentProgressModel(
          courseId: courseId,
          userId: userId,
          completedLessonIds: List<String>.from(map['completedLessonIds'] ?? []),
          lastWatchedLessonId: map['lastWatchedLessonId']?.toString(),
          progressPercentage: (map['progressPercentage'] as num?)?.toDouble() ?? 0.0,
          lastUpdatedAt: DateTime.now(),
        );
      }

      final db = _firestore;
      if (db != null && !userId.startsWith('demo_')) {
        final doc = await db
            .collection('progress')
            .doc(userId)
            .collection('courses')
            .doc(courseId)
            .get()
            .timeout(const Duration(seconds: 2));
        if (doc.exists && doc.data() != null) {
          return StudentProgressModel.fromFirestore(doc);
        }
      }
    } catch (e) {
      debugPrint('Error getting course progress: $e');
    }

    // Default demo progress for Moussa on React course
    if ((userId.startsWith('demo_student') || userId == 'user_moussa') && courseId == 'react') {
      return StudentProgressModel(
        courseId: 'react',
        userId: userId,
        completedLessonIds: const ['l1', 'l2'],
        lastWatchedLessonId: 'l2',
        progressPercentage: 0.65,
        lastUpdatedAt: DateTime.now(),
      );
    }

    return null;
  }

  /// Mark a lesson as completed
  Future<StudentProgressModel> markLessonCompleted({
    required String userId,
    required String courseId,
    required String lessonId,
    required int totalLessons,
  }) async {
    final current = await getCourseProgress(userId, courseId);
    final completedIds = Set<String>.from(current?.completedLessonIds ?? []);
    completedIds.add(lessonId);

    final percentage =
        totalLessons > 0 ? (completedIds.length / totalLessons).clamp(0.0, 1.0) : 1.0;

    final updated = StudentProgressModel(
      courseId: courseId,
      userId: userId,
      completedLessonIds: completedIds.toList(),
      lastWatchedLessonId: lessonId,
      progressPercentage: percentage,
      lastUpdatedAt: DateTime.now(),
    );

    // 1. Save to local cache & broadcast immediately
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'progress_${userId}_$courseId';
      await prefs.setString(
        key,
        jsonEncode({
          'completedLessonIds': updated.completedLessonIds,
          'lastWatchedLessonId': updated.lastWatchedLessonId,
          'progressPercentage': updated.progressPercentage,
        }),
      );
    } catch (e) {
      debugPrint('Local save progress error: $e');
    }

    _controllers['${userId}_$courseId']?.add(updated);

    // 2. Sync with Laravel API (/api/v1/enrollments/{id}/progress)
    unawaited(_api.patch('/enrollments/${userId}_$courseId/progress', {
      'user_id': userId,
      'course_id': courseId,
      'lesson_id': lessonId,
      'progress_percent': (percentage * 100).round(),
      'completed_lesson_ids': updated.completedLessonIds,
    }));

    // 3. Save to Firestore
    try {
      final db = _firestore;
      if (db != null && !userId.startsWith('demo_')) {
        await db
            .collection('progress')
            .doc(userId)
            .collection('courses')
            .doc(courseId)
            .set(updated.toMap(), SetOptions(merge: true))
            .timeout(const Duration(seconds: 3));
      }
    } catch (e) {
      debugPrint('Firestore save progress error: $e');
    }

    return updated;
  }

  /// Get all courses progress for student dashboard
  Future<Map<String, StudentProgressModel>> getAllUserProgress(String userId) async {
    final Map<String, StudentProgressModel> result = {};
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefix = 'progress_${userId}_';
      for (final k in prefs.getKeys()) {
        if (k.startsWith(prefix)) {
          final cId = k.substring(prefix.length);
          final p = await getCourseProgress(userId, cId);
          if (p != null) result[cId] = p;
        }
      }
    } catch (_) {}

    if ((userId.startsWith('demo_student') || userId == 'user_moussa') &&
        !result.containsKey('react')) {
      final p = await getCourseProgress(userId, 'react');
      if (p != null) result['react'] = p;
    }

    return result;
  }
}
