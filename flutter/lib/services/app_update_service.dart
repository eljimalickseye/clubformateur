// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_version_model.dart';
import '../utils/fullscreen_web_helper.dart';
import 'firebase_config.dart';

class AppUpdateService extends ChangeNotifier {
  static final AppUpdateService _instance = AppUpdateService._internal();
  factory AppUpdateService() => _instance;
  AppUpdateService._internal();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // --- Current App Version Constants ---
  // IMPORTANT: doit correspondre au buildNumber dans Firestore platform_settings/app_version
  // Incrémenter ICI + dans Firestore lors d'un vrai déploiement pour déclencher la MAJ
  static const String currentAppVersion = '1.0.24';
  static const int currentBuildNumber = 124;

  FirebaseFirestore? get _firestore => FirebaseConfig.firestore;

  AppVersionModel? _latestVersion;
  AppVersionModel? get latestVersion => _latestVersion;

  bool _hasUpdateAvailable = false;
  bool get hasUpdateAvailable => _hasUpdateAvailable;

  bool _isChecking = false;
  bool get isChecking => _isChecking;

  bool _isUpdating = false;
  bool get isUpdating => _isUpdating;

  bool _isSnoozed = false;
  bool get isSnoozed => _isSnoozed;

  bool _dialogAlreadyShown = false;
  bool get dialogAlreadyShown => _dialogAlreadyShown;

  DateTime? _snoozedUntil;
  Timer? _periodicTimer;
  StreamSubscription? _firestoreSub;

  /// Initializes update detection: checks immediately and starts realtime listeners
  void initialize() {
    _loadSnoozeState();
    _listenToRealtimeUpdates();

    // Check after a brief delay so main UI loads first
    Timer(const Duration(seconds: 3), () {
      checkForUpdates();
    });

    // Check periodically every 15 minutes
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      checkForUpdates();
    });
  }

  Future<void> _loadSnoozeState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final snoozedMillis = prefs.getInt('app_update_snoozed_until');
      if (snoozedMillis != null) {
        final until = DateTime.fromMillisecondsSinceEpoch(snoozedMillis);
        if (DateTime.now().isBefore(until)) {
          _isSnoozed = true;
          _snoozedUntil = until;
          notifyListeners();
        } else {
          await prefs.remove('app_update_snoozed_until');
          _isSnoozed = false;
        }
      }
    } catch (e) {
      debugPrint('Error reading snooze state: $e');
    }
  }

  /// Listen for immediate updates pushed to Firestore in real-time
  void _listenToRealtimeUpdates() {
    _firestoreSub?.cancel();
    final firestore = _firestore;
    if (firestore == null) return;
    try {
      _firestoreSub = firestore
          .collection('platform_settings')
          .doc('app_version')
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data();
          if (data != null) {
            final remoteVer = AppVersionModel.fromJson(data);
            _evaluateVersion(remoteVer);
          }
        }
      }, onError: (err) {
        debugPrint('Firestore version stream error: $err');
      });
    } catch (e) {
      debugPrint('Could not bind version stream: $e');
    }
  }

  /// Check for updates from Firestore or static version.json
  Future<bool> checkForUpdates({bool userInitiated = false}) async {
    if (_isChecking) return _hasUpdateAvailable;
    _isChecking = true;
    notifyListeners();

    AppVersionModel? fetchedVersion;

    // 1. Try Firestore first
    try {
      final firestore = _firestore;
      if (firestore == null) throw StateError('Firestore unavailable');
      final doc = await firestore.collection('platform_settings').doc('app_version').get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          fetchedVersion = AppVersionModel.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint('Firestore version check failed: $e');
    }

    // 2. Fallback to static version.json
    if (fetchedVersion == null && kIsWeb) {
      try {
        final cacheBuster = DateTime.now().millisecondsSinceEpoch;
        final response = await http.get(Uri.parse('version.json?t=$cacheBuster'));
        if (response.statusCode == 200) {
          final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
          fetchedVersion = AppVersionModel.fromJson(jsonMap);
        }
      } catch (e) {
        debugPrint('Static version.json check failed: $e');
      }
    }

    _isChecking = false;

    if (fetchedVersion != null) {
      if (userInitiated) {
        _isSnoozed = false;
        _dialogAlreadyShown = false;
      }
      _evaluateVersion(fetchedVersion);
      return _hasUpdateAvailable;
    }

    notifyListeners();
    return false;
  }

  void _evaluateVersion(AppVersionModel remoteVer) {
    _latestVersion = remoteVer;
    final isNewer = remoteVer.isNewerThan(currentBuildNumber, currentAppVersion);

    if (isNewer) {
      _hasUpdateAvailable = true;
      // If snoozed period expired, reset snooze
      if (_snoozedUntil != null && DateTime.now().isAfter(_snoozedUntil!)) {
        _isSnoozed = false;
        _snoozedUntil = null;
      }
    } else {
      _hasUpdateAvailable = false;
    }
    notifyListeners();
  }

  /// Snoozes the popup for a given duration (default: 2 hours)
  Future<void> snoozeUpdate({Duration duration = const Duration(hours: 2)}) async {
    _isSnoozed = true;
    _dialogAlreadyShown = true;
    final until = DateTime.now().add(duration);
    _snoozedUntil = until;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('app_update_snoozed_until', until.millisecondsSinceEpoch);
    } catch (_) {}
    notifyListeners();
  }

  /// Marks dialog as shown for the current session
  void markDialogShown() {
    _dialogAlreadyShown = true;
    notifyListeners();
  }

  /// Reset snooze and show popup immediately
  void showUpdateModal() {
    _isSnoozed = false;
    _dialogAlreadyShown = false;
    notifyListeners();
  }

  /// Clears caches and performs a hard reload
  Future<void> applyUpdate() async {
    _isUpdating = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('app_update_snoozed_until');
    } catch (_) {}

    if (kIsWeb) {
      FullscreenWebHelper.toggleFullscreen(false);
      await Future.delayed(const Duration(milliseconds: 600));

      try {
        if (js.context.hasProperty('forceAppUpdate')) {
          js.context.callMethod('forceAppUpdate');
          return;
        }
      } catch (_) {}

      try {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        html.window.location.href = '${html.window.location.origin}${html.window.location.pathname}?v=$timestamp';
      } catch (e) {
        html.window.location.reload();
      }
    }
  }

  /// Super Admin publishing action: broadcasts a new version to all users instantly
  Future<void> publishNewVersion({
    required String version,
    required int buildNumber,
    required String title,
    required String releaseNotes,
    required List<String> highlights,
    bool isMandatory = false,
  }) async {
    final newVersion = AppVersionModel(
      version: version,
      buildNumber: buildNumber,
      title: title,
      releaseNotes: releaseNotes,
      highlights: highlights,
      releasedAt: DateTime.now(),
      isMandatory: isMandatory,
    );

    final firestore = _firestore;
    if (firestore == null) {
      debugPrint('Cannot publish version: Firestore unavailable');
      return;
    }
    await firestore
        .collection('platform_settings')
        .doc('app_version')
        .set(newVersion.toJson(), SetOptions(merge: true));

    _latestVersion = newVersion;
    _hasUpdateAvailable = newVersion.isNewerThan(currentBuildNumber, currentAppVersion);
    _isSnoozed = false;
    _dialogAlreadyShown = false;
    notifyListeners();
  }

  /// Testing helper: simulate update available immediately
  void simulateUpdateAvailable() {
    _latestVersion = AppVersionModel(
      version: '1.0.1',
      buildNumber: 101,
      title: 'Mise à jour disponible ! 🎉',
      releaseNotes: 'Nouvelle version avec lecteur vidéo Plein Écran, optimisations de performances et corrections.',
      highlights: [
        'Nouveau lecteur vidéo immersif avec mode Plein Écran (Full Screen)',
        'Barre de contrôles enrichie : timeline, vitesse, volume, sauts de 10s',
        'Tiroir latéral des leçons accessible directement en plein écran',
        'Détecteur de mise à jour intelligent en temps réel',
      ],
      releasedAt: DateTime.now(),
      isMandatory: false,
    );
    _hasUpdateAvailable = true;
    _isSnoozed = false;
    _dialogAlreadyShown = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
    _firestoreSub?.cancel();
    super.dispose();
  }
}
