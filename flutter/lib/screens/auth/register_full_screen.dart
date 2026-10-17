import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_svg_icon.dart';

class RegisterFullScreen extends StatefulWidget {
  final String initialRole; // 'student' or 'teacher'

  const RegisterFullScreen({
    super.key,
    this.initialRole = 'student',
  });

  @override
  State<RegisterFullScreen> createState() => _RegisterFullScreenState();
}

class _RegisterFullScreenState extends State<RegisterFullScreen> {
  final AuthService _authService = AuthService();

  late String _selectedRole; // 'student' or 'teacher'

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _acceptTerms = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authService.signInWithGoogle(role: _selectedRole);
      if (mounted) {
        _navigateUser(user);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleEmailRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      setState(() => _errorMessage = 'Veuillez accepter les conditions d\'utilisation.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authService.register(
        displayName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phoneNumber: _phoneController.text.trim(),
        role: _selectedRole,
      );

      if (mounted) {
        _navigateUser(user);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _navigateUser(UserModel user) {
    if (user.isTeacher) {
      Navigator.pushNamedAndRemoveUntil(context, '/dashboard/formateur', (r) => false);
    } else if (user.isCorrector) {
      Navigator.pushNamedAndRemoveUntil(context, '/dashboard/correcteur', (r) => false);
    } else if (user.isSuperAdmin) {
      Navigator.pushNamedAndRemoveUntil(context, '/dashboard/admin', (r) => false);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/dashboard/apprenant', (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFF062C32),
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF0D434C))),
              ),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushReplacementNamed(context, '/');
                      }
                    },
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Retour'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF165A65)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacementNamed(context, '/'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Club des ',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Formateurs',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.mintAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                    child: Text(
                      isDesktop ? 'Déjà un compte ? Se connecter' : 'Connexion',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.mintAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main Content Area
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 580),
                    child: Container(
                      padding: EdgeInsets.all(isDesktop ? 36 : 22),
                      decoration: BoxDecoration(
                        color: const Color(0xFF09373E),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFF134C56), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            bottom: -20,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: IgnorePointer(
                                child: Opacity(
                                  opacity: 0.08,
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    width: 260,
                                    height: 260,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                            // Headline
                            Text(
                              'Créer un compte',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: isDesktop ? 28 : 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Rejoignez la communauté de formation et développez votre potentiel.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: const Color(0xFFB8D3D8),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),

                            // Role Selector Card
                            Text(
                              'JE SOUHAITE REJOINDRE EN TANT QUE :',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.mintAccent,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 10),

                            Row(
                              children: [
                                Expanded(
                                  child: _buildRoleCard(
                                    role: 'student',
                                    title: 'Apprenant',
                                    subtitle: 'Suivre des cours & devoirs',
                                    icon: Icons.school_rounded,
                                    isSelected: _selectedRole == 'student',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildRoleCard(
                                    role: 'teacher',
                                    title: 'Formateur',
                                    subtitle: 'Enseigner & créer des classes',
                                    icon: Icons.cast_for_education_rounded,
                                    isSelected: _selectedRole == 'teacher',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildRoleCard(
                                    role: 'corrector',
                                    title: 'Correcteur',
                                    subtitle: 'Évaluer & corriger les copies',
                                    icon: Icons.fact_check_rounded,
                                    isSelected: _selectedRole == 'corrector',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Google Sign-In Button
                            ElevatedButton.icon(
                              icon: const GoogleOfficialLogo(size: 20),
                              label: Text(
                                _selectedRole == 'teacher'
                                    ? 'S\'inscrire comme Formateur avec Google'
                                    : (_selectedRole == 'corrector'
                                        ? 'S\'inscrire comme Correcteur avec Google'
                                        : 'S\'inscrire comme Apprenant avec Google'),
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: const Color(0xFF062C32),
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              onPressed: _isLoading ? null : _handleGoogleSignIn,
                            ),
                            const SizedBox(height: 20),

                            // Divider
                            Row(
                              children: [
                                const Expanded(child: Divider(color: Color(0xFF144D57))),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  child: Text(
                                    'ou par e-mail',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: const Color(0xFF88AFB5),
                                    ),
                                  ),
                                ),
                                const Expanded(child: Divider(color: Color(0xFF144D57))),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Error Message
                            if (_errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade900.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Full Name Input
                            _buildInputLabel('Nom et prénom'),
                            TextFormField(
                              controller: _nameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: _buildInputDecoration(
                                hint: 'Ex: Awa Ndiaye',
                                icon: Icons.person_outline_rounded,
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Veuillez saisir votre nom.' : null,
                            ),
                            const SizedBox(height: 16),

                            // Email Input
                            _buildInputLabel('Adresse email'),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Colors.white),
                              decoration: _buildInputDecoration(
                                hint: 'exemple@gmail.com',
                                icon: Icons.mail_outline_rounded,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Veuillez renseigner votre email.';
                                if (!v.contains('@') || !v.contains('.')) return 'Adresse email invalide.';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Phone Input
                            _buildInputLabel('Numéro de téléphone'),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(color: Colors.white),
                              decoration: _buildInputDecoration(
                                hint: '77 123 45 67',
                                icon: Icons.phone_outlined,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Password Input
                            _buildInputLabel('Mot de passe'),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(color: Colors.white),
                              decoration: _buildInputDecoration(
                                hint: '••••••••',
                                icon: Icons.lock_outline_rounded,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                    color: const Color(0xFF88AFB5),
                                    size: 18,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (v) => (v == null || v.length < 8) ? 'Le mot de passe doit comporter au moins 8 caractères.' : null,
                            ),
                            const SizedBox(height: 16),

                            // Terms & Conditions Checkbox
                            Row(
                              children: [
                                Checkbox(
                                  value: _acceptTerms,
                                  activeColor: AppTheme.mintAccent,
                                  checkColor: const Color(0xFF062C32),
                                  onChanged: (v) => setState(() => _acceptTerms = v ?? true),
                                ),
                                Expanded(
                                  child: Text(
                                    'J\'accepte les conditions d\'utilisation et la politique de confidentialité.',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: const Color(0xFFB8D3D8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Primary Register Action Button (Glowing & Highly visible)
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF13C7A3).withValues(alpha: 0.4),
                                    blurRadius: 18,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF13C7A3),
                                  foregroundColor: const Color(0xFF062C32),
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                                onPressed: _isLoading ? null : _handleEmailRegister,
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(color: Color(0xFF062C32), strokeWidth: 2.5),
                                      )
                                    : Text(
                                        _selectedRole == 'teacher'
                                            ? 'Créer mon compte Formateur 👨‍🏫'
                                            : (_selectedRole == 'corrector'
                                                ? 'Créer mon compte Correcteur 📝'
                                                : 'Créer mon compte Apprenant 🎓'),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String role,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => setState(() => _selectedRole = role),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F4E58) : const Color(0xFF082C32),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.mintAccent : const Color(0xFF165A65),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.mintAccent : const Color(0xFF88AFB5),
              size: 26,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: isSelected ? Colors.white : const Color(0xFF88AFB5),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.white70 : Colors.white38,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFD6EAEF),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF6B9298), fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFF88AFB5), size: 18),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFF072B31),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF144D57)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF144D57)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.mintAccent, width: 1.5),
      ),
    );
  }
}
