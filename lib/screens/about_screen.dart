import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/language_service.dart';
import '../theme/app_theme.dart';
import '../widgets/footer_section.dart';
import '../widgets/navbar.dart';
import '../widgets/studio_svg_icon.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;
    final isMobile = width < 600;
    final lang = LanguageService();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Navbar
            const Navbar(activeRoute: '/a-propos'),

            // Hero Banner
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: isMobile ? 48 : 72,
                horizontal: isMobile ? 20 : 48,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF07343B),
                    Color(0xFF05272D),
                    Color(0xFF062C32),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.mintAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: AppTheme.mintAccent.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          lang.t(fr: 'NOTRE VISION & MISSION', en: 'OUR VISION & MISSION'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.mintAccent,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        lang.t(
                          fr: 'Bâtir la nouvelle élite professionnelle et académique',
                          en: 'Building the new professional & academic elite',
                        ),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: isMobile ? 28 : (isDesktop ? 44 : 36),
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.8,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        lang.t(
                          fr: 'Club des Formateurs est la première plateforme d\'apprentissage combinant formations certifiantes de haut niveau, accompagnement par correcteurs dédiés et sessions en direct interactives.',
                          en: 'Club des Formateurs is the premier learning platform combining certified high-level courses, dedicated corrector support, and interactive live sessions.',
                        ),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: isMobile ? 14 : 16,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFFD9ECE7),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Main Content Container
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: isMobile ? 36 : 60,
                horizontal: isMobile ? 16 : 40,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1160),
                  child: Column(
                    children: [
                      // Pillars
                      _buildPillarsGrid(context, isDesktop, isMobile, lang),
                      const SizedBox(height: 56),

                      // Values Card
                      _buildManifestoCard(isDesktop, isMobile, lang),
                      const SizedBox(height: 56),

                      // CTA Banner
                      _buildCtaSection(context, isMobile, lang),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            FooterSection(
              onNavigate: (route) => Navigator.pushNamed(context, route),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillarsGrid(BuildContext context, bool isDesktop, bool isMobile, LanguageService lang) {
    final pillars = [
      {
        'icon': 'graduation',
        'title': lang.t(fr: 'Formateurs Experts Vérifiés', en: 'Verified Expert Trainers'),
        'desc': lang.t(
          fr: 'Chaque formateur est rigoureusement sélectionné pour son expertise terrain et sa pédagogie avérée.',
          en: 'Every instructor is thoroughly vetted for practical field expertise and teaching excellence.',
        ),
      },
      {
        'icon': 'assignment',
        'title': lang.t(fr: 'Correcteurs Attitrés & Feedback Réel', en: 'Dedicated Correctors & Real Feedback'),
        'desc': lang.t(
          fr: 'Vos devoirs et exercices pratiques sont minutieusement corrigés et commentés pour garantir votre montée en compétences.',
          en: 'Assignments and practical projects are carefully graded with actionable feedback to ensure your success.',
        ),
      },
      {
        'icon': 'live',
        'title': lang.t(fr: 'Classes Virtuelles & Directs', en: 'Virtual Classrooms & Live Sessions'),
        'desc': lang.t(
          fr: 'Participez à des sessions en direct immersives propulsées par LiveKit Cloud avec échange vidéo et questions-réponses.',
          en: 'Join interactive live streaming sessions with realtime voice, video, and live Q&A.',
        ),
      },
    ];

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: pillars.map((p) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: _buildPillarCard(p['icon']!, p['title']!, p['desc']!),
          ),
        )).toList(),
      );
    }

    return Column(
      children: pillars.map((p) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _buildPillarCard(p['icon']!, p['title']!, p['desc']!),
      )).toList(),
    );
  }

  Widget _buildPillarCard(String icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.paleMint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: StudioSvgIcon(
              iconKey: icon,
              size: 26,
              color: AppTheme.emeraldGreenDark,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: AppTheme.textMuted,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManifestoCard(bool isDesktop, bool isMobile, LanguageService lang) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 24 : 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.t(fr: 'Notre Engagement Pédagogique', en: 'Our Pedagogical Commitment'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 22 : 28,
              fontWeight: FontWeight.w900,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            lang.t(
              fr: 'Au Club des Formateurs, nous croyons qu\'apprendre ne consiste pas simplement à consommer passivement des vidéos pré-enregistrées. '
                  'La véritable maîtrise s\'acquiert par la pratique intensive, des évaluations concrètes, un accompagnement bienveillant et des échanges directs avec des professionnels confirmés.\n\n'
                  'Nos programmes couvrent l\'Informatique & le Développement, le Design, le Marketing Digital, le Business & Management, et la préparation aux concours universitaires.',
              en: 'At Club des Formateurs, we believe learning goes far beyond passively watching pre-recorded videos. '
                  'True mastery comes from deliberate practice, real homework, personalized mentor guidance, and direct interaction with recognized professionals.',
            ),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF475569),
              height: 1.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCtaSection(BuildContext context, bool isMobile, LanguageService lang) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isMobile ? 32 : 44, horizontal: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF062C32), Color(0xFF0B463E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            lang.t(fr: 'Prêt à propulser vos compétences ?', en: 'Ready to boost your skills?'),
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 22 : 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            lang.t(
              fr: 'Rejoignez des centaines d\'apprenants et formateurs qui façonnent l\'avenir.',
              en: 'Join hundreds of learners and educators shaping the future.',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFD9ECE7), fontSize: 14),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.school_rounded, size: 16),
                label: Text(lang.t(fr: 'Explorer les formations', en: 'Explore Courses')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.mintAccent,
                  foregroundColor: const Color(0xFF062C32),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pushNamed(context, '/formations'),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                label: Text(lang.t(fr: 'Devenir formateur', en: 'Become an Instructor')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pushNamed(context, '/inscription'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
