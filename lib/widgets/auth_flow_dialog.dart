import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'app_svg_icon.dart';

enum AuthFlowStep {
  roleChoice,          // 01
  registerStudent,     // 02
  registerTeacher,     // 03
  registerCorrector,   // 03b
  login,               // 04
  forgotPassword,      // 05
  emailVerification,   // 06
  profileStep1,        // 07
  profileStep2Student, // 08
  profileStep2Teacher, // 09
  profileStep3Success, // 10
}

class AuthFlowDialog extends StatefulWidget {
  final AuthFlowStep initialStep;
  final String? initialEmail;

  const AuthFlowDialog({
    super.key,
    this.initialStep = AuthFlowStep.login,
    this.initialEmail,
  });

  static Future<void> show(
    BuildContext context, {
    AuthFlowStep initialStep = AuthFlowStep.login,
    String? initialEmail,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AuthFlowDialog(
        initialStep: initialStep,
        initialEmail: initialEmail,
      ),
    );
  }

  @override
  State<AuthFlowDialog> createState() => _AuthFlowDialogState();
}

class _AuthFlowDialogState extends State<AuthFlowDialog> {
  Uint8List? _registrationAvatarBytes;
  String? _registrationAvatarFileName;
  late AuthFlowStep _currentStep;
  final AuthService _authService = AuthService();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(text: '77 123 45 67');
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _acceptTerms = true;
  bool _rememberMe = true;
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedLoginRole = 'student';

  final Set<String> _selectedTags = {'Informatique'};

  Timer? _countdownTimer;
  int _resendCountdown = 58;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _countdownTimer?.cancel();
    setState(() => _resendCountdown = 58);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendCountdown <= 1) {
        timer.cancel();
        setState(() => _resendCountdown = 0);
      } else {
        setState(() => _resendCountdown--);
      }
    });
  }

  void _goTo(AuthFlowStep step) {
    setState(() {
      _errorMessage = null;
      _currentStep = step;
    });
    if (step == AuthFlowStep.emailVerification) {
      _startResendTimer();
    }
  }

  Future<void> _handleRegister(String role) async {
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Veuillez saisir une adresse email valide.');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Le mot de passe doit contenir au moins 6 caractères.');
      return;
    }
    if (!_acceptTerms) {
      setState(() => _errorMessage = 'Veuillez accepter les conditions d\'utilisation.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.register(
        email: email,
        password: password,
        displayName: name.isEmpty ? (role == 'teacher' ? 'Formateur' : 'Apprenant') : name,
        role: role,
        avatarBytes: _registrationAvatarBytes,
        avatarFileName: _registrationAvatarFileName,
      );
      if (mounted) {
        setState(() => _isLoading = false);
        _goTo(AuthFlowStep.profileStep1);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn({String role = 'student'}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = await _authService.signInWithGoogle(role: role);
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context);
        if (user.isSuperAdmin) {
          Navigator.pushNamed(context, '/dashboard/admin');
        } else if (user.isCorrector || role == 'corrector') {
          Navigator.pushNamed(context, '/dashboard/correcteur');
        } else if (role == 'teacher' || user.isTeacher) {
          Navigator.pushNamed(context, '/dashboard/formateur');
        } else {
          Navigator.pushNamed(context, '/dashboard/apprenant');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      setState(() => _errorMessage = 'Veuillez renseigner votre email.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = await _authService.signIn(email: email, password: password);
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context);
        if (user.isSuperAdmin) {
          Navigator.pushNamed(context, '/dashboard/admin');
        } else if (_selectedLoginRole == 'corrector' || user.isCorrector) {
          Navigator.pushNamed(context, '/dashboard/correcteur');
        } else if (_selectedLoginRole == 'teacher' || user.isTeacher) {
          Navigator.pushNamed(context, '/dashboard/formateur');
        } else {
          Navigator.pushNamed(context, '/dashboard/apprenant');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Identifiants invalides ou service indisponible.';
        });
      }
    }
  }

  Future<void> _handleFinishOnboarding() async {
    final user = _authService.currentUser;
    await _authService.updateUserProfile(
      displayName: _nameController.text.trim(),
      phoneNumber: '+221 ' + _phoneController.text.trim(),
      interests: user?.isStudent == true ? _selectedTags.toList() : null,
      expertises: user?.isTeacher == true ? _selectedTags.toList() : null,
      onboardingStep: 3,
      isEmailVerified: true,
    );

    if (mounted) {
      Navigator.pop(context);
      String route = '/dashboard/apprenant';
      if (user?.role == 'super_admin') {
        route = '/dashboard/admin';
      } else if (user?.role == 'corrector') {
        route = '/dashboard/correcteur';
      } else if (user?.role == 'teacher') {
        route = '/dashboard/formateur';
      }
      Navigator.pushReplacementNamed(context, route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 16,
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 440,
          maxHeight: 700,
        ),
        child: Container(
          color: Colors.white,
          child: Stack(
            children: [
              Positioned(
                bottom: -15,
                left: 0,
                right: 0,
                child: Center(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.08,
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 220,
                        height: 220,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ),
              SingleChildScrollView(
                child: _buildCurrentStep(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case AuthFlowStep.roleChoice:
        return _buildRoleChoiceStep();
      case AuthFlowStep.registerStudent:
        return _buildRegisterStep(role: 'student');
      case AuthFlowStep.registerTeacher:
        return _buildRegisterStep(role: 'teacher');
      case AuthFlowStep.registerCorrector:
        return _buildRegisterStep(role: 'corrector');
      case AuthFlowStep.login:
        return _buildLoginStep();
      case AuthFlowStep.forgotPassword:
        return _buildForgotPasswordStep();
      case AuthFlowStep.emailVerification:
        return _buildEmailVerificationStep();
      case AuthFlowStep.profileStep1:
        return _buildProfileStep1();
      case AuthFlowStep.profileStep2Student:
        return _buildProfileStep2(isStudent: true);
      case AuthFlowStep.profileStep2Teacher:
        return _buildProfileStep2(isStudent: false);
      case AuthFlowStep.profileStep3Success:
        return _buildProfileStep3Success();
    }
  }

  Widget _buildRoleChoiceStep() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D322B), Color(0xFF082520)],
        ),
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBrandLogo(isLight: true),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Rejoignez notre\ncommunauté',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Que souhaitez-vous faire sur la plateforme ?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFFD3EBE5),
            ),
          ),
          const SizedBox(height: 24),

          _buildRoleOptionCard(
            title: 'Je suis apprenant',
            subtitle: 'J\'accède à des formations et je développe mes compétences.',
            icon: Icons.school_rounded,
            iconColor: AppTheme.emeraldGreenDark,
            iconBg: AppTheme.paleMint,
            onTap: () => _goTo(AuthFlowStep.registerStudent),
          ),
          const SizedBox(height: 14),

          _buildRoleOptionCard(
            title: 'Je suis formateur',
            subtitle: 'Je partage mes connaissances et j\'impacte des apprenants.',
            icon: Icons.people_alt_rounded,
            iconColor: const Color(0xFFD97706),
            iconBg: const Color(0xFFFEF3C7),
            onTap: () => _goTo(AuthFlowStep.registerTeacher),
          ),
          const SizedBox(height: 14),

          _buildRoleOptionCard(
            title: 'Je suis correcteur',
            subtitle: 'J\'évalue les devoirs, corrige les copies et accompagne les apprenants.',
            icon: Icons.fact_check_rounded,
            iconColor: const Color(0xFF6366F1),
            iconBg: const Color(0xFFEEF2FF),
            onTap: () => _goTo(AuthFlowStep.registerCorrector),
          ),
          const SizedBox(height: 28),

          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              alignment: Alignment.bottomLeft,
              children: [
                Image.asset(
                  'assets/images/student-woman.jpeg',
                  height: 130,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 130,
                    color: AppTheme.emeraldGreenDark,
                  ),
                ),
                Container(
                  height: 130,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Des compétences\npour un meilleur avenir !',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.mintAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          Center(
            child: TextButton(
              onPressed: () => _goTo(AuthFlowStep.login),
              child: Text(
                'Vous avez déjà un compte ? Se connecter',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.mintAccent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
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
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppTheme.paleMint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: AppTheme.emeraldGreenDark,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterStep({required String role}) {
    final isTeacher = role == 'teacher';
    final isCorrector = role == 'corrector';
    return Padding(
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.ink, size: 20),
                    tooltip: 'Retour',
                    onPressed: () => _goTo(AuthFlowStep.roleChoice),
                  ),
                  const SizedBox(width: 4),
                  _buildBrandLogo(isLight: false),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            isTeacher
                ? 'Créer un compte formateur'
                : (isCorrector ? 'Créer un compte correcteur' : 'Créer un compte apprenant'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isTeacher
                ? 'Partagez votre expertise et formez la prochaine génération de talents.'
                : (isCorrector
                    ? 'Évaluez les devoirs, corrigez les copies et accompagnez les apprenants vers l\'excellence.'
                    : 'Rejoignez des milliers d\'apprenants et accédez à des formations de qualité.'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppTheme.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),

          _buildSocialLogins(role: role),
          const SizedBox(height: 14),

          _buildDividerText('ou s\'inscrire avec votre email'),
          const SizedBox(height: 14),

          if (_errorMessage != null) _buildErrorMessage(),

          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppTheme.paleMint,
                  backgroundImage: _registrationAvatarBytes != null ? MemoryImage(_registrationAvatarBytes!) : null,
                  child: _registrationAvatarBytes == null
                      ? const Icon(Icons.person, size: 36, color: AppTheme.emeraldGreenDark)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: () async {
                      final res = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
                      if (res != null && res.files.single.bytes != null) {
                        setState(() {
                          _registrationAvatarBytes = res.files.single.bytes;
                          _registrationAvatarFileName = res.files.single.name;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppTheme.emeraldGreenDark,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Photo de profil (optionnelle)',
              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted),
            ),
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _nameController,
            label: 'Nom complet',
            prefixIcon: Icons.person_outline_rounded,
            hint: 'Ex: Amsatou Ndiaye',
          ),
          const SizedBox(height: 12),

          _buildTextField(
            controller: _emailController,
            label: 'Adresse email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            hint: 'exemple@gmail.com',
          ),
          const SizedBox(height: 12),

          _buildTextField(
            controller: _passwordController,
            label: 'Mot de passe',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 18,
                color: AppTheme.textMuted,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: _acceptTerms,
                  activeColor: AppTheme.emeraldGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  onChanged: (val) => setState(() => _acceptTerms = val ?? true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'J\'accepte les conditions d\'utilisation et la politique de confidentialité',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _handleRegister(role),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emeraldGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      isTeacher
                          ? 'Créer mon compte Formateur 👨‍🏫'
                          : (isCorrector ? 'Créer mon compte Correcteur 📝' : 'Créer mon compte Apprenant 🎓'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 14),

          Center(
            child: TextButton(
              onPressed: () => _goTo(AuthFlowStep.login),
              child: Text(
                'Vous avez déjà un compte ? Se connecter',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.emeraldGreenDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginStep() {
    return Padding(
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.ink, size: 20),
                    tooltip: 'Retour',
                    onPressed: () => _goTo(AuthFlowStep.roleChoice),
                  ),
                  const SizedBox(width: 4),
                  _buildBrandLogo(isLight: false),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _selectedLoginRole == 'teacher'
                ? 'Espace Formateur'
                : (_selectedLoginRole == 'corrector'
                    ? 'Espace Correcteur'
                    : 'Espace Apprenant'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _selectedLoginRole == 'teacher'
                ? 'Connectez-vous à votre studio pour dispenser vos cours et gérer vos élèves.'
                : (_selectedLoginRole == 'corrector'
                    ? 'Connectez-vous pour évaluer les devoirs et accompagner vos promotions.'
                    : 'Connectez-vous à votre compte pour continuer votre apprentissage.'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 16),

          // Sélecteur dynamique d'espace (Apprenant, Formateur, Correcteur)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.paleMint.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.emeraldGreen.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedLoginRole = 'student'),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _selectedLoginRole == 'student' ? AppTheme.emeraldGreenDark : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.school_rounded,
                            size: 15,
                            color: _selectedLoginRole == 'student' ? Colors.white : AppTheme.emeraldGreenDark,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Apprenant',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _selectedLoginRole == 'student' ? Colors.white : AppTheme.emeraldGreenDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedLoginRole = 'teacher'),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _selectedLoginRole == 'teacher' ? AppTheme.emeraldGreenDark : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_pin_rounded,
                            size: 15,
                            color: _selectedLoginRole == 'teacher' ? Colors.white : AppTheme.emeraldGreenDark,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Formateur',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _selectedLoginRole == 'teacher' ? Colors.white : AppTheme.emeraldGreenDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedLoginRole = 'corrector'),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _selectedLoginRole == 'corrector' ? AppTheme.emeraldGreenDark : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.fact_check_rounded,
                            size: 15,
                            color: _selectedLoginRole == 'corrector' ? Colors.white : AppTheme.emeraldGreenDark,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Correcteur',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _selectedLoginRole == 'corrector' ? Colors.white : AppTheme.emeraldGreenDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          _buildSocialLogins(role: _selectedLoginRole),
          const SizedBox(height: 16),

          _buildDividerText('ou se connecter avec votre email'),
          const SizedBox(height: 16),

          if (_errorMessage != null) _buildErrorMessage(),

          _buildTextField(
            controller: _emailController,
            label: 'Adresse email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            hint: 'Ex: moussa.ndiaye@gmail.com',
          ),
          const SizedBox(height: 12),

          _buildTextField(
            controller: _passwordController,
            label: 'Mot de passe',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 18,
                color: AppTheme.textMuted,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Checkbox(
                      value: _rememberMe,
                      activeColor: AppTheme.emeraldGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      onChanged: (val) => setState(() => _rememberMe = val ?? true),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Se souvenir de moi',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => _goTo(AuthFlowStep.forgotPassword),
                child: Text(
                  'Mot de passe oublié ?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.emeraldGreenDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emeraldGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _selectedLoginRole == 'teacher'
                          ? 'Se connecter comme Formateur'
                          : (_selectedLoginRole == 'corrector'
                              ? 'Se connecter comme Correcteur'
                              : 'Se connecter comme Apprenant'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 14),

          Center(
            child: TextButton(
              onPressed: () => _goTo(AuthFlowStep.roleChoice),
              child: Text(
                'Vous n\'avez pas encore de compte ? S\'inscrire',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.emeraldGreenDark,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.fact_check_rounded, size: 15, color: Color(0xFF6366F1)),
                  label: Text(
                    'Connexion Espace Correcteur',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6366F1),
                    ),
                  ),
                  onPressed: () {
                    _emailController.text = 'correcteur@clubdesformateurs.com';
                    _passwordController.text = 'correcteur123';
                    setState(() => _selectedLoginRole = 'corrector');
                    _handleLogin();
                  },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.admin_panel_settings_rounded, size: 15, color: Color(0xFFEF4444)),
                  label: Text(
                    'Connexion Administrateur',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                  onPressed: () {
                    _emailController.text = 'admin@clubdesformateurs.com';
                    _passwordController.text = 'admin123';
                    _handleLogin();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForgotPasswordStep() {
    return Padding(
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.ink, size: 20),
                    tooltip: 'Retour',
                    onPressed: () => _goTo(AuthFlowStep.login),
                  ),
                  const SizedBox(width: 4),
                  _buildBrandLogo(isLight: false),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Réinitialiser votre mot\nde passe',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Entrez votre adresse email et nous vous enverrons un lien pour réinitialiser votre mot de passe.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppTheme.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          _buildTextField(
            controller: _emailController,
            label: 'Adresse email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _authService.sendPasswordReset(_emailController.text);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lien de réinitialisation envoyé !'),
                    backgroundColor: AppTheme.emeraldGreen,
                  ),
                );
                _goTo(AuthFlowStep.login);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emeraldGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Envoyer le lien',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Center(
            child: TextButton(
              onPressed: () => _goTo(AuthFlowStep.login),
              child: Text(
                'Retour à la connexion',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.emeraldGreenDark,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.paleMint.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.emeraldGreen.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.mark_email_read_rounded, color: AppTheme.emeraldGreenDark, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Accédez de nouveau à votre compte en toute sécurité.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.emeraldGreenDark,
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

  Widget _buildEmailVerificationStep() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.paleMint,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.emeraldGreen.withValues(alpha: 0.3), width: 2),
            ),
            child: const Center(
              child: Icon(Icons.mark_email_read_rounded, size: 40, color: AppTheme.emeraldGreenDark),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Vérifiez votre email',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Nous avons envoyé un lien de vérification à votre adresse email. Cliquez sur le lien pour activer votre compte.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 26),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _goTo(AuthFlowStep.profileStep1),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.emeraldGreenDark,
                side: const BorderSide(color: AppTheme.emeraldGreen, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Ouvrir ma boîte email',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          TextButton(
            onPressed: _resendCountdown == 0 ? _startResendTimer : null,
            child: Text(
              _resendCountdown > 0
                  ? 'Renvoyer l\'email (' + _resendCountdown.toString() + 's)'
                  : 'Renvoyer l\'email maintenant',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _resendCountdown > 0 ? AppTheme.textMuted : AppTheme.emeraldGreenDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStep1() {
    return Padding(
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildProgressHeader(step: 1, total: 3),
          const SizedBox(height: 20),
          Text(
            'Informations personnelles',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ces informations nous permettent de mieux vous connaître.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 20),

          _buildTextField(
            controller: _nameController,
            label: 'Nom complet',
            prefixIcon: Icons.person_outline_rounded,
            hint: 'Amsatou Ndiaye',
          ),
          const SizedBox(height: 14),

          _buildTextField(
            controller: _emailController,
            label: 'Adresse email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            hint: 'amsatou@gmail.com',
          ),
          const SizedBox(height: 14),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Téléphone',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: const BoxDecoration(
                        border: Border(right: BorderSide(color: AppTheme.cardBorder)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🇸🇳', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            '+221',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 14),
                          hintText: '77 123 45 67',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final user = _authService.currentUser;
                final isTeacher = user?.isTeacher == true;
                _goTo(isTeacher ? AuthFlowStep.profileStep2Teacher : AuthFlowStep.profileStep2Student);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emeraldGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Continuer',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStep2({required bool isStudent}) {
    final availableTags = [
      'Informatique',
      'Marketing',
      'Business',
      'Design',
      'Développement personnel',
      'Langues',
      'Photographie',
      'Autres',
    ];

    return Padding(
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildProgressHeader(step: 2, total: 3),
          const SizedBox(height: 20),
          Text(
            isStudent ? 'Vos centres d\'intérêt' : 'Votre expertise',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isStudent
                ? 'Sélectionnez les domaines qui vous intéressent.'
                : 'Sélectionnez vos domaines d\'expertise.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 20),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: availableTags.map((tag) {
              final isSelected = _selectedTags.contains(tag);
              return ChoiceChip(
                label: Text(tag),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTags.add(tag);
                    } else {
                      _selectedTags.remove(tag);
                    }
                  });
                },
                selectedColor: AppTheme.emeraldGreen,
                backgroundColor: const Color(0xFFF1F5F9),
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppTheme.ink,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSelected ? AppTheme.emeraldGreen : Colors.transparent,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _goTo(AuthFlowStep.profileStep1),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.ink,
                    side: const BorderSide(color: AppTheme.cardBorder),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Retour',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _goTo(AuthFlowStep.profileStep3Success),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emeraldGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Continuer',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStep3Success() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildProgressHeader(step: 3, total: 3),
          const SizedBox(height: 36),

          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppTheme.paleMint,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.emeraldGreen.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Center(
              child: Text('🎉', style: TextStyle(fontSize: 38)),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'C\'est presque terminé !',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Votre compte est prêt. Vous pouvez maintenant explorer la plateforme.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleFinishOnboarding,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emeraldGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Accéder à mon tableau de bord',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader({required int step, required int total}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Complétons votre profil',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
              ),
            ),
            Text(
              'Étape ' + step.toString() + ' sur ' + total.toString(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.emeraldGreenDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: step / total,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.emeraldGreen),
            minHeight: 5,
          ),
        ),
      ],
    );
  }

  Widget _buildBrandLogo({required bool isLight}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/images/logo.png',
            width: 34,
            height: 34,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Club des',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isLight ? Colors.white : AppTheme.ink,
                height: 1.1,
              ),
            ),
            Text(
              'Formateurs',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isLight ? AppTheme.mintAccent : AppTheme.emeraldGreen,
                height: 1.1,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialLogins({String role = 'student'}) {
    return _buildSocialButton(
      title: 'Continuer avec Google',
      iconWidget: const GoogleOfficialLogo(size: 19),
      onTap: () => _handleGoogleSignIn(role: role),
    );
  }

  Widget _buildSocialButton({
    required String title,
    required Widget iconWidget,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.ink,
          side: const BorderSide(color: AppTheme.cardBorder, width: 1.2),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDividerText(String label) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: AppTheme.cardBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppTheme.textMuted,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: AppTheme.cardBorder)),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF991B1B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          decoration: InputDecoration(
            prefixIcon: Icon(prefixIcon, size: 18, color: AppTheme.textMuted),
            suffixIcon: suffixIcon,
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted.withValues(alpha: 0.7)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}
