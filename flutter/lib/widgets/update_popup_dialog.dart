import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_version_model.dart';
import '../services/app_update_service.dart';
import '../theme/app_theme.dart';

class UpdatePopupDialog extends StatefulWidget {
  final AppVersionModel versionInfo;
  final VoidCallback onUpdate;
  final VoidCallback onSnooze;

  const UpdatePopupDialog({
    super.key,
    required this.versionInfo,
    required this.onUpdate,
    required this.onSnooze,
  });

  static Future<void> show(BuildContext context, {required AppVersionModel versionInfo}) {
    return showDialog(
      context: context,
      barrierDismissible: !versionInfo.isMandatory,
      builder: (ctx) => UpdatePopupDialog(
        versionInfo: versionInfo,
        onUpdate: () {
          Navigator.of(ctx, rootNavigator: true).pop();
          AppUpdateService().applyUpdate();
        },
        onSnooze: () {
          Navigator.of(ctx, rootNavigator: true).pop();
          AppUpdateService().snoozeUpdate();
        },
      ),
    );
  }

  @override
  State<UpdatePopupDialog> createState() => _UpdatePopupDialogState();
}

class _UpdatePopupDialogState extends State<UpdatePopupDialog> {
  bool _isProcessing = false;

  void _handleUpdateClick() {
    setState(() => _isProcessing = true);
    widget.onUpdate();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.versionInfo;
    final highlights = v.highlights.isNotEmpty
        ? v.highlights
        : [
            'Nouveau lecteur vidéo immersif avec mode Plein Écran (Full Screen)',
            'Barre de contrôles vidéo complète : timeline, vitesse, volume, sauts de 10s',
            'Tiroir latéral des leçons accessible directement en plein écran',
            'Performances optimisées et corrections de stabilité',
          ];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 35,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Header Banner with Emerald Gradient ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0A2B24), Color(0xFF0F3D34)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    // Animated Rocket Badge
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: AppTheme.emeraldGreenDark.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.emeraldGreen.withValues(alpha: 0.6), width: 2),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.rocket_launch_rounded,
                          color: AppTheme.emeraldGreen,
                          size: 36,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      v.title.isNotEmpty ? v.title : 'Mise à jour disponible ! 🎉',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Une nouvelle version de la plateforme est prête pour vous.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),

                    // Version Compare Badges
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Actuelle : v${AppUpdateService.currentAppVersion}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(Icons.arrow_forward_rounded, color: AppTheme.emeraldGreen, size: 14),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.emeraldGreen,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Nouvelle : v${v.version}',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // --- Body Content ---
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (v.releaseNotes.isNotEmpty) ...[
                      Text(
                        v.releaseNotes,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    Text(
                      'Nouveautés de cette version :',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Highlights List
                    ...highlights.map((h) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: AppTheme.emeraldGreen.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: AppTheme.emeraldGreenDark,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  h,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    color: AppTheme.ink,
                                    height: 1.35,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),

                    const SizedBox(height: 22),

                    // --- Action Buttons ---
                    Row(
                      children: [
                        if (!v.isMandatory) ...[
                          Expanded(
                            flex: 1,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _isProcessing ? null : widget.onSnooze,
                              child: Text(
                                'Plus tard',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.emeraldGreenDark,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _isProcessing ? null : _handleUpdateClick,
                            icon: _isProcessing
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.refresh_rounded, size: 20),
                            label: Text(
                              _isProcessing ? 'Rechargement...' : 'Mettre à jour maintenant',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Floating Pill Badge that stays accessible if the user snoozed the update
class UpdateFloatingBadge extends StatelessWidget {
  final AppVersionModel versionInfo;
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
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppTheme.emeraldGreen.withValues(alpha: 0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.emeraldGreenDark.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.rocket_launch_rounded, color: AppTheme.emeraldGreen, size: 16),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Mise à jour prête !',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    'Version ${versionInfo.version}',
                    style: const TextStyle(color: AppTheme.emeraldGreen, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emeraldGreenDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: onOpen,
                child: const Text('Recharger', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: onDismiss,
                borderRadius: BorderRadius.circular(16),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded, color: Colors.white54, size: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
