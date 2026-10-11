import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/course_model.dart';
import '../models/user_model.dart';
import '../services/course_service.dart';
import '../services/firebase_storage_service.dart';
import '../services/homework_service.dart';
import '../theme/app_theme.dart';
import '../utils/file_download_helper.dart';
import 'studio_svg_icon.dart';

class HomeworkAssignmentDialog extends StatefulWidget {
  final UserModel user;
  final String? presetCourseId;
  final String? presetCourseName;

  const HomeworkAssignmentDialog({
    super.key,
    required this.user,
    this.presetCourseId,
    this.presetCourseName,
  });

  static Future<void> show(
    BuildContext context, {
    required UserModel user,
    String? presetCourseId,
    String? presetCourseName,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => HomeworkAssignmentDialog(
        user: user,
        presetCourseId: presetCourseId,
        presetCourseName: presetCourseName,
      ),
    );
  }

  @override
  State<HomeworkAssignmentDialog> createState() => _HomeworkAssignmentDialogState();
}

class _UploadedAttachment {
  final String name;
  final String url;
  final int sizeBytes;

  _UploadedAttachment({
    required this.name,
    required this.url,
    required this.sizeBytes,
  });
}

class _HomeworkAssignmentDialogState extends State<HomeworkAssignmentDialog> {
  final CourseService _courseService = CourseService();
  final HomeworkService _homeworkService = HomeworkService();
  final FirebaseStorageService _storageService = FirebaseStorageService();

  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _instructionsCtrl = TextEditingController();
  final TextEditingController _linkUrlCtrl = TextEditingController();
  final TextEditingController _linkNameCtrl = TextEditingController();

  String? _selectedCourseId;
  String _selectedCourseName = '';
  DateTime _deadline = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _deadlineTime = const TimeOfDay(hour: 23, minute: 59);
  int _points = 20;

  // Allowed submissions
  bool _allowBlankPage = true;
  bool _allowPhotoSheet = true;
  bool _allowWordDocument = true;

  // Attachments
  final List<_UploadedAttachment> _attachments = [];
  bool _isUploadingFile = false;
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    _selectedCourseId = widget.presetCourseId;
    _selectedCourseName = widget.presetCourseName ?? '';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _instructionsCtrl.dispose();
    _linkUrlCtrl.dispose();
    _linkNameCtrl.dispose();
    super.dispose();
  }

  void _applyTemplate(String type) {
    switch (type) {
      case 'tp':
        _titleCtrl.text = 'TP Pratique - Application & Résolution de Cas';
        _instructionsCtrl.text = '''🎯 Objectifs pédagogiques :
- Mettre en pratique les notions abordées dans les derniers chapitres.
- Développer une solution propre, structurée et documentée.

📝 Consignes détaillées :
1. Téléchargez les ressources et le sujet ci-joints.
2. Suivez les étapes de résolution pas-à-pas.
3. Rédigez un compte-rendu synthétique ou soumettez votre code source.

📦 Livrables attendus :
- Fichier PDF ou copie manuscrite avec explications et captures d'écran.''';
        _points = 20;
        break;

      case 'projet':
        _titleCtrl.text = 'Projet Final de Synthèse - Cas Réel';
        _instructionsCtrl.text = '''🎯 Objectif du Projet :
Concevoir et livrer un projet d'envergure démontrant votre maîtrise intégrale de la formation.

📝 Cahier des charges :
1. Architecture et conception du projet.
2. Implémentation complète et tests.
3. Documentation d'utilisation et bilan réflexif.

📦 Livrables attendus :
- Archive ZIP ou document Word/PDF complet + lien du dépôt ou prototype.''';
        _points = 50;
        break;

      case 'exercices':
        _titleCtrl.text = 'Série d\'Exercices N°1 - Fondamentaux';
        _instructionsCtrl.text = '''🎯 Objectifs :
Vérifier l'assimilation des principes de base et automatiser les réflexes méthodologiques.

📝 Travail à réaliser :
- Répondre aux questions de compréhension dans l'ordre.
- Justifier chaque réponse et détailler vos démarches de calcul/raisonnement.

📦 Format de remise :
- Page blanche numérique ou photo claire de votre feuille d'exercices.''';
        _points = 20;
        break;

      case 'etude_cas':
        _titleCtrl.text = 'Étude de Cas & Recommandations Stratégiques';
        _instructionsCtrl.text = '''🎯 Contexte & Objectif :
Analyser la situation présentée dans le document joint et formuler des recommandations concrètes.

📝 Questions clés :
1. Diagnostic de la problématique principale.
2. Analyse SWOT ou critique des options disponibles.
3. Plan d'action prioritaire et calendrier de mise en œuvre.

📦 Livrables attendus :
- Document de synthèse (2 à 4 pages maximum).''';
        _points = 20;
        break;
    }
    setState(() {});
  }

  void _insertPrompt(String tag, String text) {
    final current = _instructionsCtrl.text;
    final prefix = current.isEmpty ? '' : '\n\n';
    _instructionsCtrl.text = '$current$prefix$tag\n$text';
    _instructionsCtrl.selection = TextSelection.fromPosition(
      TextPosition(offset: _instructionsCtrl.text.length),
    );
    setState(() {});
  }

  Future<void> _pickAndUploadAttachment() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf', 'doc', 'docx', 'xls', 'xlsx', 'zip', 'rar',
          'png', 'jpg', 'jpeg', 'txt', 'dart', 'py', 'js',
        ],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) return;

      setState(() => _isUploadingFile = true);

      final hwTempId = 'hw_${DateTime.now().millisecondsSinceEpoch}';
      final url = await _storageService.uploadHomeworkAttachment(
        homeworkId: hwTempId,
        bytes: bytes,
        fileName: file.name,
      );

      if (url != null) {
        setState(() {
          _attachments.add(_UploadedAttachment(
            name: file.name,
            url: url,
            sizeBytes: file.size,
          ));
        });
      }
    } catch (e) {
      debugPrint('Upload attachment error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'ajout du fichier : $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingFile = false);
    }
  }

  void _showAddLinkModal() {
    _linkUrlCtrl.clear();
    _linkNameCtrl.clear();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.link_rounded, color: AppTheme.emeraldGreenDark),
            const SizedBox(width: 8),
            Text('Ajouter une ressource en ligne', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _linkNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom du document ou de la ressource',
                hintText: 'Ex: Sujet Google Drive / Repo GitHub',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _linkUrlCtrl,
              decoration: const InputDecoration(
                labelText: 'Lien URL complet (https://...)',
                hintText: 'https://...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldGreenDark, foregroundColor: Colors.white),
            onPressed: () {
              final url = _linkUrlCtrl.text.trim();
              if (url.isEmpty || !url.startsWith('http')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veuillez entrer une URL valide commençant par http/https.')),
                );
                return;
              }
              final name = _linkNameCtrl.text.trim().isEmpty ? 'Ressource externe' : _linkNameCtrl.text.trim();
              setState(() {
                _attachments.add(_UploadedAttachment(name: name, url: url, sizeBytes: 0));
              });
              Navigator.pop(c);
            },
            child: const Text('Ajouter le lien'),
          ),
        ],
      ),
    );
  }

  Future<void> _publish() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez renseigner le titre du devoir.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final instructions = _instructionsCtrl.text.trim();
    if (instructions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez rédiger les consignes du devoir.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final finalDeadline = DateTime(
      _deadline.year,
      _deadline.month,
      _deadline.day,
      _deadlineTime.hour,
      _deadlineTime.minute,
    );

    final allowedTypes = <String>[];
    if (_allowBlankPage) allowedTypes.add('blank_page');
    if (_allowPhotoSheet) allowedTypes.add('photo_sheet');
    if (_allowWordDocument) allowedTypes.add('word_document');
    if (allowedTypes.isEmpty) allowedTypes.add('blank_page');

    setState(() => _isPublishing = true);

    try {
      await _homeworkService.publishHomework(
        title: title,
        courseId: _selectedCourseId ?? 'course_all',
        courseName: _selectedCourseName.isNotEmpty ? _selectedCourseName : 'Toutes les promotions',
        teacherId: widget.user.uid,
        teacherName: widget.user.displayName,
        instructions: instructions,
        deadline: finalDeadline,
        attachmentUrls: _attachments.map((a) => a.url).toList(),
        attachmentNames: _attachments.map((a) => a.name).toList(),
        points: _points,
        allowedSubmissionTypes: allowedTypes,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Le devoir "$title" a été assigné et notifié aux apprenants !')),
              ],
            ),
            backgroundColor: AppTheme.emeraldGreenDark,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la publication : $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 860,
        constraints: const BoxConstraints(maxHeight: 820),
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.paleMint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const StudioSvgIcon(iconKey: StudioSvgIcon.book, size: 24, color: AppTheme.emeraldGreenDark),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assigner un devoir pratique',
                        style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.ink),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Configurez l\'énoncé, les ressources à télécharger, les points et la date de remise.',
                        style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const StudioSvgIcon(iconKey: StudioSvgIcon.close, size: 20, color: AppTheme.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppTheme.cardBorder),
            const SizedBox(height: 16),

            // Scrollable Body
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Templates Pills
                    Text(
                      'Modèles de devoirs types (remplissage en 1 clic) :',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.ink),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildTemplateChip('🚀 TP Pratique', () => _applyTemplate('tp')),
                        _buildTemplateChip('📊 Projet Synthèse (50 pts)', () => _applyTemplate('projet')),
                        _buildTemplateChip('📝 Série d\'Exercices', () => _applyTemplate('exercices')),
                        _buildTemplateChip('💡 Étude de Cas', () => _applyTemplate('etude_cas')),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Section 1: Cours & Titre
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Course selector
                        Expanded(
                          flex: 5,
                          child: StreamBuilder<List<CourseModel>>(
                            stream: (widget.user.role == 'corrector' || widget.user.role == 'admin' || widget.user.role == 'superadmin')
                                ? _courseService.getAllCoursesStream()
                                : _courseService.getTeacherCoursesStream(widget.user.uid),
                            builder: (context, snap) {
                              final courses = snap.data ?? [];
                              if (_selectedCourseId == null && courses.isNotEmpty) {
                                _selectedCourseId = courses.first.id;
                                _selectedCourseName = courses.first.title;
                              }

                              return DropdownButtonFormField<String>(
                                initialValue: _selectedCourseId,
                                decoration: InputDecoration(
                                  labelText: 'Formation concernée *',
                                  prefixIcon: const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: StudioSvgIcon(iconKey: StudioSvgIcon.graduation, size: 18, color: AppTheme.emeraldGreenDark),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.cardBorder)),
                                ),
                                items: [
                                  const DropdownMenuItem(
                                    value: 'course_all',
                                    child: Text('Toutes mes promotions', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                  ...courses.map((c) => DropdownMenuItem(
                                        value: c.id,
                                        child: Text(c.title, overflow: TextOverflow.ellipsis),
                                      )),
                                ],
                                onChanged: (val) {
                                  setState(() {
                                    _selectedCourseId = val;
                                    if (val == 'course_all') {
                                      _selectedCourseName = 'Toutes mes promotions';
                                    } else {
                                      final matched = courses.where((c) => c.id == val).firstOrNull;
                                      _selectedCourseName = matched?.title ?? '';
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Points Barème
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<int>(
                            initialValue: _points,
                            decoration: InputDecoration(
                              labelText: 'Barème de notation *',
                              prefixIcon: const Icon(Icons.star_rounded, size: 20, color: Color(0xFFF59E0B)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.cardBorder)),
                            ),
                            items: const [
                              DropdownMenuItem(value: 20, child: Text('Sur 20 points (Standard)')),
                              DropdownMenuItem(value: 40, child: Text('Sur 40 points')),
                              DropdownMenuItem(value: 50, child: Text('Sur 50 points (Projet)')),
                              DropdownMenuItem(value: 100, child: Text('Sur 100 points')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _points = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Titre
                    TextField(
                      controller: _titleCtrl,
                      decoration: InputDecoration(
                        labelText: 'Titre du devoir *',
                        hintText: 'Ex: TP 02 - Implémentation d\'une architecture robuste',
                        prefixIcon: const Padding(
                          padding: EdgeInsets.all(12),
                          child: StudioSvgIcon(iconKey: StudioSvgIcon.assignment, size: 18, color: AppTheme.emeraldGreenDark),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.cardBorder)),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Deadline Date & Time with quick presets
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const StudioSvgIcon(iconKey: StudioSvgIcon.clock, color: AppTheme.emeraldGreenDark, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Date & heure limite de remise des copies',
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.ink),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                icon: const StudioSvgIcon(iconKey: StudioSvgIcon.clock, size: 15, color: AppTheme.emeraldGreenDark),
                                label: Text(
                                  '${_deadline.day.toString().padLeft(2, '0')}/${_deadline.month.toString().padLeft(2, '0')}/${_deadline.year} à ${_deadlineTime.hour.toString().padLeft(2, '0')}h${_deadlineTime.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.emeraldGreenDark,
                                  side: const BorderSide(color: AppTheme.emeraldGreen),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () async {
                                  final d = await showDatePicker(
                                    context: context,
                                    initialDate: _deadline,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (d != null && context.mounted) {
                                    final t = await showTimePicker(
                                      context: context,
                                      initialTime: _deadlineTime,
                                    );
                                    setState(() {
                                      _deadline = d;
                                      if (t != null) _deadlineTime = t;
                                    });
                                  }
                                },
                              ),
                              _buildQuickDayPreset('+3 jours', () {
                                setState(() => _deadline = DateTime.now().add(const Duration(days: 3)));
                              }),
                              _buildQuickDayPreset('+1 semaine', () {
                                setState(() => _deadline = DateTime.now().add(const Duration(days: 7)));
                              }),
                              _buildQuickDayPreset('+2 semaines', () {
                                setState(() => _deadline = DateTime.now().add(const Duration(days: 14)));
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Instructions / Consignes Editor
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Énoncé & Consignes détaillées *',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.ink),
                        ),
                        Wrap(
                          spacing: 6,
                          children: [
                            _buildTagInsertButton('🎯 Objectifs', () => _insertPrompt('🎯 Objectifs pédagogiques :', '- Point 1\n- Point 2')),
                            _buildTagInsertButton('📝 Étapes', () => _insertPrompt('📝 Étapes à réaliser :', '1. Étape 1\n2. Étape 2')),
                            _buildTagInsertButton('📦 Livrables', () => _insertPrompt('📦 Livrables attendus :', '- Document PDF\n- Fichier de code')),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _instructionsCtrl,
                      maxLines: 7,
                      decoration: InputDecoration(
                        hintText: 'Détaillez les étapes attendues, les questions à résoudre et les critères d\'évaluation...',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.cardBorder)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.emeraldGreenDark, width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Section Pièces Jointes / Documents du Sujet
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const StudioSvgIcon(iconKey: StudioSvgIcon.file, color: AppTheme.emeraldGreenDark, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Documents & Fichiers du sujet à télécharger',
                                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.ink),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  TextButton.icon(
                                    icon: const StudioSvgIcon(iconKey: StudioSvgIcon.copy, size: 16, color: AppTheme.emeraldGreenDark),
                                    label: const Text('Lien externe'),
                                    onPressed: _showAddLinkModal,
                                  ),
                                  const SizedBox(width: 6),
                                  ElevatedButton.icon(
                                    icon: _isUploadingFile
                                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                        : const StudioSvgIcon(iconKey: StudioSvgIcon.upload, size: 16, color: Colors.white),
                                    label: const Text('Téléverser un fichier'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.emeraldGreenDark,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    ),
                                    onPressed: _isUploadingFile ? null : _pickAndUploadAttachment,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Formats acceptés : PDF, Word (.docx), Archives (.zip), Images, Fichiers source. Les élèves pourront les télécharger directement depuis leur espace.',
                            style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                          ),
                          const SizedBox(height: 12),

                          if (_attachments.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
                              ),
                              child: Column(
                                children: [
                                  const StudioSvgIcon(iconKey: StudioSvgIcon.upload, size: 36, color: AppTheme.textMuted),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Aucun fichier joint pour le moment (Optionnel)',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text('Cliquez sur "Téléverser un fichier" pour joindre un sujet PDF ou un énoncé.', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                ],
                              ),
                            )
                          else
                            Column(
                              children: [
                                for (int i = 0; i < _attachments.length; i++)
                                  _buildAttachmentTile(_attachments[i], i),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Allowed Submission Types
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Modes de rendu autorisés pour les apprenants :',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.ink),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 16,
                            runSpacing: 10,
                            children: [
                              _buildCheckbox('📄 Page blanche numérique (éditeur)', _allowBlankPage, (v) {
                                setState(() => _allowBlankPage = v ?? true);
                              }),
                              _buildCheckbox('📷 Copie manuscrite (photo de feuille)', _allowPhotoSheet, (v) {
                                setState(() => _allowPhotoSheet = v ?? true);
                              }),
                              _buildCheckbox('📁 Document Word / PDF / Archive ZIP', _allowWordDocument, (v) {
                                setState(() => _allowWordDocument = v ?? true);
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Divider(height: 1, color: AppTheme.cardBorder),
            const SizedBox(height: 16),

            // Actions Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler', style: TextStyle(color: AppTheme.textMuted)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emeraldGreenDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _isPublishing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const StudioSvgIcon(iconKey: StudioSvgIcon.send, size: 18, color: Colors.white),
                  label: Text(
                    _isPublishing ? 'Publication en cours...' : 'Assigner & Notifier les apprenants',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  onPressed: _isPublishing ? null : _publish,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
      backgroundColor: Colors.white,
      side: const BorderSide(color: AppTheme.emeraldGreen),
      onPressed: onTap,
    );
  }

  Widget _buildQuickDayPreset(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
      ),
    );
  }

  Widget _buildTagInsertButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppTheme.paleMint,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.emeraldGreenDark)),
      ),
    );
  }

  Widget _buildAttachmentTile(_UploadedAttachment att, int index) {
    final color = FileDownloadHelper.getFileColor(att.name);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withAlpha(30),
            child: StudioSvgIcon(iconKey: StudioSvgIcon.file, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  att.name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (att.sizeBytes > 0)
                  Text(
                    FileDownloadHelper.formatFileSize(att.sizeBytes),
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  )
                else
                  const Text('Lien web externe', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),
          IconButton(
            icon: const StudioSvgIcon(iconKey: StudioSvgIcon.download, size: 18, color: AppTheme.emeraldGreenDark),
            tooltip: 'Tester le téléchargement',
            onPressed: () => FileDownloadHelper.downloadOrOpenFile(att.url, fileName: att.name),
          ),
          IconButton(
            icon: const StudioSvgIcon(iconKey: StudioSvgIcon.trash, size: 18, color: Color(0xFFEF4444)),
            tooltip: 'Supprimer',
            onPressed: () {
              setState(() => _attachments.removeAt(index));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCheckbox(String label, bool value, ValueChanged<bool?> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          activeColor: AppTheme.emeraldGreenDark,
          onChanged: onChanged,
        ),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.ink)),
      ],
    );
  }
}
