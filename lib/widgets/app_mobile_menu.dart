import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../theme/app_theme.dart';
import 'auth_flow_dialog.dart';
import 'legal_documents_widget.dart';
import 'language_switcher_widget.dart';

class AppMobileMenu extends StatelessWidget {
  final String activeRoute;

  const AppMobileMenu({
    super.key,
    this.activeRoute = '/',
  });

  static Future<void> show(BuildContext context, {String activeRoute = '/'}) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Menu de navigation',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, anim1, anim2) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: AppMobileMenu(activeRoute: activeRoute),
          ),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: anim1,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      },
    );
  }

  void _close(BuildContext context) {
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold != null && scaffold.isEndDrawerOpen) {
      scaffold.closeEndDrawer();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void _nav(BuildContext context, String route) {
    _close(context);
    if (route == activeRoute) return;
    if (route == '/') {
      Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
    } else {
      Navigator.pushNamed(context, route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final menuWidth = math.min(size.width * 0.85, 340.0);
    final user = AuthService().currentUser;

    return Container(
      width: menuWidth,
      height: size.height,
      decoration: const BoxDecoration(
        color: Color(0xFF062C32),
        boxShadow: [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 30,
            offset: Offset(-8, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header: Logo + Close Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Club des Formateurs',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 24),
                    onPressed: () => _close(context),
                  ),
                ],
              ),
            ),

            const Divider(color: Color(0xFF14454C), height: 1),

            // User Info Banner (if logged in or guest)
            Padding(
              padding: const EdgeInsets.all(16),
              child: user != null
                  ? _buildUserCard(context, user)
                  : _buildGuestCard(context),
            ),

            const Divider(color: Color(0xFF14454C), height: 1),

            // Nav Links
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                children: [
                  _MenuItem(
                    icon: Icons.home_rounded,
                    title: LanguageService().tr('nav_home'),
                    subtitle: LanguageService().t(fr: 'Page principale', en: 'Main page'),
                    isActive: activeRoute == '/',
                    onTap: () => _nav(context, '/'),
                  ),
                  const SizedBox(height: 6),
                  _MenuItem(
                    icon: Icons.school_rounded,
                    title: LanguageService().tr('nav_courses'),
                    subtitle: LanguageService().tr('menu_courses_sub'),
                    isActive: activeRoute == '/formations',
                    onTap: () => _nav(context, '/formations'),
                  ),
                  const SizedBox(height: 6),
                  _MenuItem(
                    icon: Icons.groups_rounded,
                    title: LanguageService().tr('nav_trainers'),
                    subtitle: LanguageService().tr('menu_trainers_sub'),
                    isActive: activeRoute == '/formateurs',
                    onTap: () => _nav(context, '/formateurs'),
                  ),
                  const SizedBox(height: 6),
                  _MenuItem(
                    icon: Icons.info_outline_rounded,
                    title: LanguageService().tr('nav_about'),
                    subtitle: LanguageService().tr('menu_about_sub'),
                    isActive: activeRoute == '/a-propos',
                    onTap: () => _nav(context, '/a-propos'),
                  ),
                  const SizedBox(height: 6),
                  _MenuItem(
                    icon: Icons.support_agent_rounded,
                    title: LanguageService().tr('nav_contact'),
                    subtitle: LanguageService().tr('menu_contact_sub'),
                    isActive: activeRoute == '/contact',
                    onTap: () => _nav(context, '/contact'),
                  ),
                  const SizedBox(height: 6),
                  if (user != null) ...[
                    _MenuItem(
                      icon: Icons.dashboard_rounded,
                      title: LanguageService().tr('nav_dashboard'),
                      subtitle: _getDashboardLabel(user.role),
                      isActive: activeRoute.startsWith('/dashboard'),
                      onTap: () {
                        Navigator.of(context, rootNavigator: true).pop();
                        final route = _getDashboardRoute(user.role);
                        Navigator.pushNamed(context, route);
                      },
                    ),
                    const SizedBox(height: 6),
                  ],
                  _MenuItem(
                    icon: Icons.gavel_rounded,
                    title: LanguageService().tr('menu_official_docs'),
                    subtitle: LanguageService().tr('menu_official_docs_sub'),
                    isActive: false,
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).pop();
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => LegalDocumentsView(userId: user?.uid ?? 'guest', isModal: true),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Bottom Actions (Language Switcher & Auth Buttons)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF042024),
                border: Border(top: BorderSide(color: Color(0xFF14454C))),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Langue / Language',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const LanguageSwitcherWidget(isDark: true),
                      ],
                    ),
                  ),
                  if (user == null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context, rootNavigator: true).pop();
                          AuthFlowDialog.show(context, initialStep: AuthFlowStep.login);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF23656F), width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Se connecter',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00E676), Color(0xFF13C7A3), Color(0xFF00B4D8)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF13C7A3).withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context, rootNavigator: true).pop();
                            Navigator.pushNamed(context, '/inscription');
                          },
                          icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 16),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          label: Text(
                            "S'inscrire gratuitement",
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ] else
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 18),
                        label: Text(
                          'Déconnexion',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFFEF4444),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        onPressed: () async {
                          Navigator.of(context, rootNavigator: true).pop();
                          await AuthService().signOut();
                          if (context.mounted) {
                            Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
                          }
                        },
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

  Widget _buildUserCard(BuildContext context, UserModel user) {
    final roleName = {
      'teacher': 'Formateur',
      'corrector': 'Correcteur',
      'super_admin': 'Super Admin',
    }[user.role] ?? 'Apprenant';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.emeraldGreen,
            child: Text(
              user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.emeraldGreen.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    roleName,
                    style: const TextStyle(
                      color: AppTheme.emeraldGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF14454C),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person_outline_rounded, color: Colors.white70, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenue !',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Rejoignez la communauté',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF90A4AE),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getDashboardLabel(String role) {
    switch (role) {
      case 'teacher':
        return 'Espace Formateur';
      case 'corrector':
        return 'Espace Correcteur';
      case 'super_admin':
        return 'Super Admin';
      default:
        return 'Espace Apprenant';
    }
  }

  String _getDashboardRoute(String role) {
    switch (role) {
      case 'teacher':
        return '/dashboard/formateur';
      case 'corrector':
        return '/dashboard/correcteur';
      case 'super_admin':
        return '/dashboard/admin';
      default:
        return '/dashboard/apprenant';
    }
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isActive;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.emeraldGreen.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isActive
              ? Border.all(color: AppTheme.emeraldGreen.withValues(alpha: 0.4))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isActive ? AppTheme.emeraldGreen : const Color(0xFF0C383F),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isActive ? Colors.white : const Color(0xFF90A4AE),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      color: isActive ? Colors.white : const Color(0xFFE2E8F0),
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isActive ? AppTheme.emeraldGreen : const Color(0xFF64748B),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isActive ? AppTheme.emeraldGreen : const Color(0xFF475569),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
