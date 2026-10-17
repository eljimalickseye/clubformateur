import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/language_service.dart';
import '../theme/app_theme.dart';
import '../widgets/footer_section.dart';
import '../widgets/navbar.dart';
import '../widgets/studio_svg_icon.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String _selectedSubject = 'Information générale';
  bool _isSubmitting = false;
  bool _submittedSuccess = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitMessage() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      await FirebaseFirestore.instance.collection('contact_messages').add({
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'subject': _selectedSubject,
        'message': _messageCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'unread',
      });

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _submittedSuccess = true;
        });
        _nameCtrl.clear();
        _emailCtrl.clear();
        _messageCtrl.clear();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'envoi : $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;
    final isMobile = width < 600;
    final lang = LanguageService();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Navbar
            const Navbar(activeRoute: '/contact'),

            // Hero Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: isMobile ? 40 : 64,
                horizontal: isMobile ? 20 : 48,
              ),
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
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.mintAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: AppTheme.mintAccent.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          lang.t(fr: 'ASSISTANCE & CONTACT', en: 'SUPPORT & CONTACT'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.mintAccent,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        lang.t(
                          fr: 'Comment pouvons-nous vous aider ?',
                          en: 'How can we help you today?',
                        ),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: isMobile ? 28 : (isDesktop ? 40 : 34),
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        lang.t(
                          fr: 'Notre équipe pédagogique et technique est à votre écoute pour vous orienter et répondre à vos questions.',
                          en: 'Our educational and technical support team is ready to guide you and answer all your inquiries.',
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFFD9ECE7), fontSize: 15, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Content Section
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: isMobile ? 36 : 60,
                horizontal: isMobile ? 16 : 40,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1160),
                  child: isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 4, child: _buildContactInfo(lang)),
                            const SizedBox(width: 40),
                            Expanded(flex: 5, child: _buildContactForm(lang, isMobile)),
                          ],
                        )
                      : Column(
                          children: [
                            _buildContactInfo(lang),
                            const SizedBox(height: 32),
                            _buildContactForm(lang, isMobile),
                          ],
                        ),
                ),
              ),
            ),

            // Footer
            FooterSection(
              onNavigate: (route) => Navigator.pushNamed(context, route),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo(LanguageService lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang.t(fr: 'Nos Coordonnées Directes', en: 'Direct Contact Details'),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          lang.t(
            fr: 'N\'hésitez pas à nous joindre par email ou téléphone. Nous répondons en moins de 24h ouvrées.',
            en: 'Reach out to us via email or phone. We reply within 24 working hours.',
          ),
          style: const TextStyle(fontSize: 14, color: AppTheme.textMuted, height: 1.5),
        ),
        const SizedBox(height: 28),

        _buildContactCard(
          icon: 'message',
          title: lang.t(fr: 'Email de support', en: 'Support Email'),
          detail: 'contact@club-des-formateurs.web.app',
          subtext: lang.t(fr: 'Réponse sous 24h', en: 'Reply within 24 hours'),
        ),
        const SizedBox(height: 16),
        _buildContactCard(
          icon: 'user',
          title: lang.t(fr: 'Téléphone & WhatsApp', en: 'Phone & WhatsApp'),
          detail: '+221 78 456 78 90 / +221 33 800 00 00',
          subtext: lang.t(fr: 'Lun - Sam : 8h00 - 20h00 GMT', en: 'Mon - Sat: 8:00 AM - 8:00 PM GMT'),
        ),
        const SizedBox(height: 16),
        _buildContactCard(
          icon: 'home',
          title: lang.t(fr: 'Siège & Couverture', en: 'Headquarters & Region'),
          detail: 'Dakar, Sénégal (Service Panafricain & International)',
          subtext: lang.t(fr: 'Disponible dans toute l\'Afrique de l\'Ouest et la diaspora', en: 'Available across West Africa and worldwide diaspora'),
        ),
      ],
    );
  }

  Widget _buildContactCard({
    required String icon,
    required String title,
    required String detail,
    required String subtext,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.paleMint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: StudioSvgIcon(
              iconKey: icon,
              size: 20,
              color: AppTheme.emeraldGreenDark,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  detail,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtext,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactForm(LanguageService lang, bool isMobile) {
    if (_submittedSuccess) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF86EFAC)),
        ),
        child: Column(
          children: [
            const Icon(Icons.check_circle_rounded, size: 54, color: AppTheme.emeraldGreenDark),
            const SizedBox(height: 16),
            Text(
              lang.t(fr: 'Message envoyé avec succès !', en: 'Message sent successfully!'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.emeraldGreenDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              lang.t(
                fr: 'Merci de nous avoir contactés. Notre équipe vous répondra dans les plus brefs délais.',
                en: 'Thank you for reaching out. Our team will get back to you shortly.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF166534), height: 1.5),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emeraldGreenDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => setState(() => _submittedSuccess = false),
              child: Text(lang.t(fr: 'Envoyer un autre message', en: 'Send another message')),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 22 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang.t(fr: 'Formulaire de contact', en: 'Contact Form'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              lang.t(fr: 'Remplissez les champs ci-dessous pour nous envoyer votre message.', en: 'Fill out the fields below to send us your inquiry.'),
              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 22),

            // Nom complet
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: lang.t(fr: 'Votre nom complet *', en: 'Your Full Name *'),
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(12),
                  child: StudioSvgIcon(iconKey: 'user', size: 18, color: AppTheme.textMuted),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? lang.t(fr: 'Veuillez saisir votre nom', en: 'Please enter your name')
                  : null,
            ),
            const SizedBox(height: 16),

            // Email
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: lang.t(fr: 'Votre adresse email *', en: 'Your Email Address *'),
                prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.textMuted, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => v == null || !v.contains('@')
                  ? lang.t(fr: 'Veuillez saisir une adresse email valide', en: 'Please enter a valid email address')
                  : null,
            ),
            const SizedBox(height: 16),

            // Objet
            DropdownButtonFormField<String>(
              initialValue: _selectedSubject,
              decoration: InputDecoration(
                labelText: lang.t(fr: 'Objet de votre demande', en: 'Subject'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: [
                'Information générale',
                'Question sur une formation',
                'Devenir formateur / Recrutement',
                'Problème technique / Connexion',
                'Partenariat & Entreprise',
              ].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedSubject = val);
              },
            ),
            const SizedBox(height: 16),

            // Message
            TextFormField(
              controller: _messageCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: lang.t(fr: 'Votre message *', en: 'Your Message *'),
                hintText: lang.t(fr: 'Expliquez-nous votre demande en détail...', en: 'Describe your request in detail...'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => v == null || v.trim().length < 5
                  ? lang.t(fr: 'Veuillez écrire un message (min. 5 caractères)', en: 'Please write a message (at least 5 chars)')
                  : null,
            ),
            const SizedBox(height: 24),

            // Bouton Envoyer
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const StudioSvgIcon(iconKey: 'send', size: 16, color: Colors.white),
                label: Text(
                  _isSubmitting
                      ? lang.t(fr: 'Envoi en cours...', en: 'Sending...')
                      : lang.t(fr: 'Envoyer mon message', en: 'Send My Message'),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emeraldGreenDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _isSubmitting ? null : _submitMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
