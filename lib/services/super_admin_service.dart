import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'course_service.dart';
import 'laravel_api_service.dart';
import 'live_session_service.dart';

class SuperAdminService {
  static final SuperAdminService _instance = SuperAdminService._internal();
  factory SuperAdminService() => _instance;
  SuperAdminService._internal();

  static const String _usersCacheKey = 'local_admin_users_v1';
  static const String _paymentsCacheKey = 'local_admin_payments_v1';

  final LaravelApiService _api = LaravelApiService();
  final StreamController<List<UserModel>> _usersController =
      StreamController<List<UserModel>>.broadcast();
  final StreamController<List<Map<String, dynamic>>> _paymentsController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  List<UserModel> _cachedUsers = [];
  List<Map<String, dynamic>> _cachedPayments = [];
  bool _initialized = false;

  FirebaseFirestore? get _db {
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('Firestore error SuperAdminService: $e');
    }
    return null;
  }

  Future<void> _initCache() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_usersCacheKey);
      if (raw != null && raw.isNotEmpty) {
        _cachedUsers = (jsonDecode(raw) as List)
            .map((e) {
              final m = Map<String, dynamic>.from(e as Map);
              return UserModel.fromMap(m, m['uid']?.toString() ?? m['id']?.toString() ?? '');
            })
            .toList();
      }

      final payRaw = prefs.getString(_paymentsCacheKey);
      if (payRaw != null && payRaw.isNotEmpty) {
        _cachedPayments = (jsonDecode(payRaw) as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading SuperAdminService cache: $e');
    }

    if (_cachedUsers.isEmpty) {
      _cachedUsers = List<UserModel>.from(_defaultUsers);
      await _saveCache();
    }
    if (_cachedPayments.isEmpty) {
      _cachedPayments = List<Map<String, dynamic>>.from(_defaultPayments);
      await _saveCache();
    }

    _usersController.add(_cachedUsers);
    _paymentsController.add(_cachedPayments);
    unawaited(_syncRemote());
  }

  Future<void> _saveCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _usersCacheKey,
        jsonEncode(_cachedUsers.map((u) => u.toMap()).toList()),
      );
      await prefs.setString(
        _paymentsCacheKey,
        jsonEncode(_cachedPayments),
      );
    } catch (_) {}
  }

  Future<void> _syncRemote() async {
    try {
      final res = await _api.get('/admin/users');
      if (res != null && res['data'] is List) {
        final list = (res['data'] as List).map((item) {
          final m = Map<String, dynamic>.from(item as Map);
          final roleRaw = m['role']?.toString() ?? 'student';
          final mappedRole = roleRaw == 'formateur'
              ? 'teacher'
              : roleRaw == 'eleve'
                  ? 'student'
                  : roleRaw == 'correcteur'
                      ? 'corrector'
                      : roleRaw;
          return UserModel.fromMap({
            ...m,
            'displayName': m['name'] ?? m['displayName'] ?? 'Utilisateur',
            'role': mappedRole,
            'phoneNumber': m['phone'] ?? m['phoneNumber'],
          }, m['id']?.toString() ?? m['uid']?.toString() ?? '');
        }).toList();
        if (list.isNotEmpty) {
          final existingIds = _cachedUsers.map((u) => u.uid).toSet();
          for (final u in list) {
            if (!existingIds.contains(u.uid)) {
              _cachedUsers.add(u);
            }
          }
          await _saveCache();
          _usersController.add(_cachedUsers);
        }
      }
    } catch (_) {}
  }

  /// Tous les utilisateurs en stream
  Stream<List<UserModel>> getAllUsersStream() async* {
    await _initCache();
    yield _cachedUsers;
    yield* _usersController.stream;
  }

  /// Utilisateurs filtrés par rôle
  Stream<List<UserModel>> getUsersByRoleStream(String role) async* {
    await _initCache();
    List<UserModel> filter(List<UserModel> all) =>
        all.where((u) => u.role == role).toList();
    yield filter(_cachedUsers);
    yield* _usersController.stream.map(filter);
  }

  /// Assigne un correcteur à un prof (et vice versa)
  Future<void> assignCorrectorToTeacher({
    required String correctorId,
    required String teacherId,
  }) async {
    await _initCache();
    _cachedUsers = _cachedUsers.map((u) {
      if (u.uid == correctorId) {
        return u.copyWith(linkedTeacherId: teacherId);
      }
      if (u.uid == teacherId) {
        return u.copyWith(linkedCorrectorId: correctorId);
      }
      return u;
    }).toList();
    await _saveCache();
    _usersController.add(_cachedUsers);

    try {
      final db = _db;
      if (db != null) {
        final batch = db.batch();
        batch.update(db.collection('users').doc(correctorId), {
          'linkedTeacherId': teacherId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        batch.update(db.collection('users').doc(teacherId), {
          'linkedCorrectorId': correctorId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        await batch.commit().timeout(const Duration(seconds: 3));
      }
    } catch (_) {}
  }

  /// Retire l'assignation
  Future<void> removeCorrectorFromTeacher({
    required String correctorId,
    required String teacherId,
  }) async {
    await _initCache();
    _cachedUsers = _cachedUsers.map((u) {
      if (u.uid == correctorId) {
        return UserModel(
          uid: u.uid,
          email: u.email,
          displayName: u.displayName,
          role: u.role,
          phoneNumber: u.phoneNumber,
          interests: u.interests,
          expertises: u.expertises,
          photoUrl: u.photoUrl,
          onboardingStep: u.onboardingStep,
          isEmailVerified: u.isEmailVerified,
          createdAt: u.createdAt,
          linkedTeacherId: null,
          linkedCorrectorId: u.linkedCorrectorId,
          legalAcceptances: u.legalAcceptances,
        );
      }
      if (u.uid == teacherId) {
        return UserModel(
          uid: u.uid,
          email: u.email,
          displayName: u.displayName,
          role: u.role,
          phoneNumber: u.phoneNumber,
          interests: u.interests,
          expertises: u.expertises,
          photoUrl: u.photoUrl,
          onboardingStep: u.onboardingStep,
          isEmailVerified: u.isEmailVerified,
          createdAt: u.createdAt,
          linkedTeacherId: u.linkedTeacherId,
          linkedCorrectorId: null,
          legalAcceptances: u.legalAcceptances,
        );
      }
      return u;
    }).toList();
    await _saveCache();
    _usersController.add(_cachedUsers);

    try {
      final db = _db;
      if (db != null) {
        final batch = db.batch();
        batch.update(db.collection('users').doc(correctorId), {
          'linkedTeacherId': FieldValue.delete(),
        });
        batch.update(db.collection('users').doc(teacherId), {
          'linkedCorrectorId': FieldValue.delete(),
        });
        await batch.commit().timeout(const Duration(seconds: 3));
      }
    } catch (_) {}
  }

  /// Suspend un compte
  Future<void> suspendUser(String userId) async {
    await _initCache();
    try {
      await _db?.collection('users').doc(userId).update({
        'isSuspended': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  /// Réactive un compte
  Future<void> activateUser(String userId) async {
    await _initCache();
    try {
      await _db?.collection('users').doc(userId).update({
        'isSuspended': false,
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  /// Crée un nouvel utilisateur (ex: ajouter un correcteur ou formateur depuis l'admin)
  Future<UserModel> createUser({
    required String email,
    required String displayName,
    required String role,
    String? phoneNumber,
    String? linkedTeacherId,
    String? linkedCorrectorId,
    String? speciality,
    String? bio,
    String? experienceYears,
  }) async {
    await _initCache();
    final newUid = 'usr_${DateTime.now().millisecondsSinceEpoch}';
    final newUser = UserModel(
      uid: newUid,
      email: email,
      displayName: displayName,
      role: role,
      phoneNumber: phoneNumber,
      linkedTeacherId: linkedTeacherId,
      linkedCorrectorId: linkedCorrectorId,
      speciality: speciality,
      bio: bio,
      experienceYears: experienceYears,
      expertises: (speciality != null && speciality.isNotEmpty) ? [speciality] : const [],
      isEmailVerified: true,
      isApproved: true,
      onboardingStep: 3,
      createdAt: DateTime.now(),
    );

    _cachedUsers.insert(0, newUser);
    await _saveCache();
    _usersController.add(_cachedUsers);

    try {
      final db = _db;
      if (db != null) {
        await db.collection('users').doc(newUid).set({
          ...newUser.toMap(),
          'isApproved': true,
          'isVerified': true,
          'createdAt': FieldValue.serverTimestamp(),
        }).timeout(const Duration(seconds: 4));

        if (linkedTeacherId != null && role == 'corrector') {
          await db.collection('users').doc(linkedTeacherId).update({
            'linkedCorrectorId': newUid,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      debugPrint('SuperAdminService createUser error: $e');
    }

    return newUser;
  }

  /// Valide / Approuve un formateur
  Future<void> validateTeacher(String userId) async {
    await _initCache();
    _cachedUsers = _cachedUsers.map((u) {
      if (u.uid == userId) {
        return u.copyWith(isEmailVerified: true);
      }
      return u;
    }).toList();
    await _saveCache();
    _usersController.add(_cachedUsers);

    try {
      await _db?.collection('users').doc(userId).update({
        'isApproved': true,
        'isVerified': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  /// Change le role d'un utilisateur
  Future<void> updateUserRole(String userId, String newRole) async {
    await _initCache();
    _cachedUsers = _cachedUsers.map((u) {
      if (u.uid == userId) {
        return u.copyWith(role: newRole);
      }
      return u;
    }).toList();
    await _saveCache();
    _usersController.add(_cachedUsers);

    unawaited(_api.patch('/admin/users/$userId/role', {'role': newRole}));

    try {
      await _db?.collection('users').doc(userId).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  /// Supprime un utilisateur
  Future<void> deleteUserData(String userId) async {
    await _initCache();
    _cachedUsers = _cachedUsers.where((u) => u.uid != userId).toList();
    await _saveCache();
    _usersController.add(_cachedUsers);

    unawaited(_api.delete('/admin/users/$userId'));

    try {
      await _db?.collection('users').doc(userId).delete().timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  /// Stats globales
  Future<Map<String, dynamic>> getGlobalStats() async {
    await _initCache();
    final courses = await CourseService().getTeacherCoursesStream('').first;
    final lives = await LiveSessionService().getActiveLiveSessionsStream().first;

    final res = await _api.get('/admin/overview');
    if (res != null && res['data'] is Map) {
      final d = Map<String, dynamic>.from(res['data'] as Map);
      return {
        'totalUsers': d['users_count'] ?? _cachedUsers.length,
        'totalCourses': d['courses_count'] ?? courses.length,
        'totalEnrollments': d['enrollments_count'] ?? 18,
        'totalRevenue': (d['total_revenue'] as num?)?.toDouble() ?? 1450000.0,
        'activeLives': d['active_lives'] ?? lives.where((l) => l.isLive).length,
      };
    }

    double totalRev = 0;
    for (final p in _cachedPayments) {
      totalRev += (p['amount'] as num? ?? 0).toDouble();
    }

    return {
      'totalUsers': _cachedUsers.length,
      'totalCourses': courses.length,
      'totalEnrollments': 18,
      'totalRevenue': totalRev > 0 ? totalRev : 1450000.0,
      'activeLives': lives.where((l) => l.isLive).length,
    };
  }

  /// Toutes les transactions
  Stream<List<Map<String, dynamic>>> getAllPaymentsStream() async* {
    await _initCache();
    yield _cachedPayments;
    yield* _paymentsController.stream;
  }

  /// Publier/dépublier un cours
  Future<void> setCoursePublished(String courseId, bool published) async {
    await CourseService().togglePublishStatus(courseId, !published);
  }

  /// Stream de tous les cours
  Stream<List<Map<String, dynamic>>> getAllCoursesStream() {
    return CourseService().getTeacherCoursesStream('').map(
          (list) => list.map((c) => {'id': c.id, ...c.toMap()}).toList(),
        );
  }

  /// Mettre à jour un document légal
  Future<void> updateLegalDocument(
      String docId, String content, String version) async {
    unawaited(_api.post('/legal-documents/$docId/accept', {}));
    try {
      await _db?.collection('legal_documents').doc(docId).set({
        'content': content,
        'version': version,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  static final List<UserModel> _defaultUsers = [
    UserModel.demoTeacher,
    UserModel.demoStudent,
    UserModel.demoCorrector,
    UserModel(
      uid: 'user_awa_ndiaye',
      email: 'awa.ndiaye@club-des-formateurs.sn',
      displayName: 'Awa Ndiaye',
      role: 'teacher',
      phoneNumber: '+221 77 321 10 20',
      expertises: const ['Marketing Digital', 'E-Commerce', 'Copywriting'],
      photoUrl: 'assets/images/student-woman.jpeg',
    ),
    UserModel(
      uid: 'user_fatou_sow',
      email: 'fatou.sow@gmail.com',
      displayName: 'Fatou Sow',
      role: 'student',
      phoneNumber: '+221 76 555 44 33',
      interests: const ['Design UI/UX', 'Marketing'],
      photoUrl: 'assets/images/student-woman.jpeg',
    ),
    UserModel(
      uid: 'user_super_admin',
      email: 'admin@club-des-formateurs.sn',
      displayName: 'Super Administrateur',
      role: 'super_admin',
      phoneNumber: '+221 77 000 00 00',
    ),
  ];

  static final List<Map<String, dynamic>> _defaultPayments = [
    {
      'id': 'tx_wave_001',
      'userId': 'demo_student_moussa',
      'studentName': 'Moussa Ndiaye',
      'courseId': 'react',
      'courseTitle': 'Développement Web Moderne avec React',
      'amount': 40000,
      'paymentMethod': 'Wave',
      'status': 'completed',
      'paidAt': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
    },
    {
      'id': 'tx_om_002',
      'userId': 'user_fatou_sow',
      'studentName': 'Fatou Sow',
      'courseId': 'marketing',
      'courseTitle': 'Stratégie Marketing Digital de A à Z',
      'amount': 30000,
      'paymentMethod': 'Orange Money',
      'status': 'completed',
      'paidAt': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
    },
  ];
}
