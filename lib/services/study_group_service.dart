import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/study_group_model.dart';
import 'laravel_api_service.dart';

class StudyGroupService {
  static final StudyGroupService _instance = StudyGroupService._internal();
  factory StudyGroupService() => _instance;
  StudyGroupService._internal();

  static const String _cacheKey = 'local_study_groups_v1';
  final LaravelApiService _api = LaravelApiService();
  final StreamController<List<StudyGroupModel>> _groupsController =
      StreamController<List<StudyGroupModel>>.broadcast();

  List<StudyGroupModel> _cachedGroups = [];
  bool _initialized = false;

  FirebaseFirestore? get _firestore {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
    } catch (e) {
      debugPrint('Firestore not ready in StudyGroupService: $e');
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
        _cachedGroups = (jsonDecode(raw) as List)
            .map((e) {
              final m = Map<String, dynamic>.from(e as Map);
              return StudyGroupModel.fromMap(m, m['id']?.toString() ?? '');
            })
            .where((g) =>
                g.id != 'group_react_senegal' &&
                g.id != 'group_marketing_pro' &&
                !g.id.contains('demo'))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading StudyGroupService cache: $e');
    }

    _groupsController.add(_cachedGroups);
    unawaited(_syncRemote());
  }

  Future<void> _saveCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _cacheKey,
        jsonEncode(_cachedGroups.map((g) => g.toMap()).toList()),
      );
    } catch (e) {
      debugPrint('Error saving StudyGroupService cache: $e');
    }
  }

  Future<void> _syncRemote() async {
    // 1. Sync from Firestore
    try {
      final db = _firestore;
      if (db != null) {
        final snap = await db
            .collection('studyGroups')
            .limit(50)
            .get()
            .timeout(const Duration(seconds: 4));
        if (snap.docs.isNotEmpty) {
          final list = snap.docs
              .map((d) => StudyGroupModel.fromMap(d.data(), d.id))
              .where((g) => !g.id.contains('demo'))
              .toList();
          if (list.isNotEmpty) {
            _cachedGroups = list;
            await _saveCache();
            _groupsController.add(_cachedGroups);
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Firestore studyGroups sync fallback: $e');
    }

    // 2. Sync from Laravel API
    try {
      final res = await _api.get('/study-groups');
      if (res != null && res['data'] is List) {
        final list = (res['data'] as List).map((item) {
          final m = Map<String, dynamic>.from(item as Map);
          return StudyGroupModel.fromMap(m, m['id']?.toString() ?? '');
        }).where((g) => !g.id.contains('demo')).toList();
        if (list.isNotEmpty) {
          final existingIds = _cachedGroups.map((g) => g.id).toSet();
          for (final g in list) {
            if (!existingIds.contains(g.id)) {
              _cachedGroups.add(g);
            }
          }
          await _saveCache();
          _groupsController.add(_cachedGroups);
        }
      }
    } catch (_) {}
  }

  /// Real-time stream of all study groups
  Stream<List<StudyGroupModel>> getStudyGroupsStream() async* {
    await _initCache();
    yield _cachedGroups;
    yield* _groupsController.stream;
  }

  /// Create a new study group
  Future<String> createGroup({
    required String name,
    required String description,
    required String courseId,
    required String courseTitle,
    required String creatorId,
    required String creatorName,
    String creatorPhoto = '',
    int maxMembers = 5,
    String joinMode = 'request',
  }) async {
    await _initCache();
    final id = 'group_${DateTime.now().millisecondsSinceEpoch}';
    final group = StudyGroupModel(
      id: id,
      name: name,
      description: description,
      courseId: courseId,
      courseTitle: courseTitle,
      creatorId: creatorId,
      creatorName: creatorName,
      creatorPhoto: creatorPhoto,
      members: [creatorId],
      memberNames: {creatorId: creatorName},
      memberPhotos: {creatorId: creatorPhoto},
      maxMembers: maxMembers,
      joinMode: joinMode,
      status: 'open',
      createdAt: DateTime.now(),
    );

    _cachedGroups = [group, ..._cachedGroups];
    await _saveCache();
    _groupsController.add(_cachedGroups);

    unawaited(_api.post('/study-groups', {
      'name': name,
      'description': description,
      'course_id': courseId,
      'category': courseTitle,
      'creator_id': creatorId,
      'creator_name': creatorName,
    }));

    try {
      final db = _firestore;
      if (db != null) {
        await db
            .collection('studyGroups')
            .doc(id)
            .set(group.toMap())
            .timeout(const Duration(seconds: 3));
      }
    } catch (_) {}

    return id;
  }

  /// Send join request or join directly if open
  Future<void> requestToJoinGroup({
    required String groupId,
    required String userId,
    required String userName,
    String userPhoto = '',
    bool isOpen = false,
  }) async {
    await _initCache();

    _cachedGroups = _cachedGroups.map((g) {
      if (g.id != groupId) return g;
      if (isOpen || g.joinMode == 'open') {
        final updatedMembers = {...g.members, userId}.toList();
        final updatedNames = {...g.memberNames, userId: userName};
        final updatedPhotos = {...g.memberPhotos, userId: userPhoto};
        return StudyGroupModel(
          id: g.id,
          name: g.name,
          description: g.description,
          courseId: g.courseId,
          courseTitle: g.courseTitle,
          creatorId: g.creatorId,
          creatorName: g.creatorName,
          creatorPhoto: g.creatorPhoto,
          members: updatedMembers,
          memberNames: updatedNames,
          memberPhotos: updatedPhotos,
          maxMembers: g.maxMembers,
          joinMode: g.joinMode,
          joinRequests: g.joinRequests,
          status: updatedMembers.length >= g.maxMembers ? 'full' : 'open',
          createdAt: g.createdAt,
        );
      } else {
        final req = GroupJoinRequestModel(
          id: userId,
          groupId: groupId,
          userId: userId,
          userName: userName,
          userPhoto: userPhoto,
          status: 'pending',
          requestedAt: DateTime.now(),
        );
        final updatedReqs = [
          ...g.joinRequests.where((r) => r.userId != userId),
          req,
        ];
        return StudyGroupModel(
          id: g.id,
          name: g.name,
          description: g.description,
          courseId: g.courseId,
          courseTitle: g.courseTitle,
          creatorId: g.creatorId,
          creatorName: g.creatorName,
          creatorPhoto: g.creatorPhoto,
          members: g.members,
          memberNames: g.memberNames,
          memberPhotos: g.memberPhotos,
          maxMembers: g.maxMembers,
          joinMode: g.joinMode,
          joinRequests: updatedReqs,
          status: g.status,
          createdAt: g.createdAt,
        );
      }
    }).toList();

    await _saveCache();
    _groupsController.add(_cachedGroups);

    unawaited(_api.post('/study-groups/$groupId/join', {'user_id': userId}));

    try {
      final db = _firestore;
      if (db != null) {
        if (isOpen) {
          await db.collection('studyGroups').doc(groupId).update({
            'members': FieldValue.arrayUnion([userId]),
            'memberNames.$userId': userName,
            'memberPhotos.$userId': userPhoto,
          }).timeout(const Duration(seconds: 3));
        } else {
          await db
              .collection('studyGroups')
              .doc(groupId)
              .collection('requests')
              .doc(userId)
              .set({
            'userId': userId,
            'userName': userName,
            'userPhoto': userPhoto,
            'status': 'pending',
            'requestedAt': FieldValue.serverTimestamp(),
          }).timeout(const Duration(seconds: 3));
        }
      }
    } catch (_) {}
  }

  /// Get pending requests stream for group admin
  Stream<List<GroupJoinRequestModel>> getPendingRequestsStream(String groupId) async* {
    await _initCache();
    List<GroupJoinRequestModel> extract(List<StudyGroupModel> all) {
      final group = all.where((g) => g.id == groupId).firstOrNull;
      if (group == null) return [];
      return group.joinRequests.where((r) => r.status == 'pending').toList();
    }

    yield extract(_cachedGroups);
    yield* _groupsController.stream.map(extract);
  }

  /// Admin accepts join request
  Future<void> acceptJoinRequest({
    required String groupId,
    required String requestId,
    required String userId,
    required String userName,
    String userPhoto = '',
  }) async {
    await _initCache();
    _cachedGroups = _cachedGroups.map((g) {
      if (g.id != groupId) return g;
      final updatedMembers = {...g.members, userId}.toList();
      final updatedNames = {...g.memberNames, userId: userName};
      final updatedPhotos = {...g.memberPhotos, userId: userPhoto};
      final updatedReqs = g.joinRequests.map((r) {
        if (r.id == requestId || r.userId == userId) {
          return GroupJoinRequestModel(
            id: r.id,
            groupId: r.groupId,
            userId: r.userId,
            userName: r.userName,
            userPhoto: r.userPhoto,
            status: 'accepted',
            requestedAt: r.requestedAt,
          );
        }
        return r;
      }).toList();

      return StudyGroupModel(
        id: g.id,
        name: g.name,
        description: g.description,
        courseId: g.courseId,
        courseTitle: g.courseTitle,
        creatorId: g.creatorId,
        creatorName: g.creatorName,
        creatorPhoto: g.creatorPhoto,
        members: updatedMembers,
        memberNames: updatedNames,
        memberPhotos: updatedPhotos,
        maxMembers: g.maxMembers,
        joinMode: g.joinMode,
        joinRequests: updatedReqs,
        status: updatedMembers.length >= g.maxMembers ? 'full' : 'open',
        createdAt: g.createdAt,
      );
    }).toList();

    await _saveCache();
    _groupsController.add(_cachedGroups);
    unawaited(_api.post('/study-groups/$groupId/join', {'user_id': userId}));
  }

  /// Admin rejects join request
  Future<void> rejectJoinRequest({
    required String groupId,
    required String requestId,
  }) async {
    await _initCache();
    _cachedGroups = _cachedGroups.map((g) {
      if (g.id != groupId) return g;
      final updatedReqs = g.joinRequests.where((r) => r.id != requestId).toList();
      return StudyGroupModel(
        id: g.id,
        name: g.name,
        description: g.description,
        courseId: g.courseId,
        courseTitle: g.courseTitle,
        creatorId: g.creatorId,
        creatorName: g.creatorName,
        creatorPhoto: g.creatorPhoto,
        members: g.members,
        memberNames: g.memberNames,
        memberPhotos: g.memberPhotos,
        maxMembers: g.maxMembers,
        joinMode: g.joinMode,
        joinRequests: updatedReqs,
        status: g.status,
        createdAt: g.createdAt,
      );
    }).toList();

    await _saveCache();
    _groupsController.add(_cachedGroups);
  }
}
