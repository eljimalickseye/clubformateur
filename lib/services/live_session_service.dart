import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course_model.dart';
import '../models/live_session_model.dart';
import 'app_notification_service.dart';
import 'course_service.dart';
import 'laravel_api_service.dart';
import 'system_log_service.dart';

class LiveSessionService {
  static final LiveSessionService _instance = LiveSessionService._internal();
  factory LiveSessionService() => _instance;
  LiveSessionService._internal() {
    _initLocalCache();
  }

  static const String _liveCacheKey = 'olivia_live_sessions_v3';

  final CourseService _courseService = CourseService();
  final LaravelApiService _api = LaravelApiService();
  final StreamController<List<LiveSessionModel>> _sessionsController =
      StreamController<List<LiveSessionModel>>.broadcast();

  List<LiveSessionModel> _cachedSessions = [];
  bool _initialized = false;

  FirebaseFirestore? get _firestore {
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('Firestore not ready in LiveSessionService: $e');
    }
    return null;
  }

  Future<void> _initLocalCache() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_liveCacheKey);
      if (raw != null && raw.isNotEmpty) {
        final list = (jsonDecode(raw) as List)
            .map((item) {
              final map = Map<String, dynamic>.from(item as Map);
              return LiveSessionModel.fromJson(map, map['id']?.toString() ?? '');
            })
            .toList();
        _cachedSessions = list;
        _sessionsController.add(_cachedSessions);
      }
    } catch (e) {
      debugPrint('LiveSessionService cache init error: $e');
    }

    _syncFromRemote();
  }

  Future<void> _syncFromRemote() async {
    // 1. Sync from Laravel API
    try {
      final res = await _api.get('/live-sessions');
      if (res != null && res['sessions'] is List) {
        final apiList = (res['sessions'] as List)
            .map((item) {
              final map = Map<String, dynamic>.from(item as Map);
              return LiveSessionModel.fromJson(map, map['id']?.toString() ?? '');
            })
            .toList();
        if (apiList.isNotEmpty) {
          _cachedSessions = _mergeSessions(apiList, _cachedSessions);
          await _saveLocalCache();
          _sessionsController.add(_cachedSessions);
        }
      }
    } catch (_) {}

    // 2. Sync from Firestore
    try {
      final db = _firestore;
      if (db != null) {
        final snap = await db
            .collection('live_sessions')
            .limit(25)
            .get()
            .timeout(const Duration(seconds: 4));
        if (snap.docs.isNotEmpty) {
          final fsList = snap.docs
              .map((d) => LiveSessionModel.fromFirestore(d))
              .toList();
          _cachedSessions = _mergeSessions(fsList, _cachedSessions);
          await _saveLocalCache();
          _sessionsController.add(_cachedSessions);
        }
      }
    } catch (_) {}
  }

  List<LiveSessionModel> _mergeSessions(
    List<LiveSessionModel> primary,
    List<LiveSessionModel> secondary,
  ) {
    final map = <String, LiveSessionModel>{};
    for (final s in secondary) {
      map[s.id] = s;
    }
    for (final s in primary) {
      map[s.id] = s;
    }
    return map.values.toList();
  }

  Future<void> _saveLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _liveCacheKey,
        jsonEncode(_cachedSessions.map((s) => s.toJson()).toList()),
      );
    } catch (_) {}
  }

  Stream<List<LiveSessionModel>> getLiveSessionsStream() async* {
    await _initLocalCache();
    yield _cachedSessions;

    await for (final list in _sessionsController.stream) {
      yield list;
    }
  }

  Stream<List<LiveSessionModel>> getActiveLiveSessionsStream() async* {
    await _initLocalCache();
    yield _cachedSessions.where((s) => s.status == 'live').toList();

    await for (final list in _sessionsController.stream) {
      yield list.where((s) => s.status == 'live').toList();
    }
  }

  Stream<List<LiveSessionModel>> getCourseLiveSessionsStream(String courseId) async* {
    await _initLocalCache();
    yield _cachedSessions.where((s) => s.courseId == courseId).toList();

    await for (final list in _sessionsController.stream) {
      yield list.where((s) => s.courseId == courseId).toList();
    }
  }

  Future<LiveSessionModel?> getLiveSessionById(String id) async {
    await _initLocalCache();
    final cached = _cachedSessions.where((s) => s.id == id).firstOrNull;
    if (cached != null) return cached;
    try {
      final doc = await _firestore?.collection('live_sessions').doc(id).get().timeout(const Duration(seconds: 4));
      if (doc != null && doc.exists) {
        return LiveSessionModel.fromFirestore(doc);
      }
    } catch (_) {}
    return null;
  }

  /// Prof démarre un live (1h interactive + 30min exercices)
  Future<String> startLiveSession({
    required String courseId,
    required String courseName,
    required String title,
    required String teacherId,
    required String teacherName,
    String teacherPhotoUrl = '',
    String sessionType = 'teacher_live',
    String hostRole = 'teacher',
  }) async {
    await _initLocalCache();

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final sessionId = 'live_$nowMs';
    final roomName = 'club_live_${courseId}_$nowMs';

    final session = LiveSessionModel(
      id: sessionId,
      courseId: courseId,
      courseName: courseName,
      title: title,
      teacherId: teacherId,
      teacherName: teacherName,
      teacherPhotoUrl: teacherPhotoUrl,
      status: 'live',
      roomName: roomName,
      sessionType: sessionType,
      hostRole: hostRole,
      phase: sessionType == 'corrector_live' ? 'exercises' : 'interactive',
      participantCount: 1,
      connectedParticipants: [teacherId],
      scheduledAt: DateTime.now(),
      startedAt: DateTime.now(),
    );

    // 1. Update local cache & broadcast immediately
    _cachedSessions = [
      session,
      ..._cachedSessions.where((s) => s.id != sessionId),
    ];
    await _saveLocalCache();
    _sessionsController.add(_cachedSessions);

    // 2. Sync with Laravel API
    unawaited(_api.post('/live-sessions', session.toJson()));

    // 3. Sync with Firestore
    try {
      final db = _firestore;
      if (db != null) {
        await db
            .collection('live_sessions')
            .doc(sessionId)
            .set(session.toMap())
            .timeout(const Duration(seconds: 4));
      }
    } catch (e) {
      debugPrint('Firestore startLiveSession fallback: $e');
    }

    // 4. Notifications temps réel aux étudiants et au correcteur
    // A) Tous les étudiants du cours
    unawaited(
      AppNotificationService().notifyCourseStudents(
        courseId: courseId,
        title: '🔴 Le live a commencé !',
        message: 'Le professeur $teacherName est en direct pour "$title". Rejoignez la session maintenant !',
        type: 'live_started',
        actionRoute: '/live',
        data: {
          'sessionId': sessionId,
          'roomName': roomName,
          'courseId': courseId,
          'title': title,
          'teacherName': teacherName,
        },
      ),
    );

    // B) Au Correcteur associé
    unawaited(
      AppNotificationService().notifyLinkedCorrector(
        teacherId: teacherId,
        title: '🔴 Session Live en cours',
        message: 'Le professeur $teacherName a lancé le direct "$title" pour "$courseName".',
        type: 'live_started',
        actionRoute: '/live',
        data: {
          'sessionId': sessionId,
          'roomName': roomName,
          'courseId': courseId,
        },
      ),
    );

    // C) Log d'audit
    unawaited(
      SystemLogService().logEvent(
        action: 'Session Live démarrée',
        details: 'Le formateur $teacherName a ouvert la salle de direct "$title" ($courseName).',
        category: 'live',
        level: 'success',
        actorName: teacherName,
        actorRole: hostRole == 'corrector' ? 'Correcteur' : 'Formateur',
        metadata: {
          'sessionId': sessionId,
          'courseId': courseId,
          'roomName': roomName,
        },
      ),
    );

    return sessionId;
  }

  /// Programmer une session Live pour une date et heure futures
  Future<String> scheduleLiveSession({
    required String courseId,
    required String courseName,
    required String title,
    required String teacherId,
    required String teacherName,
    required DateTime scheduledAt,
    String teacherPhotoUrl = '',
    String sessionType = 'teacher_live',
    String hostRole = 'teacher',
  }) async {
    await _initLocalCache();

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final sessionId = 'live_$nowMs';
    final roomName = 'club_live_${courseId}_$nowMs';

    final session = LiveSessionModel(
      id: sessionId,
      courseId: courseId,
      courseName: courseName,
      title: title,
      teacherId: teacherId,
      teacherName: teacherName,
      teacherPhotoUrl: teacherPhotoUrl,
      status: 'scheduled',
      roomName: roomName,
      sessionType: sessionType,
      hostRole: hostRole,
      phase: sessionType == 'corrector_live' ? 'exercises' : 'interactive',
      participantCount: 0,
      connectedParticipants: [],
      scheduledAt: scheduledAt,
    );

    // Mettre à jour le cache local et diffuser
    _cachedSessions = [
      session,
      ..._cachedSessions.where((s) => s.id != sessionId),
    ];
    await _saveLocalCache();
    _sessionsController.add(_cachedSessions);

    // Sync avec Laravel API
    unawaited(_api.post('/live-sessions', session.toJson()));

    // Sync avec Firestore
    try {
      final db = _firestore;
      if (db != null) {
        await db
            .collection('live_sessions')
            .doc(sessionId)
            .set(session.toMap())
            .timeout(const Duration(seconds: 4));
      }
    } catch (e) {
      debugPrint('Firestore scheduleLiveSession fallback: $e');
    }

    // Notification aux apprenants du cours
    unawaited(
      AppNotificationService().notifyCourseStudents(
        courseId: courseId,
        title: '📅 Nouvelle session Live programmée',
        message: 'Le professeur $teacherName a programmé le live "$title" pour le ${scheduledAt.day.toString().padLeft(2, '0')}/${scheduledAt.month.toString().padLeft(2, '0')} à ${scheduledAt.hour.toString().padLeft(2, '0')}h${scheduledAt.minute.toString().padLeft(2, '0')}.',
        type: 'live_scheduled',
        actionRoute: '/live',
        data: {
          'sessionId': sessionId,
          'roomName': roomName,
          'courseId': courseId,
          'title': title,
          'teacherName': teacherName,
          'scheduledAt': scheduledAt.toIso8601String(),
        },
      ),
    );

    return sessionId;
  }

  /// Lancer une session précédemment programmée
  Future<void> startScheduledSession(LiveSessionModel session) async {
    await _initLocalCache();

    final started = session.copyWith(
      status: 'live',
    );

    _cachedSessions = [
      started,
      ..._cachedSessions.where((s) => s.id != session.id),
    ];
    await _saveLocalCache();
    _sessionsController.add(_cachedSessions);

    unawaited(_api.post('/live-sessions/${session.id}/start', {}));

    try {
      final db = _firestore;
      if (db != null) {
        await db.collection('live_sessions').doc(session.id).update({
          'status': 'live',
          'startedAt': FieldValue.serverTimestamp(),
        }).timeout(const Duration(seconds: 4));
      }
    } catch (_) {}

    unawaited(
      AppNotificationService().notifyCourseStudents(
        courseId: session.courseId,
        title: '🔴 Le live a commencé !',
        message: 'Le professeur ${session.teacherName} est en direct pour "${session.title}". Rejoignez la session maintenant !',
        type: 'live_started',
        actionRoute: '/live',
        data: {
          'sessionId': session.id,
          'roomName': session.roomName,
          'courseId': session.courseId,
          'title': session.title,
          'teacherName': session.teacherName,
        },
      ),
    );
  }

  /// Annuler ou supprimer une session programmée
  Future<void> cancelLiveSession(String sessionId) async {
    await _initLocalCache();

    _cachedSessions = _cachedSessions.where((s) => s.id != sessionId).toList();
    await _saveLocalCache();
    _sessionsController.add(_cachedSessions);

    unawaited(_api.delete('/live-sessions/$sessionId'));

    try {
      final db = _firestore;
      if (db != null) {
        await db.collection('live_sessions').doc(sessionId).delete().timeout(const Duration(seconds: 4));
      }
    } catch (_) {}
  }

  /// Passer à la phase exercices (prof uniquement)
  Future<void> switchToExercisesPhase(String sessionId) async {
    await _initLocalCache();

    _cachedSessions = _cachedSessions.map((s) {
      if (s.id == sessionId) {
        return s.copyWith(phase: 'exercises');
      }
      return s;
    }).toList();
    await _saveLocalCache();
    _sessionsController.add(_cachedSessions);

    unawaited(_api.patch('/live-sessions/$sessionId/phase', {'phase': 'exercises'}));

    try {
      await _firestore?.collection('live_sessions').doc(sessionId).update({
        'phase': 'exercises',
        'phaseSwitchedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<void> joinLiveSession(String sessionId, String userId) async {
    await _initLocalCache();

    _cachedSessions = _cachedSessions.map((s) {
      if (s.id == sessionId) {
        final list = <String>{...s.connectedParticipants, userId}.toList();
        return s.copyWith(
          connectedParticipants: list,
          participantCount: list.length,
        );
      }
      return s;
    }).toList();
    await _saveLocalCache();
    _sessionsController.add(_cachedSessions);

    unawaited(_api.post('/live-sessions/$sessionId/join', {'userId': userId}));

    try {
      final db = _firestore;
      if (db != null) {
        await db.collection('live_sessions').doc(sessionId).update({
          'connectedParticipants': FieldValue.arrayUnion([userId]),
          'participantCount': FieldValue.increment(1),
        });
      }
    } catch (_) {}
  }

  Future<void> leaveLiveSession(String sessionId, String userId) async {
    await _initLocalCache();

    _cachedSessions = _cachedSessions.map((s) {
      if (s.id == sessionId) {
        final list = s.connectedParticipants.where((id) => id != userId).toList();
        return s.copyWith(
          connectedParticipants: list,
          participantCount: list.isEmpty ? 1 : list.length,
        );
      }
      return s;
    }).toList();
    await _saveLocalCache();
    _sessionsController.add(_cachedSessions);

    unawaited(_api.post('/live-sessions/$sessionId/leave', {'userId': userId}));

    try {
      final db = _firestore;
      if (db != null) {
        await db.collection('live_sessions').doc(sessionId).update({
          'connectedParticipants': FieldValue.arrayRemove([userId]),
          'participantCount': FieldValue.increment(-1),
        });
      }
    } catch (_) {}
  }

  Future<void> endLiveSession({
    required String sessionId,
    required String courseId,
    required String title,
    String replayUrl =
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    String replayDuration = '1:30:00',
  }) async {
    await _initLocalCache();

    _cachedSessions = _cachedSessions.map((s) {
      if (s.id == sessionId) {
        return s.copyWith(
          status: 'ended',
          hasReplay: true,
          replayUrl: replayUrl,
          replayDuration: replayDuration,
          endedAt: DateTime.now(),
        );
      }
      return s;
    }).toList();
    await _saveLocalCache();
    _sessionsController.add(_cachedSessions);

    unawaited(_api.post('/live-sessions/$sessionId/end', {
      'replayUrl': replayUrl,
      'replayDuration': replayDuration,
    }));

    try {
      final db = _firestore;
      if (db != null) {
        await db.collection('live_sessions').doc(sessionId).update({
          'status': 'ended',
          'hasReplay': true,
          'replayUrl': replayUrl,
          'replayDuration': replayDuration,
          'endedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {}

    await _courseService.addLiveReplayToCourse(
      courseId: courseId,
      replay: CourseLiveReplay(
        id: sessionId,
        title: 'Replay : $title',
        replayUrl: replayUrl,
        duration: replayDuration,
        date: DateTime.now(),
      ),
    );
  }
}
