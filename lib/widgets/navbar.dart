import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../theme/app_theme.dart';
import 'auth_flow_dialog.dart';
import 'app_mobile_menu.dart';
import 'language_switcher_widget.dart';

class Navbar extends StatelessWidget implements PreferredSizeWidget {
  final String activeRoute;
  final bool? isDark;
  final VoidCallback? onLoginTap;
  final VoidCallback? onRegisterTap;
  final VoidCallback? onSearchTap;
  final Function(String route)? onNavigate;

  const Navbar({
    super.key,
    this.activeRoute = '/',
    this.isDark,
    this.onLoginTap,
    this.onRegisterTap,
    this.onSearchTap,
    this.onNavigate,
  });

  @override
  Size get preferredSize => const Size.fromHeight(78);

  void _navigate(BuildContext context, String route) {
    if (onNavigate != null) {
      onNavigate!(route);
    } else {
      if (route == activeRoute) return;
      if (route == '/') {
        Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
      } else {
        Navigator.pushNamed(context, route);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1024;
    final dark = isDark ?? (activeRoute == '/');

    return Container(
      height: 78,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : 20,
      ),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF072922) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: dark ? Colors.white.withValues(alpha: 0.08) : AppTheme.cardBorder,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          if (activeRoute != '/' || Navigator.canPop(context)) ...[
            IconButton(
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  _navigate(context, '/');
                }
              },
              tooltip: LanguageService().tr('nav_back'),
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: dark ? Colors.white : AppTheme.ink,
                size: 20,
              ),
              style: IconButton.styleFrom(
                backgroundColor: dark
                    ? Colors.white.withValues(alpha: 0.1)
                    : const Color(0xFFF1F5F9),
                padding: const EdgeInsets.all(8),
                minimumSize: const Size(36, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Logo
          Expanded(
            child: InkWell(
              onTap: () => _navigate(context, '/'),
              borderRadius: BorderRadius.circular(10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Club des',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: dark ? Colors.white : AppTheme.ink,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'Formateurs',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.mintAccent,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Navigation Links (Desktop)
          if (isDesktop)
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _NavLink(
                      title: LanguageService().tr('nav_home'),
                      isActive: activeRoute == '/',
                      isDark: dark,
                      onTap: () => _navigate(context, '/'),
                    ),
                    const SizedBox(width: 20),
                    _NavLink(
                      title: LanguageService().tr('nav_courses'),
                      isActive: activeRoute == '/formations',
                      isDark: dark,
                      onTap: () => _navigate(context, '/formations'),
                    ),
                    const SizedBox(width: 20),
                    _NavLink(
                      title: LanguageService().tr('nav_trainers'),
                      isActive: activeRoute == '/formateurs',
                      isDark: dark,
                      onTap: () => _navigate(context, '/formateurs'),
                    ),
                    const SizedBox(width: 20),
                    _NavLink(
                      title: LanguageService().tr('nav_about'),
                      isActive: activeRoute == '/a-propos',
                      isDark: dark,
                      onTap: () => _navigate(context, '/a-propos'),
                    ),
                    const SizedBox(width: 20),
                    _NavLink(
                      title: LanguageService().tr('nav_contact'),
                      isActive: activeRoute == '/contact',
                      isDark: dark,
                      onTap: () => _navigate(context, '/contact'),
                    ),
                  ],
                ),
              ),
            )
          else
            const Spacer(),

          // Actions
          ValueListenableBuilder<UserModel?>(
            valueListenable: AuthService().currentUserNotifier,
            builder: (context, user, _) {
              final effectiveLogin = onLoginTap ?? () => AuthFlowDialog.show(context, initialStep: AuthFlowStep.login);
              final effectiveRegister = onRegisterTap ?? () => Navigator.pushNamed(context, '/inscription');

              if (user != null) {
                final route = user.isTeacher
                    ? '/dashboard/formateur'
                    : (user.isCorrector
                        ? '/dashboard/correcteur'
                        : (user.isSuperAdmin ? '/dashboard/admin' : '/dashboard/apprenant'));

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isDesktop) ...[
                      LanguageSwitcherWidget(isDark: dark),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppTheme.mintAccent,
                        backgroundImage: (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                            ? NetworkImage(user.photoUrl!)
                            : null,
                        child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                            ? Text(
                                user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
                                style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF062C32), fontSize: 11),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        user.displayName,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: dark ? Colors.white : AppTheme.ink,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, route),
                      icon: const Icon(Icons.dashboard_rounded, size: 16),
                      label: Text(
                        isDesktop ? LanguageService().tr('nav_dashboard') : LanguageService().t(fr: 'Espace', en: 'Dashboard'),
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emeraldGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    if (isDesktop) ...[
                      const SizedBox(width: 6),
                      IconButton(
                        onPressed: () async {
                          await AuthService().signOut();
                        },
                        icon: Icon(Icons.logout_rounded, color: dark ? Colors.white70 : AppTheme.ink, size: 18),
                        tooltip: LanguageService().tr('nav_logout'),
                      ),
                    ],
                    if (!isDesktop) ...[
                      const SizedBox(width: 6),
                      LanguageSwitcherWidget(isDark: dark),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(Icons.menu_rounded, color: dark ? Colors.white : AppTheme.ink),
                        tooltip: LanguageService().tr('nav_menu'),
                        onPressed: () => AppMobileMenu.show(context, activeRoute: activeRoute),
                      ),
                    ],
                  ],
                );
              }

              if (isDesktop) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LanguageSwitcherWidget(isDark: dark),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: onSearchTap,
                      icon: Icon(Icons.search_rounded, color: dark ? Colors.white70 : AppTheme.ink, size: 22),
                      tooltip: LanguageService().tr('nav_search'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: effectiveLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: dark ? Colors.white : Colors.transparent,
                        foregroundColor: dark ? AppTheme.forestGreenDark : AppTheme.ink,
                        elevation: 0,
                        side: dark ? BorderSide.none : const BorderSide(color: AppTheme.cardBorder, width: 1.2),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(
                        LanguageService().tr('nav_login'),
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00E676), Color(0xFF13C7A3), Color(0xFF00B4D8)],
                        ),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF13C7A3).withValues(alpha: 0.5),
                            blurRadius: 14,
                            spreadRadius: 1,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: effectiveRegister,
                        icon: const Icon(Icons.person_add_alt_1_rounded, size: 16, color: Colors.white),
                        label: Text(
                          LanguageService().tr('nav_register'),
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LanguageSwitcherWidget(isDark: dark),
                    const SizedBox(width: 8),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00E676), Color(0xFF13C7A3)],
                        ),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF13C7A3).withValues(alpha: 0.45),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: effectiveRegister,
                        icon: const Icon(Icons.person_add_alt_1_rounded, size: 14, color: Colors.white),
                        label: Text(
                          LanguageService().tr('nav_register'),
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    LanguageSwitcherWidget(isDark: dark),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(Icons.menu_rounded, color: dark ? Colors.white : AppTheme.ink),
                      tooltip: LanguageService().tr('nav_menu'),
                      onPressed: () => AppMobileMenu.show(context, activeRoute: activeRoute),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  final String title;
  final bool isActive;
  final bool isDark;
  final VoidCallback? onTap;

  const _NavLink({
    required this.title,
    this.isActive = false,
    this.isDark = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color textColor;
    if (isActive) {
      textColor = isDark ? Colors.white : AppTheme.emeraldGreen;
    } else {
      textColor = isDark ? const Color(0xFFD9ECE7) : AppTheme.ink;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 2,
              width: isActive ? 22 : 0,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.mintAccent : AppTheme.emeraldGreen,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
