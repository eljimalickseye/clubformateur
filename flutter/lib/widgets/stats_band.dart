import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class StatsBand extends StatelessWidget {
  final int studentsCount;
  final int coursesCount;
  final int teachersCount;
  final String? customNote;

  const StatsBand({
    super.key,
    this.studentsCount = 0,
    this.coursesCount = 0,
    this.teachersCount = 0,
    this.customNote,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 860;

    final String displayStudents = studentsCount > 0 ? '$studentsCount+' : 'En direct';
    final String displayCourses = coursesCount > 0 ? '$coursesCount' : 'Disponibles';
    final String displayTeachers = teachersCount > 0 ? '$teachersCount' : 'Certifiés';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Une plateforme vivante et interactive',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: width < 600 ? 22 : 28,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.ink,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Suivi en temps réel des professeurs inscrits, des cours publiés et de la communauté étudiante.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 20),

              // Band Box
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 36 : 20,
                  vertical: 28,
                ),
                decoration: BoxDecoration(
                  gradient: AppTheme.statsBandGradient,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFD3EDE3)),
                ),
                child: isDesktop
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(Icons.groups_rounded, displayStudents, 'Apprenants & Étudiants'),
                          _buildDivider(),
                          _buildStatItem(Icons.auto_stories_rounded, displayCourses, 'Formations publiées'),
                          _buildDivider(),
                          _buildStatItem(Icons.verified_rounded, displayTeachers, 'Professeurs inscrits'),
                          _buildDivider(),
                          _buildStatItem(Icons.trending_up_rounded, '100%', 'Interactif & Lives'),
                        ],
                      )
                    : Wrap(
                        alignment: WrapAlignment.spaceAround,
                        runSpacing: 24,
                        spacing: 24,
                        children: [
                          _buildStatItem(Icons.groups_rounded, displayStudents, 'Apprenants & Étudiants'),
                          _buildStatItem(Icons.auto_stories_rounded, displayCourses, 'Formations publiées'),
                          _buildStatItem(Icons.verified_rounded, displayTeachers, 'Professeurs inscrits'),
                          _buildStatItem(Icons.trending_up_rounded, '100%', 'Interactif & Lives'),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 44,
      width: 1,
      color: const Color(0xFFC7E6DA),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.chipMint,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.emeraldGreenDark, size: 20),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }
}
