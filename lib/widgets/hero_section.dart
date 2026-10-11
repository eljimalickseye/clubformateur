import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class HeroBottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height);
    // Smooth upward arc in the center where the search strip overlaps
    final controlPoint = Offset(size.width * 0.5, size.height - 40);
    final endPoint = Offset(size.width, size.height);
    path.quadraticBezierTo(controlPoint.dx, controlPoint.dy, endPoint.dx, endPoint.dy);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class HeroSection extends StatelessWidget {
  final VoidCallback? onExploreTap;
  final VoidCallback? onBecomeTrainerTap;

  const HeroSection({
    super.key,
    this.onExploreTap,
    this.onBecomeTrainerTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 980;

    return ClipPath(
      clipper: isDesktop ? HeroBottomCurveClipper() : null,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF06281F),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF06281F),
              Color(0xFF09372B),
              Color(0xFF052119),
            ],
          ),
          borderRadius: isDesktop
              ? null
              : const BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
        ),
        padding: EdgeInsets.only(
          left: isDesktop ? 48 : 20,
          right: isDesktop ? 48 : 20,
          top: isDesktop ? 24 : 16,
          bottom: isDesktop ? 80 : 56,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: 46%
                      Expanded(
                        flex: 46,
                        child: _buildLeftContent(isDesktop: true),
                      ),
                      const SizedBox(width: 32),
                      // Right Column: 54%
                      Expanded(
                        flex: 54,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: _buildRightComposition(isDesktop: true),
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLeftContent(isDesktop: false),
                      const SizedBox(height: 32),
                      Center(
                        child: _buildRightComposition(isDesktop: false),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ─── LEFT COLUMN ────────────────────────────────────────────────────────────
  Widget _buildLeftContent({required bool isDesktop}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Badge "PLATEFORME PÉDAGOGIQUE"
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Text(
            'PLATEFORME P\u00c9DAGOGIQUE',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.mintAccent,
              letterSpacing: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // 2. Main Title (3 lines exact from reference)
        RichText(
          text: TextSpan(
            style: GoogleFonts.plusJakartaSans(
              fontSize: isDesktop ? 46 : 32,
              fontWeight: FontWeight.w800,
              height: 1.10,
              letterSpacing: -0.9,
            ),
            children: const [
              TextSpan(text: 'Apprenez.\n', style: TextStyle(color: Colors.white)),
              TextSpan(text: 'Partagez.\n', style: TextStyle(color: Colors.white)),
              TextSpan(
                text: 'Progressez ensemble.',
                style: TextStyle(color: AppTheme.mintAccent),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // 3. Paragraph
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Text(
            'La plateforme qui connecte les apprenants aux formateurs et experts pour d\u00e9velopper les comp\u00e9tences de demain.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: isDesktop ? 15 : 13.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFFD9ECE7),
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 28),

        // 4. Action Buttons (Pill shape)
        Wrap(
          spacing: 14,
          runSpacing: 12,
          children: [
            ElevatedButton(
              onPressed: onExploreTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emeraldGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      'Explorer les formations',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: onBecomeTrainerTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white70, width: 1.2),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                'Devenir formateur',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 38),

        // 5. Features / Réassurance (Discreet horizontal elements)
        Wrap(
          spacing: 24,
          runSpacing: 12,
          children: [
            _buildFeatureBullet(Icons.school_outlined, 'Des formations\nde qualit\u00e9'),
            _buildFeatureBullet(Icons.groups_outlined, 'Des formateurs\nexperts'),
            _buildFeatureBullet(Icons.trending_up_rounded, 'Un accompagnement\nvers la r\u00e9ussite'),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureBullet(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: const Color(0xFFD8EEE7)),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFD8EEE7),
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  // ─── RIGHT ASYMMETRIC COMPOSITION ───────────────────────────────────────────
  Widget _buildRightComposition({required bool isDesktop}) {
    final composition = SizedBox(
      width: 485,
      height: 460,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Script text top-left: "Des compétences pour un meilleur avenir !"
          Positioned(
            left: 10,
            top: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Des\ncomp\u00e9tences\npour un meilleur\navenir !',
                  style: GoogleFonts.caveat(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFACC15),
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 3),
                const Padding(
                  padding: EdgeInsets.only(left: 20),
                  child: Icon(Icons.arrow_downward_rounded, size: 14, color: Color(0xFFFACC15)),
                ),
              ],
            ),
          ),

          // 2. Card A: MAN (Top-Center, tall)
          Positioned(
            left: 110,
            top: 10,
            width: 148,
            height: 295,
            child: _buildCard(
              imagePath: 'assets/images/student-phone.jpeg',
              bgColor: const Color(0xFFBAAFD7),
              borderRadius: 36,
            ),
          ),

          // 3. Floating badge on Man: "10K+ Apprenants" (Floating to the left of card)
          Positioned(
            left: 15,
            top: 165,
            child: _buildPillBadge(
              icon: Icons.groups_rounded,
              iconColor: const Color(0xFF12A57A),
              title: '10K+',
              subtitle: 'Apprenants',
            ),
          ),

          // 4. Yellow decorative strokes below 10K+ badge
          Positioned(
            left: 65,
            top: 235,
            child: Text(
              '//',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFFACC15).withValues(alpha: 0.9),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

          // 5. Card B: WOMAN (Top-Right, medium)
          Positioned(
            left: 275,
            top: 25,
            width: 165,
            height: 230,
            child: _buildCard(
              imagePath: 'assets/images/student-woman-clean.jpeg',
              bgColor: const Color(0xFFF97316),
              borderRadius: 36,
            ),
          ),

          // 6. Floating badge on Woman: "Apprendre sans limites"
          Positioned(
            left: 285,
            top: 212,
            child: _buildPillBadge(
              icon: Icons.auto_stories_rounded,
              iconColor: const Color(0xFF12A57A),
              title: 'Apprendre sans limites',
            ),
          ),

          // 7. Decorative strokes to right of Woman
          Positioned(
            right: 15,
            top: 155,
            child: Text(
              '//',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFFACC15).withValues(alpha: 0.9),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

          // 8. Dark green capsule background pill to right of Woman
          Positioned(
            right: 0,
            top: 210,
            child: Container(
              width: 22,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF0F8C68).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(11),
              ),
            ),
          ),

          // 9. Card C: GIRL with buns (Bottom-Left, horizontal)
          Positioned(
            left: 15,
            top: 275,
            width: 175,
            height: 175,
            child: _buildCard(
              imagePath: 'assets/images/student-girl-clean.jpeg',
              bgColor: const Color(0xFFF0C446),
              borderRadius: 36,
            ),
          ),

          // 10. Floating badge on Girl: "Croire en ses rêves"
          Positioned(
            left: 25,
            top: 395,
            child: _buildPillBadge(
              icon: Icons.circle,
              iconColor: const Color(0xFFF59E0B),
              title: 'Croire en ses r\u00eaves',
            ),
          ),

          // 11. Emerald vertical pill between Girl and Boy
          Positioned(
            left: 205,
            top: 335,
            child: Container(
              width: 52,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF0F8C68),
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          ),

          // 12. Card D: BOY (Bottom-Right)
          Positioned(
            left: 265,
            top: 270,
            width: 150,
            height: 185,
            child: _buildCard(
              imagePath: 'assets/images/student-school-clean.jpeg',
              bgColor: const Color(0xFF0F766E),
              borderRadius: 36,
            ),
          ),

          // 13. Floating badge on Boy: "Se former aujourd'hui"
          Positioned(
            left: 310,
            top: 395,
            child: _buildPillBadge(
              icon: Icons.school_rounded,
              iconColor: const Color(0xFF3B82F6),
              title: 'Se former aujourd\'hui',
            ),
          ),

          // 14. Script text to right of Boy: "Former aujourd'hui, Construire demain !"
          Positioned(
            right: 0,
            top: 310,
            child: Text(
              'Former\naujourd\'hui,\nConstruire\ndemain !',
              style: GoogleFonts.caveat(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFD9ECE7),
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );

    if (isDesktop) return composition;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: composition,
    );
  }

  Widget _buildCard({
    required String imagePath,
    required Color bgColor,
    required double borderRadius,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (_, __, ___) => Container(
            color: bgColor,
            child: const Center(
              child: Icon(Icons.person, color: Colors.white, size: 36),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPillBadge({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: iconColor),
          const SizedBox(width: 6),
          if (subtitle != null) ...[
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppTheme.textMuted,
              ),
            ),
          ] else ...[
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
