import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class PrivacySettingsCard extends StatefulWidget {
  const PrivacySettingsCard({super.key});

  @override
  State<PrivacySettingsCard> createState() => _PrivacySettingsCardState();
}

class _PrivacySettingsCardState extends State<PrivacySettingsCard> {
  final AuthService _authService = AuthService();
  bool _isExporting = false;

  Future<void> _handleExportData() async {
    setState(() => _isExporting = true);
    final data = await _authService.exportPersonalData();
    setState(() => _isExporting = false);

    if (!mounted) return;

    if (data == null || data['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de récupérer l\'export des données pour le moment.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final prettyJson = const JsonEncoder.withIndent('  ').convert(data);
    final enrollmentsCount = (data['enrollments'] as List?)?.length ?? 0;
    final homeworksCount = (data['homeworks'] as List?)?.length ?? 0;
    final messagesCount = (data['messages'] as List?)?.length ?? 0;
    final transactionsCount = (data['transactions'] as List?)?.length ?? 0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.download_done_rounded, color: AppTheme.emeraldGreen, size: 24),
            const SizedBox(width: 10),
            Text('Export de vos données', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vos données enregistrées sur la plateforme conformément à la loi sénégalaise 2008-12 et au RGPD :',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildStatBadge('$enrollmentsCount Inscriptions', Icons.school_outlined),
                  _buildStatBadge('$homeworksCount Devoirs', Icons.assignment_outlined),
                  _buildStatBadge('$messagesCount Messages', Icons.chat_bubble_outline),
                  _buildStatBadge('$transactionsCount Transactions', Icons.receipt_long_outlined),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 180,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    prettyJson,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Color(0xFF38BDF8)),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copier le JSON'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: prettyJson));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Export JSON copié dans le presse-papier !'),
                  backgroundColor: AppTheme.emeraldGreen,
                ),
              );
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emeraldGreenDark,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.paleMint,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.emeraldGreenDark),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.emeraldGreenDark)),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final passwordCtrl = TextEditingController();
    bool isDeleting = false;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 26),
              SizedBox(width: 10),
              Text('Supprimer mon compte'),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cette action est irréversible. Votre compte et vos données personnelles seront définitivement anonymisés (loi 2008-12 / RGPD).',
                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Note : Si vous êtes formateur, veillez à retirer l\'intégralité de votre solde avant la suppression.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFD97706)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirmez avec votre mot de passe',
                    border: const OutlineInputBorder(),
                    errorText: errorMessage,
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isDeleting ? null : () => Navigator.pop(ctx),
              child: const Text('Annuler', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: isDeleting
                  ? null
                  : () async {
                      final pwd = passwordCtrl.text.trim();
                      if (pwd.isEmpty) {
                        setDialogState(() => errorMessage = 'Veuillez saisir votre mot de passe.');
                        return;
                      }

                      setDialogState(() {
                        isDeleting = true;
                        errorMessage = null;
                      });

                      final messenger = ScaffoldMessenger.of(context);
                      final nav = Navigator.of(context);

                      final result = await _authService.deleteAccount(pwd);

                      if (result['success'] == true) {
                        if (ctx.mounted) Navigator.pop(ctx);
                        nav.pushNamedAndRemoveUntil('/', (route) => false);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(result['message'] ?? 'Votre compte a été supprimé.'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      } else {
                        if (ctx.mounted) {
                          setDialogState(() {
                            isDeleting = false;
                            errorMessage = result['message'] ?? 'Erreur lors de la suppression.';
                          });
                        }
                      }
                    },
              child: isDeleting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Confirmer la suppression'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.security_rounded, size: 20, color: AppTheme.emeraldGreenDark),
              const SizedBox(width: 8),
              Text(
                'Données personnelles & Confidentialité',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.paleMint,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'RGPD / Loi 2008-12',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.emeraldGreenDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Vous avez le plein contrôle sur vos données personnelles. Vous pouvez télécharger une copie intégrale de vos informations ou supprimer définitivement votre compte.',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                icon: _isExporting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.download_rounded, size: 16),
                label: const Text('Exporter mes données'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.ink,
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isExporting ? null : _handleExportData,
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                label: const Text('Supprimer mon compte', style: TextStyle(color: Colors.redAccent)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFECACA)),
                  backgroundColor: const Color(0xFFFEF2F2),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _showDeleteAccountDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
