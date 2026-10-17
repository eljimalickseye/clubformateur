import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/legal_document_model.dart';
import '../services/legal_service.dart';
import '../theme/app_theme.dart';

/// Widget "classeurs inclines" flottant
/// Place-le dans un Stack au-dessus du contenu principal.
class LegalDocumentsFAB extends StatelessWidget {
  final String userId;
  const LegalDocumentsFAB({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Documents officiels',
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showDocumentsSheet(context),
        child: SizedBox(
          width: 64,
          height: 80,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Classeur arrière (contrat)
              Positioned(
                left: 4,
                top: 4,
                child: Transform.rotate(
                  angle: -0.12,
                  child: _Binder(
                    color: const Color(0xFF0E4D6E),
                    label: 'Contrat',
                    icon: Icons.gavel_rounded,
                  ),
                ),
              ),
              // Classeur avant (reglement)
              Transform.rotate(
                angle: 0.06,
                child: _Binder(
                  color: AppTheme.emeraldGreenDark,
                  label: 'Reglement',
                  icon: Icons.menu_book_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDocumentsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LegalDocumentsView(userId: userId, isModal: true),
    );
  }
}

class _Binder extends StatelessWidget {
  final Color color;
  final String label;
  final IconData icon;
  const _Binder({required this.color, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 68,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(100),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 7,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class LegalDocumentsView extends StatefulWidget {
  final String userId;
  final bool isModal;
  final double? height;
  const LegalDocumentsView({
    super.key,
    required this.userId,
    this.isModal = false,
    this.height,
  });

  @override
  State<LegalDocumentsView> createState() => _LegalDocumentsViewState();
}

class _LegalDocumentsViewState extends State<LegalDocumentsView> {
  final LegalService _legalService = LegalService();
  List<LegalDocumentModel> _docs = [];
  Map<String, bool> _accepted = {};
  bool _loading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final docs = await _legalService
          .getLegalDocuments()
          .timeout(const Duration(seconds: 3));
      final accepted = <String, bool>{};
      for (final d in docs) {
        try {
          accepted[d.id] = await _legalService.hasUserAccepted(widget.userId, d.id);
        } catch (_) {
          accepted[d.id] = false;
        }
      }
      if (mounted) {
        setState(() {
          _docs = docs;
          _accepted = accepted;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _docs = [
            LegalDocumentModel.defaultReglement,
            LegalDocumentModel.defaultContrat,
            LegalDocumentModel.defaultRemboursement,
          ];
          _accepted = {};
          _loading = false;
        });
      }
    }
  }

  Future<void> _accept(LegalDocumentModel doc) async {
    await _legalService.recordAcceptance(
      userId: widget.userId,
      documentId: doc.id,
      version: doc.version,
    );
    if (mounted) {
      setState(() => _accepted[doc.id] = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${doc.title} accepte avec succes'),
          backgroundColor: AppTheme.emeraldGreenDark,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.height ?? (widget.isModal ? MediaQuery.of(context).size.height * 0.90 : 750.0);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: widget.isModal
            ? const BorderRadius.vertical(top: Radius.circular(24))
            : BorderRadius.circular(20),
        border: widget.isModal ? null : Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          // Handle (only if modal)
          if (widget.isModal)
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(99),
              ),
            ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.folder_special_rounded,
                    color: AppTheme.emeraldGreenDark, size: 26),
                const SizedBox(width: 10),
                Text(
                  'Documents Officiels & Règlements',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink,
                  ),
                ),
                const Spacer(),
                if (widget.isModal)
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
              ],
            ),
          ),

          if (_loading)
            const Expanded(
                child: Center(
                    child:
                        CircularProgressIndicator(color: AppTheme.emeraldGreen)))
          else if (_docs.isEmpty)
            const Expanded(
                child: Center(child: Text('Aucun document disponible')))
          else ...[
            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(_docs.length, (i) {
                  final doc = _docs[i];
                  final isSelected = _selectedIndex == i;
                  final isAccepted = _accepted[doc.id] == true;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedIndex = i),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.emeraldGreenDark
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              doc.type == 'reglement'
                                  ? Icons.menu_book_rounded
                                  : Icons.gavel_rounded,
                              color:
                                  isSelected ? Colors.white : AppTheme.textMuted,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                doc.title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textMuted,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isAccepted) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.verified_rounded,
                                size: 14,
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.emeraldGreen,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),

            // Content
            Expanded(
              child: Builder(builder: (_) {
                final doc = _docs[_selectedIndex];
                final isAccepted = _accepted[doc.id] == true;
                return Column(
                  children: [
                    // Version banner
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 14, color: AppTheme.textMuted),
                          const SizedBox(width: 6),
                          Text(
                            'Version ${doc.version} - Effective le '
                            '${doc.effectiveDate.day}/${doc.effectiveDate.month}/${doc.effectiveDate.year}',
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.textMuted),
                          ),
                          const Spacer(),
                          if (isAccepted)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD1FAE5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.check_circle_rounded,
                                      size: 12, color: Color(0xFF065F46)),
                                  SizedBox(width: 4),
                                  Text('Accepte',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF065F46))),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Document text
                    Expanded(
                      child: Scrollbar(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          child: _MarkdownText(content: doc.content),
                        ),
                      ),
                    ),

                    // Accept button
                    if (!isAccepted)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check_circle_outline_rounded),
                            label: const Text(
                              "J'ai lu et j'accepte ce document",
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.emeraldGreenDark,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () => _accept(doc),
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.verified_rounded,
                                  color: Color(0xFF065F46), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Document accepte - Signature enregistree',
                                style: TextStyle(
                                  color: Color(0xFF065F46),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

/// Rendu simple du Markdown (titres, bullets, paragraphes)
class _MarkdownText extends StatelessWidget {
  final String content;
  const _MarkdownText({required this.content});

  @override
  Widget build(BuildContext context) {
    final lines = content.split('\n');
    final widgets = <Widget>[];
    for (final line in lines) {
      if (line.startsWith('# ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(line.substring(2),
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink)),
        ));
      } else if (line.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(line.substring(3),
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.emeraldGreenDark)),
        ));
      } else if (line.startsWith('---')) {
        widgets.add(const Divider(height: 24, color: AppTheme.cardBorder));
      } else if (line.startsWith('- ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('•  ',
                  style: TextStyle(
                      color: AppTheme.emeraldGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
              Expanded(
                  child: Text(line.substring(2),
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.ink, height: 1.5))),
            ],
          ),
        ));
      } else if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 6));
      } else {
        // Gras **text** simple
        final parts = line.split('**');
        if (parts.length >= 3) {
          final spans = <TextSpan>[];
          for (int i = 0; i < parts.length; i++) {
            spans.add(TextSpan(
              text: parts[i],
              style: TextStyle(
                fontWeight: i.isOdd ? FontWeight.w700 : FontWeight.normal,
                fontSize: 13,
                color: AppTheme.ink,
                height: 1.6,
              ),
            ));
          }
          widgets.add(Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: RichText(text: TextSpan(children: spans)),
          ));
        } else {
          widgets.add(Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(line,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.ink, height: 1.6)),
          ));
        }
      }
    }
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }
}
