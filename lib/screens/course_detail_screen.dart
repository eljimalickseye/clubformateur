import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/course_model.dart';
import '../models/trainer_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/corrector_service.dart';
import '../services/enrollment_service.dart';
import '../theme/app_theme.dart';
import '../widgets/footer_section.dart';
import '../widgets/navbar.dart';
import '../widgets/legal_documents_widget.dart';
import 'dashboards/student_dashboard_screen.dart';
import 'trainer_profile_screen.dart';
import 'auth/register_full_screen.dart';
import '../utils/youtube_helper.dart';

class CourseDetailScreen extends StatefulWidget {
  final CourseModel course;
  final Function(String route)? onNavigate;

  const CourseDetailScreen({
    super.key,
    required this.course,
    this.onNavigate,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  int _activeTab = 0;
  final List<String> _tabs = ['Aperçu', 'Programme', 'Formateur', 'Avis', 'Questions fréquentes'];
  final Set<String> _expandedModules = {'m1'};
  final Set<int> _expandedFaq = {0};
  bool _isFavorited = false;

  late List<Map<String, dynamic>> _reviews;

  @override
  void initState() {
    super.initState();
    _reviews = [
      {
        'name': 'Aminata Diallo',
        'avatar': 'assets/images/student-woman.jpeg',
        'date': 'Il y a 3 jours',
        'rating': 5,
        'comment': 'Excellente formation ! Les explications sont limpides et les projets pratiques permettent de progresser immédiatement. Le meilleur investissement de mon année.',
      },
      {
        'name': 'Ousmane Ba',
        'avatar': 'assets/images/student-man.jpeg',
        'date': 'Il y a 1 semaine',
        'rating': 5,
        'comment': "Formateur très pédagogue et disponible. Grâce aux corrections détaillées, j'ai pu décrocher mon premier emploi dans le domaine.",
      },
      {
        'name': 'Awa Seck',
        'avatar': 'assets/images/student-girl-clean.jpeg',
        'date': 'Il y a 2 semaines',
        'rating': 4,
        'comment': 'Contenu très complet et structuré. Les sessions de direct en live apportent une vraie valeur ajoutée pour poser nos questions.',
      },
    ];
  }

  String _getFormattedPrice(int price) {
    if (price == 0) return 'GRATUIT';
    final formatter = NumberFormat('#,###', 'fr_FR');
    return '${formatter.format(price)} FCFA';
  }

  void _handleShare() {
    Clipboard.setData(const ClipboardData(text: 'https://club-des-formateurs.web.app/#/course'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(child: Text('Lien copié dans le presse-papier ! Partagez-le avec vos contacts 📋')),
          ],
        ),
        backgroundColor: AppTheme.emeraldGreenDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _handleToggleFavorite() {
    setState(() => _isFavorited = !_isFavorited);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(_isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(_isFavorited ? 'Formation ajoutée à vos favoris ❤️' : 'Formation retirée de vos favoris'),
          ],
        ),
        backgroundColor: _isFavorited ? const Color(0xFFE11D48) : AppTheme.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openCoursePlayer(CourseModel course, UserModel? user, {bool autoPlayPresentation = false, bool initialFullscreen = false, CourseLesson? initialLesson}) {
    showDialog(
      context: context,
      builder: (_) => CoursePlayerDialog(
        course: course,
        userId: user?.uid ?? 'guest',
        onProgressUpdated: () {},
        autoPlayPresentation: autoPlayPresentation,
        initialFullscreen: initialFullscreen,
        initialLesson: initialLesson,
      ),
    );
  }

  void _showAddReviewDialog() {
    int selectedRating = 5;
    final commentCtrl = TextEditingController();
    final user = AuthService().currentUser;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.rate_review_outlined, color: AppTheme.emeraldGreenDark),
              const SizedBox(width: 8),
              Text('Donner votre avis', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Votre note :', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              Row(
                children: List.generate(5, (index) {
                  final star = index + 1;
                  return IconButton(
                    icon: Icon(
                      star <= selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: star <= selectedRating ? const Color(0xFFFBBF24) : AppTheme.textMuted,
                      size: 30,
                    ),
                    onPressed: () => setModalState(() => selectedRating = star),
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Votre commentaire',
                  hintText: 'Expliquez ce que vous avez pensé de cette formation...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (commentCtrl.text.trim().isEmpty) return;
                setState(() {
                  _reviews.insert(0, {
                    'name': user?.displayName.isNotEmpty == true ? user!.displayName : 'Apprenant vérifié',
                    'avatar': 'assets/images/student-woman.jpeg',
                    'date': "À l'instant",
                    'rating': selectedRating,
                    'comment': commentCtrl.text.trim(),
                  });
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Merci ! Votre avis a été publié avec succès. ⭐'),
                    backgroundColor: AppTheme.emeraldGreen,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emeraldGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Publier mon avis'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToTrainerProfile(BuildContext context, CourseModel course) async {
    TrainerModel? targetTrainer;
    final teacherId = course.teacherId.isNotEmpty ? course.teacherId : course.trainerName;

    if (course.teacherId.isNotEmpty) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(course.teacherId).get();
        if (doc.exists && doc.data() != null) {
          targetTrainer = TrainerModel.fromMap(doc.data()!, doc.id);
        }
      } catch (_) {}
    }

    if (targetTrainer == null) {
      targetTrainer = TrainerModel(
        id: teacherId,
        name: course.trainerName.isNotEmpty ? course.trainerName : 'Formateur',
        role: course.trainerRole.isNotEmpty ? course.trainerRole : 'Formateur Expert',
        rating: course.rating > 0 ? course.rating : 5.0,
        coursesCount: 1,
        studentsCount: course.studentsCount,
        image: course.trainerAvatar ?? '',
        bio: 'Formateur et instructeur de "${course.title}".',
        headline: course.trainerRole.isNotEmpty ? course.trainerRole : 'Formateur certifié',
        presentation: 'Spécialiste dans le domaine "${course.category}". Formateur sur Club des Formateurs.',
        experienceYears: '5+ ans',
        skills: [course.category, course.level],
        availableFor: const ['Formations en ligne', 'Sessions interactives', 'Mentorat'],
      );
    }

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TrainerProfileScreen(trainer: targetTrainer)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1000;
    final course = widget.course;

    return Scaffold(
      backgroundColor: AppTheme.ivoryBg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Navbar
            Navbar(
              onNavigate: (route) {
                if (widget.onNavigate != null) {
                  widget.onNavigate!(route);
                } else {
                  Navigator.pop(context);
                }
              },
            ),

            // Breadcrumbs & Top Actions Bar
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 48 : 20,
                vertical: 18,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1240),
                  child: width < 768
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  InkWell(
                                    onTap: () => Navigator.pop(context),
                                    child: Text('Accueil', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted)),
                                  ),
                                  const Text(' > ', style: TextStyle(color: AppTheme.textLight, fontSize: 12)),
                                  InkWell(
                                    onTap: () => Navigator.pop(context),
                                    child: Text('Formations', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted)),
                                  ),
                                  const Text(' > ', style: TextStyle(color: AppTheme.textLight, fontSize: 12)),
                                  Text(course.category, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted)),
                                  const Text(' > ', style: TextStyle(color: AppTheme.textLight, fontSize: 12)),
                                  Text(
                                    course.title,
                                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.ink),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _handleShare,
                                  icon: const Icon(Icons.share_outlined, size: 14),
                                  label: Text('Partager', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    side: const BorderSide(color: AppTheme.cardBorder),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: _handleToggleFavorite,
                                  icon: Icon(
                                    _isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                    size: 14,
                                    color: _isFavorited ? const Color(0xFFE11D48) : null,
                                  ),
                                  label: Text(
                                    _isFavorited ? 'Dans vos favoris' : 'Ajouter aux favoris',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _isFavorited ? const Color(0xFFE11D48) : null,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    side: BorderSide(color: _isFavorited ? const Color(0xFFE11D48) : AppTheme.cardBorder),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Breadcrumb
                            Expanded(
                              child: Row(
                                children: [
                                  InkWell(
                                    onTap: () => Navigator.pop(context),
                                    child: Text('Accueil', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted)),
                                  ),
                                  const Text(' > ', style: TextStyle(color: AppTheme.textLight, fontSize: 12)),
                                  InkWell(
                                    onTap: () => Navigator.pop(context),
                                    child: Text('Formations', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted)),
                                  ),
                                  const Text(' > ', style: TextStyle(color: AppTheme.textLight, fontSize: 12)),
                                  Text(course.category, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted)),
                                  const Text(' > ', style: TextStyle(color: AppTheme.textLight, fontSize: 12)),
                                  Flexible(
                                    child: Text(
                                      course.title,
                                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.ink),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Actions (Partager & Favoris)
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _handleShare,
                                  icon: const Icon(Icons.share_outlined, size: 14),
                                  label: Text('Partager', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    side: const BorderSide(color: AppTheme.cardBorder),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: _handleToggleFavorite,
                                  icon: Icon(
                                    _isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                    size: 14,
                                    color: _isFavorited ? const Color(0xFFE11D48) : null,
                                  ),
                                  label: Text(
                                    _isFavorited ? 'Dans vos favoris' : 'Ajouter aux favoris',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _isFavorited ? const Color(0xFFE11D48) : null,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    side: BorderSide(color: _isFavorited ? const Color(0xFFE11D48) : AppTheme.cardBorder),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
              ),
            ),

            // Main Content Area
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 48 : 20,
                vertical: 12,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1240),
                  child: isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 65,
                              child: _buildLeftColumn(course),
                            ),
                            const SizedBox(width: 32),
                            Expanded(
                              flex: 35,
                              child: _buildRightSidebar(course),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _buildLeftColumn(course),
                            const SizedBox(height: 32),
                            _buildRightSidebar(course),
                          ],
                        ),
                ),
              ),
            ),

            const SizedBox(height: 60),
            const FooterSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftColumn(CourseModel course) {
    final user = AuthService().currentUser;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Video Preview Card (Interactive)
        InkWell(
          onTap: () => _openCoursePlayer(course, user, autoPlayPresentation: true),
          borderRadius: BorderRadius.circular(22),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppTheme.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10233F).withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: _buildSafeCover(
                        course,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                      ),
                    ),
                    // Dark overlay
                    Container(
                      height: 280,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                        gradient: LinearGradient(
                          colors: [Colors.black.withValues(alpha: 0.4), Colors.black.withValues(alpha: 0.1)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                    // Badge: Formation populaire
                    Positioned(
                      top: 14,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Text('🔥 ', style: TextStyle(fontSize: 12)),
                            Text(
                              'Formation populaire',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Badge: Plein écran & Vidéo de présentation disponible
                    Positioned(
                      top: 14,
                      right: 14,
                      child: InkWell(
                        onTap: () => _openCoursePlayer(course, user, autoPlayPresentation: true, initialFullscreen: true),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.emeraldGreenDark.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Plein écran',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Play button in center (Interactive)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.play_arrow_rounded, color: AppTheme.emeraldGreenDark, size: 36),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    YouTubeHelper.isYouTubeUrl(course.presentationVideoUrl)
                                        ? Icons.smart_display_rounded
                                        : Icons.play_circle_fill_rounded,
                                    color: YouTubeHelper.isYouTubeUrl(course.presentationVideoUrl)
                                        ? const Color(0xFFEF4444)
                                        : Colors.white,
                                    size: 15,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    YouTubeHelper.isYouTubeUrl(course.presentationVideoUrl)
                                        ? 'Bande annonce YouTube HD'
                                        : (course.presentationVideoUrl != null && course.presentationVideoUrl!.isNotEmpty
                                            ? 'Bande annonce'
                                            : 'Aperçu vidéo'),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _openCoursePlayer(course, user, autoPlayPresentation: true, initialFullscreen: true),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: AppTheme.emeraldGreenDark,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 16),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Regarder en plein écran',
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
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                // Meta Bar below video
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9FAF8),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetaItem(Icons.auto_stories_rounded, '${course.lessonsCount} leçons'),
                      _buildMetaItem(Icons.access_time_rounded, course.duration),
                      _buildMetaItem(Icons.all_inclusive_rounded, 'Accès à vie'),
                      _buildMetaItem(Icons.verified_rounded, 'Certificat inclus'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Title and Category Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.chipMint,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            course.category,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.emeraldGreenDark,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          course.title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppTheme.ink,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          course.description,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: AppTheme.textMuted,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 14),

        // Rating and instructor row
        Row(
          children: [
            const Icon(Icons.star_rounded, color: AppTheme.amberStar, size: 18),
            const SizedBox(width: 4),
            Text(
              '${course.rating}',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.ink),
            ),
            Text(
              ' (${course.reviewsCount} avis)',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textMuted),
            ),
            const SizedBox(width: 18),
            const Icon(Icons.groups_rounded, color: AppTheme.textMuted, size: 16),
            const SizedBox(width: 4),
            Text(
              '${course.studentsCount} apprenants',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Dynamic Navigation Tabs: [Aperçu] [Programme] [Formateur] [Avis] [FAQ]
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_tabs.length, (idx) {
              final active = _activeTab == idx;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () => setState(() => _activeTab = idx),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: active ? AppTheme.emeraldGreen : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: active ? AppTheme.emeraldGreen : AppTheme.cardBorder),
                    ),
                    child: Text(
                      _tabs[idx],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: active ? Colors.white : AppTheme.ink,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 24),

        // Dynamic Tab Content
        _buildTabContent(course),
      ],
    );
  }

  Widget _buildMetaItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppTheme.emeraldGreenDark),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.ink,
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // DYNAMIC TAB ROUTER
  // -------------------------------------------------------------
  Widget _buildTabContent(CourseModel course) {
    switch (_activeTab) {
      case 1:
        return _buildProgrammeTab(course);
      case 2:
        return _buildFormateurTab(course);
      case 3:
        return _buildAvisTab(course);
      case 4:
        return _buildFaqTab(course);
      case 0:
      default:
        return _buildApercuTab(course);
    }
  }

  // -------------------------------------------------------------
  // TAB 0: APERÇU (Overview)
  // -------------------------------------------------------------
  Widget _buildApercuTab(CourseModel course) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section: Vous allez apprendre
        if (course.whatYouWillLearn.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vous allez apprendre',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 24,
                  runSpacing: 12,
                  children: course.whatYouWillLearn.map((item) {
                    return SizedBox(
                      width: 320,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppTheme.emeraldGreen, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: AppTheme.ink,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Section: Programme résumé
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Programme de la formation',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${course.lessonsCount} leçons • ${course.duration} de contenu',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => setState(() => _activeTab = 1),
                    child: Text(
                      'Voir tout le programme →',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.emeraldGreenDark,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: AppTheme.cardBorder),
              for (final mod in course.modules.take(2)) _buildModuleItem(mod),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Section: Prérequis & Public cible
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Prérequis & Public cible', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.ink)),
              const SizedBox(height: 14),
              _buildBulletItem('Aucun niveau avancé requis : la formation démarre par les fondamentaux.'),
              _buildBulletItem('Un ordinateur ou une tablette avec une connexion internet pour suivre les travaux pratiques.'),
              _buildBulletItem('Idéal pour les étudiants, reconversions professionnelles et professionnels souhaitant monter en compétences.'),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 1: PROGRAMME (Curriculum)
  // -------------------------------------------------------------
  Widget _buildProgrammeTab(CourseModel course) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Programme complet du cours',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${course.modules.length} modules • ${course.lessonsCount} leçons • ${course.duration}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (_expandedModules.length == course.modules.length) {
                      _expandedModules.clear();
                    } else {
                      _expandedModules.addAll(course.modules.map((m) => m.id));
                    }
                  });
                },
                child: Text(
                  _expandedModules.length == course.modules.length ? 'Tout replier' : 'Tout déplier',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.emeraldGreenDark),
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: AppTheme.cardBorder),
          for (final mod in course.modules) _buildModuleItem(mod),
        ],
      ),
    );
  }

  Widget _buildModuleItem(CourseModule mod) {
    final isExpanded = _expandedModules.contains(mod.id);
    final user = AuthService().currentUser;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFDFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedModules.remove(mod.id);
                } else {
                  _expandedModules.add(mod.id);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.ink,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      mod.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                  ),
                  Text(
                    '${mod.lessonsCount} leçons • ${mod.duration}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1, color: AppTheme.cardBorder),
            for (final lesson in mod.lessons)
              InkWell(
                onTap: () => _openCoursePlayer(widget.course, user, initialLesson: lesson),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        YouTubeHelper.isYouTubeUrl(lesson.videoUrl)
                            ? Icons.smart_display_rounded
                            : Icons.play_circle_outline_rounded,
                        size: 18,
                        color: YouTubeHelper.isYouTubeUrl(lesson.videoUrl)
                            ? const Color(0xFFEF4444)
                            : AppTheme.emeraldGreen,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          lesson.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.ink,
                          ),
                        ),
                      ),
                      if (YouTubeHelper.isYouTubeUrl(lesson.videoUrl))
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('YouTube', style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.w800)),
                        ),
                      if (lesson.isFreePreview)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.paleMint,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Aperçu gratuit', style: TextStyle(fontSize: 10, color: AppTheme.emeraldGreenDark, fontWeight: FontWeight.w700)),
                        ),
                      Text(
                        lesson.duration,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 2: FORMATEUR (Trainer Profile)
  // -------------------------------------------------------------
  Widget _buildFormateurTab(CourseModel course) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSafeAvatar(course.trainerAvatar, course.trainerName, size: 72),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(course.trainerName, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.ink)),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_rounded, size: 18, color: AppTheme.emeraldGreen),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(course.trainerRole, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 16),
                        const SizedBox(width: 4),
                        Text('4.8 note formateur', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.ink)),
                        const SizedBox(width: 16),
                        const Icon(Icons.groups_rounded, color: AppTheme.textMuted, size: 16),
                        const SizedBox(width: 4),
                        Text('${course.studentsCount} apprenants formés', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 32, color: AppTheme.cardBorder),
          Text('Biographie & Expertise', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.ink)),
          const SizedBox(height: 8),
          Text(
            "Expert passionné avec plus de 6 ans d'expérience dans l'enseignement et l'ingénierie logicielle. Il a accompagné des centaines d'apprenants à maîtriser des outils professionnels et à concrétiser leurs ambitions professionnelles.",
            style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.6, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.person_rounded, size: 16),
                label: const Text('Voir le profil complet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emeraldGreenDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _navigateToTrainerProfile(context, course),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.mail_outline_rounded, size: 16),
                label: const Text('Poser une question'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.ink,
                  side: const BorderSide(color: AppTheme.cardBorder),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _showAskQuestionModal(course),
              ),
            ],
          ),
          const SizedBox(height: 32),
          FutureBuilder<UserModel?>(
            future: CorrectorService().getLinkedCorrector(course.teacherId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 24, width: 24, child: CircularProgressIndicator());
              }
              final corrector = snapshot.data;
              if (corrector == null) return const SizedBox.shrink();

              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Votre correcteur attitré', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.ink)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _buildSafeAvatar(corrector.photoUrl, corrector.displayName, size: 50),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(corrector.displayName.isNotEmpty ? corrector.displayName : 'Correcteur', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.ink)),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified_rounded, size: 16, color: AppTheme.emeraldGreen),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text('Correcteur Certifié', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.emeraldGreenDark)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAskQuestionModal(CourseModel course) {
    final questionCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.help_outline_rounded, color: AppTheme.emeraldGreenDark),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Poser une question à ${course.trainerName}',
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'À propos de : ${course.title}',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.emeraldGreenDark),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: questionCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Votre question',
                hintText: 'Posez votre question sur les leçons, les prérequis ou les devoirs...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emeraldGreenDark,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final text = questionCtrl.text.trim();
              if (text.isEmpty) return;
              final user = AuthService().currentUser ?? UserModel.demoStudent;
              final targetId = 'teacher_${course.trainerName.toLowerCase().replaceAll(' ', '_')}';
              final convId = await ChatService().getOrCreateConversation(
                currentUserId: user.uid,
                currentUserName: user.displayName,
                currentUserPhoto: user.photoUrl ?? '',
                targetUserId: targetId,
                targetUserName: course.trainerName,
                targetUserPhoto: course.trainerAvatar ?? course.image,
                courseName: course.title,
                courseId: course.id,
              );
              await ChatService().sendMessage(
                conversationId: convId,
                senderId: user.uid,
                senderName: user.displayName,
                senderRole: user.role,
                content: '[${course.title}] $text',
              );
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Question envoyée à ${course.trainerName} ! La discussion est créée dans votre messagerie.')),
                      ],
                    ),
                    backgroundColor: AppTheme.emeraldGreenDark,
                    behavior: SnackBarBehavior.floating,
                    action: SnackBarAction(
                      label: 'Voir discussion',
                      textColor: Colors.white,
                      onPressed: () {
                        Navigator.pushNamed(context, '/dashboard/apprenant');
                      },
                    ),
                  ),
                );
              }
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 3: AVIS (Dynamic Reviews)
  // -------------------------------------------------------------
  Widget _buildAvisTab(CourseModel course) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with average rating & "Laisser un avis" button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '${course.rating}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 36, fontWeight: FontWeight.w900, color: AppTheme.ink),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: List.generate(
                          5,
                          (i) => const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 18),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text("Sur ${course.reviewsCount} avis d'apprenants certifiés", style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted)),
                    ],
                  ),
                ],
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.rate_review_rounded, size: 16),
                label: const Text('Donner mon avis'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emeraldGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _showAddReviewDialog,
              ),
            ],
          ),
          const Divider(height: 32, color: AppTheme.cardBorder),

          // Rating Bars
          _buildRatingBar(5, 0.85, '85%'),
          _buildRatingBar(4, 0.10, '10%'),
          _buildRatingBar(3, 0.03, '3%'),
          _buildRatingBar(2, 0.01, '1%'),
          _buildRatingBar(1, 0.01, '1%'),
          const Divider(height: 32, color: AppTheme.cardBorder),

          // Reviews List
          Text('Avis récents des apprenants', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.ink)),
          const SizedBox(height: 16),
          for (final rev in _reviews) _buildReviewItem(rev),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int stars, double ratio, String percent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 50, child: Text('$stars étoiles', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted))),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFBBF24)),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(width: 35, child: Text(percent, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted))),
        ],
      ),
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> rev) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.paleMint,
                child: Text(
                  (rev['name'] as String)[0],
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.emeraldGreenDark),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rev['name'], style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.ink)),
                    Text(rev['date'], style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    Icons.star_rounded,
                    size: 15,
                    color: i < (rev['rating'] as int) ? const Color(0xFFFBBF24) : AppTheme.cardBorder,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            rev['comment'],
            style: GoogleFonts.plusJakartaSans(fontSize: 12, height: 1.5, color: const Color(0xFF334155)),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 4: FAQ (Interactive Questions & Answers)
  // -------------------------------------------------------------
  Widget _buildFaqTab(CourseModel course) {
    final faqs = [
      {
        'q': 'Combien de temps ai-je accès à la formation ?',
        'a': 'Vous bénéficiez d\'un accès illimité à vie ! Vous pouvez consulter les leçons à votre rythme, réécouter les enregistrements et télécharger les ressources à tout moment.',
      },
      {
        'q': 'Comment se déroulent les devoirs et les corrections ?',
        'a': 'Après chaque module, des devoirs pratiques sont mis à votre disposition. Vous soumettez vos fichiers directement sur la plateforme, et notre profil correcteur dédié vous retourne une note accompagnée d\'une correction personnalisée et de sessions live interactives.',
      },
      {
        'q': 'Obtient-on un certificat vérifiable à la fin ?',
        'a': 'Oui ! À la complétion de 100% des modules et la validation des devoirs, un certificat officiel délivré par le Club des Formateurs avec QR code vérifiable vous est immédiatement généré.',
      },
      {
        'q': 'Quels sont les moyens de paiement disponibles ?',
        'a': 'Nous acceptons Wave, Orange Money, Free Money ainsi que les Cartes Bancaires (Visa / Mastercard). Tous les paiements sont instantanés et sécurisés.',
      },
      {
        'q': 'Puis-je me faire rembourser si je ne suis pas satisfait ?',
        'a': 'Absolument. Conformément à notre politique officielle, nous offrons une garantie Satisfait ou Remboursé de 14 jours à 100% (si moins de 20% du contenu a été visionné et aucun certificat émis). Le remboursement est effectué sur le moyen de paiement d\'origine (Wave, Orange Money ou Carte Bancaire).',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Questions fréquemment posées', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.ink)),
          const SizedBox(height: 6),
          const Text('Tout ce que vous devez savoir avant de commencer.', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          const Divider(height: 24, color: AppTheme.cardBorder),
          for (int i = 0; i < faqs.length; i++)
            _buildFaqItem(i, faqs[i]['q']!, faqs[i]['a']!),
        ],
      ),
    );
  }

  Widget _buildFaqItem(int index, String question, String answer) {
    final isExpanded = _expandedFaq.contains(index);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedFaq.remove(index);
                } else {
                  _expandedFaq.add(index);
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      question,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.remove_circle_outline_rounded : Icons.add_circle_outline_rounded,
                    color: AppTheme.emeraldGreenDark,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  answer,
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, height: 1.5, color: const Color(0xFF475569)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.arrow_right_rounded, color: AppTheme.emeraldGreen, size: 20),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 12, height: 1.5, color: const Color(0xFF334155))),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // RIGHT SIDEBAR (Checkout & Trainer Info)
  // -------------------------------------------------------------
  Widget _buildRightSidebar(CourseModel course) {
    final authService = AuthService();
    final user = authService.currentUser;

    return StreamBuilder<bool>(
      stream: EnrollmentService().isUserEnrolledStream(user?.uid ?? '', course.id),
      builder: (context, snapshot) {
        final isEnrolled = snapshot.data ?? false;

        return Column(
          children: [
            // Sticky Purchase Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppTheme.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10233F).withValues(alpha: 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        _getFormattedPrice(course.price),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.emeraldGreenDark,
                        ),
                      ),
                      Text(
                        'Accès complet',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  if (isEnrolled) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(12)),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF065F46), size: 18),
                          SizedBox(width: 8),
                          Text('Vous êtes inscrit à cette formation', style: TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.w700, fontSize: 13)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.play_circle_filled_rounded),
                        label: const Text('Accéder aux leçons vidéo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.emeraldGreenDark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => _openCoursePlayer(course, user),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                        label: Text('Discuter avec ${course.trainerName}'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.emeraldGreenDark,
                          side: const BorderSide(color: AppTheme.emeraldGreen),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => _showAskQuestionModal(course),
                      ),
                    ),
                  ] else ...[
                    // Button: S'inscrire maintenant (Dynamic)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (user == null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterFullScreen(initialRole: 'student'),
                              ),
                            );
                          } else {
                            _showCheckoutDialog(course, user);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.emeraldGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('S\'inscrire maintenant • ${_getFormattedPrice(course.price)}', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700)),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Button: Acheter avec Wave / Orange Money
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          if (user == null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterFullScreen(initialRole: 'student'),
                              ),
                            );
                          } else {
                            _showCheckoutDialog(course, user);
                          }
                        },
                        icon: const Icon(Icons.account_balance_wallet_outlined, size: 16),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Acheter par Wave / Orange Money', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700)),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.emeraldGreenDark,
                          side: const BorderSide(color: AppTheme.emeraldGreen, width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),

                  // Included Checklist
                  _buildIncludedItem('Accès immédiat à toutes les leçons'),
                  _buildIncludedItem('Vidéos en haute qualité'),
                  _buildIncludedItem('Projets pratiques et ressources'),
                  _buildIncludedItem('Certificat de fin de formation'),
                  _buildIncludedItem('Accès sur mobile, tablette et ordinateur'),
                  _buildIncludedItem('Support du formateur'),
                  const SizedBox(height: 18),

                  // Guarantee box (Clickable -> opens official refund policy)
                  InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => LegalDocumentsView(
                          userId: user?.uid ?? 'guest',
                          isModal: true,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.paleMint,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFC7EBDD)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_user_rounded, color: AppTheme.emeraldGreenDark, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text('Garantie 14 jours Satisfait ou Remboursé', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.emeraldGreenDark)),
                                    const Spacer(),
                                    const Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.emeraldGreenDark),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text('100% remboursé sous 14 jours (<20% visionné). Cliquez pour lire.', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.ink)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Trainer Box (Clickable -> links to TrainerProfileScreen)
            InkWell(
              onTap: () => _navigateToTrainerProfile(context, course),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Votre formateur', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.ink)),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.textMuted),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _buildSafeAvatar(course.trainerAvatar, course.trainerName, size: 50),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(course.trainerName, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.ink)),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified_rounded, size: 14, color: AppTheme.emeraldGreen),
                                ],
                              ),
                              Text(course.trainerRole, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textMuted), maxLines: 2),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildIncludedItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.check_rounded, color: AppTheme.emeraldGreen, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.ink),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // CHECKOUT DIALOG (100% Fonctionnel - Wave, Orange Money, Carte)
  // -------------------------------------------------------------
  void _showCheckoutDialog(CourseModel course, UserModel user) {
    String selectedMethod = 'Wave';
    bool isProcessing = false;
    final phoneCtrl = TextEditingController(text: user.phoneNumber ?? '');

    showDialog(
      context: context,
      barrierDismissible: !isProcessing,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.paleMint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lock_rounded, color: AppTheme.emeraldGreenDark, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paiement sécurisé',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.ink,
                      ),
                    ),
                    Text(
                      'Inscription immédiate à la formation',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Course summary card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Row(
                      children: [
                        _buildSafeCover(course, width: 52, height: 52, borderRadius: BorderRadius.circular(10)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course.title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppTheme.ink,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                course.trainerName.isNotEmpty ? course.trainerName : 'Professeur',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getFormattedPrice(course.price),
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppTheme.emeraldGreenDark,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Mode de paiement
                  Text(
                    'Mode de paiement :',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.ink),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPaymentChoiceChip(
                        label: 'Wave',
                        icon: Icons.waves_rounded,
                        color: const Color(0xFF1EA5FC),
                        isSelected: selectedMethod == 'Wave',
                        onSelected: () => setModalState(() => selectedMethod = 'Wave'),
                      ),
                      _buildPaymentChoiceChip(
                        label: 'Orange Money',
                        icon: Icons.phone_android_rounded,
                        color: const Color(0xFFFF7900),
                        isSelected: selectedMethod == 'Orange Money',
                        onSelected: () => setModalState(() => selectedMethod = 'Orange Money'),
                      ),
                      _buildPaymentChoiceChip(
                        label: 'Carte Bancaire',
                        icon: Icons.credit_card_rounded,
                        color: AppTheme.ink,
                        isSelected: selectedMethod == 'Carte Bancaire',
                        onSelected: () => setModalState(() => selectedMethod = 'Carte Bancaire'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Numéro de téléphone pour Mobile Money
                  if (selectedMethod == 'Wave' || selectedMethod == 'Orange Money') ...[
                    Text(
                      'Numéro de paiement ($selectedMethod) :',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'Ex: +221 77 123 45 67',
                        prefixIcon: const Icon(Icons.phone_outlined, size: 18, color: AppTheme.emeraldGreen),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.cardBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.emeraldGreen, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Récapitulatif montant
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.paleMint.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFC7EBDD)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Montant de la formation', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.ink)),
                            Text(_getFormattedPrice(course.price), style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.ink)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Frais de transaction', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted)),
                            Text('0 FCFA (Inclus)', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.emeraldGreenDark)),
                          ],
                        ),
                        const Divider(height: 14, color: Color(0xFFC7EBDD)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total à régler', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.ink)),
                            Text(_getFormattedPrice(course.price), style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.emeraldGreenDark)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (isProcessing) ...[
                    const SizedBox(height: 20),
                    Center(
                      child: Column(
                        children: [
                          const CircularProgressIndicator(color: AppTheme.emeraldGreenDark),
                          const SizedBox(height: 10),
                          Text(
                            'Confirmation sécurisée via $selectedMethod...',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
          actions: [
            if (!isProcessing) ...[
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Annuler', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                label: Text('Payer ${_getFormattedPrice(course.price)} ($selectedMethod)'),
                onPressed: () async {
                  setModalState(() => isProcessing = true);

                  // Process enrollment & payment transaction
                  await EnrollmentService().enrollUser(
                    userId: user.uid,
                    userName: user.displayName.isNotEmpty ? user.displayName : 'Apprenant',
                    studentEmail: user.email,
                    studentPhone: user.phoneNumber,
                    studentPhoto: user.photoUrl,
                    course: course,
                    paymentMethod: selectedMethod,
                  );

                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    _showSuccessDialog(course, user, selectedMethod);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emeraldGreenDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentChoiceChip({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.emeraldGreenDark : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.emeraldGreenDark : AppTheme.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppTheme.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(CourseModel course, UserModel user, String paymentMethod) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFD1FAE5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF065F46), size: 44),
              ),
              const SizedBox(height: 16),
              Text(
                'Paiement validé avec succès ! 🎉',
                style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.ink),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Félicitations, votre inscription à "${course.title}" est confirmée.',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textMuted, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Montant réglé :', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted)),
                        Text(_getFormattedPrice(course.price), style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.emeraldGreenDark)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Moyen de paiement :', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted)),
                        Text(paymentMethod, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.ink)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Reçu officiel :', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted)),
                        Text('Disponible (Mes Paiements)', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.emeraldGreenDark)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.play_circle_filled_rounded, size: 18),
                  label: const Text('Commencer les cours immédiatement'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emeraldGreenDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    showDialog(
                      context: context,
                      builder: (_) => CoursePlayerDialog(course: course, userId: user.uid, onProgressUpdated: () {}),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamed(context, '/student-dashboard');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.emeraldGreenDark,
                    side: const BorderSide(color: AppTheme.emeraldGreen),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Accéder à mon espace étudiant & reçus'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // SAFE MEDIA BUILDERS (Robust across Network & Dynamic Assets)
  // -------------------------------------------------------------
  Widget _buildSafeAvatar(String? avatarUrl, String name, {double size = 50}) {
    final effective = avatarUrl?.trim() ?? '';
    if (effective.startsWith('http://') || effective.startsWith('https://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          effective,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitialAvatar(name, size: size),
        ),
      );
    }
    if (effective.isNotEmpty && effective.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.asset(
          effective,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitialAvatar(name, size: size),
        ),
      );
    }
    return _buildInitialAvatar(name, size: size);
  }

  Widget _buildInitialAvatar(String name, {double size = 50}) {
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').take(2).join()
        : 'PR';
    return Container(
      width: size,
      height: size,
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
            fontSize: size * 0.36,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSafeCover(CourseModel course, {double? width, double? height, BorderRadius? borderRadius}) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(12);
    final img = course.image.trim();
    final thumb = course.thumbnailUrl?.trim() ?? '';
    final url = img.startsWith('http') ? img : (thumb.startsWith('http') ? thumb : '');

    if (url.isNotEmpty) {
      return ClipRRect(
        borderRadius: effectiveRadius,
        child: Image.network(
          url,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackCourseCover(course, width: width, height: height, borderRadius: effectiveRadius),
        ),
      );
    }
    if (img.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: effectiveRadius,
        child: Image.asset(
          img,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackCourseCover(course, width: width, height: height, borderRadius: effectiveRadius),
        ),
      );
    }
    return _buildFallbackCourseCover(course, width: width, height: height, borderRadius: effectiveRadius);
  }

  Widget _buildFallbackCourseCover(CourseModel course, {double? width, double? height, BorderRadius? borderRadius}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF062C32), Color(0xFF0F4D42), Color(0xFF13C7A3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.school_rounded, color: Colors.white70, size: 28),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                course.title,
                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
