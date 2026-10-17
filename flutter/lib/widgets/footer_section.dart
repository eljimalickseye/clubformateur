import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class FooterSection extends StatelessWidget {
  final Function(String route)? onNavigate;

  const FooterSection({
    super.key,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 960;

    return Container(
      width: double.infinity,
      color: AppTheme.footerBg,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : 20,
        vertical: 56,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            children: [
              // Main Columns
              isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Col 1: Brand
                        Expanded(flex: 3, child: _buildBrandCol()),
                        const SizedBox(width: 24),
                        // Col 2: Liens rapides
                        Expanded(flex: 2, child: _buildQuickLinksCol()),
                        const SizedBox(width: 20),
                        // Col 3: Ressources
                        Expanded(flex: 2, child: _buildResourcesCol()),
                        const SizedBox(width: 20),
                        // Col 4: Contact & Socials
                        Expanded(flex: 2, child: _buildContactCol()),
                        const SizedBox(width: 20),
                        // Col 5: Newsletter
                        Expanded(flex: 3, child: _buildNewsletterCol()),
                      ],
                    )
                  : (width < 600
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBrandCol(),
                            const SizedBox(height: 32),
                            _buildQuickLinksCol(),
                            const SizedBox(height: 32),
                            _buildResourcesCol(),
                            const SizedBox(height: 32),
                            _buildContactCol(),
                            const SizedBox(height: 32),
                            _buildNewsletterCol(),
                          ],
                        )
                      : Wrap(
                          spacing: 32,
                          runSpacing: 32,
                          children: [
                            SizedBox(width: 300, child: _buildBrandCol()),
                            SizedBox(width: 140, child: _buildQuickLinksCol()),
                            SizedBox(width: 160, child: _buildResourcesCol()),
                            SizedBox(width: 180, child: _buildContactCol()),
                            SizedBox(width: 300, child: _buildNewsletterCol()),
                          ],
                        )),
              const SizedBox(height: 48),

              // Bottom divider
              Container(
                height: 1,
                width: double.infinity,
                color: Colors.white.withValues(alpha: 0.08),
              ),
              const SizedBox(height: 24),

              // Copyright Bar
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    Text(
                      '© 2026 Club des Formateurs. Tous droits réservés.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF8BA5A0),
                      ),
                    ),
                    Text(
                      "Apprendre aujourd'hui, Construire demain !",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.mintAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandCol() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Image.asset(
                'assets/images/logo.png',
                width: 38,
                height: 38,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Club des',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                Text(
                  'Formateurs',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.mintAccent,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'La plateforme d\'excellence connectant formateurs d\'élite et apprenants ambitieux à travers l\'Afrique et le monde.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: const Color(0xFF8BA5A0),
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickLinksCol() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildColTitle('Liens rapides'),
        const SizedBox(height: 12),
        _buildFooterLink('Accueil', () => onNavigate?.call('/')),
        _buildFooterLink('Formations', () => onNavigate?.call('/formations')),
        _buildFooterLink('Formateurs', () => onNavigate?.call('/formateurs')),
        _buildFooterLink('À propos', () => onNavigate?.call('/a-propos')),
        _buildFooterLink('Contact', () => onNavigate?.call('/contact')),
      ],
    );
  }

  Widget _buildResourcesCol() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildColTitle('Ressources'),
        const SizedBox(height: 12),
        _buildFooterLink('Centre d\'aide', () {}),
        _buildFooterLink('Blog', () {}),
        _buildFooterLink('Conditions d\'utilisation', () {}),
        _buildFooterLink('Politique de confidentialité', () {}),
      ],
    );
  }

  Widget _buildContactCol() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildColTitle('Contact'),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.email_outlined, color: AppTheme.mintAccent, size: 14),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'contact@club-des-formateurs.web.app',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: const Color(0xFFC7D4D4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.location_on_outlined, color: AppTheme.mintAccent, size: 14),
            const SizedBox(width: 8),
            Text(
              'Sénégal',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: const Color(0xFFC7D4D4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Social Media Icons
        Row(
          children: [
            _buildSocialIcon(Icons.facebook_rounded),
            const SizedBox(width: 8),
            _buildSocialIcon(Icons.camera_alt_rounded),
            const SizedBox(width: 8),
            _buildSocialIcon(Icons.work_rounded),
            const SizedBox(width: 8),
            _buildSocialIcon(Icons.play_arrow_rounded),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Icon(icon, color: Colors.white70, size: 14),
      ),
    );
  }

  Widget _buildNewsletterCol() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildColTitle('Restez informé'),
        const SizedBox(height: 8),
        Text(
          'Recevez nos dernières actualités et formations.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: const Color(0xFF8BA5A0),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.ink),
                  decoration: InputDecoration(
                    hintText: 'Votre email',
                    hintStyle: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textLight),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.emeraldGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildColTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }

  Widget _buildFooterLink(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: const Color(0xFF8BA5A0),
          ),
        ),
      ),
    );
  }
}
