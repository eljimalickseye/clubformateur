import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'bootstrap_icons.dart';

class CategoryItem {
  final String key;
  final String name;
  final String description;
  final int count;
  final Color bgCircleColor;
  final Color iconColor;

  const CategoryItem({
    required this.key,
    required this.name,
    required this.description,
    required this.count,
    required this.bgCircleColor,
    required this.iconColor,
  });
}

class CategoriesSection extends StatelessWidget {
  final Function(String categoryName)? onCategoryTap;
  final VoidCallback? onViewAllTap;

  const CategoriesSection({
    super.key,
    this.onCategoryTap,
    this.onViewAllTap,
  });

  static const List<CategoryItem> categories = [
    CategoryItem(
      key: 'informatique',
      name: 'Informatique',
      description: 'Développement, bureautique, cloud...',
      count: 120,
      bgCircleColor: Color(0xFFE8F7F0),
      iconColor: Color(0xFF12A57A),
    ),
    CategoryItem(
      key: 'marketing',
      name: 'Marketing',
      description: 'Digital, réseaux sociaux, SEO...',
      count: 80,
      bgCircleColor: Color(0xFFEEF2FF),
      iconColor: Color(0xFF6366F1),
    ),
    CategoryItem(
      key: 'business',
      name: 'Business',
      description: 'Entrepreneuriat, gestion, finance...',
      count: 90,
      bgCircleColor: Color(0xFFFEF3C7),
      iconColor: Color(0xFFF59E0B),
    ),
    CategoryItem(
      key: 'design',
      name: 'Design',
      description: 'Graphisme, UI/UX, vidéo...',
      count: 60,
      bgCircleColor: Color(0xFFFCE7F3),
      iconColor: Color(0xFFEC4899),
    ),
    CategoryItem(
      key: 'dev_perso',
      name: 'Développement personnel',
      description: 'Confiance, productivité, leadership...',
      count: 50,
      bgCircleColor: Color(0xFFE0F2FE),
      iconColor: Color(0xFF0284C7),
    ),
    CategoryItem(
      key: 'autres',
      name: 'Autres domaines',
      description: 'Langues, sciences, éducation...',
      count: 40,
      bgCircleColor: Color(0xFFF1F5F9),
      iconColor: Color(0xFF64748B),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1024;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isDesktop ? 64 : 44,
        horizontal: isDesktop ? 48 : 20,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.paleMint,
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: const Color(0xFFC7EBDD), width: 1.5),
                          ),
                          child: Text(
                            'EXPLOREZ NOS DOMAINES',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.emeraldGreenDark,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Explorez nos domaines de formation',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: width < 600 ? 30 : 42,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.ink,
                            letterSpacing: -0.8,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Des compétences sur mesure, un avenir à votre image.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: width < 600 ? 15 : 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.emeraldGreenDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (width >= 600)
                    TextButton(
                      onPressed: onViewAllTap,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Voir toutes les catégories',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.emeraldGreenDark,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, size: 16, color: AppTheme.emeraldGreenDark),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 32),

              // Layout: Categories on Left + Side Banner on Right (Desktop)
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: 6 Category Cards in a 3-column grid
                    Expanded(
                      flex: 68,
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: categories.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.12,
                        ),
                        itemBuilder: (context, index) {
                          return _buildCategoryCard(categories[index], isMobile: false);
                        },
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Right: Featured Banner with custom image and "Des compétences sur mesure"
                    Expanded(
                      flex: 32,
                      child: _buildSideFeatureBanner(context),
                    ),
                  ],
                )
              else ...[
                // Mobile / Tablet: Responsive Grid + Banner below
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: categories.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: width < 600 ? 2 : 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: width < 600 ? 0.88 : 1.1,
                  ),
                  itemBuilder: (context, index) {
                    return _buildCategoryCard(categories[index], isMobile: width < 600);
                  },
                ),
                const SizedBox(height: 24),
                _buildSideFeatureBanner(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(CategoryItem item, {bool isMobile = false}) {
    return InkWell(
      onTap: () => onCategoryTap?.call(item.name),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 14 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.cardBorder),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10233F).withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Bootstrap Icon inside pastel circle
            Container(
              width: isMobile ? 46 : 44,
              height: isMobile ? 46 : 44,
              decoration: BoxDecoration(
                color: item.bgCircleColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: BootstrapIcon(
                  iconKey: item.key,
                  size: isMobile ? 22 : 20,
                  color: item.iconColor,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 18 : 17,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.ink,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 13 : 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            Text(
              '${item.count}+ formations',
              style: GoogleFonts.plusJakartaSans(
                fontSize: isMobile ? 14 : 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.emeraldGreenDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideFeatureBanner(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF072922),
            Color(0xFF0C4638),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF072922).withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFACC15)),
                const SizedBox(width: 5),
                Text(
                  'FORMATION SUR MESURE',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.mintAccent,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Des compétences\nsur mesure, un avenir\nà votre image.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Bénéficiez d\'un accompagnement personnalisé avec des formateurs certifiés pour accélérer votre carrière.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFD9ECE7),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onViewAllTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.mintAccent,
              foregroundColor: const Color(0xFF072922),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Découvrir le catalogue',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_rounded, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
