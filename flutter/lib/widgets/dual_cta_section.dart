import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class DualCtaSection extends StatelessWidget {
  final VoidCallback? onStudentRegisterTap;
  final VoidCallback? onTeacherRegisterTap;

  const DualCtaSection({
    super.key,
    this.onStudentRegisterTap,
    this.onTeacherRegisterTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 960;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppTheme.ctaGradient,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : 20,
        vertical: isDesktop ? 64 : 44,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left Text
                    Expanded(
                      flex: 5,
                      child: _buildLeftText(isDesktop),
                    ),
                    const SizedBox(width: 48),
                    // Right Dual Cards
                    Expanded(
                      flex: 6,
                      child: _buildDualCards(isDesktop),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLeftText(isDesktop),
                    const SizedBox(height: 36),
                    _buildDualCards(isDesktop),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildLeftText(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Text(
            'PRÊT À COMMENCER ?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.mintAccent,
              letterSpacing: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Rejoignez dès maintenant\nClub des Formateurs',
          style: GoogleFonts.plusJakartaSans(
            fontSize: isDesktop ? 38 : 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Apprenez de nouvelles compétences ou partagez votre expertise avec une communauté engagée.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFFD5EEE6),
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildDualCards(bool isDesktop) {
    if (!isDesktop) {
      return Column(
        children: [
          _buildActionCard(
            icon: Icons.school_rounded,
            title: 'Vous êtes apprenant ?',
            description: 'Accédez à des formations de qualité et développez vos compétences.',
            buttonText: 'Créer un compte',
            isPrimaryButton: true,
            onTap: onStudentRegisterTap,
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            icon: Icons.groups_rounded,
            title: 'Vous êtes formateur ?',
            description: 'Partagez votre savoir et inspirez des milliers d\'apprenants.',
            buttonText: 'Devenir formateur',
            isPrimaryButton: false,
            onTap: onTeacherRegisterTap,
          ),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Apprenant Card
        Expanded(
          child: _buildActionCard(
            icon: Icons.school_rounded,
            title: 'Vous êtes apprenant ?',
            description: 'Accédez à des formations de qualité et développez vos compétences.',
            buttonText: 'Créer un compte',
            isPrimaryButton: true,
            onTap: onStudentRegisterTap,
          ),
        ),
        const SizedBox(width: 16),
        // Formateur Card
        Expanded(
          child: _buildActionCard(
            icon: Icons.groups_rounded,
            title: 'Vous êtes formateur ?',
            description: 'Partagez votre savoir et inspirez des milliers d\'apprenants.',
            buttonText: 'Devenir formateur',
            isPrimaryButton: false,
            onTap: onTeacherRegisterTap,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String description,
    required String buttonText,
    required bool isPrimaryButton,
    VoidCallback? onTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.paleMint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.emeraldGreenDark, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppTheme.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: isPrimaryButton
                ? ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emeraldGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            buttonText,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 14),
                      ],
                    ),
                  )
                : OutlinedButton(
                    onPressed: onTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.emeraldGreenDark,
                      side: const BorderSide(color: AppTheme.emeraldGreen, width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            buttonText,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 14),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
