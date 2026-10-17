import '../../widgets/marketing_section_header.dart';
import '../../widgets/legal_documents_widget.dart';
import '../../widgets/voice_message_widgets.dart';
import '../../widgets/app_notification_bell.dart';
import '../../models/enrollment_model.dart';
import '../../services/enrollment_service.dart';
import '../../models/teacher_registration_model.dart';
import '../../services/teacher_registration_service.dart';
import '../../widgets/student_registration_card_dialog.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../../models/chat_model.dart';
import '../../models/course_model.dart';
import '../../models/live_session_model.dart';
import '../../models/progress_model.dart';
import '../../models/study_group_model.dart';
import '../../models/user_model.dart';
import '../../services/audio_recording_service.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/course_service.dart';
import '../../services/firebase_storage_service.dart';
import '../../services/live_session_service.dart';
import '../../services/livekit_service.dart';
import '../../services/progress_service.dart';
import '../../models/homework_model.dart';
import '../../services/homework_service.dart';
import '../../models/student_payment_model.dart';
import '../../services/student_payment_service.dart';
import '../group_chat_screen.dart';
import '../../services/study_group_service.dart';
import '../../services/trainer_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/certificate_dialog.dart';
import 'package:flutter/services.dart';
import '../../utils/fullscreen_web_helper.dart';
import '../../utils/youtube_helper.dart';
import '../../utils/file_download_helper.dart';
import '../../widgets/youtube_web_player.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();
  final ProgressService _progressService = ProgressService();
  final StudyGroupService _groupService = StudyGroupService();
  final LiveSessionService _liveService = LiveSessionService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  final AudioRecordingService _audioService = AudioRecordingService();
  final HomeworkService _homeworkService = HomeworkService();
  final StudentPaymentService _paymentService = StudentPaymentService();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _activeMenu = 'Tableau de bord';
  final _searchController = TextEditingController();

  // Active live session tracking
  LiveSessionModel? _activeLive;
  StreamSubscription? _liveSubscription;

  // Real-time progress map: courseId -> StudentProgressModel
  Map<String, StudentProgressModel> _userProgress = {};

  // Active chat state
  String? _selectedConversationId;
  String _selectedTrainerName = 'Formateur';
  bool _showMobileChatThread = false;
  final TextEditingController _chatMessageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  // Active group chat
  StudyGroupModel? _activeGroupChat;
  final TextEditingController _groupChatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _audioService.init();
    _loadUserProgress();
    _listenToActiveLives();
  }

  void _loadUserProgress() async {
    final user = _authService.currentUser ?? UserModel.demoStudent;
    final progressMap = await _progressService.getAllUserProgress(user.uid);
    if (mounted) setState(() => _userProgress = progressMap);
  }

  void _listenToActiveLives() {
    _liveSubscription = _liveService.getActiveLiveSessionsStream().listen((lives) {
      if (mounted) {
        setState(() {
          _activeLive = lives.isNotEmpty ? lives.first : null;
        });
      }
    });
  }

  @override
  void dispose() {
    _liveSubscription?.cancel();
    _chatMessageController.dispose();
    _groupChatController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ==========================================
  // 1. VIDEO PLAYER & LESSON PROGRESS MODAL
  // ==========================================
  void _openCoursePlayer(CourseModel course, {bool initialFullscreen = false}) {
    showDialog(
      context: context,
      builder: (ctx) => CoursePlayerDialog(
        course: course,
        userId: (_authService.currentUser ?? UserModel.demoStudent).uid,
        onProgressUpdated: () => _loadUserProgress(),
        initialFullscreen: initialFullscreen,
      ),
    );
  }

  // ==========================================
  // 2. LIVE SESSION VIEWER MODAL
  // ==========================================
  void _openLiveSessionModal(LiveSessionModel live) async {
    final user = _authService.currentUser ?? UserModel.demoStudent;
    await _liveService.joinLiveSession(live.id, user.uid);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => LiveViewerDialog(
        live: live,
        currentUser: user,
        onLeave: () => _liveService.leaveLiveSession(live.id, user.uid),
      ),
    );
  }

  // ==========================================
  // 3. MAIN BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1024;
    final user = _authService.currentUser ?? UserModel.demoStudent;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: !isDesktop ? Drawer(child: _buildSidebar(isMobileDrawer: true)) : null,
      bottomNavigationBar: !isDesktop ? _buildStudentBottomNavBar() : null,
      floatingActionButton: LegalDocumentsFAB(userId: user.uid),
      body: Row(
        children: [
          if (isDesktop) SizedBox(width: 240, child: _buildSidebar()),
          Expanded(
            child: Column(
              children: [
                _buildTopHeader(context, user, isDesktop),
                if (_activeLive != null) _buildLiveBanner(_activeLive!),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16, vertical: 24),
                    child: _buildDynamicBody(user, isDesktop),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentBottomNavBar() {
    final navItems = [
      {'title': 'Tableau de bord', 'icon': Icons.dashboard_rounded, 'label': 'Accueil'},
      {'title': 'Mes cours', 'icon': Icons.auto_stories_rounded, 'label': 'Cours'},
      {'title': 'Devoirs & Examens', 'icon': Icons.assignment_rounded, 'label': 'Devoirs'},
      {'title': 'Messages', 'icon': Icons.chat_bubble_outline_rounded, 'label': 'Messages'},
      {'title': 'Menu', 'icon': Icons.grid_view_rounded, 'label': 'Plus'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
        border: const Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: navItems.map((item) {
              final isMenu = item['title'] == 'Menu';
              final isSelected = !isMenu && _activeMenu == item['title'];
              return InkWell(
                onTap: () {
                  if (isMenu) {
                    _scaffoldKey.currentState?.openDrawer();
                  } else {
                    setState(() {
                      _activeMenu = item['title'] as String;
                    });
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        color: isSelected ? AppTheme.emeraldGreenDark : AppTheme.textMuted,
                        size: 22,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item['label'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                          color: isSelected ? AppTheme.emeraldGreenDark : AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveBanner(LiveSessionModel live) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFDC2626),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.sensors_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '🔴 EN DIRECT MAINTENANT : "${live.title}" par ${live.teacherName} (${live.participantCount} participant${live.participantCount > 1 ? 's' : ''})',
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow_rounded, size: 16),
            label: const Text('Rejoindre le direct'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.red[800],
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            ),
            onPressed: () => _openLiveSessionModal(live),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBackBanner() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          setState(() {
            if (_activeGroupChat != null) {
              _activeGroupChat = null;
            } else if (_activeMenu != 'Tableau de bord') {
              _activeMenu = 'Tableau de bord';
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushNamed(context, '/');
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_back_rounded, size: 18, color: AppTheme.emeraldGreenDark),
              const SizedBox(width: 8),
              Text(
                _activeMenu != 'Tableau de bord' ? 'Retour au tableau de bord' : 'Retour à l\'accueil',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.emeraldGreenDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicBody(UserModel user, bool isDesktop) {
    Widget content;
    switch (_activeMenu) {
      case 'Mes inscriptions':
        content = _buildMyRegistrationsView(user);
        break;
      case 'Mes cours':
        content = _buildFullCoursesView(user);
        break;
      case 'Devoirs & Examens':
        content = _buildHomeworksView(user);
        break;
      case 'Groupes d\'étude':
        content = _buildStudyGroupsView(user);
        break;
      case 'Mes Paiements':
        content = _buildPaymentsView(user);
        break;
      case 'Messages':
        content = _buildMessagesView(user);
        break;
      case 'Règlement & Documents':
        content = LegalDocumentsView(userId: user.uid);
        break;
      case 'Paramètres':
        content = _buildSettingsView(user);
        break;
      case 'Tableau de bord':
      default:
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreetingBanner(user),
            const SizedBox(height: 24),
            _buildStatCards(user),
            const SizedBox(height: 28),
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildActiveRegistrationsBanner(user),
                        _buildOngoingCoursesSection(user),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        _buildUpcomingDeadlinesSection(),
                        const SizedBox(height: 24),
                        _buildQuickStudyGroupWidget(user),
                      ],
                    ),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildActiveRegistrationsBanner(user),
                  _buildOngoingCoursesSection(user),
                  const SizedBox(height: 24),
                  _buildUpcomingDeadlinesSection(),
                  const SizedBox(height: 24),
                  _buildQuickStudyGroupWidget(user),
                ],
              ),
          ],
        );
    }

    if (!isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMobileBackBanner(),
          content,
        ],
      );
    }
    return content;
  }

  Widget _buildActiveRegistrationsBanner(UserModel user) {
    return StreamBuilder<List<TeacherStudentRegistrationModel>>(
      stream: TeacherRegistrationService().getStudentRegistrationsStream(user.uid),
      builder: (context, snapshot) {
        final regs = snapshot.data ?? [];
        if (regs.isEmpty) return const SizedBox.shrink();

        final latest = regs.first;
        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF062C32), Color(0xFF0F4C5C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF062C32).withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.mintAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded, size: 13, color: AppTheme.mintAccent),
                        const SizedBox(width: 5),
                        Text(
                          'INSCRIPTION CONFIRMÉE',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.mintAccent,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    latest.registrationNumber,
                    style: GoogleFonts.firaCode(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${latest.subject} — ${latest.studyLevel}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Professeur référent : ${latest.teacherName} • ${latest.proposedSchedule}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: const Color(0xFFD9ECE7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      StudentRegistrationCardDialog.show(context, registration: latest);
                    },
                    icon: const Icon(Icons.assignment_rounded, size: 15, color: AppTheme.emeraldGreenDark),
                    label: const Text('Voir ma fiche officielle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.emeraldGreenDark,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () {
                      setState(() => _activeMenu = 'Mes inscriptions');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      regs.length > 1 ? 'Voir toutes mes inscriptions (${regs.length})' : 'Gérer mon inscription',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // 4. ONGOING COURSES & ENROLLMENT (REAL PROGRESS)
  // ==========================================
  Widget _buildOngoingCoursesSection(UserModel user) {
    return Container(
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
              Text('Formations en cours', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.ink)),
              TextButton(
                onPressed: () => setState(() => _activeMenu = 'Mes cours'),
                child: Text('Voir tout', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.emeraldGreenDark)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          StreamBuilder<List<EnrollmentModel>>(
            stream: EnrollmentService().getUserEnrollmentsStream(user.uid),
            builder: (context, snapshot) {
              final enrollments = snapshot.data ?? [];
              if (enrollments.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.school_outlined, size: 40, color: AppTheme.textMuted),
                        const SizedBox(height: 10),
                        Text('Vous n\'avez pas encore de formation suivie.', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.ink)),
                        const SizedBox(height: 4),
                        const Text('Inscrivez-vous à un cours dans le catalogue pour démarrer votre apprentissage !', style: TextStyle(fontSize: 11, color: AppTheme.textMuted), textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldGreenDark, foregroundColor: Colors.white),
                          onPressed: () => Navigator.pushNamed(context, '/formations'),
                          child: const Text('Explorer le catalogue'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: enrollments.take(3).map((enrollment) {
                  final prog = _userProgress[enrollment.courseId]?.progressPercentage ?? 0.0;
                  final course = CourseModel.showcaseCourses.firstWhere(
                    (c) => c.id == enrollment.courseId,
                    orElse: () => CourseModel(
                      id: enrollment.courseId,
                      title: enrollment.courseTitle,
                      trainerName: enrollment.trainerName,
                      category: enrollment.category,
                      price: enrollment.price,
                      rating: 4.8,
                      image: enrollment.courseImage.isNotEmpty ? enrollment.courseImage : 'assets/images/course_default.jpg',
                      duration: 'Formation complète',
                    ),
                  );

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: enrollment.courseImage.startsWith('http')
                              ? Image.network(enrollment.courseImage, width: 64, height: 64, fit: BoxFit.cover)
                              : Image.asset(enrollment.courseImage, width: 64, height: 64, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(enrollment.courseTitle, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.ink), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text('${enrollment.trainerName} • Payé par ${enrollment.paymentMethod}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(99),
                                      child: LinearProgressIndicator(
                                        value: prog,
                                        minHeight: 6,
                                        backgroundColor: const Color(0xFFE2E8F0),
                                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.emeraldGreen),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text('${(prog * 100).round()}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.emeraldGreenDark)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.emeraldGreenDark,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          onPressed: () => _openCoursePlayer(course),
                          child: const Text('Continuer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ==========================================
  // DEVOIRS & EXAMENS (PAGE BLANCHE & PHOTO/WORD)
  // ==========================================
  Widget _buildHomeworksView(UserModel user) {
    return StreamBuilder<List<HomeworkModel>>(
      stream: _homeworkService.getHomeworksStream(),
      builder: (context, hwSnapshot) {
        final homeworks = hwSnapshot.data ?? [];
        return StreamBuilder<List<HomeworkSubmissionModel>>(
          stream: _homeworkService.getStudentSubmissionsStream(user.uid),
          builder: (context, subSnapshot) {
            final submissions = subSnapshot.data ?? [];
            final subMap = {for (var s in submissions) s.homeworkId: s};

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: MarketingSectionHeader(
                          badge: 'EXERCICES',
                          title: 'Rendez vos devoirs en ligne',
                          subtitle: 'Page blanche numérique, copies manuscrites ou documents Word.',
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.paleMint,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.assignment_turned_in_rounded, size: 16, color: AppTheme.emeraldGreenDark),
                            const SizedBox(width: 6),
                            Text(
                              '${submissions.length} rendu(s)',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.emeraldGreenDark),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (homeworks.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.assignment_outlined, size: 48, color: AppTheme.textMuted),
                          const SizedBox(height: 12),
                          Text('Aucun devoir assigné pour le moment', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.ink)),
                          const SizedBox(height: 4),
                          const Text('Les devoirs publiés par vos formateurs titulaires s\'afficheront ici.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: homeworks.map((hw) {
                        final submission = subMap[hw.id];
                        final isSubmitted = submission != null;
                        final isCorrected = submission?.status == 'corrected';
                        final isLate = !isSubmitted && DateTime.now().isAfter(hw.deadline);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isCorrected
                                  ? AppTheme.emeraldGreen.withValues(alpha: 0.4)
                                  : (isSubmitted ? const Color(0xFF60A5FA).withValues(alpha: 0.4) : AppTheme.cardBorder),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isCorrected
                                          ? AppTheme.paleMint
                                          : (isSubmitted ? const Color(0xFFEFF6FF) : const Color(0xFFFFFBEB)),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      isCorrected
                                          ? Icons.verified_rounded
                                          : (isSubmitted ? Icons.cloud_done_rounded : Icons.pending_actions_rounded),
                                      color: isCorrected
                                          ? AppTheme.emeraldGreenDark
                                          : (isSubmitted ? const Color(0xFF2563EB) : const Color(0xFFD97706)),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                hw.courseName,
                                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                'Par ${hw.teacherName}',
                                                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          hw.title,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.ink,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Status Badge
                                  if (isCorrected && submission != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFECFDF5),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: const Color(0xFFA7F3D0)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star_rounded, size: 16, color: Color(0xFF059669)),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Note : ${(submission.grade ?? submission.note ?? 18).toStringAsFixed(1)}/20',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12,
                                              color: Color(0xFF059669),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else if (isSubmitted)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFBFDBFE)),
                                      ),
                                      child: const Text(
                                        'Rendu (En attente du correcteur)',
                                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF1D4ED8)),
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: isLate ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: isLate ? const Color(0xFFFECACA) : const Color(0xFFFDE68A)),
                                      ),
                                      child: Text(
                                        isLate ? 'Délai dépassé' : 'À rendre',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                          color: isLate ? const Color(0xFFDC2626) : const Color(0xFFB45309),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                hw.instructions,
                                style: const TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.4),
                              ),
                              if (hw.attachmentUrls.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppTheme.cardBorder),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.attach_file_rounded, size: 16, color: AppTheme.emeraldGreenDark),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Documents & Fichiers du sujet (${hw.attachmentUrls.length}) :',
                                            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.ink),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: [
                                          for (int i = 0; i < hw.attachmentUrls.length; i++)
                                            InkWell(
                                              onTap: () => FileDownloadHelper.downloadOrOpenFile(
                                                hw.attachmentUrls[i],
                                                fileName: hw.getAttachmentName(i),
                                              ),
                                              borderRadius: BorderRadius.circular(8),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      FileDownloadHelper.getFileIcon(hw.getAttachmentName(i)),
                                                      size: 16,
                                                      color: FileDownloadHelper.getFileColor(hw.getAttachmentName(i)),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    ConstrainedBox(
                                                      constraints: const BoxConstraints(maxWidth: 240),
                                                      child: Text(
                                                        hw.getAttachmentName(i),
                                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.ink),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    const Icon(Icons.download_rounded, size: 14, color: AppTheme.emeraldGreenDark),
                                                  ],
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 14),
                              const Divider(height: 1, color: AppTheme.cardBorder),
                              const SizedBox(height: 12),

                              Wrap(
                                spacing: 12,
                                runSpacing: 10,
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.event_rounded, size: 15, color: AppTheme.textMuted),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Échéance : ${hw.deadline.day.toString().padLeft(2, '0')}/${hw.deadline.month.toString().padLeft(2, '0')}/${hw.deadline.year}',
                                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Barème : ${hw.points} pts',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (submission != null && isCorrected)
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.rate_review_rounded, size: 16),
                                      label: const Text('Voir la correction & remarques'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.emeraldGreenDark,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      onPressed: () => _showCorrectionFeedbackModal(hw, submission),
                                    )
                                  else if (submission != null)
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.visibility_rounded, size: 16),
                                      label: const Text('Voir ma copie déposée'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFF2563EB),
                                        side: const BorderSide(color: Color(0xFF93C5FD)),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      onPressed: () => _showSubmissionReviewModal(hw, submission),
                                    )
                                  else
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.edit_note_rounded, size: 18),
                                      label: const Text('Composer / Rendre mon devoir'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.emeraldGreenDark,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      onPressed: () => _showSubmitHomeworkModal(hw, user),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSubmitHomeworkModal(HomeworkModel hw, UserModel user) {
    int activeTab = 0; // 0: Page blanche, 1: Téléverser feuille/Word
    final textController = TextEditingController();
    Uint8List? fileBytes;
    String? fileName;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            width: 720,
            constraints: const BoxConstraints(maxHeight: 700),
            padding: const EdgeInsets.all(24),
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
                          Text('Rendre le devoir', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.ink)),
                          Text('${hw.title} • ${hw.courseName}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                if (hw.attachmentUrls.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.paleMint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.attach_file_rounded, size: 16, color: AppTheme.emeraldGreenDark),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Sujet joint : ${hw.getAttachmentName(0)}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.emeraldGreenDark),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                          icon: const Icon(Icons.download_rounded, size: 16, color: AppTheme.emeraldGreenDark),
                          label: const Text('Télécharger le sujet', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.emeraldGreenDark)),
                          onPressed: () => FileDownloadHelper.downloadOrOpenFile(hw.attachmentUrls.first, fileName: hw.getAttachmentName(0)),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Choice Tabs
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(() => activeTab = 0),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: activeTab == 0 ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: activeTab == 0 ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.article_rounded, size: 16, color: activeTab == 0 ? AppTheme.emeraldGreenDark : AppTheme.textMuted),
                                const SizedBox(width: 8),
                                Text(
                                  'Page blanche en ligne',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: activeTab == 0 ? AppTheme.emeraldGreenDark : AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(() => activeTab = 1),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: activeTab == 1 ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: activeTab == 1 ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.upload_file_rounded, size: 16, color: activeTab == 1 ? AppTheme.emeraldGreenDark : AppTheme.textMuted),
                                const SizedBox(width: 8),
                                Text(
                                  'Feuille propre / Word / PDF',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: activeTab == 1 ? AppTheme.emeraldGreenDark : AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Body based on activeTab
                Expanded(
                  child: activeTab == 0
                      ? Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAFAFA),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.cardBorder),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.edit_note_rounded, size: 18, color: AppTheme.emeraldGreenDark),
                                  SizedBox(width: 6),
                                  Text(
                                    'Page blanche d\'examen (saisissez vos réponses et développements) :',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.ink),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Expanded(
                                child: TextField(
                                  controller: textController,
                                  maxLines: null,
                                  expands: true,
                                  textAlignVertical: TextAlignVertical.top,
                                  style: GoogleFonts.sourceCodePro(fontSize: 13, height: 1.5, color: const Color(0xFF1E293B)),
                                  decoration: const InputDecoration(
                                    hintText: 'Écrivez ici vos réponses, démonstrations, code ou analyse...',
                                    border: InputBorder.none,
                                    hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAFAFA),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.cardBorder),
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.cloud_upload_outlined, size: 48, color: AppTheme.emeraldGreenDark),
                              const SizedBox(height: 12),
                              Text(
                                'Téléverser votre copie d\'examen',
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.ink),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Prenez en photo votre feuille propre (calculs, schémas, maths/physique)\nou joignez votre document Word (.docx, .doc) ou PDF.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              ),
                              const SizedBox(height: 20),
                              if (fileName != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.paleMint,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.check_circle_rounded, color: AppTheme.emeraldGreenDark, size: 18),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          fileName!,
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.emeraldGreenDark),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.file_open_rounded, size: 18),
                                  label: const Text('Choisir un fichier'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppTheme.ink,
                                    side: const BorderSide(color: AppTheme.cardBorder),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () async {
                                    final res = await FilePicker.platform.pickFiles(
                                      type: FileType.custom,
                                      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'zip', 'rar', 'txt'],
                                      withData: true,
                                    );
                                    if (res != null && res.files.isNotEmpty) {
                                      setModalState(() {
                                        fileBytes = res.files.first.bytes;
                                        fileName = res.files.first.name;
                                      });
                                    }
                                  },
                                ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 20),

                // Footer Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emeraldGreenDark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final text = textController.text.trim();
                              if (activeTab == 0 && text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Veuillez saisir votre copie sur la page blanche.')),
                                );
                                return;
                              }
                              if (activeTab == 1 && fileBytes == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Veuillez choisir un fichier (photo ou Word/PDF).')),
                                );
                                return;
                              }

                              setModalState(() => isSubmitting = true);

                              String? uploadedUrl;
                              String submissionType = activeTab == 0 ? 'blank_page' : 'word_document';

                              if (activeTab == 1 && fileBytes != null) {
                                final ext = fileName?.split('.').last.toLowerCase() ?? '';
                                if (['jpg', 'jpeg', 'png'].contains(ext)) {
                                  submissionType = 'photo_sheet';
                                }
                                uploadedUrl = await _storageService.uploadHomeworkAttachment(
                                  homeworkId: hw.id,
                                  bytes: fileBytes!,
                                  fileName: fileName ?? 'copie_$ext',
                                );
                              }

                              await _homeworkService.submitHomework(
                                homeworkId: hw.id,
                                studentId: user.uid,
                                studentName: user.displayName,
                                submissionType: submissionType,
                                blankPageContent: activeTab == 0 ? text : null,
                                fileUrl: uploadedUrl,
                                attachmentName: fileName,
                              );

                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Votre copie a été déposée avec succès ! Le correcteur va l\'examiner.'),
                                    backgroundColor: AppTheme.emeraldGreenDark,
                                  ),
                                );
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Valider et envoyer ma copie', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSubmissionReviewModal(HomeworkModel hw, HomeworkSubmissionModel sub) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Ma copie déposée', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16)),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Devoir : ${hw.title}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 4),
              Text('Déposé le ${sub.submittedAt.day.toString().padLeft(2, '0')}/${sub.submittedAt.month.toString().padLeft(2, '0')}/${sub.submittedAt.year}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              const SizedBox(height: 16),
              if (sub.blankPageContent != null && sub.blankPageContent!.isNotEmpty) ...[
                const Text('Contenu rédigé sur page blanche :', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 250),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: SingleChildScrollView(
                    child: Text(sub.blankPageContent!, style: GoogleFonts.sourceCodePro(fontSize: 12, height: 1.4)),
                  ),
                ),
              ],
              if (sub.attachmentName != null || sub.fileUrl != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.attach_file_rounded, size: 16, color: AppTheme.emeraldGreenDark),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(sub.attachmentName ?? 'Document joint', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    if (sub.fileUrl != null && sub.fileUrl!.isNotEmpty)
                      TextButton(
                        onPressed: () => launchUrl(Uri.parse(sub.fileUrl!)),
                        child: const Text('Ouvrir / Télécharger'),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldGreenDark, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showCorrectionFeedbackModal(HomeworkModel hw, HomeworkSubmissionModel sub) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.verified_rounded, color: AppTheme.emeraldGreenDark, size: 24),
            const SizedBox(width: 8),
            Text('Évaluation & Remarques', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Devoir : ${hw.title}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.military_tech_rounded, size: 36, color: Color(0xFF059669)),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Note attribuée', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF047857))),
                        Text(
                          '${sub.grade != null ? sub.grade!.toStringAsFixed(1) : (sub.note != null ? sub.note!.toStringAsFixed(1) : "18")} / 20',
                          style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w900, color: const Color(0xFF065F46)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Observations du Correcteur (${sub.correctedBy ?? "Équipe pédagogique"}) :',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.ink),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Text(
                  sub.feedback ?? sub.comment ?? 'Très bon travail dans l\'ensemble. Les calculs et les explications sont clairs et rigoureux.',
                  style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF334155)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldGreenDark, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MES PAIEMENTS & REÇUS OFFICIELS
  // ==========================================
  Widget _buildPaymentsView(UserModel user) {
    return StreamBuilder<List<StudentPaymentModel>>(
      stream: _paymentService.getStudentPaymentsStream(user.uid),
      builder: (context, snapshot) {
        final payments = snapshot.data ?? [];
        final totalPaid = payments.fold<int>(0, (sum, p) => sum + p.amount);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
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
                          'Mes Paiements & Scolarité',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Consultez vos mensualités réglées, téléchargez vos reçus officiels et régularisez vos frais d\'études.',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.payment_rounded, size: 18),
                    label: const Text('Payer une mensualité'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emeraldGreenDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _showMakePaymentDialog(user),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // KPI Stats
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildPaymentKpiCard(
                    title: 'Total Réglé',
                    value: '$totalPaid FCFA',
                    icon: Icons.account_balance_wallet_rounded,
                    color: AppTheme.emeraldGreenDark,
                    bgColor: AppTheme.paleMint,
                  ),
                  _buildPaymentKpiCard(
                    title: 'Mois Payés',
                    value: '${payments.length} mensualité(s)',
                    icon: Icons.calendar_month_rounded,
                    color: const Color(0xFF2563EB),
                    bgColor: const Color(0xFFEFF6FF),
                  ),
                  _buildPaymentKpiCard(
                    title: 'Statut de Scolarité',
                    value: 'À jour ✅',
                    icon: Icons.verified_user_rounded,
                    color: const Color(0xFF059669),
                    bgColor: const Color(0xFFECFDF5),
                  ),
                  _buildPaymentKpiCard(
                    title: 'Prochaine Échéance',
                    value: '05 Novembre 2026',
                    icon: Icons.alarm_rounded,
                    color: const Color(0xFFD97706),
                    bgColor: const Color(0xFFFFFBEB),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Payments List
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Historique des règlements', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.ink)),
                    const SizedBox(height: 16),
                    if (payments.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: Text('Aucun paiement enregistré pour le moment.', style: TextStyle(color: AppTheme.textMuted)),
                        ),
                      )
                    else
                      Column(
                        children: payments.map((p) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.cardBorder),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppTheme.cardBorder),
                                  ),
                                  child: const Icon(Icons.receipt_rounded, color: AppTheme.emeraldGreenDark, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.monthLabel,
                                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.ink),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Réf : ${p.receiptNumber} • ${p.paymentMethod}',
                                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${p.amount} FCFA',
                                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.ink),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${p.paidAt.day.toString().padLeft(2, '0')}/${p.paidAt.month.toString().padLeft(2, '0')}/${p.paidAt.year}',
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.download_rounded, size: 14),
                                  label: const Text('Reçu officiel'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppTheme.emeraldGreenDark,
                                    side: const BorderSide(color: AppTheme.emeraldGreenDark),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    elevation: 0,
                                  ),
                                  onPressed: () => _showReceiptDialog(p, user),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.ink)),
        ],
      ),
    );
  }

  void _showMakePaymentDialog(UserModel user) {
    String selectedMonth = 'Novembre 2026';
    String paymentMethod = 'Wave';
    final phoneCtrl = TextEditingController(text: user.phoneNumber);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Payer une mensualité', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16)),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sélectionnez le mois à régler :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedMonth,
                  items: const [
                    DropdownMenuItem(value: 'Novembre 2026', child: Text('Novembre 2026 (15 000 FCFA)')),
                    DropdownMenuItem(value: 'Décembre 2026', child: Text('Décembre 2026 (15 000 FCFA)')),
                    DropdownMenuItem(value: 'Janvier 2027', child: Text('Janvier 2027 (15 000 FCFA)')),
                  ],
                  onChanged: (v) => setModalState(() => selectedMonth = v ?? selectedMonth),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Moyen de paiement :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: ['Wave', 'Orange Money', 'Carte bancaire'].map((m) {
                    final isSel = paymentMethod == m;
                    return ChoiceChip(
                      label: Text(m, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isSel ? Colors.white : AppTheme.ink)),
                      selected: isSel,
                      selectedColor: AppTheme.emeraldGreenDark,
                      onSelected: (_) => setModalState(() => paymentMethod = m),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: phoneCtrl,
                  decoration: InputDecoration(
                    labelText: paymentMethod == 'Carte bancaire' ? 'Numéro de carte' : 'Numéro de téléphone',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldGreenDark, foregroundColor: Colors.white),
              onPressed: () async {
                final ref = 'CDF-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                await _paymentService.recordPayment(
                  studentId: user.uid,
                  studentName: user.displayName,
                  monthLabel: selectedMonth,
                  amount: 15000,
                  paymentMethod: paymentMethod,
                  transactionRef: ref,
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Paiement de 15 000 FCFA validé pour $selectedMonth !'),
                      backgroundColor: AppTheme.emeraldGreenDark,
                    ),
                  );
                }
              },
              child: const Text('Confirmer le paiement (15 000 FCFA)'),
            ),
          ],
        ),
      ),
    );
  }

  void _showReceiptDialog(StudentPaymentModel p, UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset('assets/images/logo.png', width: 32, height: 32, fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 8),
                      Text('Club des Formateurs', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.paleMint,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('REÇU OFFICIEL', style: TextStyle(color: AppTheme.emeraldGreenDark, fontWeight: FontWeight.w800, fontSize: 10)),
                  ),
                ],
              ),
              const Divider(height: 24),

              Text('ATTESTATION DE RÈGLEMENT', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.ink)),
              const SizedBox(height: 4),
              Text('Reçu N° ${p.receiptNumber}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  children: [
                    _receiptRow('Apprenant', p.studentName),
                    const SizedBox(height: 8),
                    _receiptRow('Mois de scolarité', p.monthLabel),
                    const SizedBox(height: 8),
                    _receiptRow('Montant payé', '${p.amount} FCFA'),
                    const SizedBox(height: 8),
                    _receiptRow('Date de règlement', '${p.paidAt.day.toString().padLeft(2, '0')}/${p.paidAt.month.toString().padLeft(2, '0')}/${p.paidAt.year}'),
                    const SizedBox(height: 8),
                    _receiptRow('Moyen de paiement', p.paymentMethod),
                    const SizedBox(height: 8),
                    _receiptRow('Réf. transaction', p.transactionRef),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Stamp
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF059669), width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.verified_rounded, color: Color(0xFF059669), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'DIRECTION DES ÉTUDES - CERTIFIÉ CONFORME',
                      style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w800, fontSize: 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.print_rounded, size: 16),
                    label: const Text('Imprimer / Sauvegarder PDF'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldGreenDark, foregroundColor: Colors.white),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Le reçu officiel a été téléchargé avec succès !')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.ink)),
      ],
    );
  }

  Widget _buildMyRegistrationsView(UserModel user) {
    final currency = NumberFormat('#,###', 'fr_FR');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MarketingSectionHeader(
            badge: 'INSCRIPTIONS EN DIRECT',
            title: 'Mes inscriptions auprès des professeurs',
            subtitle: 'Consultez vos fiches d\'inscription officielles, emplois du temps et statuts de validation.',
            actionLabel: 'Choisir un professeur',
            actionIcon: Icons.person_search_rounded,
            onAction: () => Navigator.pushNamed(context, '/trainers'),
          ),
          const SizedBox(height: 24),
          StreamBuilder<List<TeacherStudentRegistrationModel>>(
            stream: TeacherRegistrationService().getStudentRegistrationsStream(user.uid),
            builder: (context, snapshot) {
              final registrations = snapshot.data ?? [];
              if (snapshot.connectionState == ConnectionState.waiting && registrations.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AppTheme.emeraldGreen),
                  ),
                );
              }

              if (registrations.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
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
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: const BoxDecoration(
                          color: AppTheme.paleMint,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.how_to_reg_outlined, size: 48, color: AppTheme.emeraldGreenDark),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune inscription active pour le moment',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Choisissez un professeur référent dans notre catalogue pour vous inscrire directement à ses cours.',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/trainers'),
                        icon: const Icon(Icons.school_rounded, size: 16, color: Colors.white),
                        label: const Text('Parcourir la liste des formateurs'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.emeraldGreenDark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: registrations.map((reg) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10233F).withValues(alpha: 0.05),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Registration Number & Status Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Text(
                                    reg.registrationNumber,
                                    style: GoogleFonts.firaCode(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.emeraldGreenDark,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Année : ${reg.academicYear}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    color: AppTheme.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF86EFAC)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF16A34A)),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Statut : ${reg.status}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF166534),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Row 2: Subject & Level (e.g. "Mathématiques — L3")
                        Text(
                          '${reg.subject} — ${reg.studyLevel}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.ink,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Row 3: Teacher info
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppTheme.paleMint,
                              backgroundImage: reg.teacherPhoto.startsWith('http')
                                  ? NetworkImage(reg.teacherPhoto)
                                  : null,
                              child: !reg.teacherPhoto.startsWith('http')
                                  ? Text(
                                      reg.teacherName.isNotEmpty ? reg.teacherName[0].toUpperCase() : 'P',
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppTheme.emeraldGreenDark),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            RichText(
                              text: TextSpan(
                                text: 'Professeur : ',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: AppTheme.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                                children: [
                                  TextSpan(
                                    text: reg.teacherName,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Info grid: Schedule, Filière, Payment
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.access_time_filled_rounded, size: 15, color: Color(0xFF0F766E)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        text: 'Emploi du temps : ',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: const Color(0xFF64748B),
                                          fontWeight: FontWeight.w600,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: reg.proposedSchedule,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.emeraldGreenDark,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.menu_book_rounded, size: 15, color: Color(0xFF64748B)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Filière : ${reg.fieldOfStudy}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: const Color(0xFF475569),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Réglé : ${currency.format(reg.fee)} FCFA (${reg.paymentMethod})',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF16A34A),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Action Buttons
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                StudentRegistrationCardDialog.show(context, registration: reg);
                              },
                              icon: const Icon(Icons.assignment_rounded, size: 16, color: Colors.white),
                              label: const Text('Voir ma fiche d\'inscription'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.emeraldGreenDark,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                    title: Row(
                                      children: [
                                        const Icon(Icons.access_time_filled_rounded, color: AppTheme.emeraldGreenDark),
                                        const SizedBox(width: 10),
                                        Text('Emploi du temps', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16)),
                                      ],
                                    ),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Cours : ${reg.subject} (${reg.studyLevel})', style: const TextStyle(fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 6),
                                        Text('Professeur : ${reg.teacherName}', style: const TextStyle(color: AppTheme.textMuted)),
                                        const SizedBox(height: 14),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: AppTheme.paleMint,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            reg.proposedSchedule,
                                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppTheme.emeraldGreenDark, fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
                                    ],
                                  ),
                                );
                              },
                              icon: const Icon(Icons.schedule_rounded, size: 16),
                              label: const Text('Emploi du temps'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.ink,
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () {
                                setState(() => _activeMenu = 'Mes cours');
                              },
                              icon: const Icon(Icons.auto_stories_rounded, size: 16),
                              label: const Text('Mes cours'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.ink,
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () {
                                setState(() => _activeMenu = 'Mes Paiements');
                              },
                              icon: const Icon(Icons.receipt_long_rounded, size: 16),
                              label: const Text('Historique de paiement'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.ink,
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _activeMenu = 'Messages';
                                  _selectedTrainerName = reg.teacherName;
                                });
                              },
                              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                              label: const Text('Contacter le professeur'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.ink,
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFullCoursesView(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(24),
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
              Text('Toutes mes formations inscrites', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.ink)),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                label: const Text('Découvrir d\'autres formations'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldGreenDark, foregroundColor: Colors.white),
                onPressed: () => Navigator.pushNamed(context, '/formations'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          StreamBuilder<List<EnrollmentModel>>(
            stream: EnrollmentService().getUserEnrollmentsStream(user.uid),
            builder: (context, snapshot) {
              final enrollments = snapshot.data ?? [];
              if (enrollments.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Icon(Icons.menu_book_rounded, size: 48, color: AppTheme.textMuted),
                        const SizedBox(height: 12),
                        Text('Aucune formation achetée pour le moment.', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 6),
                        const Text('Explorez le catalogue pour vous inscrire à des formations certifiées.', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldGreenDark, foregroundColor: Colors.white),
                          onPressed: () => Navigator.pushNamed(context, '/formations'),
                          child: const Text('Consulter le catalogue'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: enrollments.map((enrollment) {
                  final prog = _userProgress[enrollment.courseId]?.progressPercentage ?? 0.0;
                  final course = CourseModel.showcaseCourses.firstWhere(
                    (c) => c.id == enrollment.courseId,
                    orElse: () => CourseModel(
                      id: enrollment.courseId,
                      title: enrollment.courseTitle,
                      trainerName: enrollment.trainerName,
                      category: enrollment.category,
                      price: enrollment.price,
                      rating: 4.8,
                      image: enrollment.courseImage.isNotEmpty ? enrollment.courseImage : 'assets/images/course_default.jpg',
                      duration: 'Formation complète',
                    ),
                  );

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: enrollment.courseImage.startsWith('http')
                              ? Image.network(enrollment.courseImage, width: 70, height: 70, fit: BoxFit.cover)
                              : Image.asset(enrollment.courseImage, width: 70, height: 70, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(enrollment.courseTitle, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.ink)),
                              Text('${enrollment.category} • Par ${enrollment.trainerName} • Payé par ${enrollment.paymentMethod}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(99),
                                      child: LinearProgressIndicator(
                                        value: prog,
                                        minHeight: 6,
                                        backgroundColor: const Color(0xFFE2E8F0),
                                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.emeraldGreen),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text('${(prog * 100).round()}% terminé', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.emeraldGreenDark)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.workspace_premium_rounded, size: 16, color: Color(0xFFD97706)),
                          label: const Text('Certificat QR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFB45309))),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFF59E0B)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => CertificateDialog(
                                studentName: user.displayName,
                                courseTitle: enrollment.courseTitle,
                                trainerName: enrollment.trainerName,
                                certificateNumber: 'CDF-2026-${enrollment.courseId.toUpperCase()}-${user.uid.hashCode.abs().toString().substring(0, 4)}',
                                issuedAt: enrollment.enrolledAt,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.play_circle_filled_rounded, size: 18),
                          label: const Text('Accéder au cours'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.emeraldGreenDark,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _openCoursePlayer(course),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 5. STUDY GROUPS VIEW & JOIN REQUESTS
  // ==========================================
  Widget _buildStudyGroupsView(UserModel user) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 10,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Groupes d\'étude et entraide',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.ink,
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.group_add_rounded, size: 18),
              label: Text(isMobile ? 'Créer un groupe' : 'Créer un groupe d\'étude'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emeraldGreenDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _showCreateGroupModal(user),
            ),
          ],
        ),
        const SizedBox(height: 20),

        StreamBuilder<List<StudyGroupModel>>(
          stream: _groupService.getStudyGroupsStream(),
          builder: (context, snapshot) {
            final groups = snapshot.data ?? [];
            if (groups.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.groups_outlined, size: 48, color: AppTheme.textMuted),
                    const SizedBox(height: 12),
                    Text(
                      'Aucun groupe d\'étude pour le moment',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Soyez le premier à créer un groupe d\'entraide avec d\'autres apprenants !',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showCreateGroupModal(user),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Créer le premier groupe'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emeraldGreenDark,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: groups.map((group) => _buildStudyGroupCard(group, user)).toList(),
            );
          },
        ),
      ],
    );
  }

  void _showCreateGroupModal(UserModel user) async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final courseCtrl = TextEditingController();
    String joinMode = 'open';

    final courses = await CourseService().getPopularCourses();
    String? selectedCourseId = courses.isNotEmpty ? courses.first.id : null;
    String selectedCourseTitle = courses.isNotEmpty ? courses.first.title : 'Général';

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Créer un groupe d\'étude',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nom du groupe *',
                    hintText: 'Ex: Entraide & Projets Pratiques',
                  ),
                ),
                const SizedBox(height: 12),
                if (courses.isNotEmpty) ...[
                  const Text('Formation associée :', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: selectedCourseId,
                    isExpanded: true,
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                    items: courses.map((c) => DropdownMenuItem(value: c.id, child: Text(c.title, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        final found = courses.firstWhere((c) => c.id == val, orElse: () => courses.first);
                        setModalState(() {
                          selectedCourseId = val;
                          selectedCourseTitle = found.title;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  TextField(
                    controller: courseCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Sujet ou cours associé',
                      hintText: 'Ex: Programmation, Marketing...',
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Objectifs et description',
                    hintText: 'Révisions en commun, entraide sur les devoirs...',
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('Mode d\'adhésion : ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ChoiceChip(
                      label: const Text('Libre (Ouvert)'),
                      selected: joinMode == 'open',
                      onSelected: (_) => setModalState(() => joinMode = 'open'),
                      selectedColor: AppTheme.emeraldGreen,
                      labelStyle: TextStyle(color: joinMode == 'open' ? Colors.white : AppTheme.ink),
                    ),
                    ChoiceChip(
                      label: const Text('Sur validation'),
                      selected: joinMode == 'request',
                      onSelected: (_) => setModalState(() => joinMode = 'request'),
                      selectedColor: const Color(0xFFD97706),
                      labelStyle: TextStyle(color: joinMode == 'request' ? Colors.white : AppTheme.ink),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldGreenDark, foregroundColor: Colors.white),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;

                final finalTitle = courses.isNotEmpty
                    ? selectedCourseTitle
                    : (courseCtrl.text.trim().isNotEmpty ? courseCtrl.text.trim() : 'Général');
                final finalCourseId = selectedCourseId ?? 'course_general';

                await _groupService.createGroup(
                  name: name,
                  description: descCtrl.text.trim(),
                  courseId: finalCourseId,
                  courseTitle: finalTitle,
                  creatorId: user.uid,
                  creatorName: user.displayName,
                  creatorPhoto: user.photoUrl ?? '',
                  joinMode: joinMode,
                );

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Groupe "$name" créé avec succès !'), backgroundColor: AppTheme.emeraldGreen),
                  );
                }
              },
              child: const Text('Créer le groupe'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudyGroupCard(StudyGroupModel group, UserModel user) {
    final isMember = group.isMember(user.uid);
    final isCreator = group.isCreator(user.uid);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
                    Text(group.name, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.ink)),
                    const SizedBox(height: 2),
                    Text('Cours : ${group.courseTitle} • Créé par ${group.creatorName}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: group.joinMode == 'open' ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  group.joinMode == 'open' ? 'Accès libre' : 'Sur demande',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: group.joinMode == 'open' ? const Color(0xFF065F46) : const Color(0xFFB45309)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(group.description, style: const TextStyle(fontSize: 13, color: AppTheme.ink)),
          const SizedBox(height: 14),

          // Actions
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('👥 ${group.members.length} / ${group.maxMembers} membres', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
              if (isMember) ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                  label: const Text('Ouvrir la discussion'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldGreenDark, foregroundColor: Colors.white),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GroupChatScreen(group: group),
                    ),
                  ),
                ),
              ] else ...[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldGreenDark, foregroundColor: Colors.white),
                  onPressed: () async {
                    await _groupService.requestToJoinGroup(
                      groupId: group.id,
                      userId: user.uid,
                      userName: user.displayName,
                      userPhoto: user.photoUrl ?? '',
                      isOpen: group.joinMode == 'open',
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(group.joinMode == 'open' ? 'Vous avez rejoint le groupe !' : 'Demande d\'adhésion envoyée au créateur.'),
                          backgroundColor: AppTheme.emeraldGreen,
                        ),
                      );
                    }
                  },
                  child: Text(group.joinMode == 'open' ? 'Rejoindre le groupe' : 'Demander à rejoindre'),
                ),
              ],
            ],
          ),

          // Pending join requests section for group creator
          if (isCreator) ...[
            const Divider(height: 24),
            StreamBuilder<List<GroupJoinRequestModel>>(
              stream: _groupService.getPendingRequestsStream(group.id),
              builder: (context, reqSnapshot) {
                final requests = reqSnapshot.data ?? [];
                if (requests.isEmpty) {
                  return const Text('Aucune demande d\'adhésion en attente.', style: TextStyle(fontSize: 12, color: AppTheme.textMuted));
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Demandes d\'adhésion en attente (${requests.length}) :', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.ink)),
                    const SizedBox(height: 8),
                    ...requests.map((req) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
                          child: Row(
                            children: [
                              Text(req.userName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                              const Spacer(),
                              TextButton(
                                onPressed: () => _groupService.rejectJoinRequest(groupId: group.id, requestId: req.id),
                                child: const Text('Refuser', style: TextStyle(color: Colors.red, fontSize: 12)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                                onPressed: () => _groupService.acceptJoinRequest(
                                  groupId: group.id,
                                  requestId: req.id,
                                  userId: req.userId,
                                  userName: req.userName,
                                  userPhoto: req.userPhoto,
                                ),
                                child: const Text('Accepter', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        )),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  void _openGroupChatModal(StudyGroupModel group, UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setChatState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 550,
            height: 600,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Salon : ${group.name}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16)),
                    IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: StreamBuilder<List<MessageModel>>(
                    stream: _chatService.getGroupMessagesStream(group.id),
                    builder: (context, snapshot) {
                      final msgs = snapshot.data ?? [];
                      if (msgs.isEmpty) {
                        return const Center(child: Text('Bienvenue dans le salon du groupe ! Démarrez l\'échange.'));
                      }
                      return ListView.builder(
                        itemCount: msgs.length,
                        itemBuilder: (context, index) {
                          final m = msgs[index];
                          final isMe = m.senderId == user.uid;
                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isMe ? AppTheme.emeraldGreenDark : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isMe) Text(m.senderName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10, color: AppTheme.emeraldGreenDark)),
                                  Text(m.content, style: TextStyle(color: isMe ? Colors.white : AppTheme.ink, fontSize: 13)),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _groupChatController,
                        decoration: const InputDecoration(hintText: 'Votre message...', border: OutlineInputBorder()),
                        onSubmitted: (_) {
                          final text = _groupChatController.text.trim();
                          if (text.isNotEmpty) {
                            _chatService.sendGroupMessage(
                              groupId: group.id,
                              senderId: user.uid,
                              senderName: user.displayName,
                              senderRole: 'student',
                              content: text,
                            );
                            _groupChatController.clear();
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send_rounded, color: AppTheme.emeraldGreenDark),
                      onPressed: () {
                        final text = _groupChatController.text.trim();
                        if (text.isNotEmpty) {
                          _chatService.sendGroupMessage(
                            groupId: group.id,
                            senderId: user.uid,
                            senderName: user.displayName,
                            senderRole: 'student',
                            content: text,
                          );
                          _groupChatController.clear();
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 6. MESSAGES VIEW (100% DYNAMIQUE & PERSISTANT)
  // ==========================================
  String _formatChatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.day == yesterday.day && dt.month == yesterday.month && dt.year == yesterday.year) {
      return 'Hier';
    }
    return '${dt.day}/${dt.month}';
  }

  void _showNewConversationDialog(UserModel user) async {
    final trainers = await TrainerService().getExpertTrainers();
    final courses = await CourseService().getPopularCourses();

    final contacts = <Map<String, String>>[];
    for (final t in trainers) {
      contacts.add({
        'id': t.id,
        'name': t.name,
        'role': t.role,
        'avatar': t.image,
        'course': t.role,
      });
    }
    for (final c in courses) {
      if (!contacts.any((ct) => ct['name'] == c.trainerName)) {
        contacts.add({
          'id': c.teacherId,
          'name': c.trainerName,
          'role': c.trainerRole,
          'avatar': c.trainerAvatar ?? '',
          'course': c.title,
        });
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.add_comment_rounded, color: AppTheme.emeraldGreenDark),
            const SizedBox(width: 8),
            Text('Nouvelle discussion', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choisissez un formateur pour démarrer une conversation :',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 12),
              if (contacts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('Aucun formateur disponible pour le moment.', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: contacts.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final c = contacts[index];
                      final name = c['name'] ?? 'Formateur';
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.paleMint,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'F',
                            style: const TextStyle(color: AppTheme.emeraldGreenDark, fontWeight: FontWeight.w700),
                          ),
                        ),
                        title: Text(name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
                        subtitle: Text(c['role'] ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        onTap: () async {
                          Navigator.pop(ctx);
                          final convId = await _chatService.getOrCreateConversation(
                            currentUserId: user.uid,
                            currentUserName: user.displayName,
                            currentUserPhoto: user.photoUrl ?? '',
                            targetUserId: c['id']!,
                            targetUserName: name,
                            targetUserPhoto: c['avatar'] ?? '',
                            courseName: c['course'] ?? '',
                          );
                          setState(() {
                            _selectedConversationId = convId;
                            _selectedTrainerName = name;
                          });
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesView(UserModel user) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    final convsListWidget = SizedBox(
      width: isMobile ? double.infinity : 290,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.forum_rounded, color: AppTheme.emeraldGreenDark, size: 20),
                    const SizedBox(width: 8),
                    Text('Discussions', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.ink)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.add_comment_rounded, color: AppTheme.emeraldGreenDark, size: 20),
                  tooltip: 'Nouvelle discussion',
                  onPressed: () => _showNewConversationDialog(user),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.cardBorder),
          Expanded(
            child: StreamBuilder<List<ConversationModel>>(
              stream: _chatService.getUserConversationsStream(user.uid),
              builder: (context, snapshot) {
                final conversations = snapshot.data ?? [];
                if (conversations.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.textMuted, size: 36),
                          const SizedBox(height: 8),
                          const Text('Aucune discussion active.', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add, size: 14),
                            label: const Text('Démarrer', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.emeraldGreenDark,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            ),
                            onPressed: () => _showNewConversationDialog(user),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Auto-select first conversation if none selected (on desktop)
                if (_selectedConversationId == null && conversations.isNotEmpty && !isMobile) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _selectedConversationId == null) {
                      setState(() {
                        _selectedConversationId = conversations.first.id;
                        _selectedTrainerName = conversations.first.getOtherUserName(user.uid);
                      });
                    }
                  });
                }

                return ListView.separated(
                  itemCount: conversations.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (context, index) {
                    final conv = conversations[index];
                    final otherName = conv.getOtherUserName(user.uid);
                    final isSelected = _selectedConversationId == conv.id;
                    final initial = otherName.isNotEmpty ? otherName[0].toUpperCase() : 'F';
                    final isCorrector = otherName.toLowerCase().contains('correcteur') || conv.id.contains('corr');

                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: const Color(0xFFF0FDF4),
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            backgroundColor: isSelected ? AppTheme.emeraldGreenDark : AppTheme.paleMint,
                            child: Text(
                              initial,
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppTheme.emeraldGreenDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: isCorrector ? const Color(0xFF3B82F6) : AppTheme.emeraldGreen,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              otherName,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppTheme.ink,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatChatTime(conv.lastMessageAt),
                            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                      subtitle: Row(
                        children: [
                          if (isCorrector) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDBEAFE),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('Correcteur', style: TextStyle(fontSize: 8, color: Color(0xFF1D4ED8), fontWeight: FontWeight.w700)),
                            ),
                          ],
                          Expanded(
                            child: Text(
                              conv.lastMessage.isNotEmpty ? conv.lastMessage : conv.courseName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected ? AppTheme.ink : AppTheme.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      onTap: () => setState(() {
                        _selectedConversationId = conv.id;
                        _selectedTrainerName = otherName;
                        if (isMobile) _showMobileChatThread = true;
                      }),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );

    final chatBoxWidget = _selectedConversationId == null
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.forum_outlined, size: 48, color: AppTheme.textMuted),
                const SizedBox(height: 12),
                Text('Sélectionnez une discussion pour échanger.', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted)),
              ],
            ),
          )
        : Column(
            children: [
              // Chat Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  children: [
                    if (isMobile) ...[
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.ink, size: 20),
                        tooltip: 'Retour aux discussions',
                        onPressed: () => setState(() => _showMobileChatThread = false),
                      ),
                      const SizedBox(width: 4),
                    ],
                    CircleAvatar(
                      backgroundColor: AppTheme.paleMint,
                      child: Text(
                        _selectedTrainerName.isNotEmpty ? _selectedTrainerName[0].toUpperCase() : 'F',
                        style: const TextStyle(color: AppTheme.emeraldGreenDark, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedTrainerName,
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.ink),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(color: AppTheme.emeraldGreen, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _selectedTrainerName.toLowerCase().contains('correcteur') ? 'Correcteur Dédié • En ligne' : 'Formateur Certifié • En ligne',
                                style: const TextStyle(fontSize: 11, color: AppTheme.emeraldGreenDark, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Messages Stream
              Expanded(
                child: StreamBuilder<List<MessageModel>>(
                  stream: _chatService.getMessagesStream(_selectedConversationId!),
                  builder: (context, snapshot) {
                    final messages = snapshot.data ?? [];
                    if (messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.chat_bubble_outline_rounded, size: 40, color: AppTheme.textMuted),
                            const SizedBox(height: 8),
                            Text('Commencez à discuter avec $_selectedTrainerName !', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted)),
                          ],
                        ),
                      );
                    }

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_chatScrollController.hasClients) {
                        _chatScrollController.jumpTo(_chatScrollController.position.maxScrollExtent);
                      }
                    });

                    return ListView.builder(
                      controller: _chatScrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg.senderId == user.uid;
                        return _buildMessageBubble(msg, isMe);
                      },
                    );
                  },
                ),
              ),

              // Input Bar with VoiceRecordingBar (Functional Voice Notes for Students)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: VoiceRecordingBar(
                  conversationId: _selectedConversationId!,
                  onAudioSent: (audioUrl, duration) async {
                    await _chatService.sendMessage(
                      conversationId: _selectedConversationId!,
                      senderId: user.uid,
                      senderName: user.displayName.isNotEmpty ? user.displayName : 'Apprenant',
                      senderRole: 'student',
                      content: 'Note vocale (${duration}s)',
                      type: MessageType.audio,
                      fileUrl: audioUrl,
                      audioDuration: duration,
                    );
                  },
                  child: Row(
                    children: [
                      // Attach image
                      IconButton(
                        icon: const Icon(Icons.image_outlined, color: AppTheme.emeraldGreenDark),
                        tooltip: 'Envoyer une capture ou photo',
                        onPressed: () async {
                          final res = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
                          if (res != null && res.files.single.bytes != null) {
                            final url = await _storageService.uploadChatMedia(
                              conversationId: _selectedConversationId!,
                              bytes: res.files.single.bytes!,
                              fileName: res.files.single.name,
                            );
                            if (url != null) {
                              await _chatService.sendMessage(
                                conversationId: _selectedConversationId!,
                                senderId: user.uid,
                                senderName: user.displayName,
                                senderRole: 'student',
                                content: 'Photo envoyée',
                                type: MessageType.image,
                                fileUrl: url,
                              );
                            }
                          }
                        },
                      ),
                      Expanded(
                        child: TextField(
                          controller: _chatMessageController,
                          decoration: InputDecoration(
                            hintText: 'Écrivez votre message à $_selectedTrainerName...',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                          ),
                          onSubmitted: (_) => _sendTextMessage(user),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send_rounded, color: AppTheme.emeraldGreenDark),
                        tooltip: 'Envoyer',
                        onPressed: () => _sendTextMessage(user),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );

    return Container(
      height: 650,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: isMobile
          ? (_showMobileChatThread && _selectedConversationId != null ? chatBoxWidget : convsListWidget)
          : Row(
              children: [
                convsListWidget,
                const VerticalDivider(width: 1, color: AppTheme.cardBorder),
                Expanded(child: chatBoxWidget),
              ],
            ),
    );
  }

  void _sendTextMessage(UserModel user) async {
    final text = _chatMessageController.text.trim();
    if (text.isEmpty || _selectedConversationId == null) return;
    _chatMessageController.clear();

    await _chatService.sendMessage(
      conversationId: _selectedConversationId!,
      senderId: user.uid,
      senderName: user.displayName,
      senderRole: 'student',
      content: text,
      type: (text.startsWith('http://') || text.startsWith('https://')) ? MessageType.link : MessageType.text,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildMessageBubble(MessageModel msg, bool isMe) {
    if (msg.isAudio) {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: AudioMessageBubble(
          audioUrl: msg.fileUrl ?? '',
          durationSeconds: msg.audioDuration ?? 10,
          isMe: isMe,
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.emeraldGreenDark : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.isImage && msg.fileUrl != null) ...[
              ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(msg.fileUrl!, width: 200, height: 140, fit: BoxFit.cover)),
            ] else if (msg.isLink) ...[
              InkWell(
                onTap: () async {
                  final uri = Uri.parse(msg.content);
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                },
                child: Text(msg.content, style: TextStyle(color: isMe ? Colors.white : Colors.blue[700], decoration: TextDecoration.underline, fontSize: 13)),
              ),
            ] else ...[
              Text(msg.content, style: TextStyle(color: isMe ? Colors.white : AppTheme.ink, fontSize: 13)),
            ],
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  _formatChatTime(msg.createdAt),
                  style: TextStyle(
                    fontSize: 9,
                    color: isMe ? Colors.white70 : AppTheme.textMuted,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.done_all_rounded, size: 12, color: Colors.white70),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 7. PROFILE & SETTINGS VIEW
  // ==========================================
  Widget _buildSettingsView(UserModel user) {
    final nameCtrl = TextEditingController(text: user.displayName);
    final phoneCtrl = TextEditingController(text: user.phoneNumber ?? '+221 77 123 45 67');
    Uint8List? avatarBytes;
    bool isSaving = false;

    return StatefulBuilder(
      builder: (context, setSettingsState) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const MarketingSectionHeader(
              badge: 'MON PROFIL',
              title: 'Personnalisez votre compte',
              subtitle: 'Informations personnelles, sécurité et préférences.',
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: avatarBytes != null
                      ? Image.memory(avatarBytes!, width: 80, height: 80, fit: BoxFit.cover)
                      : (user.photoUrl != null && user.photoUrl!.isNotEmpty
                          ? (user.photoUrl!.startsWith('http')
                              ? Image.network(user.photoUrl!, width: 80, height: 80, fit: BoxFit.cover)
                              : Image.asset(user.photoUrl!, width: 80, height: 80, fit: BoxFit.cover))
                          : Container(width: 80, height: 80, color: AppTheme.paleMint, child: const Icon(Icons.person, size: 40, color: AppTheme.emeraldGreenDark))),
                ),
                const SizedBox(width: 18),
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt_rounded, size: 16),
                  label: const Text('Modifier ma photo'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.paleMint, foregroundColor: AppTheme.emeraldGreenDark, elevation: 0),
                  onPressed: () async {
                    final res = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
                    if (res != null && res.files.single.bytes != null) {
                      setSettingsState(() => avatarBytes = res.files.single.bytes);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nom complet', border: OutlineInputBorder())),
            const SizedBox(height: 14),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Téléphone', border: OutlineInputBorder())),
            const SizedBox(height: 24),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emeraldGreenDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
              onPressed: isSaving ? null : () async {
                setSettingsState(() => isSaving = true);
                await _authService.updateUserProfile(
                  displayName: nameCtrl.text.trim(),
                  phoneNumber: phoneCtrl.text.trim(),
                  avatarBytes: avatarBytes,
                  avatarFileName: 'student_avatar.jpg',
                );
                setSettingsState(() => isSaving = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profil mis à jour !'), backgroundColor: AppTheme.emeraldGreen),
                );
              },
              child: isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Sauvegarder'),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 8. HEADER, SIDEBAR & STATS
  // ==========================================
  Widget _buildTopHeader(BuildContext context, UserModel user, bool isDesktop) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 12, vertical: 14),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.ink, size: 22),
            tooltip: _activeGroupChat != null
                ? 'Retour aux groupes'
                : (_activeMenu != 'Tableau de bord' ? 'Retour au tableau de bord' : 'Retour à l\'accueil'),
            onPressed: () {
              setState(() {
                if (_activeGroupChat != null) {
                  _activeGroupChat = null;
                } else if (_activeMenu != 'Tableau de bord') {
                  _activeMenu = 'Tableau de bord';
                } else if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacementNamed(context, '/');
                }
              });
            },
          ),
          if (isDesktop) ...[
            InkWell(
              onTap: () {
                setState(() {
                  if (_activeGroupChat != null) {
                    _activeGroupChat = null;
                  } else if (_activeMenu != 'Tableau de bord') {
                    _activeMenu = 'Tableau de bord';
                  } else if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacementNamed(context, '/');
                  }
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Text(
                  _activeGroupChat != null
                      ? 'Retour'
                      : (_activeMenu != 'Tableau de bord' ? 'Tableau de bord' : 'Accueil site'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.emeraldGreenDark,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (!isDesktop)
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: AppTheme.ink, size: 26),
              tooltip: 'Menu',
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher une formation, un formateur...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          AppNotificationBell(
            userId: user.uid,
            onNotificationAction: (n) async {
              if (n.type == 'live_started' || n.data['sessionId'] != null || n.data['liveId'] != null) {
                final sessionId = (n.data['sessionId'] ?? n.data['liveId']) as String?;
                if (sessionId != null) {
                  final live = await _liveService.getLiveSessionById(sessionId);
                  if (live != null && mounted) {
                    _openLiveSessionModal(live);
                    return;
                  }
                }
                if (_activeLive != null && mounted) {
                  _openLiveSessionModal(_activeLive!);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingBanner(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF07251F), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ravi de vous revoir, ${user.displayName} 🎓', style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 6),
                const Text('Reprenez vos leçons là où vous vous êtes arrêté et échangez avec vos formateurs.', style: TextStyle(color: Color(0xFFC7DFD9), fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards(UserModel user) {
    return StreamBuilder<List<EnrollmentModel>>(
      stream: EnrollmentService().getUserEnrollmentsStream(user.uid),
      builder: (context, snapEnroll) {
        final enrollments = snapEnroll.data ?? [];
        final totalCourses = enrollments.length;
        final totalCompletedLessons = _userProgress.values.fold<int>(0, (sum, p) => sum + p.completedLessonIds.length);

        return StreamBuilder<List<HomeworkSubmissionModel>>(
          stream: _homeworkService.getStudentSubmissionsStream(user.uid),
          builder: (context, snapSub) {
            final submissions = snapSub.data ?? [];
            final totalSubmissions = submissions.length;

            return LayoutBuilder(builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 600;
              final w = isCompact ? (constraints.maxWidth - 16) / 2 : (constraints.maxWidth - 48) / 4;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildStatCard(
                    width: w,
                    icon: Icons.auto_stories_rounded,
                    color: AppTheme.emeraldGreenDark,
                    bg: AppTheme.paleMint,
                    val: '$totalCourses',
                    label: 'Formations suivies',
                  ),
                  _buildStatCard(
                    width: w,
                    icon: Icons.check_circle_outline_rounded,
                    color: const Color(0xFF0284C7),
                    bg: const Color(0xFFE0F2FE),
                    val: '$totalCompletedLessons',
                    label: 'Leçons terminées',
                  ),
                  _buildStatCard(
                    width: w,
                    icon: Icons.assignment_turned_in_rounded,
                    color: const Color(0xFFD97706),
                    bg: const Color(0xFFFEF3C7),
                    val: '$totalSubmissions',
                    label: 'Devoirs rendus',
                  ),
                  _buildStatCard(
                    width: w,
                    icon: Icons.military_tech_rounded,
                    color: const Color(0xFF7C3AED),
                    bg: const Color(0xFFEDE9FE),
                    val: totalCourses > 0
                        ? '${(enrollments.fold<double>(0.0, (s, e) => s + (_userProgress[e.courseId]?.progressPercentage ?? 0.0)) / totalCourses * 100).round()}%'
                        : '0%',
                    label: 'Progression globale',
                  ),
                ],
              );
            });
          },
        );
      },
    );
  }

  Widget _buildStatCard({required double width, required IconData icon, required Color color, required Color bg, required String val, required String label}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.cardBorder)),
      child: Row(
        children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(val, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.ink)),
                Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingDeadlinesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.cardBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Cours en direct', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.ink)),
              InkWell(
                onTap: () => setState(() => _activeMenu = 'Directs & Visioconférence'),
                child: Text('Voir tout', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.emeraldGreenDark)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<LiveSessionModel>>(
            stream: _liveService.getLiveSessionsStream(),
            builder: (context, snapshot) {
              final lives = snapshot.data ?? [];
              if (lives.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppTheme.paleMint,
                        radius: 18,
                        child: Icon(Icons.videocam_outlined, color: AppTheme.emeraldGreenDark, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Aucun direct en cours', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.ink)),
                            const SizedBox(height: 2),
                            const Text('Les prochaines sessions des formateurs apparaîtront ici.', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
              final nextLive = lives.first;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: nextLive.isLive ? Colors.red.withValues(alpha: 0.1) : AppTheme.paleMint,
                  radius: 18,
                  child: Icon(
                    nextLive.isLive ? Icons.sensors_rounded : Icons.calendar_today_rounded,
                    color: nextLive.isLive ? Colors.red : AppTheme.emeraldGreenDark,
                    size: 18,
                  ),
                ),
                title: Text(nextLive.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                subtitle: Text('Animé par ${nextLive.teacherName}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: nextLive.isLive ? Colors.red : AppTheme.emeraldGreenDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                  onPressed: () => setState(() => _activeMenu = 'Directs & Visioconférence'),
                  child: Text(nextLive.isLive ? 'En direct' : 'Rejoindre', style: const TextStyle(fontSize: 11)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStudyGroupWidget(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.cardBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mon groupe d\'étude', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.ink)),
          const SizedBox(height: 10),
          const Text('Rejoignez d\'autres étudiants pour réviser ensemble et poser vos questions.', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 14),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldGreenDark, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => setState(() => _activeMenu = 'Groupes d\'étude'),
            child: const Text('Accéder aux groupes', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar({bool isMobileDrawer = false}) {
    final menuItems = [
      {'title': 'Tableau de bord', 'icon': Icons.dashboard_rounded},
      {'title': 'Mes inscriptions', 'icon': Icons.how_to_reg_rounded},
      {'title': 'Mes cours', 'icon': Icons.auto_stories_rounded},
      {'title': 'Devoirs & Examens', 'icon': Icons.assignment_rounded},
      {'title': 'Groupes d\'étude', 'icon': Icons.groups_rounded},
      {'title': 'Mes Paiements', 'icon': Icons.receipt_long_rounded},
      {'title': 'Messages', 'icon': Icons.chat_bubble_outline_rounded},
      {'title': 'Règlement & Documents', 'icon': Icons.menu_book_rounded},
      {'title': 'Paramètres', 'icon': Icons.settings_outlined},
    ];

    return Container(
      color: const Color(0xFF07251F),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => Navigator.pushNamed(context, '/'),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 38,
                    height: 38,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Club des Formateurs', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('ESPACE APPRENANT', style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.mintAccent, letterSpacing: 0.8)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Expanded(
            child: ListView(
              children: menuItems.map((item) {
                final isSelected = _activeMenu == item['title'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: InkWell(
                    onTap: () {
                      setState(() => _activeMenu = item['title'] as String);
                      if (isMobileDrawer) Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(item['icon'] as IconData, size: 18, color: isSelected ? AppTheme.mintAccent : const Color(0xFF94B5AD)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item['title'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? Colors.white : const Color(0xFFC7DFD9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Bouton bascule vers l'Espace Formateur
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () async {
                final cur = _authService.currentUser;
                if (cur != null) {
                  await _authService.updateUserProfile(role: 'teacher');
                }
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/dashboard/formateur');
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: AppTheme.emeraldGreenDark.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.mintAccent.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.swap_horiz_rounded, color: AppTheme.mintAccent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Passer à l\'Espace Formateur',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.mintAccent, size: 10),
                  ],
                ),
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppTheme.paleMint,
                  radius: 16,
                  child: Icon(Icons.person, size: 18, color: AppTheme.emeraldGreenDark),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _authService.currentUser?.displayName ?? 'Apprenant',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text('Apprenant', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.mintAccent)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.white60, size: 18),
                  onPressed: () {
                    _authService.signOut();
                    Navigator.pushReplacementNamed(context, '/');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 9. COURSE VIDEO PLAYER DIALOG (REAL PLAYER)
// ==========================================
// ==========================================
// 9. COURSE VIDEO PLAYER DIALOG (REAL PLAYER & FULLSCREEN)
// ==========================================
class CoursePlayerDialog extends StatefulWidget {
  final CourseModel course;
  final String userId;
  final VoidCallback onProgressUpdated;
  final bool autoPlayPresentation;
  final bool initialFullscreen;
  final CourseLesson? initialLesson;

  const CoursePlayerDialog({
    super.key,
    required this.course,
    required this.userId,
    required this.onProgressUpdated,
    this.autoPlayPresentation = false,
    this.initialFullscreen = false,
    this.initialLesson,
  });

  @override
  State<CoursePlayerDialog> createState() => _CoursePlayerDialogState();
}

class _CoursePlayerDialogState extends State<CoursePlayerDialog> {
  final CourseService _courseService = CourseService();
  final ProgressService _progressService = ProgressService();
  final FocusNode _focusNode = FocusNode();

  VideoPlayerController? _controller;
  CourseLesson? _currentLesson;
  bool _isPlaying = false;
  Set<String> _completedIds = {};

  bool _isFullscreen = false;
  bool _showControls = true;
  bool _showPlaylistDrawer = false;
  Timer? _hideTimer;
  StreamSubscription? _fsSubscription;

  double _volume = 1.0;
  bool _isMuted = false;
  double _playbackSpeed = 1.0;
  bool _isSeeking = false;
  double _seekPositionSeconds = 0.0;

  bool get _isCurrentYouTube =>
      _currentLesson != null && YouTubeHelper.isYouTubeUrl(_currentLesson!.videoUrl);

  @override
  void initState() {
    super.initState();
    _isFullscreen = widget.initialFullscreen;
    if (_isFullscreen) {
      FullscreenWebHelper.toggleFullscreen(true);
    }
    _fsSubscription = FullscreenWebHelper.addFullscreenListener((isFs) {
      if (mounted && _isFullscreen != isFs) {
        setState(() {
          _isFullscreen = isFs;
          if (!_isFullscreen) {
            _showPlaylistDrawer = false;
          }
        });
      }
    });

    _loadProgress();
    _checkInitialVideo();
  }

  void _checkInitialVideo() {
    if (widget.initialLesson != null) {
      _initVideo(widget.initialLesson!);
      return;
    }
    final promoUrl = widget.course.presentationVideoUrl;
    if (widget.autoPlayPresentation || (promoUrl != null && promoUrl.isNotEmpty)) {
      final promoLesson = CourseLesson(
        id: 'promo_video',
        title: 'Vidéo de présentation (Bande annonce)',
        duration: 'Aperçu gratuit',
        videoUrl: (promoUrl != null && promoUrl.isNotEmpty)
            ? promoUrl
            : 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        isFreePreview: true,
      );
      _initVideo(promoLesson);
    } else if (widget.course.flatLessons.isNotEmpty) {
      _initVideo(widget.course.flatLessons.first);
    } else if (widget.course.modules.isNotEmpty && widget.course.modules.first.lessons.isNotEmpty) {
      _initVideo(widget.course.modules.first.lessons.first);
    }
  }

  void _loadProgress() async {
    final prog = await _progressService.getCourseProgress(widget.userId, widget.course.id);
    if (mounted && prog != null) {
      setState(() => _completedIds = Set<String>.from(prog.completedLessonIds));
    }
  }

  void _initVideo(CourseLesson lesson) async {
    _currentLesson = lesson;
    final old = _controller;
    _controller = null;
    if (old != null) {
      old.removeListener(_onControllerUpdate);
      await old.dispose();
    }
    if (mounted) setState(() {});

    if (YouTubeHelper.isYouTubeUrl(lesson.videoUrl)) {
      if (mounted) {
        setState(() {
          _isPlaying = true;
        });
      }
      return;
    }

    final newController = VideoPlayerController.networkUrl(Uri.parse(lesson.videoUrl));
    _controller = newController;
    try {
      await newController.initialize();
      if (mounted && _controller == newController) {
        newController.addListener(_onControllerUpdate);
        await newController.setVolume(_isMuted ? 0.0 : _volume);
        await newController.setPlaybackSpeed(_playbackSpeed);
        await newController.play();
        setState(() {
          _isPlaying = true;
        });
        _startHideTimer();
      }
    } catch (e) {
      debugPrint('Video player initialization error: $e');
    }
  }

  void _onControllerUpdate() {
    if (!mounted || _controller == null) return;
    final playing = _controller!.value.isPlaying;
    if (playing != _isPlaying) {
      setState(() {
        _isPlaying = playing;
      });
      if (_isPlaying) {
        _startHideTimer();
      } else {
        _hideTimer?.cancel();
        setState(() => _showControls = true);
      }
    } else {
      if (!_isSeeking) {
        setState(() {});
      }
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    if (_isPlaying) {
      _hideTimer = Timer(const Duration(seconds: 4), () {
        if (mounted && _isPlaying && !_isSeeking) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  void _onUserInteraction() {
    if (!_showControls) {
      setState(() {
        _showControls = true;
      });
    }
    _startHideTimer();
  }

  void _togglePlayPause() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isPlaying) {
      _controller!.pause();
      setState(() {
        _isPlaying = false;
        _showControls = true;
      });
      _hideTimer?.cancel();
    } else {
      _controller!.play();
      setState(() {
        _isPlaying = true;
      });
      _startHideTimer();
    }
  }

  void _seekRelative(int seconds) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final current = _controller!.value.position;
    final total = _controller!.value.duration;
    var target = current + Duration(seconds: seconds);
    if (target < Duration.zero) target = Duration.zero;
    if (target > total) target = total;
    _controller!.seekTo(target);
    _onUserInteraction();
  }

  void _toggleMute() {
    if (_controller == null) return;
    setState(() {
      _isMuted = !_isMuted;
      _controller!.setVolume(_isMuted ? 0.0 : _volume);
    });
    _onUserInteraction();
  }

  void _setVolume(double val) {
    if (_controller == null) return;
    setState(() {
      _volume = val;
      _isMuted = val == 0;
      _controller!.setVolume(_volume);
    });
    _onUserInteraction();
  }

  void _setSpeed(double speed) {
    if (_controller == null) return;
    setState(() {
      _playbackSpeed = speed;
      _controller!.setPlaybackSpeed(_playbackSpeed);
    });
    _onUserInteraction();
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
      if (!_isFullscreen) {
        _showPlaylistDrawer = false;
      }
      FullscreenWebHelper.toggleFullscreen(_isFullscreen);
    });
    _onUserInteraction();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      final hours = d.inHours.toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  Future<void> _markCompleted() async {
    if (_currentLesson != null) {
      await _progressService.markLessonCompleted(
        userId: widget.userId,
        courseId: widget.course.id,
        lessonId: _currentLesson!.id,
        totalLessons: widget.course.lessonsCount > 0 ? widget.course.lessonsCount : 10,
      );
      if (mounted) {
        setState(() => _completedIds.add(_currentLesson!.id));
        widget.onProgressUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leçon validée ! Progression mise à jour.'),
            backgroundColor: AppTheme.emeraldGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.space) {
        _togglePlayPause();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.keyF) {
        _toggleFullscreen();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.keyM) {
        _toggleMute();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _seekRelative(-10);
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _seekRelative(10);
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.escape && _isFullscreen) {
        _toggleFullscreen();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _fsSubscription?.cancel();
    if (_isFullscreen) {
      FullscreenWebHelper.toggleFullscreen(false);
    }
    _hideTimer?.cancel();
    _focusNode.dispose();
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Dialog(
        insetPadding: _isFullscreen
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: _isFullscreen ? size.width : 1100,
          height: _isFullscreen ? size.height : 700,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: _isFullscreen ? BorderRadius.zero : BorderRadius.circular(20),
            boxShadow: _isFullscreen
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
          ),
          child: _isFullscreen
              ? Stack(
                  children: [
                    Positioned.fill(child: _buildPlayerArea(true)),
                    if (_showPlaylistDrawer) ...[
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: () => setState(() => _showPlaylistDrawer = false),
                          child: Container(color: Colors.black.withValues(alpha: 0.45)),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        bottom: 0,
                        right: 0,
                        width: size.width < 500 ? size.width * 0.85 : 380,
                        child: _buildPlaylistWidget(isDarkDrawer: true),
                      ),
                    ],
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      flex: 7,
                      child: _buildPlayerArea(false),
                    ),
                    Expanded(
                      flex: 4,
                      child: _buildPlaylistWidget(isDarkDrawer: false),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildPlayerArea(bool isFull) {
    final position = _controller?.value.position ?? Duration.zero;
    final duration = _controller?.value.duration ?? Duration.zero;
    final posSeconds = _isSeeking ? _seekPositionSeconds : position.inMilliseconds / 1000.0;
    final totalSeconds = duration.inMilliseconds > 0 ? duration.inMilliseconds / 1000.0 : 1.0;
    final clampedVal = posSeconds.clamp(0.0, totalSeconds);

    return MouseRegion(
      onHover: (_) => _onUserInteraction(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!_showControls) {
            _onUserInteraction();
          } else {
            _togglePlayPause();
          }
        },
        onDoubleTap: _toggleFullscreen,
        child: Container(
          color: Colors.black,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Main Video Display
              if (_isCurrentYouTube)
                Positioned.fill(
                  child: YouTubeWebPlayer(
                    key: ValueKey(_currentLesson!.videoUrl),
                    videoUrl: _currentLesson!.videoUrl,
                    autoPlay: true,
                  ),
                )
              else if (_controller != null && _controller!.value.isInitialized)
                Center(
                  child: AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: VideoPlayer(_controller!),
                  ),
                )
              else
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_circle_outline_rounded, color: Colors.white54, size: 64),
                      const SizedBox(height: 14),
                      Text(
                        _currentLesson == null ? 'Sélectionnez une leçon pour démarrer' : 'Chargement de la vidéo...',
                        style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),

              // Center Play/Pause Floating Icon when paused (MP4 only)
              if (!_isCurrentYouTube && !_isPlaying && _controller != null && _controller!.value.isInitialized)
                IgnorePointer(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 48),
                  ),
                ),

              // YouTube Dedicated Top Bar (Direct & Unobstructed)
              if (_isCurrentYouTube)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildYouTubeTopBar(),
                ),

              // Overlay Controls for MP4 (Top & Bottom)
              if (!_isCurrentYouTube)
                Positioned.fill(
                  child: AnimatedOpacity(
                    opacity: _showControls ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: IgnorePointer(
                      ignoring: !_showControls,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // --- TOP HEADER BAR ---
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.85),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                                tooltip: _isFullscreen ? 'Quitter plein écran' : 'Retour',
                                onPressed: () {
                                  if (_isFullscreen) {
                                    _toggleFullscreen();
                                  } else {
                                    Navigator.pop(context);
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _currentLesson?.title ?? widget.course.title,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (_currentLesson != null)
                                      Text(
                                        widget.course.title,
                                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              if (_isFullscreen) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.emeraldGreenDark.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.high_quality_rounded, color: Colors.white, size: 14),
                                      SizedBox(width: 4),
                                      Text('Plein écran', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.playlist_play_rounded, size: 18),
                                  label: const Text('Programme', style: TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _showPlaylistDrawer = !_showPlaylistDrawer;
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                              ],
                              IconButton(
                                icon: Icon(_isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded, color: Colors.white),
                                tooltip: _isFullscreen ? 'Quitter plein écran (F)' : 'Plein écran (F)',
                                onPressed: _toggleFullscreen,
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, color: Colors.white),
                                tooltip: 'Fermer le lecteur',
                                onPressed: () {
                                  if (_isFullscreen) {
                                    FullscreenWebHelper.toggleFullscreen(false);
                                  }
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        ),

                        // --- BOTTOM CONTROLS BAR ---
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.9),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Scrubber Slider
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                  activeTrackColor: AppTheme.emeraldGreen,
                                  inactiveTrackColor: Colors.white24,
                                  thumbColor: AppTheme.emeraldGreen,
                                  overlayColor: AppTheme.emeraldGreen.withValues(alpha: 0.3),
                                ),
                                child: Slider(
                                  value: clampedVal,
                                  min: 0.0,
                                  max: totalSeconds,
                                  onChanged: (val) {
                                    setState(() {
                                      _isSeeking = true;
                                      _seekPositionSeconds = val;
                                    });
                                    _onUserInteraction();
                                  },
                                  onChangeEnd: (val) {
                                    _controller?.seekTo(Duration(milliseconds: (val * 1000).toInt()));
                                    setState(() {
                                      _isSeeking = false;
                                    });
                                    _onUserInteraction();
                                  },
                                ),
                              ),

                              // Buttons Row
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 28),
                                    tooltip: _isPlaying ? 'Pause (Espace)' : 'Lecture (Espace)',
                                    onPressed: _togglePlayPause,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 22),
                                    tooltip: 'Reculer de 10s',
                                    onPressed: () => _seekRelative(-10),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 22),
                                    tooltip: 'Avancer de 10s',
                                    onPressed: () => _seekRelative(10),
                                  ),
                                  const SizedBox(width: 4),

                                  // Volume & Mute
                                  IconButton(
                                    icon: Icon(
                                      _isMuted || _volume == 0
                                          ? Icons.volume_off_rounded
                                          : (_volume < 0.5 ? Icons.volume_down_rounded : Icons.volume_up_rounded),
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    tooltip: _isMuted ? 'Activer le son (M)' : 'Couper le son (M)',
                                    onPressed: _toggleMute,
                                  ),
                                  SizedBox(
                                    width: 70,
                                    child: SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        trackHeight: 3,
                                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                                        activeTrackColor: Colors.white,
                                        inactiveTrackColor: Colors.white24,
                                        thumbColor: Colors.white,
                                      ),
                                      child: Slider(
                                        value: _isMuted ? 0.0 : _volume,
                                        min: 0.0,
                                        max: 1.0,
                                        onChanged: _setVolume,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Time Display
                                  Text(
                                    '${_formatDuration(position)} / ${_formatDuration(duration)}',
                                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),

                                  const Spacer(),

                                  // Playback Speed
                                  PopupMenuButton<double>(
                                    tooltip: 'Vitesse de lecture',
                                    initialValue: _playbackSpeed,
                                    onSelected: _setSpeed,
                                    color: const Color(0xFF1E293B),
                                    itemBuilder: (ctx) => [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((s) {
                                      return PopupMenuItem<double>(
                                        value: s,
                                        child: Text(
                                          s == 1.0 ? 'Normal (1.0x)' : '${s}x',
                                          style: TextStyle(
                                            color: _playbackSpeed == s ? AppTheme.emeraldGreen : Colors.white,
                                            fontWeight: _playbackSpeed == s ? FontWeight.bold : FontWeight.normal,
                                            fontSize: 12,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${_playbackSpeed}x',
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Mark lesson completed
                                  if (_currentLesson != null && _currentLesson!.id != 'promo_video')
                                    ElevatedButton.icon(
                                      icon: Icon(
                                        _completedIds.contains(_currentLesson!.id) ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                                        size: 16,
                                      ),
                                      label: Text(
                                        _completedIds.contains(_currentLesson!.id) ? 'Terminée' : 'Valider la leçon',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _completedIds.contains(_currentLesson!.id) ? AppTheme.emeraldGreenDark : AppTheme.emeraldGreen,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: _markCompleted,
                                    ),

                                  // Playlist drawer toggle in fullscreen
                                  if (_isFullscreen) ...[
                                    const SizedBox(width: 6),
                                    IconButton(
                                      icon: const Icon(Icons.playlist_play_rounded, color: Colors.white, size: 24),
                                      tooltip: 'Programme des leçons',
                                      onPressed: () {
                                        setState(() {
                                          _showPlaylistDrawer = !_showPlaylistDrawer;
                                        });
                                      },
                                    ),
                                  ],

                                  const SizedBox(width: 4),
                                  // Fullscreen Toggle
                                  IconButton(
                                    icon: Icon(_isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded, color: Colors.white, size: 26),
                                    tooltip: _isFullscreen ? 'Quitter plein écran (F)' : 'Plein écran (F)',
                                    onPressed: _toggleFullscreen,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYouTubeTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.9),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            tooltip: _isFullscreen ? 'Quitter plein écran' : 'Retour',
            onPressed: () {
              if (_isFullscreen) {
                _toggleFullscreen();
              } else {
                Navigator.pop(context);
              }
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _currentLesson?.title ?? widget.course.title,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF0000),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.smart_display_rounded, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text('YouTube HD', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ],
                ),
                Text(
                  widget.course.title,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (_currentLesson != null && _currentLesson!.id != 'promo_video') ...[
            ElevatedButton.icon(
              icon: Icon(
                _completedIds.contains(_currentLesson!.id) ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                size: 15,
              ),
              label: Text(
                _completedIds.contains(_currentLesson!.id) ? 'Terminée' : 'Valider la leçon',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _completedIds.contains(_currentLesson!.id) ? AppTheme.emeraldGreenDark : AppTheme.emeraldGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _markCompleted,
            ),
            const SizedBox(width: 8),
          ],
          if (_isFullscreen) ...[
            ElevatedButton.icon(
              icon: const Icon(Icons.playlist_play_rounded, size: 18),
              label: const Text('Programme', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                setState(() {
                  _showPlaylistDrawer = !_showPlaylistDrawer;
                });
              },
            ),
            const SizedBox(width: 8),
          ],
          IconButton(
            icon: Icon(_isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded, color: Colors.white),
            tooltip: _isFullscreen ? 'Quitter plein écran (F)' : 'Plein écran (F)',
            onPressed: _toggleFullscreen,
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            tooltip: 'Fermer le lecteur',
            onPressed: () {
              if (_isFullscreen) {
                FullscreenWebHelper.toggleFullscreen(false);
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLessonTile(CourseLesson lesson, Color itemBg, Color itemBorder, Color titleColor, Color textMutedColor, bool isDarkDrawer) {
    final isSelected = _currentLesson?.id == lesson.id;
    final isDone = _completedIds.contains(lesson.id);
    final isYouTube = YouTubeHelper.isYouTubeUrl(lesson.videoUrl);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDarkDrawer ? AppTheme.emeraldGreenDark.withValues(alpha: 0.3) : AppTheme.paleMint)
            : itemBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? AppTheme.emeraldGreenDark : itemBorder,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: () => _initVideo(lesson),
        leading: Icon(
          isDone
              ? Icons.check_circle_rounded
              : (isYouTube ? Icons.smart_display_rounded : Icons.play_circle_outline_rounded),
          color: isDone
              ? AppTheme.emeraldGreen
              : (isSelected
                  ? AppTheme.emeraldGreenDark
                  : (isYouTube ? const Color(0xFFEF4444) : textMutedColor)),
          size: 20,
        ),
        title: Text(
          lesson.title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected && !isDarkDrawer ? AppTheme.emeraldGreenDark : titleColor,
          ),
        ),
        subtitle: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isYouTube) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('YouTube', style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.w700)),
              ),
            ],
            Text(lesson.duration, style: TextStyle(fontSize: 10, color: textMutedColor)),
            if (lesson.isFreePreview) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppTheme.emeraldGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Aperçu gratuit', style: TextStyle(color: AppTheme.emeraldGreenDark, fontSize: 9, fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
        trailing: isDone
            ? const Icon(Icons.done_all_rounded, color: AppTheme.emeraldGreen, size: 16)
            : null,
      ),
    );
  }

  Widget _buildPlaylistWidget({required bool isDarkDrawer}) {
    final bgColor = isDarkDrawer ? const Color(0xFF0F172A).withValues(alpha: 0.96) : const Color(0xFFF8FAFC);
    final titleColor = isDarkDrawer ? Colors.white : AppTheme.ink;
    final itemBg = isDarkDrawer ? Colors.white.withValues(alpha: 0.05) : Colors.white;
    final itemBorder = isDarkDrawer ? Colors.white.withValues(alpha: 0.1) : AppTheme.cardBorder;
    final textMutedColor = isDarkDrawer ? Colors.white60 : AppTheme.textMuted;

    return Container(
      color: bgColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Contenu de la formation',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: titleColor,
                  ),
                ),
              ),
              if (isDarkDrawer)
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                  tooltip: 'Fermer le panneau',
                  onPressed: () => setState(() => _showPlaylistDrawer = false),
                ),
            ],
          ),
          const SizedBox(height: 12),

          Expanded(
            child: ListView(
              children: [
                // Presentation Video Pinned Tile
                if (widget.course.presentationVideoUrl != null && widget.course.presentationVideoUrl!.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: _currentLesson?.id == 'promo_video' ? AppTheme.paleMint : itemBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _currentLesson?.id == 'promo_video' ? AppTheme.emeraldGreenDark : itemBorder,
                        width: _currentLesson?.id == 'promo_video' ? 1.5 : 1.0,
                      ),
                    ),
                    child: ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onTap: () {
                        _initVideo(CourseLesson(
                          id: 'promo_video',
                          title: 'Vidéo de présentation (Bande annonce)',
                          duration: 'Aperçu gratuit',
                          videoUrl: widget.course.presentationVideoUrl!,
                          isFreePreview: true,
                        ));
                      },
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.emeraldGreenDark.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          YouTubeHelper.isYouTubeUrl(widget.course.presentationVideoUrl)
                              ? Icons.smart_display_rounded
                              : Icons.movie_creation_rounded,
                          color: YouTubeHelper.isYouTubeUrl(widget.course.presentationVideoUrl)
                              ? const Color(0xFFEF4444)
                              : AppTheme.emeraldGreenDark,
                          size: 18,
                        ),
                      ),
                      title: Text(
                        'Vidéo de présentation',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _currentLesson?.id == 'promo_video' ? AppTheme.emeraldGreenDark : titleColor,
                        ),
                      ),
                      subtitle: Text(
                        YouTubeHelper.isYouTubeUrl(widget.course.presentationVideoUrl)
                            ? 'YouTube HD • Aperçu gratuit'
                            : 'Bande annonce • Aperçu gratuit',
                        style: const TextStyle(fontSize: 10, color: AppTheme.emeraldGreenDark, fontWeight: FontWeight.w600),
                      ),
                      trailing: const Icon(Icons.play_circle_fill_rounded, color: AppTheme.emeraldGreenDark, size: 22),
                    ),
                  ),
                  Divider(height: 16, color: itemBorder),
                ],

                // Modules / Sections if present (OpenClassrooms style)
                if (widget.course.modules.isNotEmpty) ...[
                  for (final mod in widget.course.modules) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 3,
                            height: 14,
                            decoration: BoxDecoration(
                              color: AppTheme.emeraldGreenDark,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              mod.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: titleColor,
                              ),
                            ),
                          ),
                          Text(
                            '${mod.lessons.length} leçons',
                            style: TextStyle(fontSize: 10, color: textMutedColor, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    for (final l in mod.lessons)
                      _buildLessonTile(l, itemBg, itemBorder, titleColor, textMutedColor, isDarkDrawer),
                    const SizedBox(height: 6),
                  ],
                ] else ...[
                  // Flat Course Lessons Stream / Fallback
                  StreamBuilder<List<CourseLesson>>(
                    stream: _courseService.getCourseLessonsStream(widget.course.id),
                    builder: (context, snapshot) {
                      List<CourseLesson> lessons = snapshot.data ?? [];
                      if (lessons.isEmpty) {
                        lessons = widget.course.flatLessons;
                      }

                      if (lessons.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'Aucune leçon disponible pour l\'instant.',
                              style: TextStyle(fontSize: 11, color: textMutedColor),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: lessons
                            .map((lesson) => _buildLessonTile(lesson, itemBg, itemBorder, titleColor, textMutedColor, isDarkDrawer))
                            .toList(),
                      );
                    },
                  ),
                ],

                // Live Replays Section if any
                if (widget.course.replays.isNotEmpty) ...[
                  Divider(height: 24, color: itemBorder),
                  Text(
                    'Replays des Sessions Live (${widget.course.replays.length})',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...widget.course.replays.map((r) => Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: itemBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: itemBorder),
                        ),
                        child: ListTile(
                          dense: true,
                          leading: const Icon(Icons.replay_rounded, color: Colors.redAccent, size: 20),
                          title: Text(r.title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: titleColor)),
                          subtitle: Text('Durée : ${r.duration}', style: TextStyle(fontSize: 10, color: textMutedColor)),
                          onTap: () {
                            _initVideo(CourseLesson(id: r.id, title: r.title, duration: r.duration, videoUrl: r.replayUrl));
                          },
                        ),
                      )),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkDrawer ? Colors.white.withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: itemBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppTheme.emeraldGreenDark,
                      backgroundImage: widget.course.trainerAvatar != null && widget.course.trainerAvatar!.isNotEmpty
                          ? NetworkImage(widget.course.trainerAvatar!)
                          : null,
                      child: widget.course.trainerAvatar == null || widget.course.trainerAvatar!.isEmpty
                          ? const Icon(Icons.person_rounded, size: 14, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.course.trainerName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emeraldGreenDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14),
                    label: const Text('Poser une question au formateur', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () => _openTeacherChatModal(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openTeacherChatModal(BuildContext context) {
    final questionCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.emeraldGreenDark, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Échanger avec ${widget.course.trainerName}',
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.ink),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Formation : ${widget.course.title}${_currentLesson != null ? " • Leçon : ${_currentLesson!.title}" : ""}',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.emeraldGreenDark),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: questionCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Posez votre question ou demandez des éclaircissements sur cette leçon...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.cardBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.emeraldGreenDark, width: 1.5)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emeraldGreenDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final text = questionCtrl.text.trim();
              if (text.isEmpty) return;
              final user = AuthService().currentUser ?? UserModel.demoStudent;
              final teacherId = widget.course.trainerId.isNotEmpty
                  ? widget.course.trainerId
                  : 'teacher_${widget.course.trainerName.toLowerCase().replaceAll(' ', '_')}';

              final convId = await ChatService().getOrCreateConversation(
                currentUserId: user.uid,
                currentUserName: user.displayName,
                currentUserPhoto: user.photoUrl ?? '',
                targetUserId: teacherId,
                targetUserName: widget.course.trainerName,
                targetUserPhoto: widget.course.trainerAvatar ?? '',
                courseName: widget.course.title,
                courseId: widget.course.id,
              );

              final lessonContext = _currentLesson != null ? '[${_currentLesson!.title}] ' : '';
              await ChatService().sendMessage(
                conversationId: convId,
                senderId: user.uid,
                senderName: user.displayName,
                senderRole: 'student',
                content: '$lessonContext$text',
              );

              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Message envoyé à ${widget.course.trainerName} ! Retrouvez la conversation dans votre messagerie.'),
                    backgroundColor: AppTheme.emeraldGreenDark,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Envoyer la question'),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 10. LIVE VIEWER DIALOG
// ==========================================
class LiveViewerDialog extends StatefulWidget {
  final LiveSessionModel live;
  final UserModel currentUser;
  final VoidCallback onLeave;

  const LiveViewerDialog({
    super.key,
    required this.live,
    required this.currentUser,
    required this.onLeave,
  });

  @override
  State<LiveViewerDialog> createState() => _LiveViewerDialogState();
}

class _LiveViewerDialogState extends State<LiveViewerDialog> {
  final ChatService _chatService = ChatService();
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late Map<String, dynamic> _liveKitConfig;
  Timer? _sessionTimer;
  int _secondsElapsed = 0;
  bool _isHandRaised = false;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    final room = widget.live.roomName.isNotEmpty ? widget.live.roomName : widget.live.id;
    _liveKitConfig = LiveKitService().getConnectionConfig(
      roomName: room,
      participantIdentity: widget.currentUser.uid,
      participantName: widget.currentUser.displayName,
      isTeacher: false,
    );
    _loadLiveKitConfig(room);

    final startDiff = DateTime.now().difference(widget.live.scheduledAt).inSeconds;
    _secondsElapsed = startDiff > 0 ? startDiff : 0;

    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  Future<void> _loadLiveKitConfig(String room) async {
    final config = await LiveKitService().fetchConnectionConfig(
      roomName: room,
      participantIdentity: widget.currentUser.uid,
      participantName: widget.currentUser.displayName,
      isTeacher: false,
    );
    if (mounted && config['token'] != null && (config['token'] as String).isNotEmpty) {
      setState(() {
        _liveKitConfig = config;
      });
    }
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _msgCtrl.dispose();
    _scrollController.dispose();
    widget.onLeave();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _toggleHandRaise() {
    setState(() {
      _isHandRaised = !_isHandRaised;
    });

    final handMsg = _isHandRaised
        ? '✋ ${widget.currentUser.displayName} a levé la main pour une question !'
        : '👇 ${widget.currentUser.displayName} a baissé la main.';

    _chatService.sendMessage(
      conversationId: widget.live.id,
      senderId: widget.currentUser.uid,
      senderName: widget.currentUser.displayName,
      senderRole: 'student',
      content: handMsg,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isHandRaised
            ? 'Votre main est levée. Le formateur a reçu votre notification !'
            : 'Vous avez baissé la main.'),
        backgroundColor: _isHandRaised ? const Color(0xFFEAB308) : AppTheme.ink,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _sendMessage() {
    final text = _msgCtrl.text.trim();
    if (text.isNotEmpty) {
      _chatService.sendMessage(
        conversationId: widget.live.id,
        senderId: widget.currentUser.uid,
        senderName: widget.currentUser.displayName,
        senderRole: 'student',
        content: text,
      );
      _msgCtrl.clear();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 800;
    final isInteractivePhase = _secondsElapsed < 3600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 1020,
        height: 680,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Header Bar with LiveKit Connection & Live Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                border: Border(bottom: BorderSide(color: Color(0xFF334155))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sensors_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'EN DIRECT',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.8),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.live.title,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Animé par ${widget.live.teacherName} • ${widget.live.courseName}',
                          style: const TextStyle(color: Colors.white60, fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'LiveKit: ${_liveKitConfig['serverUrl']}',
                          style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    tooltip: 'Quitter la session',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Phase and timer banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isInteractivePhase ? const Color(0xFF064E3B) : const Color(0xFF0369A1),
              child: Row(
                children: [
                  Icon(
                    isInteractivePhase ? Icons.record_voice_over_rounded : Icons.code_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isInteractivePhase
                          ? 'Phase 1 : Cours interactif & Démonstration (1h)'
                          : 'Phase 2 : Exercices pratiques & Questions/Réponses (30m)',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '⏱ ${_formatDuration(_secondsElapsed)}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),

            // Main Content Area: Video Player + Chat
            Expanded(
              child: isCompact
                  ? Column(
                      children: [
                        Expanded(flex: 5, child: _buildVideoFrame()),
                        Expanded(flex: 5, child: _buildChatFrame()),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(flex: 65, child: _buildVideoFrame()),
                        Expanded(flex: 35, child: _buildChatFrame()),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoFrame() {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.mintAccent.withValues(alpha: 0.4), width: 3),
                        ),
                        child: const Center(
                          child: Icon(Icons.person_rounded, size: 52, color: AppTheme.mintAccent),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        widget.live.teacherName,
                        style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Présentation en direct via LiveKit Cloud',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF10B981)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.volume_up_rounded, color: Color(0xFF10B981), size: 14),
                                SizedBox(width: 4),
                                Text('Audio Enseignant Actif', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                          if (_isHandRaised) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAB308).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFEAB308)),
                              ),
                              child: const Row(
                                children: [
                                  Text('✋ Main Levée', style: TextStyle(color: Color(0xFFEAB308), fontSize: 10, fontWeight: FontWeight.w800)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Text(
                      'Salon : ${widget.live.id}',
                      style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Control Bar for Students
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF0B132B),
              border: Border(top: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  tooltip: _isMuted ? 'Activer le son' : 'Couper le son',
                  icon: Icon(
                    _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                    color: _isMuted ? Colors.redAccent : Colors.white70,
                  ),
                  onPressed: () => setState(() => _isMuted = !_isMuted),
                ),

                ElevatedButton.icon(
                  onPressed: _toggleHandRaise,
                  icon: Text(_isHandRaised ? '👇' : '✋', style: const TextStyle(fontSize: 16)),
                  label: Text(
                    _isHandRaised ? 'Baisser la main' : 'Lever la main',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _isHandRaised ? const Color(0xFF0F172A) : Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isHandRaised ? const Color(0xFFEAB308) : const Color(0xFF334155),
                    elevation: _isHandRaised ? 4 : 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: _isHandRaised ? const Color(0xFFFACC15) : Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                ),

                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 16),
                  label: const Text('Quitter', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatFrame() {
    return Container(
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              border: Border(bottom: BorderSide(color: Color(0xFF334155))),
            ),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.mintAccent, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Échanges en direct',
                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                ),
                const Spacer(),
                Text(
                  '${widget.live.activeViewersCount} participant(s)',
                  style: const TextStyle(color: Colors.white60, fontSize: 10),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.getMessagesStream(widget.live.id),
              builder: (context, snapshot) {
                final msgs = snapshot.data ?? [];
                if (msgs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.forum_outlined, color: Colors.white.withValues(alpha: 0.3), size: 36),
                          const SizedBox(height: 8),
                          Text(
                            'Le chat est ouvert !\nPosez vos questions au formateur.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: msgs.length,
                  itemBuilder: (context, index) {
                    final m = msgs[index];
                    final isMe = m.senderId == widget.currentUser.uid;
                    final isTeacher = m.senderRole == 'teacher';
                    final isHandNotification = m.content.contains('✋') || m.content.contains('👇');

                    if (isHandNotification) {
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAB308).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFEAB308).withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          m.content,
                          style: const TextStyle(color: Color(0xFFFDE047), fontSize: 11, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isMe ? 'Vous' : m.senderName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                  color: isTeacher ? const Color(0xFF38BDF8) : AppTheme.mintAccent,
                                ),
                              ),
                              if (isTeacher) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0284C7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('FORMATEUR', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isMe ? AppTheme.emeraldGreenDark : const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              m.content,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              border: Border(top: BorderSide(color: Color(0xFF334155))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Poser une question en direct...',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppTheme.mintAccent),
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: AppTheme.mintAccent),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

