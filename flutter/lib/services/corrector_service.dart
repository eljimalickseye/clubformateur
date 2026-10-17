import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/live_session_model.dart';
import '../models/user_model.dart';
import 'chat_service.dart';
import 'live_session_service.dart';
import 'super_admin_service.dart';

class CorrectorService {
  static final CorrectorService _instance = CorrectorService._internal();
  factory CorrectorService() => _instance;
  CorrectorService._internal();

  FirebaseFirestore? get _db {
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('Firestore error CorrectorService: $e');
    }
    return null;
  }

  /// Recupere le prof lie a un correcteur
  Future<UserModel?> getLinkedTeacher(String correctorId) async {
    try {
      final users = await SuperAdminService().getAllUsersStream().first;
      final corr = users.where((u) => u.uid == correctorId).firstOrNull;
      if (corr != null && corr.linkedTeacherId != null) {
        final teacher = users.where((u) => u.uid == corr.linkedTeacherId).firstOrNull;
        if (teacher != null) return teacher;
      }
    } catch (_) {}

    final db = _db;
    if (db != null) {
      try {
        final doc = await db.collection('users').doc(correctorId).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final teacherId = data['linkedTeacherId'] as String?;
          if (teacherId != null) {
            final teacherDoc = await db.collection('users').doc(teacherId).get();
            if (teacherDoc.exists) {
              return UserModel.fromMap(teacherDoc.data() as Map<String, dynamic>, teacherDoc.id);
            }
          }
        }
      } catch (e) {
        debugPrint('getLinkedTeacher error: $e');
      }
    }
    return null;
  }

  /// Recupere le correcteur lie a un prof
  Future<UserModel?> getLinkedCorrector(String teacherId) async {
    try {
      final users = await SuperAdminService().getAllUsersStream().first;
      final teacher = users.where((u) => u.uid == teacherId).firstOrNull;
      if (teacher != null && teacher.linkedCorrectorId != null) {
        final corr = users.where((u) => u.uid == teacher.linkedCorrectorId).firstOrNull;
        if (corr != null) return corr;
      }
    } catch (_) {}

    final db = _db;
    if (db != null) {
      try {
        final doc = await db.collection('users').doc(teacherId).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final correctorId = data['linkedCorrectorId'] as String?;
          if (correctorId != null) {
            final correctorDoc = await db.collection('users').doc(correctorId).get();
            if (correctorDoc.exists) {
              return UserModel.fromMap(correctorDoc.data() as Map<String, dynamic>, correctorDoc.id);
            }
          }
        }
      } catch (e) {
        debugPrint('getLinkedCorrector error: $e');
      }
    }
    return null;
  }

  /// Ouvre ou cree la conversation entre prof et correcteur
  Future<String> openTeacherCorrectorConversation({
    required String currentUserId,
    required String currentUserName,
    String currentUserPhoto = '',
    required String otherUserId,
    required String otherUserName,
    String otherUserPhoto = '',
  }) async {
    return ChatService().getOrCreateConversation(
      currentUserId: currentUserId,
      currentUserName: currentUserName,
      currentUserPhoto: currentUserPhoto,
      targetUserId: otherUserId,
      targetUserName: otherUserName,
      targetUserPhoto: otherUserPhoto,
      courseName: 'Canal Professeur-Correcteur',
    );
  }

  /// Correcteur demarre un live d'exercices (1h30)
  Future<String> startCorrectorLive({
    required String correctorId,
    required String correctorName,
    String correctorPhotoUrl = '',
    required String courseId,
    required String courseName,
    required String title,
  }) async {
    final id = await LiveSessionService().startLiveSession(
      courseId: courseId,
      courseName: courseName,
      title: title,
      teacherId: correctorId,
      teacherName: correctorName,
      teacherPhotoUrl: correctorPhotoUrl,
      sessionType: 'corrector_live',
      hostRole: 'corrector',
    );
    await LiveSessionService().switchToExercisesPhase(id);
    return id;
  }

  /// Stream des lives actifs du correcteur
  Stream<List<LiveSessionModel>> getCorrectorLiveSessionsStream() {
    return LiveSessionService().getActiveLiveSessionsStream().map(
          (list) => list
              .where((s) =>
                  (s.sessionType == 'corrector_live' || s.hostRole == 'corrector') &&
                  s.status == 'live')
              .toList(),
        );
  }
}
