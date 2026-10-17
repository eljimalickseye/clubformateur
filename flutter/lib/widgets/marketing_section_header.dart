import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Widget de header de section avec le style marketing de la page d'accueil.
/// Badge pill + titre accrocheur + sous-titre inspirant + action optionnelle.
class MarketingSectionHeader extends StatelessWidget {
  /// Texte du badge pill (ex: 'MES COURS', 'CLASSE VIRTUELLE')
  final String badge;

  /// Titre principal (ex: 'Reprenez votre apprentissage')
  final String title;

  /// Sous-titre descriptif / inspirant
  final String? subtitle;

  /// Label du bouton d'action (optionnel)
  final String? actionLabel;

  /// Callback du bouton d'action
  final VoidCallback? onAction;

  /// Icône du bouton d'action
  final IconData? actionIcon;

  /// Couleur du badge — défaut : vert émeraude
  final Color? badgeColor;

  /// Couleur du texte du badge
  final Color? badgeTextColor;

  /// Padding du widget (défaut : 0)
  final EdgeInsetsGeometry padding;

  const MarketingSectionHeader({
    super.key,
    required this.badge,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
    this.badgeColor,
    this.badgeTextColor,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final bg = badgeColor ?? AppTheme.paleMint;
    final fg = badgeTextColor ?? AppTheme.emeraldGreenDark;

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    badge,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: fg,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Titre
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink,
                    height: 1.2,
                  ),
                ),

                // Sous-titre
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    subtitle!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppTheme.textMuted,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Bouton action optionnel
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: Icon(actionIcon ?? Icons.add_circle_outline_rounded, size: 17),
              label: Text(actionLabel!),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emeraldGreenDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Variante sombre (fond vert sapin) — identique au hero de la landing page.
/// Utilisée pour les bannières de bienvenue dans les dashboards.
class MarketingDarkBanner extends StatelessWidget {
  final String badge;
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final List<Widget>? rightWidgets;

  const MarketingDarkBanner({
    super.key,
    required this.badge,
    required this.title,
    this.subtitle,
    this.actions,
    this.rightWidgets,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF07343B), Color(0xFF05272D), Color(0xFF062C32)],
        ),
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge pill style landing
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D655B),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Color(0xFF6DE0C4),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Titre blanc
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),

                // Sous-titre
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: Color(0xFFC0CCCE),
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ],

                // Actions
                if (actions != null && actions!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(spacing: 12, runSpacing: 10, children: actions!),
                ],
              ],
            ),
          ),

          // Widgets droite (icône, image, etc.)
          if (rightWidgets != null && rightWidgets!.isNotEmpty) ...[
            const SizedBox(width: 20),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: rightWidgets!,
            ),
          ],
        ],
      ),
    );
  }
}
