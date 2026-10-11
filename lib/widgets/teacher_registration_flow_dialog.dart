import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/teacher_registration_model.dart';
import '../models/trainer_model.dart';
import '../services/auth_service.dart';
import '../services/teacher_registration_service.dart';
import '../theme/app_theme.dart';
import 'student_registration_card_dialog.dart';

enum RegistrationStep {
  form,       // Step 1: Formulaire d'inscription
  payment,    // Step 2: Récapitulatif & Paiement
  confirmed,  // Step 3: Confirmation & Fiche d'inscription
}

class TeacherRegistrationFlowDialog extends StatefulWidget {
  final TrainerModel teacher;

  const TeacherRegistrationFlowDialog({
    super.key,
    required this.teacher,
  });

  static Future<void> show(
    BuildContext context, {
    required TrainerModel teacher,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => TeacherRegistrationFlowDialog(teacher: teacher),
    );
  }

  @override
  State<TeacherRegistrationFlowDialog> createState() => _TeacherRegistrationFlowDialogState();
}

class _TeacherRegistrationFlowDialogState extends State<TeacherRegistrationFlowDialog> {
  RegistrationStep _currentStep = RegistrationStep.form;

  final _formKey = GlobalKey<FormState>();

  // Personal Info Controllers
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _birthPlaceController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  // Academic Info Controllers
  late String _selectedLevel;
  final _fieldOfStudyController = TextEditingController();
  final String _academicYear = '2026-2027';

  // Payment Selection
  String _selectedPaymentMethod = 'Wave';
  final _paymentPhoneController = TextEditingController();
  bool _isProcessingPayment = false;

  TeacherStudentRegistrationModel? _completedRegistration;

  @override
  void initState() {
    super.initState();
    // Default level set to Licence 3
    final availableLevels = widget.teacher.levels.isNotEmpty ? widget.teacher.levels : ['Licence 3', 'Licence 1', 'Licence 2', 'Master'];
    _selectedLevel = availableLevels.contains('Licence 3') ? 'Licence 3' : availableLevels.first;
    _fieldOfStudyController.text = widget.teacher.subject;

    // Pre-fill user if logged in
    final currentUser = AuthService().currentUser;
    if (currentUser != null) {
      final names = currentUser.displayName.trim().split(' ');
      if (names.isNotEmpty) {
        _firstNameController.text = names.first;
        if (names.length > 1) {
          _lastNameController.text = names.sublist(1).join(' ');
        }
      }
      _emailController.text = currentUser.email;
      if (currentUser.phoneNumber != null && currentUser.phoneNumber!.isNotEmpty) {
        _phoneController.text = currentUser.phoneNumber!;
        _paymentPhoneController.text = currentUser.phoneNumber!;
      }
    }
  }

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _birthDateController.dispose();
    _birthPlaceController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _fieldOfStudyController.dispose();
    _paymentPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20, 1, 1),
      firstDate: DateTime(1960),
      lastDate: DateTime(now.year - 14),
      locale: const Locale('fr', 'FR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.emeraldGreenDark,
              onPrimary: Colors.white,
              onSurface: AppTheme.ink,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _birthDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _proceedToPayment() {
    if (!_formKey.currentState!.validate()) return;
    if (_paymentPhoneController.text.trim().isEmpty) {
      _paymentPhoneController.text = _phoneController.text.trim();
    }
    setState(() {
      _currentStep = RegistrationStep.payment;
    });
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessingPayment = true);

    try {
      // Small realistic processing delay
      await Future.delayed(const Duration(milliseconds: 1400));

      final currentUser = AuthService().currentUser;
      final studentId = currentUser?.uid ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';

      final reg = await TeacherRegistrationService().registerStudent(
        teacher: widget.teacher,
        studentId: studentId,
        studentLastName: _lastNameController.text.trim(),
        studentFirstName: _firstNameController.text.trim(),
        birthDate: _birthDateController.text.trim(),
        birthPlace: _birthPlaceController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        studyLevel: _selectedLevel,
        fieldOfStudy: _fieldOfStudyController.text.trim().isNotEmpty
            ? _fieldOfStudyController.text.trim()
            : widget.teacher.subject,
        academicYear: _academicYear,
        proposedSchedule: widget.teacher.schedule,
        fee: widget.teacher.registrationFee,
        paymentMethod: _selectedPaymentMethod,
      );

      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
          _completedRegistration = reg;
          _currentStep = RegistrationStep.confirmed;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du paiement : $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: isMobile ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: isMobile
          ? Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.white,
              child: SafeArea(
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        child: _buildStepContent(),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600, maxHeight: 760),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 36,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeader(),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                            child: _buildStepContent(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF062C32),
        border: Border(bottom: BorderSide(color: Color(0xFF0D434C))),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.paleMint,
            backgroundImage: widget.teacher.image.startsWith('http')
                ? NetworkImage(widget.teacher.image)
                : (widget.teacher.image.isNotEmpty && !widget.teacher.image.contains('dummy')
                    ? AssetImage(widget.teacher.image)
                    : null) as ImageProvider<Object>?,
            child: (widget.teacher.image.isEmpty || (!widget.teacher.image.startsWith('http') && widget.teacher.image.contains('dummy')))
                ? Text(
                    widget.teacher.name.isNotEmpty ? widget.teacher.name[0].toUpperCase() : 'P',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.emeraldGreenDark),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.teacher.name,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.mintAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Professeur Référent',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.mintAccent,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.teacher.subject} • Niveaux : ${widget.teacher.levels.isNotEmpty ? widget.teacher.levels.join(", ") : "Licence 3"}',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFFD9ECE7),
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
            tooltip: 'Fermer',
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case RegistrationStep.form:
        return _buildFormStep();
      case RegistrationStep.payment:
        return _buildPaymentStep();
      case RegistrationStep.confirmed:
        return _buildConfirmationStep();
    }
  }

  // ==========================================
  // STEP 1: FORMULAIRE D'INSCRIPTION
  // ==========================================
  Widget _buildFormStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner chosen professor
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFF16A34A), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Vous vous inscrivez auprès de ${widget.teacher.name} pour les cours de ${widget.teacher.subject}.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF166534),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          _buildSectionHeader('1. INFORMATIONS PERSONNELLES', Icons.person_rounded),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom *',
                    hintText: 'Ex: Ndiaye',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge_outlined, size: 18),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'Prénom *',
                    hintText: 'Ex: Awa',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _birthDateController,
                  readOnly: true,
                  onTap: _pickBirthDate,
                  decoration: const InputDecoration(
                    labelText: 'Date de naissance *',
                    hintText: 'JJ/MM/AAAA',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _birthPlaceController,
                  decoration: const InputDecoration(
                    labelText: 'Lieu de naissance *',
                    hintText: 'Ex: Dakar',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Numéro de téléphone *',
                    hintText: '77 123 45 67',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone_rounded, size: 18),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Adresse e-mail *',
                    hintText: 'etudiant@exemple.com',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined, size: 18),
                  ),
                  validator: (v) => v == null || !v.contains('@') ? 'E-mail valide requis' : null,
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),
          _buildSectionHeader('2. INFORMATIONS ACADÉMIQUES', Icons.school_rounded),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                flex: 5,
                child: DropdownButtonFormField<String>(
                  value: _selectedLevel,
                  decoration: const InputDecoration(
                    labelText: 'Niveau enseigné *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.workspace_premium_rounded, size: 18),
                  ),
                  items: (widget.teacher.levels.isNotEmpty ? widget.teacher.levels : const ['Licence 3', 'Licence 1', 'Licence 2', 'Master']).map((lvl) {
                    return DropdownMenuItem(value: lvl, child: Text(lvl));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedLevel = v);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 7,
                child: TextFormField(
                  controller: _fieldOfStudyController,
                  decoration: const InputDecoration(
                    labelText: 'Filière *',
                    hintText: 'Ex: Mathématiques, Info...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.menu_book_rounded, size: 18),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Year and Schedule reminder (Responsive & Wrap to prevent overflow)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_month_rounded, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text(
                      'Année scolaire : $_academicYear',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.ink),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time_filled_rounded, size: 16, color: AppTheme.emeraldGreenDark),
                    const SizedBox(width: 6),
                    Text(
                      widget.teacher.schedule,
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.emeraldGreenDark),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Proceed button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _proceedToPayment,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
              label: Text(
                'Vérifier le récapitulatif & Payer (${NumberFormat('#,###', 'fr_FR').format(widget.teacher.registrationFee)} FCFA)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emeraldGreenDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 2: RÉCAPITULATIF & PAIEMENT
  // ==========================================
  Widget _buildPaymentStep() {
    final currency = NumberFormat('#,###', 'fr_FR');
    final formattedFee = '${currency.format(widget.teacher.registrationFee)} FCFA';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back to form
        InkWell(
          onTap: () => setState(() => _currentStep = RegistrationStep.form),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_back_rounded, size: 16, color: AppTheme.emeraldGreenDark),
                const SizedBox(width: 4),
                Text(
                  'Modifier mes informations',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.emeraldGreenDark,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Récapitulatif Box
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RÉCAPITULATIF DE L\'INSCRIPTION',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF64748B),
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              _buildSummaryRow('Professeur', widget.teacher.name),
              _buildSummaryRow('Matière', widget.teacher.subject),
              _buildSummaryRow('Niveau choisi', _selectedLevel),
              _buildSummaryRow('Étudiant', '${_firstNameController.text} ${_lastNameController.text}'),
              _buildSummaryRow('Emploi du temps', widget.teacher.schedule),
              _buildSummaryRow('Frais d\'inscription', formattedFee),
              const Divider(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TOTAL À PAYER',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.ink,
                    ),
                  ),
                  Text(
                    formattedFee,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.emeraldGreenDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        _buildSectionHeader('CHOISIR LE MODE DE PAIEMENT', Icons.payment_rounded),
        const SizedBox(height: 12),

        // Payment Methods Grid
        Row(
          children: [
            Expanded(
              child: _buildPaymentMethodCard(
                id: 'Wave',
                label: 'Wave Sénégal',
                color: const Color(0xFF1D9BF0),
                icon: Icons.waves_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildPaymentMethodCard(
                id: 'Orange Money',
                label: 'Orange Money',
                color: const Color(0xFFFF7900),
                icon: Icons.phone_android_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildPaymentMethodCard(
                id: 'Carte Bancaire',
                label: 'Carte Bancaire',
                color: const Color(0xFF2563EB),
                icon: Icons.credit_card_rounded,
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        if (_selectedPaymentMethod != 'Carte Bancaire') ...[
          TextFormField(
            controller: _paymentPhoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Numéro $_selectedPaymentMethod pour validation',
              hintText: '77 123 45 67',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.phone_iphone_rounded, size: 18),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Vous recevrez une notification de confirmation sécurisée sur votre application $_selectedPaymentMethod.',
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_rounded, size: 16, color: Color(0xFF4F46E5)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Paiement sécurisé par carte Visa / Mastercard (cryptage SSL 256 bits).',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF3730A3)),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Pay Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isProcessingPayment ? null : _processPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isProcessingPayment
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Validation sécurisée en cours...',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_rounded, size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Procéder au paiement ($formattedFee)',
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // STEP 3: CONFIRMATION & FICHE D'INSCRIPTION
  // ==========================================
  Widget _buildConfirmationStep() {
    final reg = _completedRegistration;
    if (reg == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 8),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF86EFAC), width: 2),
          ),
          child: const Icon(Icons.check_rounded, color: Color(0xFF16A34A), size: 36),
        ),
        const SizedBox(height: 14),

        Text(
          'Votre inscription a été enregistrée avec succès !',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.ink,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'Statut : Paiement confirmé • Une fiche d\'inscription a été ajoutée à votre compte.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: const Color(0xFF16A34A),
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 20),

        // Compact preview card of the fiche
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'FICHE D\'INSCRIPTION CRÉÉE',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.emeraldGreenDark,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    reg.registrationNumber,
                    style: GoogleFonts.firaCode(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
              _buildSummaryRow('Nom et prénom', reg.studentFullName),
              _buildSummaryRow('Niveau', reg.studyLevel),
              _buildSummaryRow('Professeur', reg.teacherName),
              _buildSummaryRow('Matière', reg.subject),
              _buildSummaryRow('Année scolaire', reg.academicYear),
              _buildSummaryRow('Montant payé', '${NumberFormat("#,###", "fr_FR").format(reg.fee)} FCFA (${reg.paymentMethod})'),
              _buildSummaryRow('Statut', reg.status),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  StudentRegistrationCardDialog.show(context, registration: reg);
                },
                icon: const Icon(Icons.assignment_rounded, size: 18),
                label: const Text('Consulter ma fiche'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.emeraldGreenDark,
                  side: const BorderSide(color: AppTheme.emeraldGreen),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/dashboard/apprenant');
                },
                icon: const Icon(Icons.school_rounded, size: 18, color: Colors.white),
                label: const Text('Mon espace étudiant'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emeraldGreenDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard({
    required String id,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    final isSelected = _selectedPaymentMethod == id;
    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? color : AppTheme.ink,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B)),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.ink),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.emeraldGreenDark),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppTheme.emeraldGreenDark,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
