// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:js' as js;
import '../models/app_version_model.dart';
import '../services/app_update_service.dart';

class UpdateDetectorWrapper extends StatefulWidget {
  final Widget child;

  const UpdateDetectorWrapper({super.key, required this.child});

  @override
  State<UpdateDetectorWrapper> createState() => _UpdateDetectorWrapperState();
}

class _UpdateDetectorWrapperState extends State<UpdateDetectorWrapper> {
  AppUpdateService? _updateService;
  bool _updateTriggered = false;

  @override
  void initState() {
    super.initState();
    try {
      _updateService = AppUpdateService();
      _updateService!.addListener(_onUpdateServiceChanged);
    } catch (e) {
      debugPrint('UpdateDetectorWrapper init skipped (iOS Safari): $e');
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (kIsWeb) {
        try {
          if (js.context.hasProperty('removeSplash')) {
            js.context.callMethod('removeSplash');
          }
        } catch (_) {}
      }
    });
  }

  @override
  void dispose() {
    try {
      _updateService?.removeListener(_onUpdateServiceChanged);
    } catch (_) {}
    super.dispose();
  }

  void _onUpdateServiceChanged() {
    if (!mounted) return;
    setState(() {});

    // Si une mise à jour est disponible et non encore signalée, inviter gentiment l'utilisateur sans forcer de rechargement en boucle
    final service = _updateService;
    if (service == null) return;
    if (service.hasUpdateAvailable && !_updateTriggered && !service.dialogAlreadyShown) {
      _showUpdatePrompt();
    }
  }

  void _showUpdatePrompt() {
    if (_updateTriggered) return;
    _updateTriggered = true;
    _updateService?.markDialogShown();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final version = _updateService?.latestVersion;
      final versionText = version != null ? ' (v${version.version})' : '';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Colors.amberAccent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Une mise à jour$versionText est prête ! Actualisez quand vous le souhaitez.',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'Actualiser',
            textColor: Colors.amberAccent,
            onPressed: () => _updateService?.applyUpdate(),
          ),
          duration: const Duration(seconds: 10),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// Badge flottant conservé pour l'admin (debug/supervision uniquement)
class UpdateFloatingBadge extends StatelessWidget {
  final AppVersionModel? versionInfo;
  final VoidCallback onOpen;
  final VoidCallback onDismiss;

  const UpdateFloatingBadge({
    super.key,
    required this.versionInfo,
    required this.onOpen,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
      right: 24,
      child: GestureDetector(
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.system_update_alt, color: Colors.white, size: 16),
              SizedBox(width: 6),
              Text(
                'Mise à jour',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
