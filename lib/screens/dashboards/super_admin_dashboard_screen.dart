import 'package:flutter/material.dart';
import '../../widgets/marketing_section_header.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/app_version_model.dart';
import '../../models/course_model.dart';
import '../../models/system_log_model.dart';
import '../../services/auth_service.dart';
import '../../services/course_service.dart';
import '../../services/super_admin_service.dart';
import '../../services/system_log_service.dart';
import '../../services/app_update_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/legal_documents_widget.dart';
import '../../widgets/video_preview_dialog.dart';
import '../../widgets/studio_svg_icon.dart';
import '../teacher/course_creation_studio_screen.dart';

class SuperAdminDashboardScreen extends StatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  State<SuperAdminDashboardScreen> createState() =>
      _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState
    extends State<SuperAdminDashboardScreen> {
  final SuperAdminService _adminService = SuperAdminService();
  final AuthService _authService = AuthService();
  final CourseService _courseService = CourseService();
  final SystemLogService _logService = SystemLogService();

  String _activeMenu = 'Vue globale';
  String _userRoleFilter = 'all';
  Map<String, dynamic> _stats = {};
  bool _statsLoading = true;

  // Courses management state
  String _coursesCategoryFilter = 'all';
  final TextEditingController _coursesSearchCtrl = TextEditingController();
  final Set<String> _expandedCourseIds = {};

  // Logs & Traffic monitoring state
  int _trafficSubTabIndex = 0;
  String _logsCategoryFilter = 'all';
  String _logsSeverityFilter = 'all';
  final TextEditingController _logsSearchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _adminService.getGlobalStats();
    if (mounted) setState(() { _stats = stats; _statsLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser ??
        UserModel(uid: 'admin', email: 'admin@cf.sn', displayName: 'Super Admin', role: 'super_admin');
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          if (isWide) _buildSidebar(user),
          Expanded(child: Column(children: [
            _buildTopBar(user),
            Expanded(child: _buildBody(user)),
          ])),
        ],
      ),
    );
  }

  Widget _buildSidebar(UserModel user) {
    const items = [
      ('Vue globale', Icons.dashboard_rounded),
      ('Utilisateurs', Icons.people_rounded),
      ('Assignations', Icons.link_rounded),
      ('Cours', Icons.library_books_rounded),
      ('Paiements', Icons.payment_rounded),
      ('Logs & Trafic', Icons.query_stats_rounded),
      ('Documents legaux', Icons.gavel_rounded),
      ('Mises a jour', Icons.system_update_rounded),
    ];
    return Container(
      width: 240,
      color: const Color(0xFF0A1628),
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Logo
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(children: [
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
            Text('Super Admin', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
          ]),
        ),
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white.withAlpha(15), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            CircleAvatar(radius: 18, backgroundColor: const Color(0xFFEF4444),
              child: Text(user.displayName[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user.displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12), overflow: TextOverflow.ellipsis),
              const Text('Super Admin', style: TextStyle(color: Color(0xFFEF4444), fontSize: 10)),
            ])),
          ]),
        ),
        const SizedBox(height: 8),
        for (final item in items)
          _AdminNavItem(icon: item.$2, label: item.$1, isActive: _activeMenu == item.$1, onTap: () => setState(() => _activeMenu = item.$1)),
        const Spacer(),
        Padding(padding: const EdgeInsets.all(16), child: LegalDocumentsFAB(userId: user.uid)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextButton.icon(
            onPressed: () async { await AuthService().signOut(); if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false); },
            icon: const Icon(Icons.logout_rounded, color: AppTheme.textMuted, size: 16),
            label: const Text('Deconnexion', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          ),
        ),
      ]),
    );
  }

  Widget _buildTopBar(UserModel user) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 12, vertical: 14),
      decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: AppTheme.cardBorder))),
      child: Row(children: [
        if (!isWide) ...[
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.ink, size: 20),
            tooltip: 'Retour',
            onPressed: () {
              setState(() {
                if (_activeMenu != 'Vue globale') {
                  _activeMenu = 'Vue globale';
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
        Text(_activeMenu, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.ink)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(20)),
          child: const Row(children: [
            Icon(Icons.admin_panel_settings_rounded, size: 14, color: Color(0xFFB91C1C)),
            SizedBox(width: 6),
            Text('Acces Total', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFB91C1C))),
          ]),
        ),
      ]),
    );
  }

  Widget _buildBody(UserModel user) {
    switch (_activeMenu) {
      case 'Utilisateurs': return _buildUsersView();
      case 'Assignations': return _buildAssignationsView();
      case 'Cours': return _buildCoursesView();
      case 'Paiements': return _buildPaymentsView();
      case 'Logs & Trafic': return _buildLogsAndTrafficView();
      case 'Documents legaux': return _buildLegalDocsView(user);
      case 'Mises a jour': return _buildUpdatesView();
      default: return _buildGlobalView();
    }
  }

  Widget _buildGlobalView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Vue d\'ensemble', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.ink)),
        const SizedBox(height: 20),
        if (_statsLoading)
          const Center(child: CircularProgressIndicator(color: Color(0xFFEF4444)))
        else
          Wrap(spacing: 16, runSpacing: 16, children: [
            _GlobalStatCard(label: 'Utilisateurs', value: '${_stats['totalUsers'] ?? 0}', icon: Icons.people_rounded, color: const Color(0xFF6366F1)),
            _GlobalStatCard(label: 'Cours', value: '${_stats['totalCourses'] ?? 0}', icon: Icons.library_books_rounded, color: AppTheme.emeraldGreenDark),
            _GlobalStatCard(label: 'Inscriptions', value: '${_stats['totalEnrollments'] ?? 0}', icon: Icons.school_rounded, color: const Color(0xFFF59E0B)),
            _GlobalStatCard(label: 'Revenus (FCFA)', value: '${(_stats['totalRevenue'] ?? 0.0).toInt()}', icon: Icons.payments_rounded, color: const Color(0xFFEF4444)),
            _GlobalStatCard(label: 'Lives actifs', value: '${_stats['activeLives'] ?? 0}', icon: Icons.videocam_rounded, color: const Color(0xFFEC4899)),
          ]),
        const SizedBox(height: 24),
        // Quick actions
        Text('Actions rapides', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.ink)),
        const SizedBox(height: 12),
        Wrap(spacing: 12, runSpacing: 12, children: [
          _AdminQuickAction(icon: Icons.link_rounded, label: 'Assigner un correcteur', color: AppTheme.emeraldGreenDark, onTap: () => setState(() => _activeMenu = 'Assignations')),
          _AdminQuickAction(icon: Icons.people_rounded, label: 'Gerer les utilisateurs', color: const Color(0xFF6366F1), onTap: () => setState(() => _activeMenu = 'Utilisateurs')),
          _AdminQuickAction(icon: Icons.query_stats_rounded, label: 'Logs & Trafic en direct', color: const Color(0xFF0EA5E9), onTap: () => setState(() => _activeMenu = 'Logs & Trafic')),
          _AdminQuickAction(icon: Icons.library_books_rounded, label: 'Catalogue des cours', color: const Color(0xFF10B981), onTap: () => setState(() => _activeMenu = 'Cours')),
          _AdminQuickAction(icon: Icons.gavel_rounded, label: 'Documents legaux', color: const Color(0xFFF59E0B), onTap: () => setState(() => _activeMenu = 'Documents legaux')),
        ]),
      ]),
    );
  }

  Widget _buildUsersView() {
    final filters = [('Tous', 'all'), ('Etudiants', 'student'), ('Formateurs', 'teacher'), ('Correcteurs', 'corrector'), ('Admins', 'super_admin')];
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Gestion des Comptes & Correcteurs', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.ink)),
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add_rounded, size: 16),
              label: const Text('Ajouter un utilisateur', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emeraldGreenDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onPressed: () => _showAddUserDialog(),
            ),
          ],
        ),
      ),
      // Filter bar
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: filters.map((f) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilterChip(
            label: Text(f.$1, style: TextStyle(fontWeight: FontWeight.w700, color: _userRoleFilter == f.$2 ? Colors.white : AppTheme.ink, fontSize: 12)),
            selected: _userRoleFilter == f.$2,
            selectedColor: AppTheme.emeraldGreenDark,
            backgroundColor: Colors.white,
            side: const BorderSide(color: AppTheme.cardBorder),
            onSelected: (_) => setState(() => _userRoleFilter = f.$2),
          ),
        )).toList()),
      ),
      Expanded(
        child: StreamBuilder<List<UserModel>>(
          stream: _userRoleFilter == 'all'
              ? _adminService.getAllUsersStream()
              : _adminService.getUsersByRoleStream(_userRoleFilter),
          builder: (context, snapshot) {
            final users = snapshot.data ?? [];
            if (users.isEmpty) return const Center(child: Text('Aucun utilisateur', style: TextStyle(color: AppTheme.textMuted)));
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: users.length,
              itemBuilder: (context, i) {
                final u = users[i];
                return _UserAdminCard(user: u, adminService: _adminService);
              },
            );
          },
        ),
      ),
    ]);
  }

  Widget _buildAssignationsView() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.all(20),
        child: const MarketingSectionHeader(
          badge: 'ASSIGNATIONS',
          title: 'Assigner un Correcteur a un Formateur',
          subtitle: 'Selectionnez un correcteur et un formateur pour les lier.',
        ),
      ),
      Expanded(child: _AssignationPanel(adminService: _adminService)),
    ]);
  }

  // ==========================================
  // COURS : GESTION COMPLÈTE (MODULES, LEÇONS, VIDÉOS, MODÉRATION)
  // ==========================================
  Widget _buildCoursesView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gestion Complète des Formations & Leçons',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Accès complet aux modules, leçons vidéo, prix, inscrits et modération en direct.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('+ Créer une formation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emeraldGreenDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CourseCreationStudioScreen()),
                  ).then((_) => setState(() {}));
                },
              ),
            ],
          ),
        ),

        // Search & category filter bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _coursesSearchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Rechercher par titre, formateur ou catégorie...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.cardBorder),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _coursesCategoryFilter,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.cardBorder),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Toutes les catégories', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'Informatique & Tech', child: Text('Informatique & Tech', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'Business', child: Text('Business & Gestion', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'Marketing & Digital', child: Text('Marketing & Digital', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'Sciences & Mathématiques', child: Text('Sciences & Maths', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'Langues', child: Text('Langues', style: TextStyle(fontSize: 12))),
                  ],
                  onChanged: (val) => setState(() => _coursesCategoryFilter = val ?? 'all'),
                ),
              ),
            ],
          ),
        ),

        // Courses stream
        Expanded(
          child: StreamBuilder<List<CourseModel>>(
            stream: _courseService.getAllCoursesStream(),
            builder: (context, snapshot) {
              final allCourses = snapshot.data ?? [];
              final q = _coursesSearchCtrl.text.trim().toLowerCase();

              final filtered = allCourses.where((c) {
                if (q.isNotEmpty) {
                  final m = c.title.toLowerCase().contains(q) ||
                      c.trainerName.toLowerCase().contains(q) ||
                      c.category.toLowerCase().contains(q);
                  if (!m) return false;
                }
                if (_coursesCategoryFilter != 'all' && c.category != _coursesCategoryFilter) {
                  return false;
                }
                return true;
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.library_books_rounded, size: 48, color: AppTheme.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          'Aucune formation trouvée',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: AppTheme.ink),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Modifiez vos critères de recherche ou créez un nouveau cours.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                itemCount: filtered.length,
                itemBuilder: (context, i) => _buildAdminCourseCard(filtered[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAdminCourseCard(CourseModel course) {
    final isExpanded = _expandedCourseIds.contains(course.id);
    final isPublished = course.publicationStatus == 'Publiée' || course.isPublished;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: course.image.startsWith('http')
                      ? Image.network(
                          course.image,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 56,
                            height: 56,
                            color: AppTheme.paleMint,
                            child: const Icon(Icons.book_rounded, color: AppTheme.emeraldGreenDark),
                          ),
                        )
                      : Image.asset(
                          course.image,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 56,
                            height: 56,
                            color: AppTheme.paleMint,
                            child: const Icon(Icons.book_rounded, color: AppTheme.emeraldGreenDark),
                          ),
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
                              course.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: AppTheme.ink,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPublished ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPublished ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                                  size: 13,
                                  color: isPublished ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isPublished ? 'Publiée' : 'Brouillon',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isPublished ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: isPublished,
                            activeThumbColor: AppTheme.emeraldGreenDark,
                            onChanged: (val) async {
                              await _courseService.togglePublishStatus(course.id, !val);
                              await _logService.logEvent(
                                action: val ? 'Formation publiée par Super Admin' : 'Formation dépubliée',
                                details: 'Statut du cours "${course.title}" modifié vers ${val ? 'Publiée' : 'Brouillon'}.',
                                category: 'course',
                                actorName: 'Super Admin',
                                actorRole: 'Super Admin',
                              );
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Formateur : ${course.trainerName} • ${course.category} • ${course.level} • ${course.formattedPrice}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          _buildCoursePill(Icons.groups_rounded, '${course.studentsCount} apprenants'),
                          _buildCoursePill(Icons.star_rounded, '${course.rating} ★ (${course.reviewsCount} avis)'),
                          _buildCoursePill(Icons.folder_special_rounded, '${course.modules.length} modules'),
                          _buildCoursePill(Icons.play_circle_outline, '${course.lessonsCount} leçons vidéo'),
                          _buildCoursePill(Icons.access_time_rounded, course.duration),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (course.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                course.description,
                style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                maxLines: isExpanded ? 6 : 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          const Divider(height: 1),

          // Actions & Expand bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedCourseIds.remove(course.id);
                      } else {
                        _expandedCourseIds.add(course.id);
                      }
                    });
                  },
                  icon: Icon(
                    isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: AppTheme.emeraldGreenDark,
                  ),
                  label: Text(
                    isExpanded
                        ? 'Masquer le programme complet'
                        : 'Consulter le programme & leçons (${course.modules.length} modules • ${course.lessonsCount} leçons)',
                    style: const TextStyle(
                      color: AppTheme.emeraldGreenDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.edit_rounded, size: 16, color: AppTheme.ink),
                      label: const Text('Modifier', style: TextStyle(color: AppTheme.ink, fontSize: 12)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CourseCreationStudioScreen(existingCourse: course),
                          ),
                        ).then((_) => setState(() {}));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                      tooltip: 'Supprimer la formation',
                      onPressed: () => _confirmDeleteCourse(course),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Expanded Curriculum Details
          if (isExpanded) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Programme Pédagogique Détaillé',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.ink),
                  ),
                  const SizedBox(height: 10),
                  if (course.modules.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Aucun module structuré dans cette formation.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    )
                  else
                    ...course.modules.asMap().entries.map((mEntry) {
                      final mIdx = mEntry.key;
                      final mod = mEntry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Section ${mIdx + 1} : ${mod.title}',
                                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12.5),
                                  ),
                                  Text(
                                    '${mod.lessons.length} leçons',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            if (mod.lessons.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(10),
                                child: Text('Aucune leçon dans cette section.', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: mod.lessons.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, lIdx) {
                                  final l = mod.lessons[lIdx];
                                  return ListTile(
                                    dense: true,
                                    visualDensity: VisualDensity.compact,
                                    leading: Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: AppTheme.paleMint,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '#${lIdx + 1}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emeraldGreenDark, fontSize: 10.5),
                                        ),
                                      ),
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            l.title,
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                                          ),
                                        ),
                                        if (l.isFreePreview)
                                          Container(
                                            margin: const EdgeInsets.only(left: 6),
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFDCFCE7),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text('Gratuit',
                                                style: TextStyle(fontSize: 9.5, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                                          ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      'Durée : ${l.duration} • URL : ${l.videoUrl.length > 35 ? '${l.videoUrl.substring(0, 32)}...' : l.videoUrl}',
                                      style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
                                    ),
                                    trailing: TextButton.icon(
                                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                      icon: const StudioSvgIcon(iconKey: StudioSvgIcon.play, size: 14, color: AppTheme.emeraldGreenDark),
                                      label: const Text('Tester', style: TextStyle(fontSize: 11, color: AppTheme.emeraldGreenDark)),
                                      onPressed: () {
                                        VideoPreviewDialog.show(
                                          context,
                                          videoUrl: l.videoUrl,
                                          title: l.title,
                                          duration: l.duration,
                                          isFreePreview: l.isFreePreview,
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCoursePill(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppTheme.textMuted),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
      ],
    );
  }

  void _confirmDeleteCourse(CourseModel course) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer cette formation ?'),
        content: Text('Voulez-vous définitivement supprimer "${course.title}" ? Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await _courseService.deleteCourse(course.id);
              await _logService.logEvent(
                action: 'Formation supprimée',
                details: 'Le Super Admin a supprimé la formation "${course.title}".',
                category: 'course',
                level: 'warning',
                actorName: 'Super Admin',
                actorRole: 'Super Admin',
              );
              setState(() {});
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Formation supprimée.'), backgroundColor: Colors.redAccent),
                );
              }
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // NOUVEAU MODULE : LOGS & TRAFIC & SURVEILLANCE SYSTÈME
  // ==========================================
  Widget _buildLogsAndTrafficView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Surveillance Système, Trafic & Audit Logs',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Observabilité en direct du trafic, des sessions WebRTC, des paiements et des actions.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),

              // Segmented Sub-tabs
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildSubTabButton(0, '📊 Trafic & Audience', Icons.insights_rounded),
                    _buildSubTabButton(1, '📜 Audit Logs en Direct', Icons.list_alt_rounded),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Sub-tab content
        Expanded(
          child: _trafficSubTabIndex == 0 ? _buildTrafficTab() : _buildAuditLogsTab(),
        ),
      ],
    );
  }

  Widget _buildSubTabButton(int index, String label, IconData icon) {
    final isSelected = _trafficSubTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _trafficSubTabIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 4, offset: const Offset(0, 1))]
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? AppTheme.emeraldGreenDark : AppTheme.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? AppTheme.emeraldGreenDark : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Sub-tab 0: Traffic & Analytics
  Widget _buildTrafficTab() {
    final data = _logService.getTrafficAnalytics();
    final chartData = (data['chartData'] as List<dynamic>? ?? []);
    final devices = (data['devices'] as List<dynamic>? ?? []);
    final channels = (data['channels'] as List<dynamic>? ?? []);
    final locations = (data['topLocations'] as List<dynamic>? ?? []);
    final topCourses = (data['topCoursesVisited'] as List<dynamic>? ?? []);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 4 KPIs
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildTrafficKpiCard(
                label: 'Visiteurs Uniques (Aujourd\'hui)',
                value: '${data['dailyVisitors']}',
                growth: '${data['dailyVisitorsGrowth']} vs hier',
                icon: Icons.people_alt_rounded,
                color: const Color(0xFF3B82F6),
              ),
              _buildTrafficKpiCard(
                label: 'Sessions Actives en Direct',
                value: '${data['activeSessions']}',
                growth: 'En temps réel sur l\'app',
                icon: Icons.sensors_rounded,
                color: const Color(0xFF10B981),
                isLive: true,
              ),
              _buildTrafficKpiCard(
                label: 'Taux de Conversion Global',
                value: '${data['conversionRate']}%',
                growth: '${data['weeklyRegistrations']} inscrits cette semaine',
                icon: Icons.trending_up_rounded,
                color: const Color(0xFFF59E0B),
              ),
              _buildTrafficKpiCard(
                label: 'Durée Moyenne / Session',
                value: '${data['avgSessionMinutes']}',
                growth: 'Engagement très élevé',
                icon: Icons.timer_rounded,
                color: const Color(0xFF8B5CF6),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Weekly Traffic Chart Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                          'Fréquentation Hebdomadaire (7 derniers jours)',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.ink),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Total : ${data['weeklyViews']} visites cumulées sur la plateforme',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.paleMint,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.bar_chart_rounded, size: 14, color: AppTheme.emeraldGreenDark),
                          SizedBox(width: 4),
                          Text('Semaine en cours', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.emeraldGreenDark)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Interactive Bar Chart
                SizedBox(
                  height: 180,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: chartData.map((item) {
                      final day = item['day']?.toString() ?? '';
                      final views = (item['views'] as num?)?.toInt() ?? 1000;
                      final conv = (item['conversions'] as num?)?.toInt() ?? 10;
                      const maxViews = 2000.0;
                      final barHeight = (views / maxViews * 130).clamp(20.0, 130.0);

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('$conv ins.', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.emeraldGreenDark)),
                          const SizedBox(height: 4),
                          Container(
                            width: 32,
                            height: barHeight,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppTheme.emeraldGreen, AppTheme.emeraldGreenDark],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(day, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.ink)),
                          Text('$views v.', style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2 Columns Breakdown
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 720;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Column 1: Devices & Channels
                  Expanded(
                    child: Column(
                      children: [
                        // Devices
                        _buildBreakdownCard(
                          title: 'Répartition par Appareil',
                          icon: Icons.devices_rounded,
                          items: devices.map((d) {
                            return _BreakdownRow(
                              label: d['device']?.toString() ?? '',
                              percent: (d['percent'] as num?)?.toDouble() ?? 0,
                              color: Color(d['color'] as int? ?? 0xFF10B981),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        // Channels
                        _buildBreakdownCard(
                          title: 'Canaux d\'Acquisition',
                          icon: Icons.traffic_rounded,
                          items: channels.map((c) {
                            return _BreakdownRow(
                              label: '${c['source']} (${c['visits']} visites)',
                              percent: (c['percent'] as num?)?.toDouble() ?? 0,
                              color: const Color(0xFF0EA5E9),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  if (isWide) const SizedBox(width: 16),
                  // Column 2: Geography & Top Courses
                  Expanded(
                    child: Column(
                      children: [
                        // Geography
                        _buildBreakdownCard(
                          title: 'Origine Géographique (Villes & Pays)',
                          icon: Icons.public_rounded,
                          items: locations.map((loc) {
                            return _BreakdownRow(
                              label: loc['city']?.toString() ?? '',
                              percent: (loc['percent'] as num?)?.toDouble() ?? 0,
                              color: const Color(0xFFF59E0B),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        // Top Courses
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.cardBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.star_outline_rounded, size: 18, color: AppTheme.emeraldGreenDark),
                                  const SizedBox(width: 8),
                                  Text('Formations les plus consultées',
                                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...topCourses.map((tc) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          tc['title']?.toString() ?? '',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: AppTheme.paleMint, borderRadius: BorderRadius.circular(6)),
                                        child: Text(
                                          '${tc['views']} vues • ${tc['enrolled']} inscrits',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.emeraldGreenDark),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTrafficKpiCard({
    required String label,
    required String value,
    required String growth,
    required IconData icon,
    required Color color,
    bool isLive = false,
  }) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20),
              ),
              if (isLive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                  child: const Row(
                    children: [
                      CircleAvatar(radius: 3, backgroundColor: Color(0xFF16A34A)),
                      SizedBox(width: 4),
                      Text('EN DIRECT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.ink)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted)),
          const SizedBox(height: 6),
          Text(growth, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard({
    required String title,
    required IconData icon,
    required List<_BreakdownRow> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.emeraldGreenDark),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 14),
          ...items.map((row) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(row.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      Text('${row.percent.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: row.percent / 100,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation(row.color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // Sub-tab 1: Audit Logs & Surveillance System
  Widget _buildAuditLogsTab() {
    return Column(
      children: [
        // Controls bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _logsSearchCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Filtrer par action, utilisateur, IP ou mot-clé...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.cardBorder)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emeraldGreenDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Actualiser'),
                    onPressed: () => setState(() {}),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.ink,
                      side: const BorderSide(color: AppTheme.cardBorder),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Exporter JSON'),
                    onPressed: () async {
                      final jsonStr = await _logService.exportLogsAsJson();
                      if (mounted) {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: const Text('Export JSON des logs d\'audit'),
                            content: SizedBox(
                              width: 500,
                              height: 300,
                              child: SingleChildScrollView(child: SelectableText(jsonStr, style: const TextStyle(fontFamily: 'monospace', fontSize: 11))),
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Filter chips for Category
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildLogFilterChip('Toutes catégories', 'all'),
                    _buildLogFilterChip('💳 Paiements Wave/OM', 'payment'),
                    _buildLogFilterChip('👤 Inscriptions & Auth', 'auth'),
                    _buildLogFilterChip('📚 Formations & Cours', 'course'),
                    _buildLogFilterChip('🔴 Sessions Live', 'live'),
                    _buildLogFilterChip('⚠️ Système & Alertes', 'system'),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Filter chips for Severity
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildLogSeverityChip('Tous niveaux', 'all'),
                    _buildLogSeverityChip('✅ Succès', 'success'),
                    _buildLogSeverityChip('ℹ️ Info', 'info'),
                    _buildLogSeverityChip('⚠️ Avertissement', 'warning'),
                    _buildLogSeverityChip('🛑 Erreur', 'error'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Logs list
        Expanded(
          child: StreamBuilder<List<SystemLogModel>>(
            stream: _logService.getLogsStream(),
            builder: (context, snapshot) {
              final logs = snapshot.data ?? [];
              final q = _logsSearchCtrl.text.trim().toLowerCase();

              final filtered = logs.where((l) {
                if (_logsCategoryFilter != 'all' && l.category != _logsCategoryFilter) {
                  return false;
                }
                if (_logsSeverityFilter != 'all' && l.level != _logsSeverityFilter) {
                  return false;
                }
                if (q.isNotEmpty) {
                  final matches = l.action.toLowerCase().contains(q) ||
                      l.actorName.toLowerCase().contains(q) ||
                      l.details.toLowerCase().contains(q) ||
                      l.ipAddress.toLowerCase().contains(q);
                  if (!matches) return false;
                }
                return true;
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.checklist_rounded, size: 48, color: AppTheme.textMuted),
                      const SizedBox(height: 10),
                      Text('Aucun log trouvé pour ces filtres', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted)),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _buildLogCard(filtered[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLogFilterChip(String label, String categoryKey) {
    final isSelected = _logsCategoryFilter == categoryKey;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
        selectedColor: AppTheme.paleMint,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: isSelected ? AppTheme.emeraldGreenDark : AppTheme.cardBorder),
        ),
        onSelected: (_) => setState(() => _logsCategoryFilter = categoryKey),
      ),
    );
  }

  Widget _buildLogSeverityChip(String label, String severityKey) {
    final isSelected = _logsSeverityFilter == severityKey;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
        selectedColor: AppTheme.paleMint,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: isSelected ? AppTheme.emeraldGreenDark : AppTheme.cardBorder),
        ),
        onSelected: (_) => setState(() => _logsSeverityFilter = severityKey),
      ),
    );
  }

  Widget _buildLogCard(SystemLogModel log) {
    Color levelColor;
    IconData levelIcon;
    switch (log.level) {
      case 'success':
        levelColor = const Color(0xFF10B981);
        levelIcon = Icons.check_circle_rounded;
        break;
      case 'warning':
        levelColor = const Color(0xFFF59E0B);
        levelIcon = Icons.warning_amber_rounded;
        break;
      case 'error':
        levelColor = const Color(0xFFEF4444);
        levelIcon = Icons.error_outline_rounded;
        break;
      default:
        levelColor = const Color(0xFF3B82F6);
        levelIcon = Icons.info_outline_rounded;
    }

    final diff = DateTime.now().difference(log.timestamp);
    String relativeTime;
    if (diff.inMinutes < 1) {
      relativeTime = 'À l\'instant';
    } else if (diff.inMinutes < 60) {
      relativeTime = 'Il y a ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      relativeTime = 'Il y a ${diff.inHours} h';
    } else {
      relativeTime = '${log.timestamp.day}/${log.timestamp.month} ${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')}';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: levelColor.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(levelIcon, color: levelColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      log.action,
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppTheme.ink),
                    ),
                    Text(
                      relativeTime,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${log.actorName} (${log.actorRole})',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• ${log.platform} • IP : ${log.ipAddress}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  log.details,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.code_rounded, size: 16, color: AppTheme.textMuted),
            tooltip: 'Inspecter les métadonnées techniques',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Text('Détails Log #${log.id}', style: const TextStyle(fontSize: 15)),
                  content: SizedBox(
                    width: 440,
                    child: SingleChildScrollView(
                      child: SelectableText(
                        'Action: ${log.action}\nNiveau: ${log.level}\nCatégorie: ${log.category}\nActeur: ${log.actorName} (${log.actorRole})\nDate: ${log.timestamp.toIso8601String()}\nIP: ${log.ipAddress}\nPlateforme: ${log.platform}\nDétails: ${log.details}\nMétadonnées: ${log.metadata}',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsView() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _adminService.getAllPaymentsStream(),
      builder: (context, snapshot) {
        final payments = snapshot.data ?? [];
        if (payments.isEmpty) return const Center(child: Text('Aucun paiement', style: TextStyle(color: AppTheme.textMuted)));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: payments.length,
          itemBuilder: (context, i) {
            final p = payments[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFD1FAE5),
                  child: Icon(Icons.check_circle_rounded, color: AppTheme.emeraldGreenDark, size: 20),
                ),
                title: Text(p['courseTitle'] ?? 'Cours', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: Text('${p['studentName'] ?? ''} - ${p['method'] ?? ''}\n${p['amount'] ?? 0} FCFA', style: const TextStyle(fontSize: 12)),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLegalDocsView(UserModel user) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.gavel_rounded, size: 64, color: AppTheme.emeraldGreenDark),
        const SizedBox(height: 16),
        Text('Documents Legaux', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.ink)),
        const SizedBox(height: 8),
        const Text('Accedez et gerez les documents officiels de la plateforme.', style: TextStyle(color: AppTheme.textMuted)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          icon: const Icon(Icons.folder_open_rounded),
          label: const Text('Ouvrir les documents', style: TextStyle(fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldGreenDark, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => _LegalSheetProxy(userId: user.uid),
            );
          },
        ),
      ]),
    );
  }

  Widget _buildUpdatesView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MarketingSectionHeader(
            badge: 'VERSIONS',
            title: 'Gestion des Mises à Jour & Versions',
            subtitle: 'Diffusez et contrôlez les versions de la plateforme en temps réel pour tous les utilisateurs.',
            actionLabel: 'Publier une nouvelle version',
            actionIcon: Icons.send_rounded,
            onAction: () => _showPublishVersionDialog(),
          ),
          const SizedBox(height: 24),

          // Status & Info Cards
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.emeraldGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.code_rounded, color: AppTheme.emeraldGreenDark, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Version du code local', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                              Text('v${AppUpdateService.currentAppVersion} (Build ${AppUpdateService.currentBuildNumber})', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.ink)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Version actuellement packagée dans le bundle du client.',
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance.collection('platform_settings').doc('app_version').snapshots(),
                  builder: (context, snapshot) {
                    final data = snapshot.data?.data();
                    final remoteVer = data != null ? AppVersionModel.fromJson(data) : null;

                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.cloud_done_rounded, color: Colors.blue, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Dernière version publiée (Serveur)', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                  Text(
                                    remoteVer != null ? 'v${remoteVer.version} (Build ${remoteVer.buildNumber})' : 'Non configurée',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.ink),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            remoteVer != null && remoteVer.isNewerThan(AppUpdateService.currentBuildNumber, AppUpdateService.currentAppVersion)
                                ? 'Une mise à jour plus récente est diffusée aux utilisateurs.'
                                : 'Le serveur est aligné avec la version actuelle du code.',
                            style: TextStyle(
                              fontSize: 11,
                              color: remoteVer != null && remoteVer.isNewerThan(AppUpdateService.currentBuildNumber, AppUpdateService.currentAppVersion)
                                  ? AppTheme.emeraldGreenDark
                                  : AppTheme.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Actions Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Actions Rapides & Tests',
                  style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.ink),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.remove_red_eye_rounded, size: 18),
                      label: const Text('Tester la Popup de Mise à Jour (Aperçu direct)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        AppUpdateService().simulateUpdateAvailable();
                      },
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.sync_rounded, size: 18),
                      label: const Text('Vérifier les mises à jour maintenant'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.ink,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        side: const BorderSide(color: AppTheme.cardBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final hasUpdate = await AppUpdateService().checkForUpdates(userInitiated: true);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(hasUpdate
                                  ? 'Nouvelle mise à jour détectée !'
                                  : 'Votre plateforme est déjà à jour (v${AppUpdateService.currentAppVersion}).'),
                              backgroundColor: hasUpdate ? AppTheme.emeraldGreenDark : Colors.blueGrey,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPublishVersionDialog() {
    final versionCtrl = TextEditingController(text: '1.0.1');
    final buildCtrl = TextEditingController(text: '101');
    final titleCtrl = TextEditingController(text: 'Mise à jour disponible ! 🎉');
    final notesCtrl = TextEditingController(
      text: 'Nouvelle version avec lecteur vidéo Plein Écran immersif, barre de contrôles enrichie et améliorations de performances.',
    );
    final h1Ctrl = TextEditingController(text: 'Nouveau lecteur vidéo immersif avec mode Plein Écran (Full Screen)');
    final h2Ctrl = TextEditingController(text: 'Barre de contrôles vidéo complète : timeline, vitesse, volume, sauts de 10s');
    final h3Ctrl = TextEditingController(text: 'Tiroir latéral des leçons accessible directement en plein écran');
    bool isMandatory = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.emeraldGreen.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.rocket_launch_rounded, color: AppTheme.emeraldGreenDark, size: 22),
              ),
              const SizedBox(width: 12),
              const Text('Publier une Mise à Jour'),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cette version sera instantanément diffusée à tous les utilisateurs connectés.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: versionCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Version (ex: 1.0.1)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: buildCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Numéro de build (ex: 101)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Titre de la popup',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description / Notes de version',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Points forts / Nouveautés :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: h1Ctrl,
                    decoration: const InputDecoration(hintText: 'Nouveauté 1', border: OutlineInputBorder(), isDense: true),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: h2Ctrl,
                    decoration: const InputDecoration(hintText: 'Nouveauté 2', border: OutlineInputBorder(), isDense: true),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: h3Ctrl,
                    decoration: const InputDecoration(hintText: 'Nouveauté 3', border: OutlineInputBorder(), isDense: true),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Mise à jour obligatoire', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Empêche l\'utilisateur de fermer la popup sans mettre à jour', style: TextStyle(fontSize: 11)),
                    value: isMandatory,
                    onChanged: (val) => setDlgState(() => isMandatory = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('Diffuser la mise à jour'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emeraldGreenDark,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final buildNum = int.tryParse(buildCtrl.text.trim()) ?? 101;
                final highlights = [
                  h1Ctrl.text.trim(),
                  h2Ctrl.text.trim(),
                  h3Ctrl.text.trim(),
                ].where((h) => h.isNotEmpty).toList();

                await AppUpdateService().publishNewVersion(
                  version: versionCtrl.text.trim(),
                  buildNumber: buildNum,
                  title: titleCtrl.text.trim(),
                  releaseNotes: notesCtrl.text.trim(),
                  highlights: highlights,
                  isMandatory: isMandatory,
                );

                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Mise à jour v${versionCtrl.text.trim()} diffusée avec succès !'),
                      backgroundColor: AppTheme.emeraldGreenDark,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddUserDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final specialityCtrl = TextEditingController();
    final experienceCtrl = TextEditingController();
    final bioCtrl = TextEditingController();
    String selectedRole = 'corrector';
    String? selectedLinkedTeacherId;
    String? selectedLinkedCorrectorId;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.emeraldGreen.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_add_rounded, color: AppTheme.emeraldGreenDark, size: 22),
              ),
              const SizedBox(width: 12),
              const Text('Créer un utilisateur'),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rôle du compte', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.ink)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    items: const [
                      DropdownMenuItem(value: 'corrector', child: Text('Correcteur')),
                      DropdownMenuItem(value: 'teacher', child: Text('Formateur')),
                      DropdownMenuItem(value: 'student', child: Text('Étudiant')),
                      DropdownMenuItem(value: 'super_admin', child: Text('Administrateur')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDlgState(() {
                          selectedRole = val;
                          selectedLinkedTeacherId = null;
                          selectedLinkedCorrectorId = null;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Nom complet *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.ink)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      hintText: 'Ex: Mamadou Diallo',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Adresse Email *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.ink)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Ex: formateur@clubdesformateurs.com',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Numéro de téléphone', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.ink)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Ex: +221 77 123 45 67',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  if (selectedRole == 'teacher' || selectedRole == 'corrector') ...[
                    const SizedBox(height: 14),
                    const Text('Spécialité / Domaine d\'enseignement', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.ink)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: specialityCtrl,
                      decoration: InputDecoration(
                        hintText: 'Ex: Développement Web & Mobile, Marketing Digital...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Années d\'expérience', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.ink)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: experienceCtrl,
                      decoration: InputDecoration(
                        hintText: 'Ex: 5 ans',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Présentation / Biographie', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.ink)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: bioCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Courte biographie et parcours professionnel...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ],
                  if (selectedRole == 'corrector') ...[
                    const SizedBox(height: 14),
                    const Text('Assigner à un Formateur (optionnel)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.ink)),
                    const SizedBox(height: 6),
                    StreamBuilder<List<UserModel>>(
                      stream: _adminService.getUsersByRoleStream('teacher'),
                      builder: (context, snap) {
                        final teachers = snap.data ?? [];
                        return DropdownButtonFormField<String?>(
                          value: selectedLinkedTeacherId,
                          hint: const Text('Aucun formateur pour le moment'),
                          items: [
                            const DropdownMenuItem<String?>(value: null, child: Text('Aucun')),
                            ...teachers.map((t) => DropdownMenuItem<String?>(value: t.uid, child: Text(t.displayName))),
                          ],
                          onChanged: (val) => setDlgState(() => selectedLinkedTeacherId = val),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        );
                      },
                    ),
                  ],
                  if (selectedRole == 'teacher') ...[
                    const SizedBox(height: 14),
                    const Text('Assigner un Correcteur (optionnel)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.ink)),
                    const SizedBox(height: 6),
                    StreamBuilder<List<UserModel>>(
                      stream: _adminService.getUsersByRoleStream('corrector'),
                      builder: (context, snap) {
                        final correctors = snap.data ?? [];
                        return DropdownButtonFormField<String?>(
                          value: selectedLinkedCorrectorId,
                          hint: const Text('Aucun correcteur pour le moment'),
                          items: [
                            const DropdownMenuItem<String?>(value: null, child: Text('Aucun')),
                            ...correctors.map((c) => DropdownMenuItem<String?>(value: c.uid, child: Text(c.displayName))),
                          ],
                          onChanged: (val) => setDlgState(() => selectedLinkedCorrectorId = val),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
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
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (emailCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Veuillez remplir le nom et l\'email.')),
                        );
                        return;
                      }
                      setDlgState(() => isSubmitting = true);
                      try {
                        await _adminService.createUser(
                          email: emailCtrl.text.trim(),
                          displayName: nameCtrl.text.trim(),
                          role: selectedRole,
                          phoneNumber: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                          linkedTeacherId: selectedLinkedTeacherId,
                          linkedCorrectorId: selectedLinkedCorrectorId,
                          speciality: specialityCtrl.text.trim().isNotEmpty ? specialityCtrl.text.trim() : null,
                          experienceYears: experienceCtrl.text.trim().isNotEmpty ? experienceCtrl.text.trim() : null,
                          bio: bioCtrl.text.trim().isNotEmpty ? bioCtrl.text.trim() : null,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Compte créé avec succès pour ${nameCtrl.text.trim()} !'),
                              backgroundColor: AppTheme.emeraldGreenDark,
                            ),
                          );
                        }
                      } catch (e) {
                        setDlgState(() => isSubmitting = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.redAccent),
                          );
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Créer le compte'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────

class _AdminNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _AdminNavItem({required this.icon, required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEF4444).withAlpha(40) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Icon(icon, color: isActive ? const Color(0xFFEF4444) : AppTheme.textMuted, size: 18),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: isActive ? const Color(0xFFEF4444) : AppTheme.textMuted, fontSize: 13, fontWeight: isActive ? FontWeight.w700 : FontWeight.normal)),
        ]),
      ),
    );
  }
}

class _GlobalStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _GlobalStatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.cardBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 10),
        Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.ink)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      ]),
    );
  }
}

class _AdminQuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _AdminQuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withAlpha(60))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
      ),
    );
  }
}

class _UserAdminCard extends StatelessWidget {
  final UserModel user;
  final SuperAdminService adminService;
  const _UserAdminCard({required this.user, required this.adminService});

  void _confirmDeleteUser(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
            SizedBox(width: 10),
            Text('Supprimer définitivement'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Voulez-vous supprimer définitivement ${user.displayName} (${user.email}) ?',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            const Text(
              'Cette action supprimera définitivement le profil et toutes les données associées de la plateforme.',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
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
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await adminService.deleteUserData(user.uid);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Le compte de ${user.displayName} a été supprimé.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('Supprimer définitivement'),
          ),
        ],
      ),
    );
  }

  void _showUserDetailsModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.paleMint,
              child: Text(
                user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                style: const TextStyle(color: AppTheme.emeraldGreenDark, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.displayName, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800)),
                  Text(
                    user.role == 'teacher' ? 'Dossier d\'inscription Formateur' : 'Profil ${user.role}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInfoRow('Email', user.email),
                if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty)
                  _buildInfoRow('Téléphone', user.phoneNumber!),
                if (user.speciality != null && user.speciality!.isNotEmpty)
                  _buildInfoRow('Spécialité / Titre', user.speciality!),
                if (user.experienceYears != null && user.experienceYears!.isNotEmpty)
                  _buildInfoRow('Expérience', user.experienceYears!),
                if (user.bio != null && user.bio!.isNotEmpty)
                  _buildInfoRow('Biographie', user.bio!),
                if (user.expertises.isNotEmpty)
                  _buildInfoRow('Expertises', user.expertises.join(', ')),
                if (user.skills.isNotEmpty)
                  _buildInfoRow('Compétences', user.skills.join(', ')),
                _buildInfoRow('Identifiant Unique', user.uid),
                _buildInfoRow(
                  'Statut du profil',
                  user.isApproved ? 'Validé par l\'administration' : 'En attente de validation',
                  color: user.isApproved ? AppTheme.emeraldGreenDark : Colors.orange,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer', style: TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton.icon(
            icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 16),
            label: const Text('Supprimer ce compte', style: TextStyle(color: Colors.redAccent)),
            onPressed: () {
              Navigator.pop(ctx);
              _confirmDeleteUser(context);
            },
          ),
          if (user.role == 'teacher' && !user.isApproved)
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_rounded, size: 16),
              label: const Text('Valider et approuver'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emeraldGreenDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await adminService.validateTeacher(user.uid);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Formateur ${user.displayName} validé avec succès !'),
                      backgroundColor: AppTheme.emeraldGreenDark,
                    ),
                  );
                }
              },
            ),
        ],
      ),
    );
  }

  static Widget _buildInfoRow(String title, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color ?? AppTheme.ink),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roleColor = {
      'teacher': AppTheme.emeraldGreenDark,
      'corrector': const Color(0xFF6366F1),
      'super_admin': const Color(0xFFEF4444),
      'student': const Color(0xFF0284C7),
    }[user.role] ?? AppTheme.textMuted;

    final roleLabel = {
      'teacher': 'Formateur',
      'corrector': 'Correcteur',
      'super_admin': 'Super Admin',
      'student': 'Étudiant',
    }[user.role] ?? user.role;

    final isTeacher = user.role == 'teacher';
    final isCorrector = user.role == 'corrector';
    final isApproved = user.isApproved;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: roleColor.withAlpha(30),
            child: Text(
              user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
              style: TextStyle(color: roleColor, fontWeight: FontWeight.w700),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  user.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isTeacher && isApproved)
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppTheme.paleMint, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.verified_rounded, size: 12, color: AppTheme.emeraldGreenDark),
                      SizedBox(width: 4),
                      Text('Validé', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.emeraldGreenDark)),
                    ],
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${user.email}${user.phoneNumber != null && user.phoneNumber!.isNotEmpty ? " • ${user.phoneNumber}" : ""}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              if (isTeacher && user.linkedCorrectorId != null)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    'Correcteur lié: ID ${user.linkedCorrectorId}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF6366F1), fontWeight: FontWeight.w600),
                  ),
                ),
              if (isCorrector && user.linkedTeacherId != null)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    'Formateur titulaire lié: ID ${user.linkedTeacherId}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.emeraldGreenDark, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isTeacher && !isApproved)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 14),
                    label: const Text('Valider', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emeraldGreenDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      await adminService.validateTeacher(user.uid);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Formateur ${user.displayName} validé avec succès !'), backgroundColor: AppTheme.emeraldGreenDark),
                      );
                    },
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.info_outline_rounded, size: 20, color: AppTheme.emeraldGreenDark),
                tooltip: 'Voir le dossier complet',
                onPressed: () => _showUserDetailsModal(context),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                tooltip: 'Supprimer ce compte',
                onPressed: () => _confirmDeleteUser(context),
              ),
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: roleColor.withAlpha(30), borderRadius: BorderRadius.circular(20)),
                child: Text(roleLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: roleColor)),
              ),
              PopupMenuButton<String>(
                onSelected: (action) async {
                  if (action == 'details') {
                    _showUserDetailsModal(context);
                  }
                  if (action == 'delete') {
                    _confirmDeleteUser(context);
                  }
                  if (action == 'validate') {
                    await adminService.validateTeacher(user.uid);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Formateur ${user.displayName} validé !'), backgroundColor: AppTheme.emeraldGreenDark),
                    );
                  }
                  if (action == 'suspend') await adminService.suspendUser(user.uid);
                  if (action == 'activate') await adminService.activateUser(user.uid);
                  if (action == 'unlink_corrector' && user.linkedCorrectorId != null) {
                    await adminService.removeCorrectorFromTeacher(correctorId: user.linkedCorrectorId!, teacherId: user.uid);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Correcteur dissocié !'), backgroundColor: AppTheme.emeraldGreenDark),
                    );
                  }
                  if (action == 'unlink_teacher' && user.linkedTeacherId != null) {
                    await adminService.removeCorrectorFromTeacher(correctorId: user.uid, teacherId: user.linkedTeacherId!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Formateur dissocié !'), backgroundColor: AppTheme.emeraldGreenDark),
                    );
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'details', child: Text('Voir le dossier complet')),
                  if (isTeacher && !isApproved)
                    const PopupMenuItem(value: 'validate', child: Text('Valider le formateur')),
                  if (isTeacher && user.linkedCorrectorId != null)
                    const PopupMenuItem(value: 'unlink_corrector', child: Text('Dissocier le correcteur')),
                  if (isCorrector && user.linkedTeacherId != null)
                    const PopupMenuItem(value: 'unlink_teacher', child: Text('Dissocier du formateur')),
                  const PopupMenuItem(value: 'suspend', child: Text('Suspendre le compte')),
                  const PopupMenuItem(value: 'activate', child: Text('Activer le compte')),
                  const PopupMenuItem(value: 'delete', child: Text('Supprimer définitivement', style: TextStyle(color: Colors.redAccent))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssignationPanel extends StatefulWidget {
  final SuperAdminService adminService;
  const _AssignationPanel({required this.adminService});

  @override
  State<_AssignationPanel> createState() => _AssignationPanelState();
}

class _AssignationPanelState extends State<_AssignationPanel> {
  String? _selectedCorrectorId;
  String? _selectedTeacherId;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card de nouvelle liaison
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Créer une nouvelle liaison', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.ink)),
                const SizedBox(height: 16),
                // Correctors dropdown
                Text('Correcteur', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.ink)),
                const SizedBox(height: 8),
                StreamBuilder<List<UserModel>>(
                  stream: widget.adminService.getUsersByRoleStream('corrector'),
                  builder: (context, snap) {
                    final correctors = snap.data ?? [];
                    return DropdownButtonFormField<String>(
                      value: _selectedCorrectorId,
                      hint: const Text('Sélectionner un correcteur'),
                      items: correctors.map((u) => DropdownMenuItem(value: u.uid, child: Text('${u.displayName} (${u.email})'))).toList(),
                      onChanged: (v) => setState(() => _selectedCorrectorId = v),
                      decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: const Color(0xFFF8FAFC)),
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Teachers dropdown
                Text('Formateur Titulaire', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.ink)),
                const SizedBox(height: 8),
                StreamBuilder<List<UserModel>>(
                  stream: widget.adminService.getUsersByRoleStream('teacher'),
                  builder: (context, snap) {
                    final teachers = snap.data ?? [];
                    return DropdownButtonFormField<String>(
                      value: _selectedTeacherId,
                      hint: const Text('Sélectionner un formateur'),
                      items: teachers.map((u) => DropdownMenuItem(value: u.uid, child: Text('${u.displayName} (${u.email})'))).toList(),
                      onChanged: (v) => setState(() => _selectedTeacherId = v),
                      decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: const Color(0xFFF8FAFC)),
                    );
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.link_rounded),
                    label: const Text('Lier le correcteur au formateur', style: TextStyle(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emeraldGreenDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: (_selectedCorrectorId == null || _selectedTeacherId == null || _saving)
                        ? null
                        : () async {
                            setState(() => _saving = true);
                            await widget.adminService.assignCorrectorToTeacher(
                              correctorId: _selectedCorrectorId!,
                              teacherId: _selectedTeacherId!,
                            );
                            setState(() {
                              _saving = false;
                              _selectedCorrectorId = null;
                              _selectedTeacherId = null;
                            });
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Assignation réussie avec succès !'), backgroundColor: AppTheme.emeraldGreenDark),
                              );
                            }
                          },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Liste des assignations actives
          Text('Liaisons Formateur ↔ Correcteur Actives', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.ink)),
          const SizedBox(height: 12),
          StreamBuilder<List<UserModel>>(
            stream: widget.adminService.getAllUsersStream(),
            builder: (context, snap) {
              final users = snap.data ?? [];
              final teachersWithCorrector = users.where((u) => u.role == 'teacher' && u.linkedCorrectorId != null).toList();

              if (teachersWithCorrector.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: const Center(
                    child: Text('Aucune liaison active pour le moment.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                  ),
                );
              }

              return Column(
                children: teachersWithCorrector.map((teacher) {
                  final corrector = users.firstWhere(
                    (u) => u.uid == teacher.linkedCorrectorId,
                    orElse: () => UserModel(uid: teacher.linkedCorrectorId!, email: '', displayName: 'Correcteur (${teacher.linkedCorrectorId})', role: 'corrector'),
                  );

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Row(
                      children: [
                        // Teacher side
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: AppTheme.paleMint, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.school_rounded, color: AppTheme.emeraldGreenDark, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(teacher.displayName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.ink)),
                              const Text('Formateur titulaire', style: TextStyle(fontSize: 11, color: AppTheme.emeraldGreenDark, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        // Link icon
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Icon(Icons.sync_alt_rounded, color: AppTheme.textMuted, size: 20),
                        ),
                        // Corrector side
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.rate_review_rounded, color: Color(0xFF6366F1), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(corrector.displayName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.ink)),
                              const Text('Correcteur attitré', style: TextStyle(fontSize: 11, color: Color(0xFF6366F1), fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        // Unlink action
                        IconButton(
                          icon: const Icon(Icons.link_off_rounded, color: Colors.redAccent),
                          tooltip: 'Dissocier',
                          onPressed: () async {
                            await widget.adminService.removeCorrectorFromTeacher(
                              correctorId: corrector.uid,
                              teacherId: teacher.uid,
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Liaison supprimée !'), backgroundColor: AppTheme.emeraldGreenDark),
                              );
                            }
                          },
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
}

class _LegalSheetProxy extends StatelessWidget {
  final String userId;
  const _LegalSheetProxy({required this.userId});

  @override
  Widget build(BuildContext context) {
    return _build(context);
  }

  Widget _build(BuildContext context) {
    // Delegate to the real sheet from LegalDocumentsFAB internals
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Center(child: LegalDocumentsFAB(userId: userId)),
    );
  }
}

class _BreakdownRow {
  final String label;
  final double percent;
  final Color color;

  const _BreakdownRow({
    required this.label,
    required this.percent,
    required this.color,
  });
}
