import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'models/course_model.dart';
import 'models/trainer_model.dart';
import 'models/user_model.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'screens/catalog_screen.dart';
import 'screens/course_detail_screen.dart';
import 'screens/trainers_screen.dart';
import 'screens/trainer_profile_screen.dart';
import 'screens/auth/register_full_screen.dart';
import 'screens/dashboards/student_dashboard_screen.dart';
import 'screens/dashboards/teacher_dashboard_screen.dart';
import 'screens/dashboards/corrector_dashboard_screen.dart';
import 'screens/dashboards/super_admin_dashboard_screen.dart';
import 'screens/about_screen.dart';
import 'screens/contact_screen.dart';
import 'widgets/language_switcher_widget.dart';
import 'services/language_service.dart';
import 'services/firebase_config.dart';
import 'services/course_service.dart';
import 'services/trainer_service.dart';
import 'widgets/auth_flow_dialog.dart';
import 'widgets/categories_section.dart';
import 'widgets/stats_band.dart';
import 'widgets/popular_courses_section.dart';
import 'widgets/trainers_section.dart';
import 'widgets/dual_cta_section.dart';
import 'widgets/app_mobile_menu.dart';
import 'widgets/footer_section.dart';
import 'services/app_update_service.dart';
import 'utils/app_scroll.dart';
import 'widgets/update_detector_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase connected to backend anour-84a69
  try {
    await FirebaseConfig.initialize();
  } catch (e) {
    debugPrint('Firebase initialization error (safe fallback): $e');
  }

  // Initialize update detection
  try {
    AppUpdateService().initialize();
  } catch (e) {
    debugPrint('AppUpdateService initialization error (safe fallback): $e');
  }

  try {
    await initializeDateFormatting('fr_FR', null);
    await initializeDateFormatting('fr', null);
  } catch (e) {
    debugPrint('Date formatting initialization error: $e');
  }

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('App Error caught: ${details.exceptionAsString()}');
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    final err = details.exceptionAsString();
    final contextDesc = details.context?.toDescription() ?? '';
    final stack = details.stack != null
        ? details.stack.toString().split('\n').take(6).join('\n')
        : '';
    debugPrint('[ClubFormateurs ERROR] $err\nContext: $contextDesc\n$stack');

    return Material(
      color: const Color(0xFF062C32),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: Color(0xFF13C7A3), size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Affichage temporairement indisponible',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Un composant nécessite un réajustement d\'affichage sur cet écran.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFBFCBCD), fontSize: 13),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF13C7A3).withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SelectableText(
                        err.isNotEmpty ? err : 'Erreur inconnue',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF86EFAC),
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                      if (contextDesc.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        SelectableText(
                          'Origine : $contextDesc',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF93C5FD),
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                      if (stack.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        SelectableText(
                          stack,
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 10,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        try {
                          AppUpdateService().applyUpdate();
                        } catch (_) {}
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Actualiser la page'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF13C7A3),
                        foregroundColor: const Color(0xFF062C32),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        try {
                          AppUpdateService.navigatorKey.currentState?.pushNamedAndRemoveUntil('/', (r) => false);
                        } catch (_) {}
                      },
                      icon: const Icon(Icons.home_rounded, size: 18, color: Colors.white),
                      label: const Text('Retour à l\'accueil', style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF13C7A3)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };

  runApp(const ClubFormateursApp());
}

class ClubFormateursApp extends StatelessWidget {
  const ClubFormateursApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService().currentLanguageNotifier,
      builder: (context, langCode, _) {
        return MaterialApp(
          key: ValueKey('app_locale_$langCode'),
          navigatorKey: AppUpdateService.navigatorKey,
          builder: (context, child) => UpdateDetectorWrapper(child: child ?? const SizedBox.shrink()),
          debugShowCheckedModeBanner: false,
          title: langCode == 'en' ? 'Trainers Club' : 'Club des Formateurs',
          scrollBehavior: const AppScrollBehavior(),
          theme: ThemeData(
            fontFamily: GoogleFonts.poppins().fontFamily,
            fontFamilyFallback: const [
              'Plus Jakarta Sans',
              'Inter',
              '-apple-system',
              'BlinkMacSystemFont',
              'Segoe UI',
              'Roboto',
              'Helvetica Neue',
              'sans-serif',
            ],
            textTheme: GoogleFonts.poppinsTextTheme(),
            scaffoldBackgroundColor: const Color(0xFF062C32),
            useMaterial3: true,
            pageTransitionsTheme: PageTransitionsTheme(
              builders: {
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
                TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
                TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
                TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
              },
            ),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF13C7A3),
              primary: const Color(0xFF13C7A3),
            ),
          ),
          locale: Locale(langCode),
          supportedLocales: const [
            Locale('fr', 'FR'),
            Locale('fr'),
            Locale('en'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          initialRoute: '/',
          routes: {
            '/': (context) => const HomePage(),
            '/formations': (context) => const CatalogScreen(),
            '/formateurs': (context) => const TrainersScreen(),
            '/formateur-profil': (context) => const TrainerProfileScreen(),
            '/dashboard/apprenant': (context) => const StudentDashboardScreen(),
            '/dashboard/formateur': (context) => const TeacherDashboardScreen(),
            '/dashboard/correcteur': (context) => const CorrectorDashboardScreen(),
            '/dashboard/admin': (context) => const SuperAdminDashboardScreen(),
            '/login': (context) => const _AuthScreenWrapper(initialStep: AuthFlowStep.login),
            '/connexion': (context) => const _AuthScreenWrapper(initialStep: AuthFlowStep.login),
            '/inscription': (context) => const RegisterFullScreen(initialRole: 'student'),
            '/register': (context) => const RegisterFullScreen(initialRole: 'student'),
            '/a-propos': (context) => const AboutScreen(),
            '/contact': (context) => const ContactScreen(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == '/course') {
              final course = settings.arguments as CourseModel? ?? CourseModel.showcaseCourses.first;
              return MaterialPageRoute(builder: (_) => CourseDetailScreen(course: course));
            }
            if (settings.name == '/trainer-profile') {
              final trainer = settings.arguments as TrainerModel?;
              return MaterialPageRoute(builder: (_) => TrainerProfileScreen(trainer: trainer));
            }
            return null;
          },
        );
      },
    );
  }
}

class _AuthScreenWrapper extends StatelessWidget {
  final AuthFlowStep initialStep;
  const _AuthScreenWrapper({this.initialStep = AuthFlowStep.login});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF041D17),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/');
            }
          },
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Center(
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.09,
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 320,
                    height: 320,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: AuthFlowDialog(initialStep: initialStep),
            ),
          ),
        ],
      ),
    );
  }
}

typedef ClubDesFormateursApp = ClubFormateursApp;

// =======================================================
// HOME PAGE
// =======================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const Color darkBackground = Color(0xFF062C32);
  static const Color darkSecondary = Color(0xFF083940);
  static const Color green = Color(0xFF13C7A3);
  static const Color lightGreen = Color(0xFF29D3AE);
  static const Color white = Color(0xFFFFFFFF);
  static const Color textGrey = Color(0xFFBFCBCD);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CourseService _courseService = CourseService();
  final TrainerService _trainerService = TrainerService();

  List<CourseModel> _popularCourses = [];
  List<TrainerWithCourses> _trainersWithCourses = [];
  int _studentsCount = 0;
  int _coursesCount = 0;
  int _teachersCount = 0;
  StreamSubscription? _coursesSub;
  Timer? _homeRefreshDebounce;
  String _lastCourseSignature = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _coursesSub = _courseService.getAllCoursesStream().listen(
      (courses) {
        _homeRefreshDebounce?.cancel();
        _homeRefreshDebounce = Timer(const Duration(milliseconds: 450), () {
          _applyHomeCourses(courses);
        });
      },
      onError: (err) {
        debugPrint('HomePage courses stream error (graceful fallback): $err');
      },
    );
  }

  @override
  void dispose() {
    _homeRefreshDebounce?.cancel();
    _coursesSub?.cancel();
    super.dispose();
  }

  Future<void> _applyHomeCourses(List<CourseModel> courses) async {
    if (!mounted) return;
    final signature = courses.map((c) => c.id).join(',');
    if (signature == _lastCourseSignature && _trainersWithCourses.isNotEmpty) {
      return;
    }
    _lastCourseSignature = signature;
    final teachersWithCourses = await _trainerService.getRealTrainersWithCourses();
    if (!mounted) return;
    setState(() {
      _popularCourses = courses;
      _trainersWithCourses = teachersWithCourses;
      _coursesCount = courses.length;
      _teachersCount = teachersWithCourses.length;
    });
  }

  Future<void> _loadData() async {
    final courses = await _courseService.getPopularCourses();
    final teachersWithCourses = await _trainerService.getRealTrainersWithCourses();

    int students = 0;
    int teachers = teachersWithCourses.length;
    try {
      final firestore = FirebaseConfig.firestore;
      if (firestore != null) {
        final snap = await firestore.collection('users').get();
        students = snap.docs.where((d) {
          final r = d.data()['role']?.toString().toLowerCase() ?? '';
          return r == 'student' || r == 'apprenant';
        }).length;
        final tCount = snap.docs.where((d) {
          final r = d.data()['role']?.toString().toLowerCase() ?? '';
          return r == 'teacher' || r == 'formateur';
        }).length;
        if (tCount > teachers) teachers = tCount;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _popularCourses = courses;
        _trainersWithCourses = teachersWithCourses;
        _coursesCount = courses.length;
        _teachersCount = teachers;
        _studentsCount = students > 0 ? students : 15;
        _lastCourseSignature = courses.map((c) => c.id).join(',');
      });
    }
  }

  void _showAuthModal({bool isRegister = false, String defaultRole = 'student'}) {
    if (isRegister) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RegisterFullScreen(initialRole: defaultRole),
        ),
      );
      return;
    }
    AuthFlowDialog.show(
      context,
      initialStep: AuthFlowStep.login,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 950;

    return Scaffold(
      backgroundColor: HomePage.darkBackground,
      endDrawer: _buildMobileDrawer(),
      body: SingleChildScrollView(
        physics: kIsWeb ? const ClampingScrollPhysics() : const BouncingScrollPhysics(),
        child: Column(
          children: [
            RepaintBoundary(
              child: Container(
              constraints: const BoxConstraints(
                minHeight: 760,
              ),
              width: double.infinity,
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
              child: Stack(
                children: [
                  Positioned(
                    right: -100,
                    top: 70,
                    child: Container(
                      width: 350,
                      height: 350,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: HomePage.green.withValues(alpha: .05),
                      ),
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width > 1200 ? 90 : (size.width > 600 ? 30 : 16),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 25),

                        // HEADER
                        Header(
                          onLoginTap: () => _showAuthModal(isRegister: false),
                          onRegisterTap: () => _showAuthModal(isRegister: true),
                        ),

                        SizedBox(height: isDesktop ? 60 : 35),

                        // HERO
                        isDesktop
                            ? DesktopHero(
                                onExploreTap: () => Navigator.pushNamed(context, '/formations'),
                                onBecomeTrainerTap: () => _showAuthModal(isRegister: true, defaultRole: 'teacher'),
                              )
                            : MobileHero(
                                onExploreTap: () => Navigator.pushNamed(context, '/formations'),
                                onBecomeTrainerTap: () => _showAuthModal(isRegister: true, defaultRole: 'teacher'),
                              ),

                        const SizedBox(height: 35),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ),

            Transform.translate(
              offset: const Offset(0, -55),
              child: SearchArea(
                onSearch: (query) => Navigator.pushNamed(context, '/formations'),
                onCategorySelect: (cat) => Navigator.pushNamed(context, '/formations'),
              ),
            ),

            // Dynamic Sections below Hero
            Container(
              color: const Color(0xFFF8FAFA),
              child: Column(
                children: [
                  // Categories Section (with Bootstrap icons and side banner)
                  RepaintBoundary(
                    child: CategoriesSection(
                    onCategoryTap: (category) => Navigator.pushNamed(context, '/formations'),
                    onViewAllTap: () => Navigator.pushNamed(context, '/formations'),
                  ),
                  ),

                  // Growth Stats Band (Dynamic)
                  RepaintBoundary(
                    child: StatsBand(
                    studentsCount: _studentsCount,
                    coursesCount: _coursesCount,
                    teachersCount: _teachersCount,
                  ),
                  ),

                  // Popular Courses (Dynamic created courses, no dummy data)
                  RepaintBoundary(
                    child: PopularCoursesSection(
                    courses: _popularCourses,
                    onCourseTap: (course) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CourseDetailScreen(course: course),
                        ),
                      );
                    },
                    onViewAllTap: () => Navigator.pushNamed(context, '/formations'),
                    onCreateCourseTap: () => _showAuthModal(isRegister: true, defaultRole: 'teacher'),
                  ),
                  ),

                  // Real Professors & their created courses (Students can view and enroll)
                  RepaintBoundary(
                    child: TrainersSection(
                    trainersWithCourses: _trainersWithCourses,
                    onTrainerTap: (trainer) {
                      Navigator.pushNamed(context, '/trainer-profile', arguments: trainer);
                    },
                    onCourseEnrollTap: (course) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CourseDetailScreen(course: course),
                        ),
                      );
                    },
                    onViewAllTap: () => Navigator.pushNamed(context, '/formateurs'),
                    onBecomeTrainerTap: () => _showAuthModal(isRegister: true, defaultRole: 'teacher'),
                  ),
                  ),

                  // Dual CTA (Apprenant & Formateur)
                  DualCtaSection(
                    onStudentRegisterTap: () => _showAuthModal(isRegister: true, defaultRole: 'student'),
                    onTeacherRegisterTap: () => _showAuthModal(isRegister: true, defaultRole: 'teacher'),
                  ),

                  // Footer
                  FooterSection(
                    onNavigate: (route) {
                      if (route == '/formations') {
                        Navigator.pushNamed(context, '/formations');
                      } else if (route == '/formateurs') {
                        Navigator.pushNamed(context, '/formateurs');
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileDrawer() {
    return const AppMobileMenu(activeRoute: '/');
  }
}

// =======================================================
// HEADER
// =======================================================

class Header extends StatelessWidget {
  final VoidCallback? onLoginTap;
  final VoidCallback? onRegisterTap;

  const Header({
    super.key,
    this.onLoginTap,
    this.onRegisterTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/'),
            child: const LogoClub(),
          ),
        ),

        if (width > 900) ...[
          NavItem(
            title: LanguageService().tr('nav_home'),
            active: true,
            onTap: () {},
          ),
          NavItem(
            title: LanguageService().tr('nav_courses'),
            onTap: () => Navigator.pushNamed(context, '/formations'),
          ),
          NavItem(
            title: LanguageService().tr('nav_trainers'),
            onTap: () => Navigator.pushNamed(context, '/formateurs'),
          ),
          NavItem(
            title: LanguageService().tr('nav_about'),
            onTap: () => Navigator.pushNamed(context, '/a-propos'),
          ),
          NavItem(
            title: LanguageService().tr('nav_contact'),
            onTap: () => Navigator.pushNamed(context, '/contact'),
          ),

          const SizedBox(width: 14),

          const LanguageSwitcherWidget(isDark: true),

          const SizedBox(width: 8),

          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/formations'),
            icon: const Icon(
              Icons.search_rounded,
              color: Colors.white,
            ),
          ),

          const SizedBox(width: 10),

          ValueListenableBuilder<UserModel?>(
            valueListenable: AuthService().currentUserNotifier,
            builder: (context, user, _) {
              if (user != null) {
                final route = user.isTeacher
                    ? '/dashboard/formateur'
                    : (user.isCorrector
                        ? '/dashboard/correcteur'
                        : (user.isSuperAdmin ? '/dashboard/admin' : '/dashboard/apprenant'));

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => Navigator.pushNamed(context, route),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 15,
                              backgroundColor: AppTheme.mintAccent,
                              backgroundImage: (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                                  ? NetworkImage(user.photoUrl ?? '')
                                  : null,
                              child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                                  ? Text(
                                      user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
                                      style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF062C32), fontSize: 13),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  user.displayName,
                                  style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13),
                                ),
                                Text(
                                  user.isTeacher
                                      ? LanguageService().tr('role_teacher')
                                      : (user.isCorrector
                                          ? LanguageService().tr('role_corrector')
                                          : (user.isSuperAdmin ? LanguageService().tr('role_admin') : LanguageService().tr('role_student'))),
                                  style: const TextStyle(color: Color(0xFF35D3A3), fontSize: 10, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00E676), Color(0xFF13C7A3), Color(0xFF00B4D8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF13C7A3).withValues(alpha: 0.55),
                            blurRadius: 16,
                            spreadRadius: 1,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, route),
                        icon: const Icon(Icons.dashboard_rounded, size: 18, color: Colors.white),
                        label: Text(
                          LanguageService().tr('nav_dashboard'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () async {
                        await AuthService().signOut();
                      },
                      icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 20),
                      tooltip: LanguageService().tr('nav_logout'),
                    ),
                  ],
                );
              }

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(
                    onPressed: onLoginTap ?? () {},
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF073039),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 17),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text(LanguageService().tr('nav_login'), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 12),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E676), Color(0xFF13C7A3), Color(0xFF00B4D8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF13C7A3).withValues(alpha: 0.55),
                          blurRadius: 16,
                          spreadRadius: 1,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: onRegisterTap ?? () {},
                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 18, color: Colors.white),
                      label: Text(
                        LanguageService().tr('nav_register'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: 0.3,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 17),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ] else
          ValueListenableBuilder<UserModel?>(
            valueListenable: AuthService().currentUserNotifier,
            builder: (context, user, _) {
              if (user != null) {
                final route = user.isTeacher
                    ? '/dashboard/formateur'
                    : (user.isCorrector
                        ? '/dashboard/correcteur'
                        : (user.isSuperAdmin ? '/dashboard/admin' : '/dashboard/apprenant'));

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00E676), Color(0xFF13C7A3)],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF13C7A3).withValues(alpha: 0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: () => Navigator.pushNamed(context, route),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.dashboard_rounded, color: Colors.white, size: 14),
                                if (width >= 360) ...[
                                  const SizedBox(width: 5),
                                  Text(
                                    user.displayName.isNotEmpty ? user.displayName.split(' ').first : LanguageService().t(fr: 'Espace', en: 'Dashboard'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (width >= 420) ...[
                      const SizedBox(width: 6),
                      const LanguageSwitcherWidget(isDark: true),
                    ],
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () => AppMobileMenu.show(context, activeRoute: '/'),
                      tooltip: LanguageService().tr('nav_menu'),
                      icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
                    ),
                  ],
                );
              }

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (width >= 440) ...[
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00E676), Color(0xFF13C7A3)],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF13C7A3).withValues(alpha: 0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: onRegisterTap ?? () {},
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 15),
                                const SizedBox(width: 6),
                                Text(
                                  LanguageService().tr('nav_register'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (width >= 350) ...[
                    const LanguageSwitcherWidget(isDark: true),
                    const SizedBox(width: 4),
                  ],
                  IconButton(
                    onPressed: () => AppMobileMenu.show(context, activeRoute: '/'),
                    tooltip: 'Menu',
                    icon: const Icon(
                      Icons.menu_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class LogoClub extends StatelessWidget {
  const LogoClub({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 480;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isCompact ? 40 : 48,
          height: isCompact ? 40 : 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isCompact ? 10 : 12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'assets/images/logo.png',
            width: isCompact ? 40 : 48,
            height: isCompact ? 40 : 48,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFF13C7A3),
              child: Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: isCompact ? 22 : 26,
              ),
            ),
          ),
        ),

        SizedBox(width: isCompact ? 8 : 12),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Club des',
              style: TextStyle(
                color: Colors.white,
                height: 1,
                fontSize: isCompact ? 13 : 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Formateurs',
              style: TextStyle(
                color: Colors.white,
                height: 1.1,
                fontSize: isCompact ? 16 : 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (!isCompact) ...[
              const SizedBox(height: 3),
              const Text(
                'APPRENDRE • ENSEIGNER • ÉVOLUER',
                style: TextStyle(
                  color: Color(0xFFA9B8BA),
                  fontSize: 6.5,
                  letterSpacing: .8,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class NavItem extends StatelessWidget {
  final String title;
  final bool active;
  final VoidCallback? onTap;

  const NavItem({
    super.key,
    required this.title,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13),
      child: Column(
        children: [
          TextButton(
            onPressed: onTap,
            child: Text(
              title,
              style: TextStyle(
                color: active
                    ? Colors.white
                    : Colors.white.withValues(alpha: .75),
                fontSize: 13,
                fontWeight:
                    active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),

          if (active)
            Container(
              width: 24,
              height: 2,
              decoration: BoxDecoration(
                color: const Color(0xFF13C7A3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
        ],
      ),
    );
  }
}

// =======================================================
// DESKTOP HERO
// =======================================================

class DesktopHero extends StatelessWidget {
  final VoidCallback? onExploreTap;
  final VoidCallback? onBecomeTrainerTap;

  const DesktopHero({
    super.key,
    this.onExploreTap,
    this.onBecomeTrainerTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 10,
          child: HeroTextSection(
            onExploreTap: onExploreTap,
            onBecomeTrainerTap: onBecomeTrainerTap,
          ),
        ),

        const SizedBox(width: 35),

        const Expanded(
          flex: 9,
          child: HeroImages(),
        ),
      ],
    );
  }
}

// =======================================================
// TEXT HERO
// =======================================================

class HeroTextSection extends StatelessWidget {
  final VoidCallback? onExploreTap;
  final VoidCallback? onBecomeTrainerTap;

  const HeroTextSection({
    super.key,
    this.onExploreTap,
    this.onBecomeTrainerTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF0D655B),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            LanguageService().tr('hero_badge'),
            style: const TextStyle(
              color: Color(0xFF6DE0C4),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        const SizedBox(height: 22),

        Text(
          LanguageService().tr('hero_title_1'),
          style: TextStyle(
            color: Colors.white,
            fontSize: isMobile ? 38 : 49,
            height: 1.02,
            fontWeight: FontWeight.w800,
          ),
        ),

        Text(
          LanguageService().tr('hero_title_2'),
          style: TextStyle(
            color: Colors.white,
            fontSize: isMobile ? 38 : 49,
            height: 1.05,
            fontWeight: FontWeight.w800,
          ),
        ),

        Text(
          LanguageService().tr('hero_title_3'),
          style: TextStyle(
            color: const Color(0xFF13C7A3),
            fontSize: isMobile ? 34 : 43,
            height: 1.12,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 23),

        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            LanguageService().tr('hero_subtitle'),
            style: TextStyle(
              color: const Color(0xFFC0CCCE),
              fontSize: isMobile ? 14 : 16,
              height: 1.7,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),

        const SizedBox(height: 27),

        Wrap(
          spacing: 16,
          runSpacing: 14,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ElevatedButton(
              onPressed: onExploreTap ?? () => Navigator.pushNamed(context, '/formations'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF13C7A3),
                foregroundColor: Colors.white,
                elevation: 8,
                shadowColor:
                    const Color(0xFF13C7A3).withValues(alpha: .25),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20 : 27,
                  vertical: isMobile ? 16 : 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(35),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    LanguageService().tr('hero_cta_explore'),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: isMobile ? 13 : 14,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                  ),
                ],
              ),
            ),

            OutlinedButton(
              onPressed: onBecomeTrainerTap ?? () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 22 : 28,
                  vertical: isMobile ? 16 : 19,
                ),
                side: BorderSide(
                  color: Colors.white.withValues(alpha: .5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(35),
                ),
              ),
              child: Text(
                LanguageService().tr('hero_cta_teach'),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: isMobile ? 13 : 14,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 42),

        const HeroStatistics(),
      ],
    );
  }
}

// =======================================================
// STATISTICS
// =======================================================

class HeroStatistics extends StatelessWidget {
  const HeroStatistics({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 32,
      runSpacing: 16,
      children: [
        Statistic(
          icon: Icons.school_rounded,
          title: LanguageService().tr('hero_stat_quality_title'),
          subtitle: LanguageService().tr('hero_stat_quality_sub'),
        ),

        Statistic(
          icon: Icons.groups_rounded,
          title: LanguageService().tr('hero_stat_experts_title'),
          subtitle: LanguageService().tr('hero_stat_experts_sub'),
        ),

        Statistic(
          icon: Icons.show_chart_rounded,
          title: LanguageService().tr('hero_stat_growth_title'),
          subtitle: LanguageService().tr('hero_stat_growth_sub'),
        ),
      ],
    );
  }
}

class Statistic extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const Statistic({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 27,
        ),

        const SizedBox(width: 10),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFFB2C0C2),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// =======================================================
// HERO IMAGES
// =======================================================

class HeroImages extends StatelessWidget {
  const HeroImages({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 505,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
            left: 75,
            top: 0,
            child: PersonCard(
              image: 'assets/images/student-phone-framed.jpeg',
              width: 215,
              height: 300,
              radius: 35,
            ),
          ),

          const Positioned(
            right: 5,
            top: 15,
            child: PersonCard(
              image: 'assets/images/formateur2.jpg',
              width: 170,
              height: 245,
              radius: 32,
            ),
          ),

          Positioned(
            left: 5,
            bottom: 0,
            child: Transform.rotate(
              angle: -.07,
              child: const PersonCard(
                image: 'assets/images/apprenant1.jpg',
                width: 190,
                height: 210,
                radius: 35,
              ),
            ),
          ),

          const Positioned(
            right: 15,
            bottom: 5,
            child: PersonCard(
              image: 'assets/images/apprenant2.jpg',
              width: 170,
              height: 210,
              radius: 35,
            ),
          ),

          Positioned(
            left: 8,
            top: 170,
            child: FloatingBadge(
              icon: Icons.groups_rounded,
              iconColor: const Color(0xFF15B9A0),
              number: '10K+',
              text: LanguageService().tr('stat_learners'),
            ),
          ),

          Positioned(
            right: 15,
            top: 210,
            child: FloatingBadge(
              icon: Icons.verified_rounded,
              iconColor: const Color(0xFF8BCD73),
              number: LanguageService().t(fr: 'Apprendre', en: 'Learn'),
              text: LanguageService().t(fr: 'sans limites', en: 'without limits'),
            ),
          ),

          Positioned(
            left: 20,
            bottom: 5,
            child: FloatingBadge(
              icon: Icons.play_circle_fill_rounded,
              iconColor: const Color(0xFFF2B632),
              number: LanguageService().t(fr: 'Créer', en: 'Create'),
              text: LanguageService().t(fr: 'en 365 idées', en: 'in 365 ideas'),
            ),
          ),

          Positioned(
            right: 0,
            bottom: 15,
            child: FloatingBadge(
              icon: Icons.auto_awesome_rounded,
              iconColor: const Color(0xFF2C8ECC),
              number: LanguageService().t(fr: 'Se former', en: 'Level up'),
              text: LanguageService().t(fr: 'aujourd’hui', en: 'today'),
            ),
          ),

          Positioned(
            left: 10,
            top: 55,
            child: Transform.rotate(
              angle: -.18,
              child: Text(
                LanguageService().t(fr: 'Des\ncompétences\npour un meilleur\navenir !', en: 'Skills\nfor a brighter\nfuture !'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.25,
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          Positioned(
            right: -20,
            bottom: 110,
            child: Transform.rotate(
              angle: -.12,
              child: Text(
                LanguageService().t(fr: "Former\naujourd'hui.\nConstruire\ndemain !", en: "Teaching\ntoday.\nBuilding\ntomorrow !"),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.25,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          Positioned(
            left: 250,
            bottom: 10,
            child: Container(
              width: 58,
              height: 125,
              decoration: BoxDecoration(
                color: const Color(0xFF13C7A3),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PersonCard extends StatelessWidget {
  final String image;
  final double width;
  final double height;
  final double radius;

  const PersonCard({
    super.key,
    required this.image,
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .22),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Image.asset(
        image,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            color: const Color(0xFF315961),
            child: const Center(
              child: Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 80,
              ),
            ),
          );
        },
      ),
    );
  }
}

// =======================================================
// FLOATING BADGES
// =======================================================

class FloatingBadge extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String number;
  final String text;

  const FloatingBadge({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.number,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),

          const SizedBox(width: 9),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                number,
                style: const TextStyle(
                  color: Color(0xFF18262A),
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
              Text(
                text,
                style: const TextStyle(
                  color: Color(0xFF6F787A),
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =======================================================
// SEARCH
// =======================================================

class SearchArea extends StatelessWidget {
  final Function(String query)? onSearch;
  final Function(String category)? onCategorySelect;

  const SearchArea({
    super.key,
    this.onSearch,
    this.onCategorySelect,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 720;

    return Container(
      width: width,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: 25,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFA),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(60),
        ),
      ),
      child: Column(
        children: [
          if (isMobile)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.search,
                    color: Color(0xFF13B899),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: LanguageService().tr('search_placeholder'),
                        hintStyle: const TextStyle(
                          color: Color(0xFF9DA7A9),
                          fontSize: 12,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => onSearch?.call('') ?? Navigator.pushNamed(context, '/formations'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF13C7A3),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      minimumSize: const Size(0, 38),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      LanguageService().tr('search_btn'),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              constraints: const BoxConstraints(
                maxWidth: 900,
              ),
              height: 72,
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .08),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search,
                    color: Color(0xFF13B899),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: LanguageService().tr('search_placeholder'),
                        hintStyle: const TextStyle(
                          color: Color(0xFF9DA7A9),
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  Container(
                    width: 1,
                    height: 30,
                    color: const Color(0xFFE5E8E8),
                  ),

                  const SizedBox(width: 20),

                  Text(
                    LanguageService().tr('search_all_cats'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF747D80),
                    ),
                  ),

                  const SizedBox(width: 5),

                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFF747D80),
                  ),

                  const SizedBox(width: 20),

                  ElevatedButton(
                    onPressed: () => onSearch?.call('') ?? Navigator.pushNamed(context, '/formations'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(145, 52),
                      backgroundColor:
                          const Color(0xFF13C7A3),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      LanguageService().tr('search_btn'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 22),

          Wrap(
            spacing: 25,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              CategoryText(LanguageService().tr('search_cat_popular'), onTap: () => onCategorySelect?.call('Formations populaires')),
              CategoryText(LanguageService().tr('search_cat_it'), onTap: () => onCategorySelect?.call('Informatique')),
              CategoryText(LanguageService().tr('search_cat_marketing'), onTap: () => onCategorySelect?.call('Marketing')),
              CategoryText(LanguageService().tr('search_cat_design'), onTap: () => onCategorySelect?.call('Design')),
              CategoryText(LanguageService().tr('search_cat_business'), onTap: () => onCategorySelect?.call('Business')),
              CategoryText(LanguageService().tr('search_cat_personal_dev'), onTap: () => onCategorySelect?.call('Développement personnel')),
            ],
          ),
        ],
      ),
    );
  }
}

class CategoryText extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const CategoryText(
    this.text, {
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => Navigator.pushNamed(context, '/formations'),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF626C6E),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// =======================================================
// MOBILE VERSION
// =======================================================

class MobileHero extends StatelessWidget {
  final VoidCallback? onExploreTap;
  final VoidCallback? onBecomeTrainerTap;

  const MobileHero({
    super.key,
    this.onExploreTap,
    this.onBecomeTrainerTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HeroTextSection(
          onExploreTap: onExploreTap,
          onBecomeTrainerTap: onBecomeTrainerTap,
        ),
        const SizedBox(height: 40),
        const FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: 480,
            height: 505,
            child: HeroImages(),
          ),
        ),
      ],
    );
  }
}
