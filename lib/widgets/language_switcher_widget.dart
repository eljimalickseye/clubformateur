import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/language_service.dart';
import '../theme/app_theme.dart';

class LanguageSwitcherWidget extends StatelessWidget {
  final bool isDark;
  const LanguageSwitcherWidget({super.key, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    final languageService = LanguageService();

    return ValueListenableBuilder<String>(
      valueListenable: languageService.currentLanguageNotifier,
      builder: (context, lang, _) {
        final isFr = lang == 'fr';

        return Tooltip(
          message: isFr ? 'Passer en anglais' : 'Switch to French',
          child: InkWell(
            onTap: languageService.toggleLanguage,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppTheme.cardBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isFr ? '🇫🇷' : '🇬🇧',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isFr ? 'FR' : 'EN',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppTheme.ink,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    Icons.sync_alt_rounded,
                    size: 11,
                    color: isDark ? AppTheme.mintAccent : AppTheme.emeraldGreenDark,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
