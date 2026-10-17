import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/course_model.dart';
import '../services/course_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_network_image.dart';
import '../widgets/footer_section.dart';
import '../widgets/navbar.dart';
import 'course_detail_screen.dart';

class CatalogScreen extends StatefulWidget {
  final Function(String route)? onNavigate;
  final VoidCallback? onLoginTap;
  final VoidCallback? onRegisterTap;

  const CatalogScreen({
    super.key,
    this.onNavigate,
    this.onLoginTap,
    this.onRegisterTap,
  });

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final CourseService _courseService = CourseService();
  List<CourseModel> _allCourses = [];
  bool _isLoading = true;
  StreamSubscription? _coursesSub;

  String _selectedCategory = 'Tous';
  String _selectedLevel = 'Tous';
  String _sortBy = 'Pertinence';
  int _currentPage = 1;

  final List<String> _levels = [
    'Tous',
    'Débutant',
    'Intermédiaire',
    'Avancé',
  ];

  final List<String> _durations = [
    'Moins de 2h',
    '2h - 5h',
    '5h - 10h',
    'Plus de 10h',
  ];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _coursesSub?.cancel();
    super.dispose();
  }

  void _loadCourses() {
    _coursesSub = _courseService.getAllCoursesStream().listen((list) {
      if (mounted) {
        setState(() {
          _allCourses = list;
          _isLoading = false;
        });
      }
    });
  }

  List<String> get dynamicCategories {
    final cats = <String>{'Tous'};
    for (final c in _allCourses) {
      if (c.category.trim().isNotEmpty) {
        cats.add(c.category.trim());
      }
    }
    if (cats.length == 1) {
      return ['Tous', 'Informatique', 'Marketing', 'Business', 'Design', 'Développement personnel', 'Langues', 'Autres'];
    }
    return cats.toList();
  }

  int countForCategory(String cat) {
    if (cat == 'Tous') return _allCourses.length;
    return _allCourses.where((c) => c.category.toLowerCase() == cat.toLowerCase()).length;
  }

  List<CourseModel> get filteredCourses {
    var list = List<CourseModel>.from(_allCourses);
    if (_selectedCategory != 'Tous') {
      list = list.where((c) => c.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();
    }
    if (_selectedLevel != 'Tous') {
      list = list.where((c) => c.level.toLowerCase() == _selectedLevel.toLowerCase()).toList();
    }
    if (_sortBy == 'Prix croissant') {
      list.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortBy == 'Prix décroissant') {
      list.sort((a, b) => b.price.compareTo(a.price));
    } else if (_sortBy == 'Mieux notés') {
      list.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return list;
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = 'Tous';
      _selectedLevel = 'Tous';
      _sortBy = 'Pertinence';
      _currentPage = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 980;
    final courses = filteredCourses;

    return Scaffold(
      backgroundColor: AppTheme.ivoryBg,
      body: SingleChildScrollView(
        physics: kIsWeb ? const ClampingScrollPhysics() : const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Top Navigation Bar (Formations active)
            Navbar(
              activeRoute: '/formations',
              onLoginTap: widget.onLoginTap,
              onRegisterTap: widget.onRegisterTap,
              onNavigate: widget.onNavigate,
            ),

            // Hero Section Catalogue (Vert Sapin)
            _buildCatalogHero(isDesktop),

            // Main Catalog Body (Filters Sidebar + Course Grid)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 48 : 20,
                vertical: 40,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1240),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Filters Sidebar (Desktop)
                      if (isDesktop) ...[
                        SizedBox(
                          width: 280,
                          child: _buildFiltersSidebar(),
                        ),
                        const SizedBox(width: 32),
                      ],

                      // Main Content (Courses Grid)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCatalogTopBar(isDesktop),
                            const SizedBox(height: 24),
                            _buildCoursesGrid(courses, isDesktop),
                            const SizedBox(height: 40),
                            _buildPagination(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            FooterSection(
              onNavigate: widget.onNavigate,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCatalogHero(bool isDesktop) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppTheme.heroGradient,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : 20,
        vertical: isDesktop ? 48 : 36,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Row(
            children: [
              // Left text info
              Expanded(
                flex: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bouton Retour à l'accueil
                    InkWell(
                      onTap: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          Navigator.pushReplacementNamed(context, '/');
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Retour à l\'accueil',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        'CATALOGUE DES FORMATIONS',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.mintAccent,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Développez vos compétences avec les meilleurs formateurs',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isDesktop ? 36 : 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Découvrez des formations de qualité pour aujourd\'hui et pour demain.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: const Color(0xFFD9ECE7),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Stats row in Hero (Dynamique)
                    Wrap(
                      spacing: 20,
                      runSpacing: 10,
                      children: [
                        _buildHeroStat('${_allCourses.length}', 'Formations en ligne', Icons.computer_rounded),
                        _buildHeroStat('${_allCourses.map((c) => c.trainerName).toSet().length}', 'Formateurs experts', Icons.verified_rounded),
                        _buildHeroStat('10K+', 'Apprenants actifs', Icons.groups_rounded),
                        _buildHeroStat('95%', 'Taux de satisfaction', Icons.trending_up_rounded),
                      ],
                    ),
                  ],
                ),
              ),

              // Right visual (Desktop only)
              if (isDesktop) ...[
                const SizedBox(width: 32),
                Expanded(
                  flex: 7,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          'assets/images/student-woman.jpeg',
                          height: 230,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.school_rounded, color: AppTheme.emeraldGreenDark, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Apprendre sans limites',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroStat(String num, String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppTheme.mintAccent, size: 16),
        const SizedBox(width: 6),
        Text(
          num,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: const Color(0xFFD8EEE7),
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersSidebar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10233F).withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Filtres',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink,
                  ),
                ),
              ),
              InkWell(
                onTap: _resetFilters,
                child: Text(
                  'Réinitialiser',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.emeraldGreenDark,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: AppTheme.cardBorder),

          // Categories
          _buildFilterSectionTitle('Catégories'),
          for (final cat in dynamicCategories)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Radio<String>(
                    value: cat,
                    groupValue: _selectedCategory,
                    activeColor: AppTheme.emeraldGreen,
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                  Expanded(
                    child: Text(
                      '$cat (${countForCategory(cat)})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.ink,
                        fontWeight: _selectedCategory == cat ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const Divider(height: 24, color: AppTheme.cardBorder),

          // Niveau
          _buildFilterSectionTitle('Niveau'),
          for (final lvl in _levels)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Radio<String>(
                    value: lvl,
                    groupValue: _selectedLevel,
                    activeColor: AppTheme.emeraldGreen,
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedLevel = val);
                    },
                  ),
                  Text(
                    lvl,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.ink,
                      fontWeight: _selectedLevel == lvl ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

          const Divider(height: 24, color: AppTheme.cardBorder),

          // Durée
          _buildFilterSectionTitle('Durée'),
          for (final dur in _durations)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_box_outline_blank_rounded, size: 16, color: AppTheme.cardBorder),
                  const SizedBox(width: 8),
                  Text(dur, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.ink)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppTheme.ink,
        ),
      ),
    );
  }

  Widget _buildCatalogTopBar(bool isDesktop) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Toutes les formations',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Découvrez notre catalogue complet de formations.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${filteredCourses.length} formation${filteredCourses.length > 1 ? 's' : ''} trouvée${filteredCourses.length > 1 ? 's' : ''}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(width: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _sortBy,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.ink, fontWeight: FontWeight.w600),
                  items: ['Pertinence', 'Plus populaires', 'Prix croissant', 'Prix décroissant', 'Mieux notés']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _sortBy = v);
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCoursesGrid(List<CourseModel> courses, bool isDesktop) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (courses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.school_outlined, size: 54, color: AppTheme.textMuted),
              const SizedBox(height: 16),
              Text(
                _allCourses.isEmpty
                    ? 'Formations en cours de préparation'
                    : 'Aucune formation trouvée avec ces critères',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _allCourses.isEmpty
                    ? 'Les professeurs inscrits conçoivent et publient leurs formations en direct. Elles apparaîtront ici dès leur création.'
                    : 'Essayez de modifier ou réinitialiser vos filtres pour voir d\'autres résultats.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (_allCourses.isNotEmpty)
                OutlinedButton(
                  onPressed: _resetFilters,
                  child: const Text('Réinitialiser les filtres'),
                ),
            ],
          ),
        ),
      );
    }
    int crossAxisCount = 3;
    final width = MediaQuery.of(context).size.width;
    double childAspectRatio = 0.68;
    if (width < 640) {
      crossAxisCount = 1;
      childAspectRatio = width < 420 ? 0.98 : 1.15;
    } else if (width < 1000) {
      crossAxisCount = 2;
      childAspectRatio = 0.72;
    } else if (width > 1400) {
      crossAxisCount = 4;
      childAspectRatio = 0.68;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: courses.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, index) {
        final course = courses[index];
        return _buildCourseCard(course);
      },
    );
  }

  Widget _buildCourseCard(CourseModel course) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CourseDetailScreen(course: course),
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
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
          children: [
            // Image with tag & bookmark
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: course.image.startsWith('http')
                        ? AppNetworkImage(
                            url: course.image,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                            cacheWidth: 720,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFFE2E8E5),
                              child: const Center(
                                child: Icon(Icons.school, color: AppTheme.textMuted, size: 36),
                              ),
                            ),
                          )
                        : Image.asset(
                            course.image,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFFE2E8E5),
                              child: const Center(
                                child: Icon(Icons.school, color: AppTheme.textMuted, size: 36),
                              ),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bookmark_border_rounded, size: 15, color: AppTheme.ink),
                  ),
                ),
                if (course.badge != null)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: course.badge == 'Bestseller' ? const Color(0xFFF59E0B) : AppTheme.emeraldGreen,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        course.badge!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.chipMint,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            course.category,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.emeraldGreenDark,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          course.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.ink,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          course.trainerName,
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                    ),

                    Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: AppTheme.amberStar, size: 14),
                            const SizedBox(width: 3),
                            Text(
                              '${course.rating} (${course.reviewsCount})',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.ink,
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.access_time_rounded, color: AppTheme.textMuted, size: 13),
                            const SizedBox(width: 3),
                            Text(
                              course.duration,
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              course.formattedPrice,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.emeraldGreenDark,
                              ),
                            ),
                            const Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.emeraldGreenDark),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPageItem('<', false, () {}),
        for (int p in [1, 2, 3, 4, 5])
          _buildPageItem('$p', _currentPage == p, () => setState(() => _currentPage = p)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Text('...', style: TextStyle(color: AppTheme.textMuted)),
        ),
        _buildPageItem('16', false, () {}),
        _buildPageItem('>', false, () {}),
      ],
    );
  }

  Widget _buildPageItem(String text, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isActive ? AppTheme.emeraldGreen : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isActive ? AppTheme.emeraldGreen : AppTheme.cardBorder),
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isActive ? Colors.white : AppTheme.ink,
            ),
          ),
        ),
      ),
    );
  }
}
