import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onNavigateToLogin;
  final VoidCallback onNavigateToPartnerRegister;
  final VoidCallback onRegisteredSuccess;

  const RegisterScreen({
    super.key,
    required this.onNavigateToLogin,
    required this.onNavigateToPartnerRegister,
    required this.onRegisteredSuccess,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _currentStep = 1;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  final _plateController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  int _fiscalPower = 8;
  String _fuelType = 'Essence';
  Uint8List? _carteGriseBytes;
  String? _carteGriseName;

  final _brokerCodeController = TextEditingController(text: 'COURTIER-DAKAR-77');

  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();

  Future<void> _pickCarteGrisePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _carteGriseBytes = bytes;
        _carteGriseName = picked.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Inscription Assuré',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppTheme.textDark,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: widget.onNavigateToLogin,
            child: const Text('Connexion', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Row(
                children: [
                  _stepDot(1, 'Identité'),
                  _stepLine(1),
                  _stepDot(2, 'Carte Grise'),
                  _stepLine(2),
                  _stepDot(3, 'Courtier & QR'),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: _buildCurrentStep(),
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_currentStep > 1)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _currentStep--),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFFD1E7DB)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Précédent',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  if (_currentStep > 1) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _handleNextOrSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _currentStep == 3 ? 'Finaliser & Générer mon Pass' : 'Suivant',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      default:
        return _buildStep1();
    }
  }

  Widget _buildStep1() {
    return Form(
      key: _formKey1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: OliviaLogo(size: 48, showSubtitle: true)),
          const SizedBox(height: 20),
          Text(
            '1. Vos Coordonnées',
            style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.darkBlue),
          ),
          const SizedBox(height: 4),
          Text(
            'Créez votre compte pour gérer vos assurances auto au Sénégal.',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 20),

          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nom et Prénom',
              hintText: 'Ex: Serigne Abdoulaye Diop',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            validator: (v) => v == null || v.trim().isEmpty ? 'Veuillez renseigner votre nom' : null,
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Adresse Email',
              hintText: 'serigne@gmail.com',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
            validator: (v) => v == null || !v.contains('@') ? 'Veuillez saisir un email valide' : null,
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Numéro de Téléphone (+221)',
              hintText: '+221 77 000 00 00',
              prefixIcon: Icon(Icons.phone_iphone_rounded),
            ),
            validator: (v) => v == null || v.trim().isEmpty ? 'Veuillez saisir votre numéro' : null,
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Mot de passe sécurisé',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) => v == null || v.length < 6 ? 'Au moins 6 caractères' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Form(
      key: _formKey2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '2. Votre Véhicule & Carte Grise',
            style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.darkBlue),
          ),
          const SizedBox(height: 4),
          Text(
            'Renseignez les données officielles figurant sur votre carte grise.',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 20),

          TextFormField(
            controller: _plateController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Numéro d\'Immatriculation',
              hintText: 'Ex: DK-5489-BG',
              prefixIcon: Icon(Icons.pin_outlined),
            ),
            validator: (v) => v == null || v.trim().isEmpty ? 'Veuillez saisir l\'immatriculation' : null,
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _makeController,
                  decoration: const InputDecoration(
                    labelText: 'Marque',
                    hintText: 'Ex: Toyota',
                    prefixIcon: Icon(Icons.directions_car_rounded),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _modelController,
                  decoration: const InputDecoration(
                    labelText: 'Modèle',
                    hintText: 'Ex: RAV4 Hybride',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _fiscalPower,
                  decoration: const InputDecoration(
                    labelText: 'Puissance Fiscale (CV)',
                  ),
                  items: [4, 5, 6, 7, 8, 9, 10, 11, 12, 14, 16]
                      .map((cv) => DropdownMenuItem(value: cv, child: Text('$cv CV')))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _fiscalPower = val);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _fuelType,
                  decoration: const InputDecoration(
                    labelText: 'Carburant',
                  ),
                  items: ['Essence', 'Diesel', 'Hybride Essence', 'Électrique']
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _fuelType = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          InkWell(
            onTap: _pickCarteGrisePhoto,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _carteGriseBytes != null ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _carteGriseBytes != null ? const Color(0xFFD1E7DD) : const Color(0xFFEDF4FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _carteGriseBytes != null ? Icons.check_circle_rounded : Icons.camera_alt_outlined,
                      color: _carteGriseBytes != null ? const Color(0xFF0F5132) : AppTheme.primaryBlue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _carteGriseBytes != null ? 'Photo Carte Grise ajoutée' : 'Photo de la Carte Grise (Optionnel)',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: _carteGriseBytes != null ? const Color(0xFF0F5132) : AppTheme.textDark,
                          ),
                        ),
                        Text(
                          _carteGriseName ?? 'Cliquez pour photographier votre document',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.add_a_photo_outlined, color: AppTheme.primaryBlue),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    final previewQrData = 'OLIVIA:PREVIEW_PASS\n'
        'Nom: ${_nameController.text.trim().isNotEmpty ? _nameController.text.trim() : "Client Assuré"}\n'
        'Tél: ${_phoneController.text.trim()}\n'
        'Immatriculation: ${_plateController.text.trim().toUpperCase()}\n'
        'Véhicule: ${_makeController.text.trim()} ${_modelController.text.trim()}\n'
        'Courtier: ${_brokerCodeController.text.trim()}';

    return Form(
      key: _formKey3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '3. Votre Agence de Courtage & Pass QR',
            style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.darkBlue),
          ),
          const SizedBox(height: 4),
          Text(
            'Renseignez le code courtier ou sélectionnez l\'un des cabinets partenaires agréés CIMA.',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 18),

          TextFormField(
            controller: _brokerCodeController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Code Courtier Partenaire',
              hintText: 'Ex: COURTIER-DAKAR-77',
              prefixIcon: Icon(Icons.confirmation_number_outlined),
            ),
            validator: (v) => v == null || v.trim().isEmpty ? 'Veuillez saisir un code courtier' : null,
          ),
          const SizedBox(height: 12),

          // Chips de sélection rapide
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _brokerChip('Cabinet Dakar (DAKAR-77)', 'COURTIER-DAKAR-77'),
              _brokerChip('Teranga (TERANGA-22)', 'TERANGA-COURTAGE-22'),
              _brokerChip('Baobab (BAOBAB-33)', 'BAOBAB-COURTAGE-33'),
              _brokerChip('Almadies (ALMADIES-99)', 'ALMADIES-PRESTIGE-99'),
            ],
          ),
          const SizedBox(height: 18),

          // Aperçu en temps réel du QR Code Pass
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFD2E3FC), width: 1.5),
            ),
            child: Row(
              children: [
                QrImageView(
                  data: previewQrData,
                  version: QrVersions.auto,
                  size: 90.0,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(6)),
                        child: const Text('PASS QR NUMÉRIQUE CIMA', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_plateController.text.trim().toUpperCase()} • ${_makeController.text.trim()} ${_modelController.text.trim()}',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.darkBlue),
                      ),
                      Text(
                        'Courtier : ${_brokerCodeController.text.trim()}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppTheme.primaryBlue, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _brokerChip(String label, String code) {
    final isSelected = _brokerCodeController.text.trim().toUpperCase() == code.toUpperCase();
    return InkWell(
      onTap: () => setState(() => _brokerCodeController.text = code),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.textDark,
          ),
        ),
      ),
    );
  }

  Widget _stepDot(int step, String label) {
    final isDone = _currentStep > step;
    final isActive = _currentStep == step;

    return Column(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: isActive ? AppTheme.primaryBlue : (isDone ? const Color(0xFF10B981) : const Color(0xFFE2E8F0)),
          child: isDone
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : Text(
                  '$step',
                  style: TextStyle(
                    color: isActive ? Colors.white : const Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? AppTheme.primaryBlue : AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _stepLine(int step) {
    final isDone = _currentStep > step;
    return Expanded(
      child: Container(
        height: 2.5,
        margin: const EdgeInsets.only(bottom: 16),
        color: isDone ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
      ),
    );
  }

  void _handleNextOrSubmit() {
    if (_currentStep == 1) {
      if (_formKey1.currentState?.validate() ?? false) {
        setState(() => _currentStep = 2);
      }
    } else if (_currentStep == 2) {
      if (_formKey2.currentState?.validate() ?? false) {
        setState(() => _currentStep = 3);
      }
    } else {
      if (_formKey3.currentState?.validate() ?? false) {
        final appState = context.read<AppState>();
        appState.registerClientWithCarteGrise(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          password: _passwordController.text.trim(),
          plateNumber: _plateController.text.trim(),
          make: _makeController.text.trim(),
          model: _modelController.text.trim(),
          fiscalPower: _fiscalPower,
          fuelType: _fuelType,
          carteGriseBytes: _carteGriseBytes,
          brokerCode: _brokerCodeController.text.trim(),
        );
        widget.onRegisteredSuccess();
      }
    }
  }
}
