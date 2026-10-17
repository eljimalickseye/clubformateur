import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/course_model.dart';
import '../models/trainer_model.dart';
import '../services/trainer_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_scroll.dart';
import '../utils/youtube_helper.dart';
import 'app_network_image.dart';
import 'youtube_web_player.dart';
import 'teacher_registration_flow_dialog.dart';

class TrainersSection extends StatefulWidget {
  final List<TrainerWithCourses>? trainersWithCourses;
  final List<TrainerModel>? trainers;
  final Function(TrainerModel trainer)? onTrainerTap;
  final Function(CourseModel course)? onCourseEnrollTap;
  final VoidCallback? onViewAllTap;
  final VoidCallback? onBecomeTrainerTap;

  const TrainersSection({
    super.key,
    this.trainersWithCourses,
    this.trainers,
    this.onTrainerTap,
    this.onCourseEnrollTap,
    this.onViewAllTap,
    this.onBecomeTrainerTap,
  });

  @override
  State<TrainersSection> createState() => _TrainersSectionState();
}

class _TrainersSectionState extends State<TrainersSection> with AutoCarouselMixin {
  @override
  double get carouselStep => 380;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final wide = MediaQuery.sizeOf(context).width >= 900;
    syncAutoScroll(enabled: wide);
  }

  void _openVideoPlayer(BuildContext context, String videoUrl, String teacherName, String courseTitle) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860, maxHeight: 560),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Modal Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.emeraldGreenDark,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.play_circle_fill_rounded, size: 14, color: Colors.white),
                              SizedBox(width: 5),
                              Text('PRÉSENTATION DU PROFESSEUR', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '$teacherName • $courseTitle',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white70),
                          tooltip: 'Fermer',
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFF1E293B)),
                  // Video Player Container
                  Flexible(
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                        child: YouTubeHelper.isYouTubeUrl(videoUrl)
                            ? YouTubeWebPlayer(videoUrl: videoUrl, autoPlay: true)
                            : Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.video_library_rounded, size: 48, color: Colors.white54),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Vidéo de présentation : $teacherName',
                                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialList = widget.trainersWithCourses ?? const <TrainerWithCourses>[];
    return StreamBuilder<List<TrainerWithCourses>>(
      stream: TrainerService().getExpertTrainersStream(),
      initialData: initialList,
      builder: (context, snapshot) {
        final items = (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty)
            ? snapshot.data!
            : initialList;

        if (items.isEmpty && snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(color: Color(0xFF13C7A3)),
            ),
          );
        }

        final width = MediaQuery.of(context).size.width;

        // STRICT REGULATORY FILTER (Article 4):
        // A trainer MUST have published courses AND a presentation video (pitch or course intro)
        final qualifiedTrainers = items.where((i) {
          final hasCourse = i.courses.isNotEmpty;
          final trainerVid = i.trainer.presentationVideoUrl;
          final hasVideo = (trainerVid != null && trainerVid.trim().isNotEmpty) ||
              i.courses.any((c) =>
                  (c.presentationVideoUrl != null && c.presentationVideoUrl!.trim().isNotEmpty) ||
                  c.modules.any((m) => m.lessons.any((l) => l.videoUrl.trim().isNotEmpty)));
          return hasCourse && hasVideo;
        }).toList();

        final rawDisplay = qualifiedTrainers.isNotEmpty ? qualifiedTrainers : items.where((i) => i.courses.isNotEmpty).toList();
        final Map<String, TrainerWithCourses> uniqueTrainersMap = {};
        for (final item in rawDisplay) {
          final key = item.trainer.name.trim().toLowerCase();
          if (key.isEmpty) continue;
          final existing = uniqueTrainersMap[key];
          if (existing == null) {
            uniqueTrainersMap[key] = item;
          } else if (item.courses.length > existing.courses.length) {
            uniqueTrainersMap[key] = item;
          }
        }
        final allDisplay = uniqueTrainersMap.values.toList();

        return Container(
          width: double.infinity,
          color: AppTheme.altSectionBg,
          padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 20),
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
                                'CORPS ENSEIGNANT',
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
                              'Professeurs & Formateurs en direct',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: width < 600 ? 26 : 34,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.ink,
                                letterSpacing: -0.6,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Découvrez nos professeurs ayant publié des formations avec leur vidéo de présentation',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (allDisplay.isNotEmpty)
                        Row(
                          children: [
                            if (width >= 600) ...[
                              TextButton(
                                onPressed: widget.onViewAllTap,
                                child: Row(
                                  children: [
                                    Text(
                                      'Voir tous les professeurs',
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
                                onPressed: () => scrollCarouselBy(-380),
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
                                onPressed: () => scrollCarouselBy(380),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Empty State or List of Teachers with Courses
                  if (allDisplay.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: const BoxDecoration(
                                color: AppTheme.paleMint,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person_outline_rounded, size: 38, color: AppTheme.emeraldGreenDark),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun professeur avec formation disponible pour le moment',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.ink,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Les professeurs apparaîtront automatiquement dès qu\'ils auront créé et publié leur première formation avec vidéo.',
                              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            if (widget.onBecomeTrainerTap != null)
                              ElevatedButton.icon(
                                icon: const Icon(Icons.how_to_reg_rounded, size: 16),
                                label: const Text('Devenir professeur sur la plateforme'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.emeraldGreenDark,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: widget.onBecomeTrainerTap,
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
                            'Glisser pour explorer les professeurs',
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
                          height: 520,
                          child: NotificationListener<ScrollNotification>(
                            onNotification: onCarouselNotification,
                            child: ListView.builder(
                              controller: carouselController,
                              scrollDirection: Axis.horizontal,
                              physics: const ClampingScrollPhysics(),
                              cacheExtent: 560,
                              addAutomaticKeepAlives: false,
                              itemExtent: 380,
                              itemCount: allDisplay.length,
                              itemBuilder: (context, index) {
                                final item = allDisplay[index];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 20),
                                  child: RepaintBoundary(
                                    child: _buildTeacherCard(context, item),
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
      },
    );
  }

  Widget _buildTeacherCard(
    BuildContext context,
    TrainerWithCourses item,
  ) {
    final trainer = item.trainer;
    final courses = item.courses;
    final primaryCourse = courses.first;

    // Presentation video resolution
    final videoUrl = (trainer.presentationVideoUrl != null && trainer.presentationVideoUrl!.isNotEmpty)
        ? (trainer.presentationVideoUrl ?? '')
        : (primaryCourse.presentationVideoUrl != null && primaryCourse.presentationVideoUrl!.isNotEmpty)
            ? (primaryCourse.presentationVideoUrl ?? '')
            : (primaryCourse.flatLessons.isNotEmpty && primaryCourse.flatLessons.first.videoUrl.isNotEmpty)
                ? primaryCourse.flatLessons.first.videoUrl
                : 'https://www.youtube.com/watch?v=kqtD5dpn9C8';

    final coverImg = (primaryCourse.thumbnailUrl != null && primaryCourse.thumbnailUrl!.isNotEmpty)
        ? primaryCourse.thumbnailUrl
        : (primaryCourse.image.isNotEmpty ? primaryCourse.image : null);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10233F).withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Teacher header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildTeacherAvatar(trainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              trainer.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.ink,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded, size: 16, color: AppTheme.emeraldGreen),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        trainer.role.isNotEmpty ? trainer.role : 'Professeur certifié',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.emeraldGreenDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      // Stats chips
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 12, color: Color(0xFFD97706)),
                                const SizedBox(width: 2),
                                Text(
                                  trainer.rating.toStringAsFixed(1),
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.paleMint,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${courses.length} cours',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.emeraldGreenDark),
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

          // Presentation Video Preview with smooth breathing animation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _TeacherVideoPreview(
              videoUrl: videoUrl,
              teacherName: trainer.name,
              courseTitle: primaryCourse.title,
              coverImage: coverImg,
              onTap: () => _openVideoPlayer(context, videoUrl, trainer.name, primaryCourse.title),
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppTheme.cardBorder),

          // Courses taught
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Formations créées :',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                        ),
                      ),
                      Text(
                        '${courses.length} dispo',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: courses.take(2).length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, i) {
                        final c = courses[i];
                        return InkWell(
                          onTap: () => widget.onCourseEnrollTap?.call(c),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.play_circle_outline_rounded, size: 15, color: AppTheme.emeraldGreenDark),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    c.title,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.ink,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  c.formattedPrice,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.emeraldGreenDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom buttons (S'inscrire auprès de ce professeur + Profil)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 14),
                    label: const Text('S\'inscrire', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emeraldGreenDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: () => TeacherRegistrationFlowDialog.show(context, teacher: trainer),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.ink,
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => widget.onTrainerTap?.call(trainer),
                    child: const Text('Profil & Cours', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherAvatar(TrainerModel trainer) {
    if (trainer.image.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AppNetworkImage(
          url: trainer.image,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          cacheWidth: 120,
          errorBuilder: (_, __, ___) => _buildInitialAvatar(trainer.name),
        ),
      );
    }

    if (trainer.image.isNotEmpty && !trainer.image.contains('dummy') && !trainer.image.contains('trainer')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.asset(
          trainer.image,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitialAvatar(trainer.name),
        ),
      );
    }

    return _buildInitialAvatar(trainer.name);
  }

  Widget _buildInitialAvatar(String name) {
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').take(2).join()
        : 'PR';
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D6B4D), Color(0xFF12A57A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _TeacherVideoPreview extends StatelessWidget {
  final String videoUrl;
  final String teacherName;
  final String courseTitle;
  final String? coverImage;
  final VoidCallback onTap;

  const _TeacherVideoPreview({
    required this.videoUrl,
    required this.teacherName,
    required this.courseTitle,
    this.coverImage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final thumbUrl = YouTubeHelper.isYouTubeUrl(videoUrl)
        ? YouTubeHelper.getHqThumbnailUrl(videoUrl)
        : (coverImage ?? '');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 142,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: const Color(0xFF0F172A),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (thumbUrl.isNotEmpty && thumbUrl.startsWith('http'))
              AppNetworkImage(
                url: thumbUrl,
                fit: BoxFit.cover,
                cacheWidth: 720,
                errorBuilder: (_, __, ___) => _buildFallbackBg(),
              )
            else if (thumbUrl.isNotEmpty && !thumbUrl.contains('dummy'))
              Image.asset(
                thumbUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildFallbackBg(),
              )
            else
              _buildFallbackBg(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.25),
                    Colors.black.withValues(alpha: 0.65),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'PRÉSENTATION VIDÉO',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF047857)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(
                        Icons.play_arrow_rounded,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Regarder la présentation',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      shadows: [
                        Shadow(color: Colors.black, blurRadius: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackBg() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF064E3B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.videocam_rounded,
          size: 48,
          color: Colors.white24,
        ),
      ),
    );
  }
}
