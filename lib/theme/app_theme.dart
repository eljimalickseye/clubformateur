import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Palette Principale - Club des Formateurs (Vert Sapin & Émeraude)
  static const Color forestGreenDark = Color(0xFF06281F);
  static const Color forestGreen = Color(0xFF0A2B24);
  static const Color forestGreenLight = Color(0xFF0D3F33);
  
  static const Color emeraldGreen = Color(0xFF12A57A);
  static const Color emeraldGreenDark = Color(0xFF0D6B4D);
  static const Color mintAccent = Color(0xFF35D3A3);
  static const Color paleMint = Color(0xFFE9F7F1);
  static const Color chipMint = Color(0xFFDCF5EB);

  // Fonds et surfaces
  static const Color ivoryBg = Color(0xFFF9FAF8);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color altSectionBg = Color(0xFFF2F7F5);
  static const Color footerBg = Color(0xFF071F24);

  // Typographie et bordures
  static const Color ink = Color(0xFF10233F);
  static const Color textMuted = Color(0xFF65748B);
  static const Color textLight = Color(0xFF94A3B8);
  static const Color cardBorder = Color(0xFFE2E8E5);
  static const Color amberStar = Color(0xFFF59E0B);

  // Backward-compatible Aliases
  static const Color primaryPurple = emeraldGreen;
  static const Color darkPurple = forestGreenDark;
  static const Color accentPurple = mintAccent;
  static const Color lightPurpleBg = paleMint;
  static const Color primaryBlue = emeraldGreen;
  static const Color darkBlue = forestGreenDark;
  static const Color textDark = ink;
  static const Color softPurple = paleMint;
  static const Color softBlue = paleMint;
  static const Color softMint = paleMint;
  static const Color iconMint = emeraldGreen;
  static const Color softAmber = Color(0xFFFFFBEB);
  static const Color iconAmber = amberStar;
  static const Color borderSubtle = cardBorder;
  static const LinearGradient heroCardGradient = heroGradient;
  static const LinearGradient headerGradient = heroGradient;

  // Gradients
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0B2D2A),
      Color(0xFF073F36),
      Color(0xFF064437),
    ],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0D6B4D),
      Color(0xFF12A57A),
    ],
  );

  static const LinearGradient statsBandGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFE8F7F1),
      Color(0xFFF6FBF8),
    ],
  );

  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF083D35),
      Color(0xFF0A5947),
    ],
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: ivoryBg,
      primaryColor: emeraldGreen,
      colorScheme: ColorScheme.fromSeed(
        seedColor: emeraldGreen,
        primary: emeraldGreen,
        secondary: mintAccent,
        surface: surfaceWhite,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          color: ink,
          letterSpacing: -0.5,
        ),
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: ink,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: ink,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textMuted,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: emeraldGreen,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: emeraldGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorder, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorder, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: emeraldGreen, width: 1.5),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: textLight,
          fontWeight: FontWeight.w400,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: cardBorder, width: 1.0),
        ),
      ),
    );
  }
}
