import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'firebase_config.dart';
import 'firebase_storage_service.dart';
import 'laravel_api_service.dart';

/// Service d'authentification de production pour Club des Formateurs
/// 
/// Fonctionnement à 3 niveaux :
/// 1. Backend Laravel 13 (API MySQL sur VPS : http://180.149.199.233:8095/api/v1/auth)
/// 2. Firebase Auth & Firestore (Synchronisation cloud temps réel)
/// 3. SharedPreferences (Persistance locale de session hors-ligne et persistance au rafraîchissement)
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    _loadPersistedSession();
    _initAuthListener();
  }

  final ValueNotifier<UserModel?> currentUserNotifier = ValueNotifier<UserModel?>(null);
  UserModel? get currentUser => currentUserNotifier.value;

  FirebaseAuth? get _auth {
    try {
      if (FirebaseConfig.hasApp) {
        return FirebaseAuth.instance;
      }
    } catch (_) {}
    return null;
  }

  FirebaseFirestore? get _firestore => FirebaseConfig.firestore;

  /// Restaure la session utilisateur enregistrée dans le stockage local (SharedPreferences)
  /// pour que l'utilisateur reste connecté même après un rechargement de page (F5).
  Future<void> _loadPersistedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userJson = prefs.getString('user_profile');

      if (token != null && token.isNotEmpty) {
        LaravelApiService().setAuthToken(token);
      }

      if (userJson != null && userJson.isNotEmpty) {
        final map = jsonDecode(userJson) as Map<String, dynamic>;
        final uid = map['uid'] as String? ?? 'user_local';
        currentUserNotifier.value = UserModel.fromMap(map, uid);

        // Rafraîchir les informations de profil en tâche de fond depuis l'API Laravel
        if (token != null && token.isNotEmpty) {
          try {
            final res = await LaravelApiService().get('/auth/me');
            if (res != null && res['user'] != null) {
              final freshMap = res['user'] as Map<String, dynamic>;
              final freshUser = UserModel.fromMap(freshMap, freshMap['uid'] ?? uid);
              currentUserNotifier.value = freshUser;
              await prefs.setString('user_profile', jsonEncode(freshUser.toMap()));
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('Erreur de restauration de session locale: $e');
    }
  }

  void _initAuthListener() {
    try {
      _auth?.authStateChanges().listen((User? firebaseUser) async {
        if (firebaseUser != null) {
          await _loadUserProfile(firebaseUser.uid, firebaseUser.email, firebaseUser.displayName);
        }
      });
    } catch (e) {
      debugPrint('Auth listener init error: $e');
    }
  }

  Future<void> _loadUserProfile(String uid, String? email, String? displayName) async {
    try {
      final doc = await _firestore?.collection('users').doc(uid).get();
      final data = doc?.data();
      if (doc != null && doc.exists && data != null) {
        final user = UserModel.fromMap(data, uid);
        currentUserNotifier.value = user;
        await _persistLocally(user, null);
      } else {
        final user = UserModel(
          uid: uid,
          email: email ?? '',
          displayName: displayName ?? 'Utilisateur',
          role: 'student',
          onboardingStep: 3,
          isEmailVerified: true,
        );
        currentUserNotifier.value = user;
        await _persistLocally(user, null);
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  Future<void> _persistLocally(UserModel user, String? token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (token != null && token.isNotEmpty) {
        LaravelApiService().setAuthToken(token);
        await prefs.setString('auth_token', token);
      }
      await prefs.setString('user_profile', jsonEncode(user.toMap()));
    } catch (e) {
      debugPrint('Failed to persist user locally: $e');
    }
  }

  /// Connexion utilisateur (authentification réelle contre la base MySQL via Laravel API)
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();


    // 1. Tenter l'authentification réelle via Laravel API (sur le VPS)
    try {
      final res = await LaravelApiService().post('/auth/login', {
        'email': cleanEmail,
        'password': password,
      });

      if (res != null && res['success'] == true && res['user'] != null) {
        final token = res['token'] as String?;
        final userMap = res['user'] as Map<String, dynamic>;
        final uid = userMap['uid'] as String? ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
        final user = UserModel.fromMap(userMap, uid);

        await _persistLocally(user, token);
        currentUserNotifier.value = user;
        return user;
      } else if (res != null && res['message'] != null) {
        throw Exception(res['message']);
      }
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('Identifiants invalides') || errStr.contains('mot de passe')) {
        throw Exception('Email ou mot de passe incorrect.');
      }
      debugPrint('Laravel API login unreachable, attempting fallback: $e');
    }

    // 2. Tenter Firebase Auth si configuré
    try {
      final auth = _auth;
      if (auth != null) {
        final credential = await auth.signInWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );
        final u = credential.user;
        if (u != null) {
          await _loadUserProfile(
            u.uid,
            u.email,
            u.displayName,
          );
          final current = currentUserNotifier.value;
          if (current != null) {
            return current;
          }
        }
      }
    } catch (e) {
      debugPrint('Firebase signIn error: $e');
      if (e is FirebaseAuthException) {
        if (e.code == 'wrong-password' || e.code == 'user-not-found' || e.code == 'invalid-credential') {
          throw Exception('Email ou mot de passe incorrect.');
        }
      }
    }

    throw Exception('Identifiants incorrects ou serveur indisponible.');
  }

  /// Authentification dynamique via Google (Popup Google Provider + Synchronisation MySQL VPS)
  Future<UserModel> signInWithGoogle({String role = 'student'}) async {
    final auth = _auth;
    if (auth == null) {
      throw Exception('Service d\'authentification Firebase non disponible.');
    }

    final googleProvider = GoogleAuthProvider();
    googleProvider.addScope('email');
    googleProvider.addScope('profile');

    final credential = await auth.signInWithPopup(googleProvider);
    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw Exception('Connexion avec Google annulée.');
    }

    final email = firebaseUser.email?.trim().toLowerCase() ?? '';
    final name = firebaseUser.displayName?.trim() ?? (email.isNotEmpty ? email.split('@').first : 'Utilisateur Google');
    final photo = firebaseUser.photoURL;
    final uid = firebaseUser.uid;

    // 1. Synchronisation dynamique avec le backend Laravel (MySQL sur le VPS)
    try {
      final idToken = await firebaseUser.getIdToken();
      final res = await LaravelApiService().post('/auth/google', {
        'idToken': idToken ?? '',
      });

      if (res != null && res['success'] == true && res['user'] != null) {
        final token = res['token'] as String?;
        final userMap = res['user'] as Map<String, dynamic>;
        final user = UserModel.fromMap(userMap, userMap['uid'] as String? ?? uid);
        await _persistLocally(user, token);
        currentUserNotifier.value = user;
        return user;
      }
    } catch (e) {
      debugPrint('Laravel sync for Google auth unreachable: $e');
    }

    // 2. Synchronisation dynamique avec Firestore
    final db = _firestore;
    UserModel user = UserModel(
      uid: uid,
      email: email,
      displayName: name,
      role: role,
      photoUrl: photo,
      onboardingStep: 3,
      isEmailVerified: true,
      createdAt: DateTime.now(),
    );

    try {
      if (db != null) {
        final doc = await db.collection('users').doc(uid).get();
        final data = doc.data();
        if (doc.exists && data != null) {
          user = UserModel.fromMap(data, uid);
          if (role.isNotEmpty && user.role != role) {
            user = user.copyWith(role: role);
            await db.collection('users').doc(uid).set({'role': role}, SetOptions(merge: true));
          }
        } else {
          await db.collection('users').doc(uid).set(user.toMap());
        }
      }
    } catch (e) {
      debugPrint('Firestore sync for Google auth: $e');
    }

    await _persistLocally(user, 'google_token_$uid');
    currentUserNotifier.value = user;
    return user;
  }

  /// Inscription réelle (enregistre l'utilisateur dans MySQL via Laravel API)
  Future<UserModel> register({
    required String email,
    required String password,
    required String displayName,
    required String role, // 'student' or 'teacher'
    String? phoneNumber,
    Uint8List? avatarBytes,
    String? avatarFileName,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = displayName.trim().isEmpty ? (role == 'teacher' ? 'Formateur' : 'Apprenant') : displayName.trim();

    // 1. Inscription réelle dans la base MySQL du VPS via l'API Laravel
    try {
      final res = await LaravelApiService().post('/auth/register', {
        'displayName': cleanName,
        'email': cleanEmail,
        'password': password,
        'role': role,
        'phoneNumber': phoneNumber ?? '+221 77 000 00 00',
      });

      if (res != null && res['success'] == true && res['user'] != null) {
        final token = res['token'] as String?;
        final userMap = res['user'] as Map<String, dynamic>;
        final uid = userMap['uid'] as String? ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
        final user = UserModel.fromMap(userMap, uid);

        await _persistLocally(user, token);
        currentUserNotifier.value = user;
        return user;
      } else if (res != null && res['message'] != null) {
        throw Exception(res['message']);
      }
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('unique') || errStr.contains('déjà') || errStr.contains('taken')) {
        throw Exception('Cette adresse email est déjà enregistrée. Veuillez vous connecter.');
      }
      debugPrint('Laravel API register error / unreachable: $e');
    }

    // 2. Fallback Firebase Auth si configuré
    try {
      final auth = _auth;
      final db = _firestore;
      if (auth != null) {
        final credential = await auth.createUserWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );
        final u = credential.user;
        if (u != null) {
          final uid = u.uid;
          await u.updateDisplayName(cleanName);

          final user = UserModel(
            uid: uid,
            email: cleanEmail,
            displayName: cleanName,
            role: role,
            phoneNumber: phoneNumber,
            onboardingStep: 1,
            isEmailVerified: true,
            createdAt: DateTime.now(),
          );

          if (db != null) {
            await db.collection('users').doc(uid).set(user.toMap());
          }

          await _persistLocally(user, null);
          currentUserNotifier.value = user;
          return user;
        }
      }
    } catch (e) {
      debugPrint('Firebase register error: $e');
      if (e is FirebaseAuthException) {
        if (e.code == 'email-already-in-use') {
          throw Exception('Cette adresse email est déjà utilisée.');
        } else if (e.code == 'weak-password') {
          throw Exception('Le mot de passe doit comporter au moins 8 caractères.');
        }
      }
      rethrow;
    }

    // 3. Fallback persistant local en cas de coupure réseau
    final localUid = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final fallbackUser = UserModel(
      uid: localUid,
      email: cleanEmail,
      displayName: cleanName,
      role: role,
      phoneNumber: phoneNumber,
      onboardingStep: 1,
      isEmailVerified: true,
      createdAt: DateTime.now(),
    );
    await _persistLocally(fallbackUser, 'local_token_$localUid');
    currentUserNotifier.value = fallbackUser;
    return fallbackUser;
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth?.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      debugPrint('Password reset error: $e');
    }
  }

  Future<void> updateUserProfile({
    String? displayName,
    String? phoneNumber,
    String? role,
    List<String>? interests,
    List<String>? expertises,
    int? onboardingStep,
    bool? isEmailVerified,
    String? photoUrl,
    Uint8List? avatarBytes,
    String? avatarFileName,
    String? experienceYears,
    String? bio,
    String? speciality,
    String? quote,
    List<String>? skills,
    List<Map<String, dynamic>>? weeklySchedule,
  }) async {
    final current = currentUserNotifier.value;
    if (current == null) return;

    String? finalPhotoUrl = photoUrl ?? current.photoUrl;
    if (avatarBytes != null && avatarBytes.isNotEmpty) {
      try {
        final uploaded = await FirebaseStorageService().uploadAvatar(
          uid: current.uid,
          bytes: avatarBytes,
          fileName: avatarFileName ?? 'avatar.jpg',
        );
        if (uploaded != null) {
          finalPhotoUrl = uploaded;
        }
      } catch (e) {
        debugPrint('Error uploading new avatar: $e');
      }
    }

    final updated = current.copyWith(
      displayName: displayName,
      phoneNumber: phoneNumber,
      role: role ?? current.role,
      interests: interests,
      expertises: expertises,
      photoUrl: finalPhotoUrl,
      onboardingStep: onboardingStep,
      isEmailVerified: isEmailVerified,
      experienceYears: experienceYears ?? current.experienceYears,
      bio: bio ?? current.bio,
      speciality: speciality ?? current.speciality,
      quote: quote ?? current.quote,
      skills: skills ?? current.skills,
      weeklySchedule: weeklySchedule ?? current.weeklySchedule,
    );

    currentUserNotifier.value = updated;
    await _persistLocally(updated, null);

    // Sync to Laravel API
    try {
      await LaravelApiService().put('/profile', {
        'displayName': updated.displayName,
        'phoneNumber': updated.phoneNumber,
        'photoUrl': updated.photoUrl,
        'role': updated.role,
      });
    } catch (e) {
      debugPrint('Sync profile to Laravel API failed: $e');
    }

    // Sync to Firestore
    try {
      final db = _firestore;
      if (db != null) {
        await db.collection('users').doc(updated.uid).set(
          updated.toMap(),
          SetOptions(merge: true),
        );
      }
    } catch (e) {
      debugPrint('Error updating user document in Firestore: $e');
    }
  }

  Future<void> setDemoUser(UserModel user) async {
    currentUserNotifier.value = user;
    await _persistLocally(user, 'demo_token_${user.role}');
  }

  void updateCurrentUser(UserModel user) {
    currentUserNotifier.value = user;
    _persistLocally(user, null);
  }

  Future<void> signOut() async {
    try {
      await LaravelApiService().post('/auth/logout', {});
    } catch (_) {}
    try {
      await _auth?.signOut();
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_profile');
      LaravelApiService().setAuthToken(null);
    } catch (_) {}
    currentUserNotifier.value = null;
  }
}
