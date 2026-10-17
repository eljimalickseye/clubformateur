import '../../widgets/pwa_install_modal.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_svg_icon.dart';
import '../../widgets/custom_widgets.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onNavigateToRegister;
  final VoidCallback onNavigateToPartnerRegister;
  final VoidCallback onLoginSuccess;

  const LoginScreen({
    super.key,
    required this.onNavigateToRegister,
    required this.onNavigateToPartnerRegister,
    required this.onLoginSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),
                    const OliviaLogo(size: 68, showSubtitle: true),
                    const SizedBox(height: 20),

                    Text(
                      'Connexion Sécurisée',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Accédez à votre espace Formateur ou Apprenant.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 22),

                    TextFormField(
                      controller: _emailPhoneController,
                      decoration: const InputDecoration(
                        labelText: 'Email ou Téléphone (+221)',
                        hintText: 'ex: serigne.fall@olivia.sn ou 77 845 12 34',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Veuillez saisir votre identifiant' : null,
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Veuillez saisir votre mot de passe' : null,
                    ),
                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        child: _isLoading
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : Text(
                                'Se connecter',
                                style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'OU CHOISISSEZ UN COMPTE DE DÉMO',
                            style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF94A3B8)),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 1. Compte Assuré
                    _demoAccountCard(
                      title: 'Compte Assuré (Serigne A. Fall)',
                      badge: '🇸🇳 DK-5489-BG • Toyota Corolla (7 CV)',
                      email: 'serigne.fall@olivia.sn',
                      password: 'pass1234',
                      color: const Color(0xFF4F46E5),
                      bgColor: const Color(0xFFEEF2FF),
                      icon: AppSvgIcon.car,
                      onTap: () {
                        _emailPhoneController.text = 'serigne.fall@olivia.sn';
                        _passwordController.text = 'pass1234';
                        _handleLogin();
                      },
                    ),
                    const SizedBox(height: 10),

                    // 2. Compte Courtier
                    _demoAccountCard(
                      title: 'Compte Courtier (Cabinet Dakar)',
                      badge: '🏢 Agréé CIMA • COURTIER-DAKAR-77',
                      email: 'courtier@assurcourtage.sn',
                      password: 'courtier123',
                      color: const Color(0xFF9333EA),
                      bgColor: const Color(0xFFF3E8FF),
                      icon: AppSvgIcon.usersBeneficiaries,
                      onTap: () {
                        _emailPhoneController.text = 'courtier@assurcourtage.sn';
                        _passwordController.text = 'courtier123';
                        _handleLogin();
                      },
                    ),
                    const SizedBox(height: 22),

                    // Bouton PWA
                    InkWell(
                      onTap: () => PwaInstallModal.show(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.install_mobile_rounded, color: AppTheme.primaryPurple, size: 18),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Installer l\'application (PWA)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textDark,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Nouveau sur OLIVIA ? ',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppTheme.textMuted),
                        ),
                        InkWell(
                          onTap: widget.onNavigateToRegister,
                          child: Text(
                            'Créer un compte assuré',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryPurple,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _demoAccountCard({
    required String title,
    required String badge,
    required String email,
    required String password,
    required Color color,
    required Color bgColor,
    required String icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
              child: Center(
                child: AppSvgIcon(
                  assetName: icon,
                  color: color,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    badge,
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$email • mot de passe : $password',
                    style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: const Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  void _handleLogin() async {
    if (_emailPhoneController.text.trim().isEmpty) {
      _emailPhoneController.text = 'serigne.fall@olivia.sn';
      _passwordController.text = 'pass1234';
    }

    setState(() => _isLoading = true);
    try {
      final appState = context.read<AppState>();
      await appState.loginUser(
        emailOrPhone: _emailPhoneController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) {
        setState(() => _isLoading = false);
        widget.onLoginSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('Erreur de connexion : $e')),
        );
      }
    }
  }
}
