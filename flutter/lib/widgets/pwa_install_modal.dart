import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'app_svg_icon.dart';

class PwaInstallModal {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => const _PwaInstallSheet(),
    );
  }
}

class _PwaInstallSheet extends StatefulWidget {
  const _PwaInstallSheet();

  @override
  State<_PwaInstallSheet> createState() => _PwaInstallSheetState();
}

class _PwaInstallSheetState extends State<_PwaInstallSheet> {
  int _selectedOs = 0; // 0: Android / Chrome, 1: iPhone / Safari, 2: PC / Mac

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Drag handle
          Container(
            width: 44,
            height: 4.5,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 18),

          // App Icon Badge
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppTheme.heroCardGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryPurple.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: AppSvgIcon(
                assetName: AppSvgIcon.shieldCheck,
                color: Colors.white,
                size: 34,
              ),
            ),
          ),
          const SizedBox(height: 12),

          Text(
            'Installer l\'Application OLIVIA',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFC7D2FE)),
            ),
            child: Text(
              '⚡ Progressive Web App (PWA) Officielle',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryPurple,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Avantages PWA
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _benefitRow(Icons.offline_bolt_rounded, 'Accès direct à votre Talon CIMA sans connexion'),
                const SizedBox(height: 8),
                _benefitRow(Icons.fullscreen_rounded, 'Expérience fluide plein écran sans barre de navigateur'),
                const SizedBox(height: 8),
                _benefitRow(Icons.bolt_rounded, 'Chargement instantané et zéro stockage lourd'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Sélecteur d'appareil
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                _osTab(0, '🤖 Android', Icons.android_rounded),
                _osTab(1, '🍎 iPhone / iPad', Icons.apple_rounded),
                _osTab(2, '💻 Ordinateur', Icons.laptop_rounded),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Instructions par OS
          if (_selectedOs == 0) _buildAndroidSteps(),
          if (_selectedOs == 1) _buildIosSteps(),
          if (_selectedOs == 2) _buildDesktopSteps(),

          const SizedBox(height: 18),

          // Bouton principal d'installation
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Color(0xFF10B981),
                    content: Text('📱 Suivez les étapes ci-dessus pour ajouter Olivia à votre écran d\'accueil !'),
                  ),
                );
              },
              icon: const Icon(Icons.download_done_rounded, size: 18),
              label: Text(
                'J\'ai compris • Ajouter à l\'écran d\'accueil',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13.5),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPurple),
            ),
          ),
        ],
      ),
    );
  }

  Widget _benefitRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF10B981), size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF334155), fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _osTab(int index, String label, IconData icon) {
    final isSelected = _selectedOs == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedOs = index),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryPurple : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAndroidSteps() {
    return Column(
      children: [
        _stepTile('1', 'Ouvrez le menu de votre navigateur (les 3 points en haut à droite ⋮).'),
        const SizedBox(height: 6),
        _stepTile('2', 'Appuyez sur « Installer l\'application » ou « Ajouter à l\'écran d\'accueil ».'),
        const SizedBox(height: 6),
        _stepTile('3', 'Confirmez en cliquant sur « Installer ». L\'icône Olivia apparaît sur votre téléphone.'),
      ],
    );
  }

  Widget _buildIosSteps() {
    return Column(
      children: [
        _stepTile('1', 'Dans Safari, appuyez sur le bouton Partager ⬆️ (en bas de votre écran).'),
        const SizedBox(height: 6),
        _stepTile('2', 'Faites défiler le menu et appuyez sur « Sur l\'écran d\'accueil » ➕.'),
        const SizedBox(height: 6),
        _stepTile('3', 'Appuyez sur « Ajouter » en haut à droite. Olivia est installée !'),
      ],
    );
  }

  Widget _buildDesktopSteps() {
    return Column(
      children: [
        _stepTile('1', 'Dans la barre d\'adresse en haut à droite, cliquez sur l\'icône « Installer » 📥.'),
        const SizedBox(height: 6),
        _stepTile('2', 'Cliquez sur « Installer ». Olivia s\'ouvre dans sa propre fenêtre autonome.'),
      ],
    );
  }

  Widget _stepTile(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppTheme.softPurple,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(color: AppTheme.primaryPurple, fontSize: 11, fontWeight: FontWeight.w900),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF475569), height: 1.3),
          ),
        ),
      ],
    );
  }
}

// Bannière PWA affichable sur l'écran d'accueil
class PwaInstallBanner extends StatelessWidget {
  const PwaInstallBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF312E81).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.install_mobile_rounded, color: Color(0xFFFFD166), size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Installer Olivia (App PWA)',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
                Text(
                  'Pass CIMA & cartes grises 100% hors-ligne',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => PwaInstallModal.show(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD166),
              foregroundColor: const Color(0xFF0F172A),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Installer', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5)),
          ),
        ],
      ),
    );
  }
}
