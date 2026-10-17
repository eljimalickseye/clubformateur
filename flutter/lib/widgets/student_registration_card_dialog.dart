import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/teacher_registration_model.dart';
import '../theme/app_theme.dart';

class StudentRegistrationCardDialog extends StatelessWidget {
  final TeacherStudentRegistrationModel registration;

  const StudentRegistrationCardDialog({
    super.key,
    required this.registration,
  });

  static Future<void> show(
    BuildContext context, {
    required TeacherStudentRegistrationModel registration,
  }) {
    return showDialog(
      context: context,
      builder: (_) => StudentRegistrationCardDialog(registration: registration),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,###', 'fr_FR');
    final formattedFee = '${currencyFormat.format(registration.fee)} FCFA';
    final formattedDate = DateFormat('dd/MM/yyyy à HH:mm').format(registration.createdAt);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top decorative header banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF062C32), Color(0xFF0F4C5C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'FICHE OFFICIELLE D\'INSCRIPTION',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Club des Formateurs • Année Académique ${registration.academicYear}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: const Color(0xFF99F6E4),
                                    fontWeight: FontWeight.w600,
                                  ),
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
                    ),

                    // Registration Body with Watermark
                    Stack(
                      children: [
                        // Subtle center-bottom logo watermark
                        Positioned(
                          bottom: 20,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: IgnorePointer(
                              child: Opacity(
                                opacity: 0.05,
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  width: 280,
                                  height: 280,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // N° Inscription & Statut Badge
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'NUMÉRO D\'INSCRIPTION',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textMuted,
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      SelectableText(
                                        registration.registrationNumber,
                                        style: GoogleFonts.firaCode(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.emeraldGreenDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFF86EFAC)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF16A34A)),
                                        const SizedBox(width: 6),
                                        Text(
                                          registration.status,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF166534),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 18),
                              const Divider(height: 1),
                              const SizedBox(height: 18),

                              // Section: Étudiant
                              _buildSectionTitle('1. Informations de l\'Étudiant'),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  children: [
                                    _buildDataRow('Nom complet', registration.studentFullName),
                                    if (registration.birthDate.isNotEmpty)
                                      _buildDataRow('Date & Lieu de naissance',
                                          '${registration.birthDate}${registration.birthPlace.isNotEmpty ? " à ${registration.birthPlace}" : ""}'),
                                    _buildDataRow('Niveau d\'étude', registration.studyLevel),
                                    if (registration.fieldOfStudy.isNotEmpty)
                                      _buildDataRow('Filière', registration.fieldOfStudy),
                                    _buildDataRow('Téléphone', registration.phone),
                                    _buildDataRow('E-mail', registration.email),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 18),

                              // Section: Professeur & Matière
                              _buildSectionTitle('2. Enseignement & Professeur Référent'),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  children: [
                                    _buildDataRow('Professeur', registration.teacherName, isHighlighted: true),
                                    _buildDataRow('Matière', registration.subject, isHighlighted: true),
                                    _buildDataRow('Emploi du temps', registration.proposedSchedule),
                                    _buildDataRow('Année scolaire', registration.academicYear),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 18),

                              // Section: Paiement & Validation
                              _buildSectionTitle('3. Frais & Règlement'),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFBBF7D0)),
                                ),
                                child: Column(
                                  children: [
                                    _buildDataRow('Montant réglé', formattedFee, isBold: true),
                                    _buildDataRow('Moyen de paiement', registration.paymentMethod),
                                    _buildDataRow('Statut paiement', registration.paymentStatus, textColor: const Color(0xFF16A34A)),
                                    _buildDataRow('Date d\'inscription', formattedDate),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // QR Code + Cachet officiel
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: QrImageView(
                                      data: 'https://club-des-formateurs.web.app/verify-registration?id=${registration.registrationNumber}',
                                      version: QrVersions.auto,
                                      size: 78.0,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'AUTHENTIFICATION NUMÉRIQUE',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.ink,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Fiche certifiée par la plateforme Club des Formateurs. Scannez pour vérifier la validité de l\'inscription.',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            color: AppTheme.textMuted,
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),
                              const Divider(height: 1),
                              const SizedBox(height: 16),

                              // Actions buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(
                                          text: 'Fiche d\'inscription n°${registration.registrationNumber}\n'
                                              'Étudiant : ${registration.studentFullName}\n'
                                              'Professeur : ${registration.teacherName}\n'
                                              'Matière : ${registration.subject} (${registration.studyLevel})\n'
                                              'Emploi du temps : ${registration.proposedSchedule}\n'
                                              'Montant : $formattedFee',
                                        ));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Informations de la fiche copiées dans le presse-papier !'),
                                            backgroundColor: AppTheme.emeraldGreen,
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.copy_rounded, size: 16),
                                      label: const Text('Copier les infos'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.ink,
                                        side: const BorderSide(color: Color(0xFFCBD5E1)),
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
                                      },
                                      icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                                      label: const Text('Terminer'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.emeraldGreen,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF0F172A),
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildDataRow(
    String label,
    String value, {
    bool isBold = false,
    bool isHighlighted = false,
    Color? textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: (isBold || isHighlighted) ? FontWeight.w700 : FontWeight.w600,
                color: textColor ?? (isHighlighted ? AppTheme.emeraldGreenDark : const Color(0xFF1E293B)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
