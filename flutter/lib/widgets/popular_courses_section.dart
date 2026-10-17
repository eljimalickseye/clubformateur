import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/course_model.dart';
import '../theme/app_theme.dart';
import '../utils/app_scroll.dart';
import 'app_network_image.dart';

class PopularCoursesSection extends StatefulWidget {
  final List<CourseModel> courses;
  final Function(CourseModel course)? onCourseTap;
  final VoidCallback? onViewAllTap;
  final VoidCallback? onCreateCourseTap;

  const PopularCoursesSection({
    super.key,
    required this.courses,
    this.onCourseTap,
    this.onViewAllTap,
    this.onCreateCourseTap,
  });

  @override
  State<PopularCoursesSection> createState() => _PopularCoursesSectionState();
}

class _PopularCoursesSectionState extends State<PopularCoursesSection>
    with AutoCarouselMixin {
  @override
  double get carouselStep => 328;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final wide = MediaQuery.sizeOf(context).width >= 900;
    syncAutoScroll(enabled: wide);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final courses = widget.courses;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.paleMint,
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: const Color(0xFFC7EBDD)),
                          ),
                          child: Text(
                            'COURS DES PROFESSEURS',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.emeraldGreenDark,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Formations disponibles',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: width < 600 ? 28 : 36,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.ink,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Les cours réellement créés par les professeurs et formateurs de la plateforme',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (courses.isNotEmpty)
                    Row(
                      children: [
                        if (width >= 600) ...[
                          TextButton(
                            onPressed: widget.onViewAllTap,
                            child: Row(
                              children: [
                                Text(
                                  'Voir tout',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.emeraldGreenDark,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.emeraldGreenDark),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.cardBorder),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: AppTheme.ink),
                            tooltip: 'Faire défiler vers la gauche',
                            onPressed: () => scrollCarouselBy(-330),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.cardBorder),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 15, color: AppTheme.ink),
                            tooltip: 'Faire défiler vers la droite',
                            onPressed: () => scrollCarouselBy(330),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // Courses Horizontal Carousel or Empty State
              if (courses.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppTheme.cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppTheme.paleMint,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.school_rounded, size: 40, color: AppTheme.emeraldGreenDark),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Formations en cours de publication',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.ink,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: Text(
                            'Les professeurs créent et programment leurs cours en direct. Dès qu\'une formation est publiée, elle apparaît immédiatement ici.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textMuted,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: [
                            if (widget.onCreateCourseTap != null)
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                                label: const Text('Créer un cours (Espace Formateur)'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.emeraldGreenDark,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: widget.onCreateCourseTap,
                              ),
                            if (widget.onViewAllTap != null)
                              OutlinedButton.icon(
                                icon: const Icon(Icons.explore_outlined, size: 18),
                                label: const Text('Explorer le catalogue'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.emeraldGreenDark,
                                  side: const BorderSide(color: AppTheme.emeraldGreen),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: widget.onViewAllTap,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.swipe_rounded, size: 16, color: AppTheme.emeraldGreenDark),
                      const SizedBox(width: 6),
                      Text(
                            'Glisser pour explorer les formations',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                MouseRegion(
                  onEnter: (_) => pauseCarousel(),
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                        PointerDeviceKind.trackpad,
                      },
                    ),
                    child: SizedBox(
                      height: 415,
                      child: NotificationListener<ScrollNotification>(
                        onNotification: onCarouselNotification,
                        child: ListView.builder(
                          controller: carouselController,
                          scrollDirection: Axis.horizontal,
                          physics: const ClampingScrollPhysics(),
                          cacheExtent: 480,
                          addAutomaticKeepAlives: false,
                          itemExtent: 328,
                          itemCount: courses.length,
                          itemBuilder: (context, index) {
                            final course = courses[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 18),
                              child: RepaintBoundary(
                                child: _buildCourseCard(course),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard(CourseModel course) {
    return InkWell(
      onTap: () => widget.onCourseTap?.call(course),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.cardBorder),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10233F).withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image or Styled Gradient
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: _buildCover(course),
              ),
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
                        // Category Chip
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.chipMint,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                course.category.isNotEmpty ? course.category : 'Formation',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.emeraldGreenDark,
                                ),
                              ),
                            ),
                            if (course.isPublished)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'En ligne',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF059669),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Title
                        Text(
                          course.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.ink,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // Trainer
                        Row(
                          children: [
                            const Icon(Icons.person_outline_rounded, size: 13, color: AppTheme.textMuted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                course.trainerName.isNotEmpty ? course.trainerName : 'Professeur',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    Column(
                      children: [
                        // Duration & lessons count
                        Row(
                          children: [
                            const Icon(Icons.menu_book_rounded, color: AppTheme.textMuted, size: 13),
                            const SizedBox(width: 3),
                            Text(
                              '${course.lessonsCount} chapitres',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.access_time_rounded, color: AppTheme.textMuted, size: 13),
                            const SizedBox(width: 3),
                            Text(
                              course.duration.isNotEmpty ? course.duration : 'En direct',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Price & Enroll button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              course.formattedPrice,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.emeraldGreenDark,
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => widget.onCourseTap?.call(course),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.emeraldGreenDark,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: Size.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'S\'inscrire',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward_rounded, size: 12),
                                ],
                              ),
                            ),
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

  Widget _buildCover(CourseModel course) {
    Widget imageWidget;
    if (course.image.startsWith('http') || (course.thumbnailUrl != null && course.thumbnailUrl!.startsWith('http'))) {
      final url = course.image.startsWith('http') ? course.image : (course.thumbnailUrl ?? '');
      imageWidget = AppNetworkImage(
        url: url,
        fit: BoxFit.cover,
        cacheWidth: 640,
        errorBuilder: (_, __, ___) => _buildFallbackCover(course),
      );
    } else if (course.image.isNotEmpty && !course.image.contains('dummy') && !course.image.contains('react') && !course.image.contains('figma')) {
      imageWidget = Image.asset(
        course.image,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallbackCover(course),
      );
    } else {
      imageWidget = _buildFallbackCover(course);
    }

    final hasVideo = course.presentationVideoUrl != null && course.presentationVideoUrl!.isNotEmpty;
    if (!hasVideo) return imageWidget;

    return Stack(
      fit: StackFit.expand,
      children: [
        imageWidget,
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withValues(alpha: 0.1),
                Colors.black.withValues(alpha: 0.4),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Positioned(
          bottom: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_circle_fill_rounded, size: 12, color: AppTheme.emeraldGreen),
                SizedBox(width: 4),
                Text(
                  'Vidéo',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackCover(CourseModel course) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF062C32), Color(0xFF0F4D42), Color(0xFF13C7A3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 18),
              ),
              Text(
                'LIVE & E-LEARNING',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.mintAccent,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          Text(
            course.title,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
