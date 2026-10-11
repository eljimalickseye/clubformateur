import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_notification_model.dart';
import 'corrector_service.dart';
import 'enrollment_service.dart';
import 'system_log_service.dart';

class AppNotificationService {
  static final AppNotificationService _instance = AppNotificationService._internal();
  factory AppNotificationService() => _instance;
  AppNotificationService._internal();

  final Map<String, StreamController<List<AppNotificationModel>>> _controllers = {};
  final Map<String, List<AppNotificationModel>> _localCache = {};

  FirebaseFirestore? get _firestore {
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('Firestore not ready in AppNotificationService: $e');
    }
    return null;
  }

  StreamController<List<AppNotificationModel>> _getController(String userId) {
    if (!_controllers.containsKey(userId) || _controllers[userId]!.isClosed) {
      _controllers[userId] = StreamController<List<AppNotificationModel>>.broadcast();
    }
    return _controllers[userId]!;
  }

  Future<void> _initUserNotifications(String userId) async {
    if (_localCache.containsKey(userId)) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'app_notifications_$userId';
      final raw = prefs.getStringList(key) ?? [];
      final list = raw.map((r) => AppNotificationModel.fromMap(jsonDecode(r) as Map<String, dynamic>)).toList();
      _localCache[userId] = list;
      _getController(userId).add(list);
    } catch (e) {
      debugPrint('Error loading notifications for $userId: $e');
      _localCache[userId] = [];
    }

    // Synchronisation depuis Firestore en arrière-plan
    _syncFromFirestore(userId);
  }

  Future<void> _syncFromFirestore(String userId) async {
    try {
      final db = _firestore;
      if (db == null) return;

      final snap = await db
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .limit(30)
          .get()
          .timeout(const Duration(seconds: 4));

      if (snap.docs.isNotEmpty) {
        final remoteList = snap.docs.map((doc) => AppNotificationModel.fromFirestore(doc)).toList();
        final current = _localCache[userId] ?? [];
        final existingIds = current.map((n) => n.id).toSet();

        bool hasNew = false;
        for (final r in remoteList) {
          if (!existingIds.contains(r.id)) {
            current.insert(0, r);
            hasNew = true;
          }
        }

        if (hasNew) {
          _localCache[userId] = current;
          await _persistLocal(userId);
          _getController(userId).add(current);
        }
      }
    } catch (_) {}
  }

  Future<void> _persistLocal(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _localCache[userId] ?? [];
      final encoded = list.map((n) => jsonEncode(n.toMap())).toList();
      await prefs.setStringList('app_notifications_$userId', encoded);
    } catch (e) {
      debugPrint('Error saving notifications for $userId: $e');
    }
  }

  /// Récupérer le flux temps réel de notifications pour un utilisateur
  Stream<List<AppNotificationModel>> getUserNotificationsStream(String userId) async* {
    await _initUserNotifications(userId);
    yield _localCache[userId] ?? [];
    yield* _getController(userId).stream;
  }

  /// Nombre de notifications non lues
  Stream<int> getUnreadCountStream(String userId) {
    return getUserNotificationsStream(userId).map((list) => list.where((n) => !n.isRead).length);
  }

  /// Envoyer une notification directe à un utilisateur (Offline-first + Firestore)
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? actionRoute,
    Map<String, dynamic> data = const {},
  }) async {
    final now = DateTime.now();
    final notifId = 'notif_${now.millisecondsSinceEpoch}_${now.microsecond}';

    final notification = AppNotificationModel(
      id: notifId,
      userId: userId,
      title: title,
      message: message,
      type: type,
      timestamp: now,
      isRead: false,
      actionRoute: actionRoute,
      data: data,
    );

    // 1. Sauvegarde locale immédiate
    await _initUserNotifications(userId);
    final list = _localCache[userId] ?? [];
    list.insert(0, notification);
    _localCache[userId] = list;
    await _persistLocal(userId);
    _getController(userId).add(list);

    // 2. Synchronisation Firestore
    try {
      final db = _firestore;
      if (db != null) {
        unawaited(
          db.collection('notifications').doc(notifId).set(
            notification.toMap(),
            SetOptions(merge: true),
          ).catchError((_) {}),
        );
      }
    } catch (_) {}

    // 3. Log d'audit
    unawaited(
      SystemLogService().logEvent(
        action: 'Notification envoyée ($type)',
        details: '$title : $message',
        category: 'system',
        level: 'info',
        actorName: 'Système Club des Formateurs',
        actorRole: 'Système',
        metadata: {'targetUserId': userId, 'type': type},
      ),
    );
  }

  /// Notifier le formateur
  Future<void> notifyTeacher({
    required String teacherId,
    required String title,
    required String message,
    required String type,
    String? actionRoute,
    Map<String, dynamic> data = const {},
  }) async {
    await sendNotification(
      userId: teacherId,
      title: title,
      message: message,
      type: type,
      actionRoute: actionRoute,
      data: data,
    );
  }

  /// Notifier le correcteur associé à un professeur
  Future<void> notifyLinkedCorrector({
    required String teacherId,
    required String title,
    required String message,
    required String type,
    String? actionRoute,
    Map<String, dynamic> data = const {},
  }) async {
    try {
      final corrector = await CorrectorService().getLinkedCorrector(teacherId);
      if (corrector != null && corrector.uid.isNotEmpty) {
        await sendNotification(
          userId: corrector.uid,
          title: title,
          message: message,
          type: type,
          actionRoute: actionRoute,
          data: data,
        );
      }
    } catch (e) {
      debugPrint('Error notifying corrector for teacher $teacherId: $e');
    }
  }

  /// Notifier tous les étudiants inscrits à un cours
  Future<void> notifyCourseStudents({
    required String courseId,
    required String title,
    required String message,
    required String type,
    String? actionRoute,
    Map<String, dynamic> data = const {},
  }) async {
    try {
      final enrollments = await EnrollmentService().getCourseEnrollments(courseId);
      final studentIds = enrollments.map((e) => e.studentId).toSet();

      for (final sId in studentIds) {
        if (sId.isNotEmpty) {
          unawaited(
            sendNotification(
              userId: sId,
              title: title,
              message: message,
              type: type,
              actionRoute: actionRoute,
              data: data,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error notifying course students: $e');
    }
  }

  /// Marquer une notification comme lue
  Future<void> markAsRead(String userId, String notificationId) async {
    await _initUserNotifications(userId);
    final list = _localCache[userId] ?? [];
    final idx = list.indexWhere((n) => n.id == notificationId);
    if (idx != -1) {
      list[idx] = list[idx].copyWith(isRead: true);
      _localCache[userId] = list;
      await _persistLocal(userId);
      _getController(userId).add(list);
    }

    try {
      final db = _firestore;
      if (db != null) {
        unawaited(
          db.collection('notifications').doc(notificationId).update({'isRead': true}).catchError((_) {}),
        );
      }
    } catch (_) {}
  }

  /// Marquer toutes les notifications comme lues
  Future<void> markAllAsRead(String userId) async {
    await _initUserNotifications(userId);
    final list = _localCache[userId] ?? [];
    final updated = list.map((n) => n.copyWith(isRead: true)).toList();
    _localCache[userId] = updated;
    await _persistLocal(userId);
    _getController(userId).add(updated);

    try {
      final db = _firestore;
      if (db != null) {
        final snap = await db.collection('notifications').where('userId', isEqualTo: userId).get();
        for (final doc in snap.docs) {
          unawaited(doc.reference.update({'isRead': true}).catchError((_) {}));
        }
      }
    } catch (_) {}
  }
}
