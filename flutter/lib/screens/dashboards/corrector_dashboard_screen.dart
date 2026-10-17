import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/chat_model.dart';
import '../../models/homework_model.dart';
import '../../models/live_session_model.dart';
import '../../models/trainer_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/corrector_service.dart';
import '../../services/homework_service.dart';
import '../../services/live_session_service.dart';
import '../../services/trainer_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/file_download_helper.dart';
import '../../widgets/app_notification_bell.dart';
import '../../widgets/homework_assignment_dialog.dart';
import '../../widgets/legal_documents_widget.dart';
import '../../widgets/marketing_section_header.dart';
import '../../widgets/voice_message_widgets.dart';

class CorrectorDashboardScreen extends StatefulWidget {
  const CorrectorDashboardScreen({super.key});

  @override
  State<CorrectorDashboardScreen> createState() =>
      _CorrectorDashboardScreenState();
}

class _CorrectorDashboardScreenState extends State<CorrectorDashboardScreen> {
  final AuthService _authService = AuthService();
  final HomeworkService _homeworkService = HomeworkService();
  final CorrectorService _correctorService = CorrectorService();
  final ChatService _chatService = ChatService();
  final LiveSessionService _liveService = LiveSessionService();
  final TrainerService _trainerService = TrainerService();

  String _activeMenu = 'Tableau de bord';
  UserModel? _linkedTeacher;
  String? _conversationId;
  bool _loadingTeacher = true;
  String? _activeLiveSessionId;

  // Active messaging contact
  String _activeContactId = 'admin_master_1';
  String _activeContactName = 'Support Administrateur';
  String _activeContactRole = 'Super Admin';
  String? _activeContactPhoto;

  // Sub-tab for homeworks view: 0 = Copies reçues en attente, 1 = Sujets de devoirs
  int _homeworkTabIndex = 0;

  // Live timer
  Timer? _liveTimer;
  int _liveElapsedSeconds = 0;

  // Chat
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadLinkedTeacher();
  }

  Future<void> _loadLinkedTeacher() async {
    final user = _authService.currentUser ?? UserModel.demoCorrector;
    UserModel? teacher;
    try {
      teacher = await _correctorService.getLinkedTeacher(user.uid);
    } catch (_) {}

    if (mounted) {
      setState(() {
        _linkedTeacher = teacher;
        _loadingTeacher = false;
      });
    }

    if (teacher != null) {
      _activeContactId = teacher.uid;
      _activeContactName = teacher.displayName;
      _activeContactRole = 'Formateur Référent';
      _activeContactPhoto = teacher.photoUrl;
      final convId = await _correctorService.openTeacherCorrectorConversation(
        currentUserId: user.uid,
        currentUserName: user.displayName,
        currentUserPhoto: user.photoUrl ?? '',
        otherUserId: teacher.uid,
        otherUserName: teacher.displayName,
        otherUserPhoto: teacher.photoUrl ?? '',
      );
      if (mounted) setState(() => _conversationId = convId);
    } else {
      // Connect to Super Admin / Support by default so messaging is 100% functional
      _activeContactId = UserModel.demoAdmin.uid;
      _activeContactName = 'Support Administrateur';
      _activeContactRole = 'Super Admin';
      _activeContactPhoto = UserModel.demoAdmin.photoUrl;
      final convId = await _chatService.getOrCreateConversation(
        currentUserId: user.uid,
        currentUserName: user.displayName,
        currentUserPhoto: user.photoUrl ?? '',
        targetUserId: UserModel.demoAdmin.uid,
        targetUserName: 'Support Administrateur',
        targetUserPhoto: UserModel.demoAdmin.photoUrl ?? '',
        courseName: 'Support & Coordination Pédagogique',
      );
      if (mounted) setState(() => _conversationId = convId);
    }
  }

  Future<void> _switchConversation({
    required String contactId,
    required String contactName,
    required String contactRole,
    String? contactPhoto,
    String courseName = 'Coordination Pédagogique',
  }) async {
    final user = _authService.currentUser ?? UserModel.demoCorrector;
    setState(() {
      _activeContactId = contactId;
      _activeContactName = contactName;
      _activeContactRole = contactRole;
      _activeContactPhoto = contactPhoto;
      _conversationId = null;
    });

    try {
      final convId = await _chatService.getOrCreateConversation(
        currentUserId: user.uid,
        currentUserName: user.displayName,
        currentUserPhoto: user.photoUrl ?? '',
        targetUserId: contactId,
        targetUserName: contactName,
        targetUserPhoto: contactPhoto ?? '',
        courseName: courseName,
      );
      if (mounted) {
        setState(() => _conversationId = convId);
      }
    } catch (e) {
      debugPrint('Error switching conversation: $e');
    }
  }

  void _showNewConversationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.forum_rounded, color: AppTheme.emeraldGreenDark),
            const SizedBox(width: 10),
            Text(
              'Choisir un interlocuteur',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: AppTheme.ink,
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: SingleChildScrollView(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Échangez directement avec le Support Administrateur ou l\'un des formateurs de la plateforme :',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 16),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppTheme.cardBorder),
                ),
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEF4444),
                  child: Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 20),
                ),
                title: const Text('Support Administrateur', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                subtitle: const Text('Supervision & Affectation des cours', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  Navigator.pop(ctx);
                  _switchConversation(
                    contactId: UserModel.demoAdmin.uid,
                    contactName: 'Support Administrateur',
                    contactRole: 'Super Admin',
                    contactPhoto: UserModel.demoAdmin.photoUrl,
                    courseName: 'Support Général & Coordination',
                  );
                },
              ),
              const SizedBox(height: 14),
              const Text('Formateurs de la plateforme :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.ink)),
              const SizedBox(height: 8),
              FutureBuilder<List<TrainerModel>>(
                future: _trainerService.getExpertTrainers(),
                builder: (context, snapshot) {
                  final trainers = snapshot.data ?? [];
                  if (trainers.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Chargement des formateurs...', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    );
                  }
                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 240),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: trainers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final t = trainers[idx];
                        final isAssigned = _linkedTeacher?.uid == t.id;
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isAssigned ? AppTheme.emeraldGreen : AppTheme.cardBorder,
                              width: isAssigned ? 1.5 : 1,
                            ),
                          ),
                          tileColor: isAssigned ? AppTheme.paleMint.withValues(alpha: 0.3) : Colors.transparent,
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.emeraldGreen,
                            child: Text(
                              t.name.isNotEmpty ? t.name[0].toUpperCase() : 'T',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  t.name,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isAssigned)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.emeraldGreenDark,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('Assigné', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          subtitle: Text(t.role, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted), overflow: TextOverflow.ellipsis),
                          trailing: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppTheme.emeraldGreenDark),
                          onTap: () {
                            Navigator.pop(ctx);
                            _switchConversation(
                              contactId: t.id,
                              contactName: t.name,
                              contactRole: 'Formateur : ${t.role}',
                              contactPhoto: t.image,
                              courseName: 'Discussion formateur - correcteur',
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
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

  @override
  void dispose() {
    _liveTimer?.cancel();
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _startLiveTimer() {
    _liveElapsedSeconds = 0;
    _liveTimer?.cancel();
    _liveTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _liveElapsedSeconds++);
    });
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _startLive() async {
    final user = _authService.currentUser ?? UserModel.demoCorrector;
    final sessionId = await _correctorService.startCorrectorLive(
      correctorId: user.uid,
      correctorName: user.displayName,
      correctorPhotoUrl: user.photoUrl ?? '',
      courseId: _linkedTeacher?.uid ?? 'general',
      courseName: 'Session de correction & exercices',
      title: 'Live exercices - ${user.displayName}',
    );
    if (mounted) {
      setState(() => _activeLiveSessionId = sessionId);
      _startLiveTimer();
    }
  }

  Future<void> _endLive() async {
    if (_activeLiveSessionId == null) return;
    await _liveService.endLiveSession(
      sessionId: _activeLiveSessionId!,
      courseId: _linkedTeacher?.uid ?? 'general',
      title: 'Session de correction & exercices',
    );
    _liveTimer?.cancel();
    if (mounted) setState(() => _activeLiveSessionId = null);
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser ?? UserModel.demoCorrector;
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      bottomNavigationBar: !isWide ? _buildBottomNavBar() : null,
      body: Row(
        children: [
          // Sidebar
          if (isWide) _buildSidebar(user),
          // Content
          Expanded(
            child: Column(
              children: [
                _buildTopBar(user),
                Expanded(child: _buildBody(user)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    final navItems = [
      ('Tableau de bord', Icons.dashboard_rounded),
      ('Devoirs à corriger', Icons.assignment_rounded),
      ('Mes corrections', Icons.rate_review_rounded),
      ('Live exercices', Icons.videocam_rounded),
      ('Messagerie', Icons.chat_bubble_rounded),
    ];

    int currentIndex = navItems.indexWhere((it) => it.$1 == _activeMenu);
    if (currentIndex == -1) currentIndex = 0;

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (idx) {
        setState(() => _activeMenu = navItems[idx].$1);
      },
      destinations: navItems.map((it) {
        return NavigationDestination(
          icon: Icon(it.$2),
          selectedIcon: Icon(it.$2, color: AppTheme.emeraldGreenDark),
          label: it.$1 == 'Devoirs à corriger' ? 'Devoirs' : (it.$1 == 'Tableau de bord' ? 'Accueil' : it.$1),
        );
      }).toList(),
    );
  }

  Widget _buildSidebar(UserModel user) {
    final items = [
      ('Tableau de bord', Icons.dashboard_rounded),
      ('Devoirs à corriger', Icons.assignment_rounded),
      ('Mes corrections', Icons.rate_review_rounded),
      ('Live exercices', Icons.videocam_rounded),
      ('Messagerie', Icons.chat_bubble_rounded),
    ];
    return Container(
      width: 240,
      color: const Color(0xFF062C32),
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Espace Correcteur',
                    style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14),
                  ),
                ),
              ],
            ),
          ),

          // User info
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.emeraldGreen,
                  child: Text(
                    user.displayName.isNotEmpty
                        ? user.displayName[0].toUpperCase()
                        : 'C',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.displayName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12),
                          overflow: TextOverflow.ellipsis),
                      const Text('Correcteur Certifié',
                          style:
                              TextStyle(color: AppTheme.emeraldGreen, fontSize: 10, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Nav items
          for (final item in items)
            _NavItem(
              icon: item.$2,
              label: item.$1,
              isActive: _activeMenu == item.$1,
              onTap: () => setState(() => _activeMenu = item.$1),
            ),

          const Spacer(),

          // Legal documents
          Padding(
            padding: const EdgeInsets.all(16),
            child: LegalDocumentsFAB(userId: user.uid),
          ),

          // Logout
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton.icon(
              onPressed: () async {
                await AuthService().signOut();
                if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
              },
              icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 18),
              label: const Text('Déconnexion', style: TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(UserModel user) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 12, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.cardBorder, width: 1)),
      ),
      child: Row(
        children: [
          if (!isWide) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.ink, size: 20),
              tooltip: 'Retour',
              onPressed: () {
                setState(() {
                  if (_activeMenu != 'Tableau de bord') {
                    _activeMenu = 'Tableau de bord';
                  } else if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushNamed(context, '/');
                  }
                });
              },
            ),
            const SizedBox(width: 4),
          ],
          Text(
            _activeMenu,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.ink),
          ),
          const Spacer(),
          if (_linkedTeacher != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.paleMint,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_pin_rounded,
                      size: 14, color: AppTheme.emeraldGreenDark),
                  const SizedBox(width: 6),
                  Text(
                    'Professeur associé : ${_linkedTeacher!.displayName}',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.emeraldGreenDark),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user_rounded, size: 14, color: Color(0xFF2563EB)),
                  SizedBox(width: 6),
                  Text(
                    'Correcteur Général • Tous les cours',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D4ED8)),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 14),
          AppNotificationBell(
            userId: user.uid,
            onNotificationAction: (n) {
              if (n.type == 'live_started' || n.data['sessionId'] != null) {
                setState(() {
                  _activeMenu = 'Live exercices';
                });
              } else if (n.type == 'homework_submitted') {
                setState(() {
                  _activeMenu = 'Devoirs à corriger';
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody(UserModel user) {
    switch (_activeMenu) {
      case 'Devoirs à corriger':
      case 'Devoirs a corriger':
        return _buildHomeworksView(user);
      case 'Mes corrections':
        return _buildMyCorrectionsView(user);
      case 'Live exercices':
        return _buildLiveView(user);
      case 'Messagerie':
        return _buildMessagingView(user);
      default:
        return _buildDashboardView(user);
    }
  }

  Widget _buildDashboardView(UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bienvenue, ${user.displayName} ! 👋',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink)),
          const SizedBox(height: 4),
          const Text('Espace pédagogique et évaluation des devoirs des apprenants',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          const SizedBox(height: 24),

          // Stats cards
          LayoutBuilder(builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 640;
            final card1 = _StatCard(
              label: 'Copies en attente d\'évaluation',
              icon: Icons.assignment_late_rounded,
              color: const Color(0xFFF59E0B),
              stream: _homeworkService
                  .getAllSubmissionsStream()
                  .map((subs) => subs.where((s) => s.status != 'corrected').length.toString()),
            );
            final card2 = _StatCard(
              label: 'Corrections effectuées',
              icon: Icons.check_circle_rounded,
              color: AppTheme.emeraldGreen,
              stream: _homeworkService
                  .getCorrectorCorrectionsStream(user.uid)
                  .map((c) => c.length.toString()),
            );
            final card3 = _StatCard(
              label: 'Formateur associé',
              icon: Icons.person_rounded,
              color: const Color(0xFF6366F1),
              value: _linkedTeacher?.displayName ?? 'Plateforme Générale (Tous les cours)',
            );
            final card4 = _StatCard(
              label: 'Session live d\'exercices',
              icon: Icons.videocam_rounded,
              color: const Color(0xFFEC4899),
              value: _activeLiveSessionId != null
                  ? 'En cours (${_formatDuration(_liveElapsedSeconds)})'
                  : 'Prêt à démarrer (1h30)',
            );

            if (isMobile) {
              return Column(
                children: [
                  card1,
                  const SizedBox(height: 12),
                  card2,
                  const SizedBox(height: 12),
                  card3,
                  const SizedBox(height: 12),
                  card4,
                ],
              );
            }

            return Column(
              children: [
                Row(children: [Expanded(child: card1), const SizedBox(width: 16), Expanded(child: card2)]),
                const SizedBox(height: 16),
                Row(children: [Expanded(child: card3), const SizedBox(width: 16), Expanded(child: card4)]),
              ],
            );
          }),
          const SizedBox(height: 24),

          // Quick actions
          Text('Actions rapides',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _QuickAction(
                icon: Icons.fact_check_rounded,
                label: 'Évaluer les copies en attente',
                color: const Color(0xFFF59E0B),
                onTap: () => setState(() {
                  _activeMenu = 'Devoirs à corriger';
                  _homeworkTabIndex = 0;
                }),
              ),
              _QuickAction(
                icon: Icons.chat_bubble_rounded,
                label: 'Messagerie & Support Prof/Admin',
                color: AppTheme.emeraldGreenDark,
                onTap: () => setState(() => _activeMenu = 'Messagerie'),
              ),
              _QuickAction(
                icon: Icons.videocam_rounded,
                label: 'Lancer un live d\'exercices',
                color: const Color(0xFFEC4899),
                onTap: () => setState(() => _activeMenu = 'Live exercices'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHomeworksView(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MarketingSectionHeader(
                badge: 'CORRECTIONS & ÉVALUATIONS',
                title: 'Copies & devoirs des apprenants',
                subtitle: 'Corrigez les devoirs, notez sur /20 et prodiguez des conseils personnalisés.',
              ),
              const SizedBox(height: 16),
              // Segmented selector & Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _TabPill(
                        label: 'Copies reçues à corriger',
                        icon: Icons.fact_check_rounded,
                        isSelected: _homeworkTabIndex == 0,
                        onTap: () => setState(() => _homeworkTabIndex = 0),
                      ),
                      const SizedBox(width: 10),
                      _TabPill(
                        label: 'Sujets & Barèmes',
                        icon: Icons.assignment_rounded,
                        isSelected: _homeworkTabIndex == 1,
                        onTap: () => setState(() => _homeworkTabIndex = 1),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_task_rounded, size: 16),
                    label: const Text('Assigner un devoir / TP', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emeraldGreenDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => HomeworkAssignmentDialog.show(context, user: user),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.cardBorder),
        Expanded(
          child: _homeworkTabIndex == 0
              ? _buildPendingSubmissionsList(user)
              : _buildHomeworkSubjectsList(user),
        ),
      ],
    );
  }

  Widget _buildPendingSubmissionsList(UserModel user) {
    return StreamBuilder<List<HomeworkModel>>(
      stream: _homeworkService.getHomeworksStream(),
      builder: (context, hwSnapshot) {
        final allHomeworks = hwSnapshot.data ?? [];
        final Map<String, HomeworkModel> hwMap = {
          for (final hw in allHomeworks) hw.id: hw,
        };

        return StreamBuilder<List<HomeworkSubmissionModel>>(
          stream: _homeworkService.getAllSubmissionsStream(),
          builder: (context, subSnapshot) {
            if (subSnapshot.connectionState == ConnectionState.waiting && !subSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.emeraldGreen));
            }

            final submissions = subSnapshot.data ?? [];
            if (submissions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 64, color: AppTheme.emeraldGreen),
                    const SizedBox(height: 16),
                    Text(
                      'Toutes les copies sont à jour !',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Aucune nouvelle copie en attente de correction pour le moment.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              );
            }

            // Sort: pending first, then by date desc
            final sorted = List<HomeworkSubmissionModel>.from(submissions)
              ..sort((a, b) {
                if (a.status != 'corrected' && b.status == 'corrected') return -1;
                if (a.status == 'corrected' && b.status != 'corrected') return 1;
                return b.submittedAt.compareTo(a.submittedAt);
              });

            return ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final sub = sorted[index];
                final hw = hwMap[sub.homeworkId] ??
                    HomeworkModel(
                      id: sub.homeworkId,
                      title: 'Devoir : ${sub.homeworkId}',
                      courseId: 'general',
                      courseName: 'Formation Club des Formateurs',
                      teacherId: _linkedTeacher?.uid ?? 'teacher_1',
                      teacherName: _linkedTeacher?.displayName ?? 'Professeur',
                      description: 'Consignes du devoir',
                      deadline: DateTime.now().add(const Duration(days: 7)),
                      createdAt: DateTime.now(),
                    );

                final isCorrected = sub.status == 'corrected';
                final isBlankPage = sub.submissionType == 'blank_page' ||
                    (sub.blankPageContent != null && sub.blankPageContent!.isNotEmpty);

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCorrected ? AppTheme.cardBorder : const Color(0xFFF59E0B).withValues(alpha: 0.4),
                      width: isCorrected ? 1 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: isCorrected ? AppTheme.paleMint : const Color(0xFFFEF3C7),
                          child: Icon(
                            isCorrected ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                            color: isCorrected ? AppTheme.emeraldGreenDark : const Color(0xFFD97706),
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
                                  Text(
                                    sub.studentName.isNotEmpty ? sub.studentName : sub.studentId,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppTheme.ink,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isBlankPage ? AppTheme.paleMint : const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isBlankPage ? 'Page Blanche' : 'Document Joint',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: isBlankPage ? AppTheme.emeraldGreenDark : const Color(0xFF1D4ED8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${hw.title} • ${hw.courseName}',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Remis le ${sub.submittedAt.day.toString().padLeft(2, '0')}/${sub.submittedAt.month.toString().padLeft(2, '0')}/${sub.submittedAt.year}',
                                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (isCorrected) ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.paleMint,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Note : ${(sub.grade ?? sub.note ?? 16).toStringAsFixed(1)}/${hw.points}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.emeraldGreenDark,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              TextButton(
                                onPressed: () => _openCorrectionModal(context, sub, hw, user),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('Revoir la copie', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                              ),
                            ],
                          ),
                        ] else ...[
                          ElevatedButton.icon(
                            icon: const Icon(Icons.edit_note_rounded, size: 16),
                            label: const Text('Corriger la copie', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.emeraldGreenDark,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _openCorrectionModal(context, sub, hw, user),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildHomeworkSubjectsList(UserModel user) {
    final stream = _linkedTeacher != null
        ? _homeworkService.getHomeworksByTeacherStream(_linkedTeacher!.uid)
        : _homeworkService.getHomeworksStream();

    return StreamBuilder<List<HomeworkModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.emeraldGreen));
        }
        final homeworks = snapshot.data ?? [];
        if (homeworks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.assignment_outlined, size: 64, color: AppTheme.textMuted),
                const SizedBox(height: 16),
                Text('Aucun sujet de devoir publié',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink)),
                const SizedBox(height: 8),
                const Text(
                    'Les professeurs n\'ont pas encore publié de devoirs.',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          itemCount: homeworks.length,
          itemBuilder: (context, index) {
            final hw = homeworks[index];
            return _HomeworkCorrectorCard(
              homework: hw,
              correctorId: user.uid,
              correctorName: user.displayName,
              homeworkService: _homeworkService,
              onCorrectSubmission: (sub) => _openCorrectionModal(context, sub, hw, user),
            );
          },
        );
      },
    );
  }

  Widget _buildMyCorrectionsView(UserModel user) {
    return StreamBuilder<List<CorrectionModel>>(
      stream: _homeworkService.getCorrectorCorrectionsStream(user.uid),
      builder: (context, snapshot) {
        final corrections = snapshot.data ?? [];
        if (corrections.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.rate_review_outlined, size: 64, color: AppTheme.textMuted),
                const SizedBox(height: 16),
                Text(
                  'Aucune correction enregistrée',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Vos copies corrigées et notes validées s\'afficheront ici.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: MarketingSectionHeader(
                badge: 'HISTORIQUE DES ÉVALUATIONS',
                title: 'Copies corrigées & notes attribuées',
                subtitle: 'Retrouvez l\'ensemble de vos évaluations pédagogiques et appréciations.',
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: corrections.length,
                itemBuilder: (context, i) {
                  final c = corrections[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppTheme.cardBorder)),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppTheme.paleMint,
                            child: Text(
                              c.note != null ? '${c.note!.round()}' : 'N/A',
                              style: const TextStyle(
                                  color: AppTheme.emeraldGreenDark,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Devoir : ${c.homeworkId}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: AppTheme.ink,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${c.correctedAt.day}/${c.correctedAt.month}/${c.correctedAt.year}',
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Apprenant : ${c.studentId}',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.emeraldGreenDark, fontWeight: FontWeight.w600),
                                ),
                                if (c.comment.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    '« ${c.comment} »',
                                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppTheme.ink),
                                  ),
                                ],
                              ],
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
        );
      },
    );
  }

  Widget _buildLiveView(UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MarketingSectionHeader(
            badge: 'LIVE',
            title: 'Session Live - Exercices & Corrigés',
            subtitle: 'Vos sessions live sont entièrement dédiées à la résolution des exercices en direct (1h30).',
          ),
          const SizedBox(height: 24),

          // Active Teacher Live Sessions Banner
          StreamBuilder<List<LiveSessionModel>>(
            stream: _liveService.getActiveLiveSessionsStream(),
            builder: (context, snapshot) {
              final activeLives = (snapshot.data ?? [])
                  .where((s) => s.status == 'live' && s.id != _activeLiveSessionId)
                  .toList();
              if (activeLives.isEmpty) return const SizedBox.shrink();

              return Column(
                children: [
                  for (final live in activeLives)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text('EN DIRECT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(live.courseName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.ink), overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('Professeur : ${live.teacherName} • ${live.title}', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.videocam_rounded, size: 16),
                            label: const Text('Rejoindre', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () async {
                              await _liveService.joinLiveSession(live.id, user.uid);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Vous avez rejoint la session de ${live.teacherName} !'),
                                    backgroundColor: AppTheme.emeraldGreenDark,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),

          // Timer card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A4A5C), Color(0xFF062C32)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(Icons.videocam_rounded,
                    color: AppTheme.emeraldGreen, size: 40),
                const SizedBox(height: 12),
                if (_activeLiveSessionId != null) ...[
                  const Text('Live en direct avec les apprenants',
                      style: TextStyle(
                          color: AppTheme.emeraldGreen,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                    _formatDuration(_liveElapsedSeconds),
                    style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Durée max recommandée : 1h30 (${90 - (_liveElapsedSeconds ~/ 60)} min restantes)',
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: (_liveElapsedSeconds / (90 * 60)).clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.emeraldGreen),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Phase badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.emeraldGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fitness_center_rounded,
                            color: AppTheme.emeraldGreen, size: 16),
                        SizedBox(width: 8),
                        Text('Phase : Résolution des travaux pratiques',
                            style: TextStyle(
                                color: AppTheme.emeraldGreen,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.stop_circle_rounded),
                      label: const Text('Terminer la session live',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _endLive,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  const Text('Aucun live en cours',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text(
                    'Vous pouvez animer une session live dédiée aux questions-réponses et corrections.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.play_circle_filled_rounded),
                      label: const Text('Démarrer le live exercices (1h30)',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emeraldGreen,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _startLive,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagingView(UserModel user) {
    if (_loadingTeacher) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.emeraldGreen));
    }

    final isWide = MediaQuery.of(context).size.width >= 800;

    return Row(
      children: [
        // Left Column: Active discussions & contacts list
        if (isWide)
          Container(
            width: 280,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: AppTheme.cardBorder)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Interlocuteurs',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppTheme.ink,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.person_add_alt_1_rounded, size: 20, color: AppTheme.emeraldGreenDark),
                        tooltip: 'Contacter un formateur',
                        onPressed: _showNewConversationDialog,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppTheme.cardBorder),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      // Admin Support item
                      _buildContactTile(
                        id: UserModel.demoAdmin.uid,
                        name: 'Support Administrateur',
                        role: 'Super Admin',
                        icon: Icons.admin_panel_settings_rounded,
                        badgeColor: const Color(0xFFEF4444),
                        isSelected: _activeContactId == UserModel.demoAdmin.uid,
                        onTap: () => _switchConversation(
                          contactId: UserModel.demoAdmin.uid,
                          contactName: 'Support Administrateur',
                          contactRole: 'Super Admin',
                          contactPhoto: UserModel.demoAdmin.photoUrl,
                          courseName: 'Support Général & Coordination',
                        ),
                      ),
                      // Assigned Teacher item if exists
                      if (_linkedTeacher != null)
                        _buildContactTile(
                          id: _linkedTeacher!.uid,
                          name: _linkedTeacher!.displayName,
                          role: 'Formateur Assigné',
                          icon: Icons.school_rounded,
                          badgeColor: AppTheme.emeraldGreen,
                          isSelected: _activeContactId == _linkedTeacher!.uid,
                          onTap: () => _switchConversation(
                            contactId: _linkedTeacher!.uid,
                            contactName: _linkedTeacher!.displayName,
                            contactRole: 'Formateur Référent',
                            contactPhoto: _linkedTeacher!.photoUrl,
                            courseName: 'Coordination Pédagogique',
                          ),
                        ),
                      // Other active contact if selected
                      if (_activeContactId != UserModel.demoAdmin.uid &&
                          (_linkedTeacher == null || _activeContactId != _linkedTeacher!.uid))
                        _buildContactTile(
                          id: _activeContactId,
                          name: _activeContactName,
                          role: _activeContactRole,
                          icon: Icons.person_rounded,
                          badgeColor: const Color(0xFF6366F1),
                          isSelected: true,
                          onTap: () {},
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add_comment_rounded, size: 16),
                      label: const Text('Choisir un formateur', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.emeraldGreenDark,
                        side: const BorderSide(color: AppTheme.emeraldGreen),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _showNewConversationDialog,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Right Column: Main Chat Room
        Expanded(
          child: Column(
            children: [
              // Chat Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: Colors.white,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: _activeContactId == UserModel.demoAdmin.uid
                          ? const Color(0xFFEF4444)
                          : AppTheme.emeraldGreen,
                      backgroundImage: _activeContactPhoto != null && _activeContactPhoto!.isNotEmpty
                          ? NetworkImage(_activeContactPhoto!)
                          : null,
                      child: (_activeContactPhoto == null || _activeContactPhoto!.isEmpty)
                          ? Text(
                              _activeContactName.isNotEmpty ? _activeContactName[0].toUpperCase() : 'C',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _activeContactName,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppTheme.ink,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _activeContactRole,
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                      label: const Text('Changer d\'interlocuteur', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.paleMint,
                        foregroundColor: AppTheme.emeraldGreenDark,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _showNewConversationDialog,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.cardBorder),

              // Chat Messages
              Expanded(
                child: _conversationId == null
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.emeraldGreen))
                    : StreamBuilder<List<MessageModel>>(
                        stream: _chatService.getMessagesStream(_conversationId!),
                        builder: (context, snapshot) {
                          final messages = snapshot.data ?? [];
                          if (messages.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: AppTheme.paleMint,
                                    child: const Icon(Icons.chat_bubble_outline_rounded, size: 28, color: AppTheme.emeraldGreenDark),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'Début de la conversation',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: AppTheme.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Échangez directement avec $_activeContactName.',
                                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          }
                          return ListView.builder(
                            controller: _chatScrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: messages.length,
                            itemBuilder: (context, i) {
                              final msg = messages[i];
                              final isMe = msg.senderId == user.uid;
                              return Align(
                                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  constraints: const BoxConstraints(maxWidth: 360),
                                  decoration: BoxDecoration(
                                    color: isMe ? AppTheme.emeraldGreenDark : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: isMe ? null : Border.all(color: AppTheme.cardBorder),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.03),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                    children: [
                                      if (!isMe)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 4),
                                          child: Text(
                                            msg.senderName,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.emeraldGreenDark,
                                            ),
                                          ),
                                        ),
                                      Text(
                                        msg.content,
                                        style: TextStyle(
                                          color: isMe ? Colors.white : AppTheme.ink,
                                          fontSize: 13,
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: isMe ? Colors.white70 : AppTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),

              // Suggestion chips
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: Colors.white,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _QuickChip(
                        label: 'Demande de barème officiel',
                        onTap: () {
                          _chatController.text = 'Bonjour, pourriez-vous me transmettre le barème de notation officiel pour ce devoir ?';
                        },
                      ),
                      const SizedBox(width: 8),
                      _QuickChip(
                        label: 'Copies corrigées prêtes',
                        onTap: () {
                          _chatController.text = 'Bonjour, l\'ensemble des copies reçues a été évalué et validé avec retours détaillés.';
                        },
                      ),
                      const SizedBox(width: 8),
                      _QuickChip(
                        label: 'Question sur l\'énoncé',
                        onTap: () {
                          _chatController.text = 'Bonjour, plusieurs apprenants ont posé une question sur la consigne 2. Devons-nous accepter les deux variantes ?';
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Input Bar with VoiceRecordingBar
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                child: VoiceRecordingBar(
                  conversationId: _conversationId ?? 'corrector_',
                  onAudioSent: (audioUrl, duration) async {
                    if (_conversationId == null) return;
                    await _chatService.sendMessage(
                      conversationId: _conversationId!,
                      senderId: user.uid,
                      senderName: user.displayName,
                      senderRole: 'corrector',
                      content: 'Message vocal (s)',
                      type: MessageType.audio,
                      fileUrl: audioUrl,
                      audioDuration: duration,
                    );
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _chatController,
                          onSubmitted: (_) => _sendMessage(user),
                          decoration: InputDecoration(
                            hintText: 'Écrire un message à ...',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(color: AppTheme.cardBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(color: AppTheme.cardBorder),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        style: IconButton.styleFrom(backgroundColor: AppTheme.emeraldGreenDark),
                        icon: const Icon(Icons.send_rounded, color: Colors.white),
                        onPressed: () => _sendMessage(user),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactTile({
    required String id,
    required String name,
    required String role,
    required IconData icon,
    required Color badgeColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.paleMint : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: badgeColor,
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 13,
            color: isSelected ? AppTheme.emeraldGreenDark : AppTheme.ink,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          role,
          style: TextStyle(fontSize: 11, color: isSelected ? AppTheme.emeraldGreenDark : AppTheme.textMuted),
          overflow: TextOverflow.ellipsis,
        ),
        onTap: onTap,
      ),
    );
  }

  Future<void> _sendMessage(UserModel user) async {
    final text = _chatController.text.trim();
    if (text.isEmpty || _conversationId == null) return;
    _chatController.clear();
    await _chatService.sendMessage(
      conversationId: _conversationId!,
      senderId: user.uid,
      senderName: user.displayName,
      senderRole: 'corrector',
      content: text,
    );
  }

  void _openCorrectionModal(
    BuildContext context,
    HomeworkSubmissionModel sub,
    HomeworkModel homework,
    UserModel user,
  ) {
    final noteCtrl = TextEditingController(text: sub.grade?.toString() ?? sub.note?.toString() ?? '');
    final commentCtrl = TextEditingController(text: sub.feedback ?? sub.comment ?? '');

    final isBlankPage = sub.submissionType == 'blank_page' || (sub.blankPageContent != null && sub.blankPageContent!.isNotEmpty);
    final allFiles = <String>[];
    if (sub.fileUrls.isNotEmpty) {
      allFiles.addAll(sub.fileUrls);
    } else if (sub.fileUrl != null && sub.fileUrl!.isNotEmpty) {
      allFiles.add(sub.fileUrl!);
    }
    final hasAttachment = allFiles.isNotEmpty;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 720,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Évaluation de la copie : ${sub.studentName}',
                            style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800, fontSize: 17, color: AppTheme.ink)),
                        const SizedBox(height: 2),
                        Text('Devoir : ${homework.title} • Cours : ${homework.courseName} • Barème : ${homework.points} points',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Subject and Resources Box for corrector reference
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.menu_book_rounded, size: 16, color: AppTheme.emeraldGreenDark),
                        const SizedBox(width: 6),
                        Text(
                          'Sujet du formateur (Barème : ${homework.points} points) :',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.ink),
                        ),
                      ],
                    ),
                    if (homework.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        homework.description,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.35),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (homework.attachmentUrls.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (int i = 0; i < homework.attachmentUrls.length; i++)
                            ActionChip(
                              avatar: Icon(FileDownloadHelper.getFileIcon(homework.getAttachmentName(i)), size: 13, color: AppTheme.emeraldGreenDark),
                              label: Text('Télécharger sujet : ${homework.getAttachmentName(i)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              backgroundColor: AppTheme.paleMint,
                              onPressed: () => FileDownloadHelper.downloadOrOpenFile(
                                homework.attachmentUrls[i],
                                fileName: homework.getAttachmentName(i),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Submission type badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isBlankPage ? AppTheme.paleMint : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isBlankPage ? Icons.edit_note_rounded : Icons.attach_file_rounded,
                        size: 15, color: isBlankPage ? AppTheme.emeraldGreenDark : const Color(0xFF2563EB)),
                    const SizedBox(width: 6),
                    Text(
                      isBlankPage ? 'Rendu sur Page Blanche Numérique' : 'Copie Manuscrite / Document Joint',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isBlankPage ? AppTheme.emeraldGreenDark : const Color(0xFF1D4ED8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Student Submission Display
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Copie remise par l\'apprenant :',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.ink)),
                        const SizedBox(height: 8),

                        if (isBlankPage && sub.blankPageContent != null && sub.blankPageContent!.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: SelectableText(
                              sub.blankPageContent!,
                              style: GoogleFonts.sourceCodePro(fontSize: 13, height: 1.5, color: const Color(0xFF1E293B)),
                            ),
                          )
                        else if (!hasAttachment && (sub.blankPageContent == null || sub.blankPageContent!.isEmpty))
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text('Aucun texte ou document attaché.', style: TextStyle(color: AppTheme.textMuted)),
                            ),
                          ),

                        if (hasAttachment) ...[
                          const SizedBox(height: 10),
                          for (int idx = 0; idx < allFiles.length; idx++) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.cardBorder),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    FileDownloadHelper.getFileIcon(sub.attachmentName ?? allFiles[idx]),
                                    color: FileDownloadHelper.getFileColor(sub.attachmentName ?? allFiles[idx]),
                                    size: 26,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          sub.attachmentName ?? HomeworkModel.extractFileName(allFiles[idx]),
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const Text('Copie / Document remis par l\'étudiant',
                                            style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.download_rounded, size: 14),
                                    label: const Text('Télécharger / Consulter'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.emeraldGreenDark,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () => FileDownloadHelper.downloadOrOpenFile(
                                      allFiles[idx],
                                      fileName: sub.attachmentName ?? HomeworkModel.extractFileName(allFiles[idx]),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Grade and Comments Form
              Row(
                children: [
                  SizedBox(
                    width: 180,
                    child: TextField(
                      controller: noteCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Note sur /${homework.points}',
                        hintText: 'Ex: ${(homework.points * 0.8).toStringAsFixed(1)}',
                        prefixIcon: const Icon(Icons.grade_rounded, color: AppTheme.emeraldGreenDark),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: commentCtrl,
                      decoration: InputDecoration(
                        labelText: 'Appréciation / Remarques pédagogiques',
                        hintText: 'Ex: Démarche rigoureuse, très bonne analyse...',
                        prefixIcon: const Icon(Icons.comment_rounded, color: AppTheme.emeraldGreenDark),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.replay_rounded, size: 16),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD97706),
                      side: const BorderSide(color: Color(0xFFD97706)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      final comment = commentCtrl.text.trim();
                      if (comment.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Veuillez préciser vos remarques dans le commentaire pour demander une révision.')),
                        );
                        return;
                      }
                      await _homeworkService.requestRevision(
                        submissionId: sub.id,
                        feedback: comment,
                      );
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Demande de révision transmise à ${sub.studentName}.'),
                            backgroundColor: const Color(0xFFD97706),
                          ),
                        );
                      }
                    },
                    label: const Text('Demander une révision', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_rounded, size: 18),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emeraldGreenDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      final note = double.tryParse(noteCtrl.text.replaceAll(',', '.'));
                      if (note == null || note < 0 || note > homework.points) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Veuillez entrer une note valide entre 0 et ${homework.points}.')),
                        );
                        return;
                      }

                      await _homeworkService.submitCorrection(
                        submissionId: sub.id,
                        homeworkId: homework.id,
                        correctorId: user.uid,
                        correctorName: user.displayName,
                        studentId: sub.studentId,
                        note: note,
                        comment: commentCtrl.text.trim(),
                      );
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Correction de ${sub.studentName} enregistrée avec la note de $note/${homework.points} !'),
                            backgroundColor: AppTheme.emeraldGreenDark,
                          ),
                        );
                      }
                    },
                    label: Text('Valider & Enregistrer la note (/${homework.points})', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────

class _TabPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabPill({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.emeraldGreenDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.emeraldGreenDark : AppTheme.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : AppTheme.textMuted),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppTheme.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.emeraldGreenDark)),
      backgroundColor: AppTheme.paleMint.withValues(alpha: 0.5),
      side: BorderSide(color: AppTheme.emeraldGreen.withValues(alpha: 0.3)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onPressed: onTap,
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _NavItem(
      {required this.icon,
      required this.label,
      required this.isActive,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.emeraldGreen.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isActive ? AppTheme.emeraldGreen : AppTheme.textMuted,
                size: 18),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                    color: isActive ? AppTheme.emeraldGreen : AppTheme.textMuted,
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final String? value;
  final Stream<String>? stream;

  const _StatCard({
    required this.label,
    required this.icon,
    required this.color,
    this.value,
    this.stream,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 10),
            if (stream != null)
              StreamBuilder<String>(
                stream: stream,
                builder: (context, snap) => Text(
                  snap.data ?? '--',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.ink),
                ),
              )
            else
              Text(
                value ?? '--',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink),
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textMuted)),
          ],
        ),
      );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _HomeworkCorrectorCard extends StatefulWidget {
  final HomeworkModel homework;
  final String correctorId;
  final String correctorName;
  final HomeworkService homeworkService;
  final Function(HomeworkSubmissionModel) onCorrectSubmission;

  const _HomeworkCorrectorCard({
    required this.homework,
    required this.correctorId,
    required this.correctorName,
    required this.homeworkService,
    required this.onCorrectSubmission,
  });

  @override
  State<_HomeworkCorrectorCard> createState() =>
      _HomeworkCorrectorCardState();
}

class _HomeworkCorrectorCardState extends State<_HomeworkCorrectorCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final hw = widget.homework;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.assignment_rounded,
                        color: Color(0xFFF59E0B), size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(hw.title,
                                  style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppTheme.ink)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.paleMint,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${hw.points} pts',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.emeraldGreenDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                            'Cours : ${hw.courseName} • '
                            'Délai : ${hw.deadline.day.toString().padLeft(2, '0')}/${hw.deadline.month.toString().padLeft(2, '0')}/${hw.deadline.year}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.textMuted,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            // Subject Details & Resources
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hw.description.isNotEmpty) ...[
                    Text(
                      hw.description,
                      style: const TextStyle(fontSize: 12, color: AppTheme.ink, height: 1.4),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (hw.attachmentUrls.isNotEmpty) ...[
                    const Text('Ressources du sujet :', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        for (int i = 0; i < hw.attachmentUrls.length; i++)
                          ActionChip(
                            avatar: Icon(FileDownloadHelper.getFileIcon(hw.getAttachmentName(i)), size: 14, color: AppTheme.emeraldGreenDark),
                            label: Text(hw.getAttachmentName(i), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            backgroundColor: AppTheme.paleMint,
                            onPressed: () => FileDownloadHelper.downloadOrOpenFile(
                              hw.attachmentUrls[i],
                              fileName: hw.getAttachmentName(i),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
            StreamBuilder<List<HomeworkSubmissionModel>>(
              stream: widget.homeworkService.getSubmissionsStream(hw.id),
              builder: (context, snapshot) {
                final submissions = snapshot.data ?? [];
                if (submissions.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Aucune soumission pour ce devoir.',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  );
                }
                return Column(
                  children: submissions.map((sub) {
                    final isCorrected = sub.status == 'corrected';
                    final hasFile = sub.fileUrls.isNotEmpty || (sub.fileUrl != null && sub.fileUrl!.isNotEmpty);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: AppTheme.cardBorder)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isCorrected ? Icons.check_circle_rounded : Icons.pending_rounded,
                            color: isCorrected ? AppTheme.emeraldGreen : const Color(0xFFF59E0B),
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sub.studentName.isNotEmpty ? sub.studentName : sub.studentId,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                if (sub.submissionType.isNotEmpty)
                                  Text(
                                    sub.submissionType == 'blank_page' ? 'Page blanche numérique' : 'Document joint',
                                    style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
                                  ),
                              ],
                            ),
                          ),
                          if (hasFile) ...[
                            IconButton(
                              icon: const Icon(Icons.download_rounded, color: AppTheme.emeraldGreenDark, size: 20),
                              tooltip: 'Télécharger le document',
                              onPressed: () {
                                final targetUrl = sub.fileUrls.isNotEmpty ? sub.fileUrls.first : sub.fileUrl!;
                                final targetName = sub.attachmentName ?? '${sub.studentName}_copie';
                                FileDownloadHelper.downloadOrOpenFile(targetUrl, fileName: targetName);
                              },
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            isCorrected ? 'Note : ${(sub.grade ?? sub.note ?? 16).toStringAsFixed(1)}/${hw.points}' : 'En attente',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isCorrected ? AppTheme.emeraldGreen : const Color(0xFFF59E0B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => widget.onCorrectSubmission(sub),
                            style: TextButton.styleFrom(foregroundColor: AppTheme.emeraldGreenDark),
                            child: Text(isCorrected ? 'Revoir' : 'Corriger',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
