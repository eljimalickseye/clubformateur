import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseConfig {
  static const FirebaseOptions options = FirebaseOptions(
    apiKey: 'AIzaSyDslsyYXqMbUsKIuDZTTYcpwDWsm_mJw_w',
    appId: '1:501861569061:web:587c13ee3d9f633c98a5cc',
    messagingSenderId: '501861569061',
    projectId: 'anour-84a69',
    authDomain: 'anour-84a69.firebaseapp.com',
    storageBucket: 'anour-84a69.firebasestorage.app',
    databaseURL: 'https://anour-84a69-default-rtdb.firebaseio.com',
  );

  /// `Firebase.apps` can throw a dart2js TypeError on iOS Safari/WebKit
  /// (JS FirebaseApp is not accepted as the Dart FirebaseApp type).
  static bool get hasApp {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (e) {
      debugPrint('Firebase.apps type check failed (iOS Safari): $e');
      return false;
    }
  }

  static FirebaseFirestore? get firestore {
    try {
      if (!hasApp) return null;
      return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('Firestore instance unavailable (iOS Safari): $e');
      return null;
    }
  }

  static Future<void> initialize() async {
    try {
      var needsInit = true;
      try {
        needsInit = Firebase.apps.isEmpty;
      } catch (_) {
        needsInit = true;
      }
      if (needsInit) {
        await Firebase.initializeApp(options: options);
      }
      if (kIsWeb) {
        // iOS Safari (WebKit / PWA): disable IndexedDB persistence to avoid ITP blocks.
        try {
          firestore?.settings = const Settings(
            persistenceEnabled: false,
          );
        } catch (settingsError) {
          debugPrint('Firestore settings config notice: $settingsError');
        }
      }
    } catch (e) {
      debugPrint('Firebase init error (graceful fallback): $e');
    }
  }
}
