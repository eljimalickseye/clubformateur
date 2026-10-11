import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/course_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/course_service.dart';
import '../../services/system_log_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/studio_svg_icon.dart';
import '../../widgets/video_preview_dialog.dart';

class CourseCreationStudioScreen extends StatefulWidget {
  final CourseModel? existingCourse;

  const CourseCreationStudioScreen({super.key, this.existingCourse});

  @override
  State<CourseCreationStudioScreen> createState() => _CourseCreationStudioScreenState();
}

class _CourseCreationStudioScreenState extends State<CourseCreationStudioScreen> {
  final AuthService _authService = AuthService();
  final CourseService _courseService = CourseService();

  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _coverUrlCtrl = TextEditingController();
  final TextEditingController _presentationVideoCtrl = TextEditingController();
  final TextEditingController _objectiveInputCtrl = TextEditingController();

  String _category = 'Informatique & Tech';
  String _level = 'Tous niveaux';
  List<String> _objectives = [];
  List<CourseModule> _modules = [];
  bool _isSaving = false;
  int _selectedTemplateIndex = 0;

  final List<String> _categories = [
    'Informatique & Tech',
    'Marketing & Digital',
    'Design & Multimédia',
    'Business',
    'Langues',
    'Développement personnel',
    'Sciences & Mathématiques',
    'Autre'
  ];

  final List<String> _levels = [
    'Débutant',
    'Intermédiaire',
    'Avancé',
    'Tous niveaux'
  ];

  // ==========================================
  // MODÈLES TYPES PRÉ-REMPLIS (EXEMPLES CLÉS EN MAIN)
  // ==========================================
  static final List<_CourseExampleTemplate> _templates = [
    _CourseExampleTemplate(
      label: '💻 Dév Mobile (Flutter)',
      category: 'Informatique & Tech',
      level: 'Intermédiaire',
      price: 35000,
      title: 'Formation Complète Flutter & Firebase : De Zéro à Développeur Pro',
      description: 'Apprenez à concevoir, coder et déployer des applications mobiles iOS et Android natives. De la maîtrise des widgets au backend Firebase temps réel et à la publication sur les stores.',
      coverUrl: 'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=800',
      presentationVideoUrl: 'https://www.youtube.com/watch?v=1xipg02Wu8s',
      objectives: [
        'Maîtriser le langage Dart et l\'architecture Flutter (Stateful & Stateless)',
        'Connecter une base de données Firebase Firestore temps réel et l\'authentification',
        'Gérer l\'état applicatif avec Provider et consommer des APIs REST',
        'Générer et publier son application sur le Google Play Store',
      ],
      modules: [
        CourseModule(
          id: 'm_fl_1',
          title: 'Module 1 — Fondations de Dart & Architecture Flutter',
          description: 'Prise en main des concepts essentiels et des premiers widgets visuels.',
          lessonsCount: 3,
          duration: '46 min',
          lessons: [
            CourseLesson(
              id: 'l_fl_1',
              title: '1. Introduction à Flutter et environnement VS Code',
              duration: '12:30',
              videoUrl: 'https://www.youtube.com/watch?v=1xipg02Wu8s',
              description: 'Installation du SDK et premier lancement sur simulateur.',
              isFreePreview: true,
              order: 1,
            ),
            CourseLesson(
              id: 'l_fl_2',
              title: '2. Les bases du langage Dart (Variables, Fonctions, POO)',
              duration: '18:45',
              videoUrl: 'https://www.youtube.com/watch?v=1xipg02Wu8s',
              description: 'Syntaxe moderne de Dart et typage fort.',
              isFreePreview: false,
              order: 2,
            ),
            CourseLesson(
              id: 'l_fl_3',
              title: '3. Construire des interfaces avec Column, Row et Container',
              duration: '15:20',
              videoUrl: 'https://www.youtube.com/watch?v=1xipg02Wu8s',
              description: 'Mise en page réactive et bonnes pratiques UI.',
              isFreePreview: false,
              order: 3,
            ),
          ],
        ),
        CourseModule(
          id: 'm_fl_2',
          title: 'Module 2 — Dynamisme, État & Connexion Cloud Firestore',
          description: 'Rendre son application vivante et persistante en ligne.',
          lessonsCount: 3,
          duration: '67 min',
          lessons: [
            CourseLesson(
              id: 'l_fl_4',
              title: '4. Gestion d\'état avec Provider et ChangeNotifier',
              duration: '22:10',
              videoUrl: 'https://www.youtube.com/watch?v=1xipg02Wu8s',
              description: 'Séparation propre de la logique métier et de la vue.',
              isFreePreview: false,
              order: 1,
            ),
            CourseLesson(
              id: 'l_fl_5',
              title: '5. Authentification Firebase (Email, Mot de passe sécurisé)',
              duration: '20:30',
              videoUrl: 'https://www.youtube.com/watch?v=1xipg02Wu8s',
              description: 'Sécurisation des accès et gestion de session utilisateur.',
              isFreePreview: false,
              order: 2,
            ),
            CourseLesson(
              id: 'l_fl_6',
              title: '6. Synchronisation temps réel avec Cloud Firestore',
              duration: '25:00',
              videoUrl: 'https://www.youtube.com/watch?v=1xipg02Wu8s',
              description: 'CRUD complet, requêtes filtrées et snapshots réactifs.',
              isFreePreview: false,
              order: 3,
            ),
          ],
        ),
        CourseModule(
          id: 'm_fl_3',
          title: 'Module 3 — Projet Final & Déploiement Store',
          description: 'Création d\'une application Marketplace complète et compilation finale.',
          lessonsCount: 2,
          duration: '51 min',
          lessons: [
            CourseLesson(
              id: 'l_fl_7',
              title: '7. Projet guidé : Application Marketplace complète',
              duration: '34:20',
              videoUrl: 'https://www.youtube.com/watch?v=1xipg02Wu8s',
              description: 'Assemblage final de toutes les notions abordées.',
              isFreePreview: false,
              order: 1,
            ),
            CourseLesson(
              id: 'l_fl_8',
              title: '8. Build de production APK/AAB et publication',
              duration: '16:40',
              videoUrl: 'https://www.youtube.com/watch?v=1xipg02Wu8s',
              description: 'Signature des clés et préparation du déploiement Google Play.',
              isFreePreview: false,
              order: 2,
            ),
          ],
        ),
      ],
    ),
    _CourseExampleTemplate(
      label: '📈 Marketing & E-Commerce',
      category: 'Marketing & Digital',
      level: 'Tous niveaux',
      price: 25000,
      title: 'Marketing Digital & Stratégie Publicitaire Facebook / TikTok Ads',
      description: 'Guide pratique pour acquérir des clients qualifiés et vendre en continu grâce aux réseaux sociaux et à la publicité ciblée en Afrique francophone.',
      coverUrl: 'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=800',
      presentationVideoUrl: 'https://www.youtube.com/watch?v=1xipg02Wu8s',
      objectives: [
        'Définir son client idéal (Persona) et structurer une offre irrésistible',
        'Configurer le Business Manager Meta, le Pixel et les comptes publicitaires',
        'Lancer des campagnes rentables sur TikTok et Facebook adaptées au marché local',
        'Optimiser la conversion WhatsApp Business et le closing de ventes',
      ],
      modules: [
        CourseModule(
          id: 'm_mkt_1',
          title: 'Module 1 — Stratégie d\'Offre & Positionnement',
          description: 'Comprendre son marché et créer une proposition irrésistible.',
          lessonsCount: 2,
          duration: '33 min',
          lessons: [
            CourseLesson(
              id: 'l_mkt_1',
              title: '1. Comment trouver un produit gagnant et définir son offre',
              duration: '14:15',
              videoUrl: 'https://www.youtube.com/watch?v=1xipg02Wu8s',
              description: 'Analyse de la demande et différenciation concurrentielle.',
              isFreePreview: true,
              order: 1,
            ),
            CourseLesson(
              id: 'l_mkt_2',
              title: '2. Créer un tunnel de vente simplifié orienté WhatsApp',
              duration: '19:30',
              videoUrl: 'https://www.youtube.com/watch?v=1xipg02Wu8s',
              description: 'Méthode directe pour capturer des prospects et convertir.',
              isFreePreview: false,
              order: 2,
            ),
          ],
        ),
        CourseModule(
          id: 'm_mkt_2',
          title: 'Module 2 — Lancement des Publicités Meta & TikTok',
          description: 'Paramétrage des campagnes payantes et ciblage d\'audience.',
          lessonsCount: 2,
          duration: '52 min',
          lessons: [
            CourseLesson(
              id: 'l_mkt_3',
              title: '3. Paramétrer le Business Manager et créer ses visuels vidéos',
              duration: '24:00',
              videoUrl: 'https://www.youtube.com/watch?v=1xipg02Wu8s',
              description: 'Formats publicitaires qui convertissent sur smartphone.',
              isFreePreview: false,
              order: 1,
            ),
            CourseLesson(
              id: 'l_mkt_4',
              title: '4. Créer et cibler sa première campagne rentable',
              duration: '28:45',
              videoUrl: 'https://www.youtube.com/watch?v=1xipg02Wu8s',
              description: 'Optimisation du budget publicitaire et des centres d\'intérêt.',
              isFreePreview: false,
              order: 2,
            ),
          ],
        ),
      ],
    ),
    _CourseExampleTemplate(
      label: '📐 Mathématiques (L1/L2)',
      category: 'Sciences & Mathématiques',
      level: 'Intermédiaire',
      price: 20000,
      title: 'Mathématiques Supérieures : Analyse Réelle & Algèbre Linéaire',
      description: 'Cours magistraux et travaux dirigés corrigés pour valider ses semestres universitaires : suites numériques, intégrales, espaces vectoriels et diagonalisation.',
      coverUrl: 'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=800',
      presentationVideoUrl: 'https://www.youtube.com/watch?v=1xipg02Wu8s',
      objectives: [
        'Maîtriser les limites de suites et la continuité des fonctions réelles',
        'Calculer les intégrales définies par parties et changements de variable',
        'Résoudre les systèmes linéaires et calculer le rang d\'une matrice',
        'Diagonaliser des endomorphismes et trouver valeurs et vecteurs propres',
      ],
      modules: [
        CourseModule(
          id: 'm_math_1',
          title: 'Module 1 — Analyse : Limites, Dérivées et Intégrales',
          description: 'Fondations de l\'analyse mathématique pour étudiants scientifiques.',
          lessonsCount: 2,
          duration: '55 min',
          lessons: [
            CourseLesson(
              id: 'l_math_1',
              title: '1. Rappels sur les suites numériques et théorèmes de convergence',
              duration: '25:00',
              videoUrl: 'https://www.youtube.com/watch?v=1xipg02Wu8s',
              description: 'Suites monotones bornées et théorèmes de comparaison.',
              isFreePreview: true,
              order: 1,
            ),
            CourseLesson(
              id: 'l_math_2',
              title: '2. Intégration par parties et changements de variable usuels',
              duration: '30:15',
              videoUrl: 'https://www.youtube.com/watch?v=1xipg02Wu8s',
              description: 'Techniques de calcul intégral avec exemples d\'examens.',
              isFreePreview: false,
              order: 2,
            ),
          ],
        ),
        CourseModule(
          id: 'm_math_2',
          title: 'Module 2 — Algèbre Linéaire : Espaces Vectoriels & Matrices',
          description: 'Structure d\'espaces vectoriels et manipulation matricielle.',
          lessonsCount: 2,
          duration: '60 min',
          lessons: [
            CourseLesson(
              id: 'l_math_3',
              title: '3. Sous-espaces vectoriels, bases et dimension finie',
              duration: '28:00',
              videoUrl: 'https://www.youtube.com/watch?v=1xipg02Wu8s',
              description: 'Définitions fondamentales, liberté et génération.',
              isFreePreview: false,
              order: 1,
            ),
            CourseLesson(
              id: 'l_math_4',
              title: '4. Calcul matriciel : Déterminant, inverse et pivot de Gauss',
              duration: '32:20',
              videoUrl: 'https://www.youtube.com/watch?v=1xipg02Wu8s',
              description: 'Résolution de systèmes 3x3 et 4x4 pas à pas.',
              isFreePreview: false,
              order: 2,
            ),
          ],
        ),
      ],
    ),
    _CourseExampleTemplate(
      label: '🎨 UI/UX Design (Figma)',
      category: 'Design & Multimédia',
      level: 'Débutant',
      price: 30000,
      title: 'UI/UX Design Professionnel : De la Recherche au Prototype Figma',
      description: 'Devenez designer d\'interfaces recherché : règles ergonomiques, typographie, design systems et maquettes interactives prêtes pour les développeurs.',
      coverUrl: 'https://images.unsplash.com/photo-1581291518857-4e27b48ff24e?w=800',
      presentationVideoUrl: 'https://www.youtube.com/watch?v=1xipg02Wu8s',
      objectives: [
        'Comprendre les principes UX fondamentaux (Wireframes, User Flow)',
        'Maîtriser l\'outil Figma (Auto-layout, Composants, Styles globaux)',
        'Concevoir un Design System complet et cohérent',
        'Animer des prototypes interactifs et préparer le handoff développeur',
      ],
      modules: [
        CourseModule(
          id: 'm_ux_1',
          title: 'Module 1 — Fondements UX et Prise en main de Figma',
          description: 'Découverte des concepts d\'ergonomie et de l\'interface Figma.',
          lessonsCount: 2,
          duration: '37 min',
          lessons: [
            CourseLesson(
              id: 'l_ux_1',
              title: '1. Qu\'est-ce qu\'une bonne expérience utilisateur ? (Principes UX)',
              duration: '16:40',
              videoUrl: 'https://www.youtube.com/watch?v=1xipg02Wu8s',
              description: 'Heuristiques de Nielsen et psychologie de l\'utilisateur.',
              isFreePreview: true,
              order: 1,
            ),
            CourseLesson(
              id: 'l_ux_2',
              title: '2. Découverte de l\'interface Figma et des raccourcis essentiels',
              duration: '21:10',
              videoUrl: 'https://www.youtube.com/watch?v=1xipg02Wu8s',
              description: 'Frames, formes géométriques, alignements et navigation.',
              isFreePreview: false,
              order: 2,
            ),
          ],
        ),
        CourseModule(
          id: 'm_ux_2',
          title: 'Module 2 — Auto-Layout, Composants & Variantes',
          description: 'Création d\'interfaces modulaires et réactives.',
          lessonsCount: 2,
          duration: '50 min',
          lessons: [
            CourseLesson(
              id: 'l_ux_3',
              title: '3. Maîtriser l\'Auto-Layout pour des maquettes responsive',
              duration: '26:30',
              videoUrl: 'https://www.youtube.com/watch?v=1xipg02Wu8s',
              description: 'Gestion des espacements automatiques et du redimensionnement.',
              isFreePreview: false,
              order: 1,
            ),
            CourseLesson(
              id: 'l_ux_4',
              title: '4. Créer un Design System complet avec Variants',
              duration: '24:15',
              videoUrl: 'https://www.youtube.com/watch?v=1xipg02Wu8s',
              description: 'Boutons avec états hover/active, champs et typographie.',
              isFreePreview: false,
              order: 2,
            ),
          ],
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingCourse != null) {
      final c = widget.existingCourse!;
      _titleCtrl.text = c.title;
      _priceCtrl.text = c.price.toString();
      _descCtrl.text = c.description;
      _coverUrlCtrl.text = c.image;
      _presentationVideoCtrl.text = c.presentationVideoUrl ?? '';
      _category = _categories.contains(c.category) ? c.category : _categories.first;
      _level = _levels.contains(c.level) ? c.level : _levels.last;
      _objectives = List.from(c.whatYouWillLearn);
      _modules = List.from(c.modules);
    } else {
      // Par défaut pour une nouvelle formation : charger automatiquement le premier exemple type
      // afin que le formateur ait des exemples concrets et un modèle structuré sous les yeux !
      _applyTemplate(_templates.first, updateState: false);
    }
  }

  void _applyTemplate(_CourseExampleTemplate t, {bool updateState = true}) {
    void apply() {
      _titleCtrl.text = t.title;
      _priceCtrl.text = t.price.toString();
      _descCtrl.text = t.description;
      _coverUrlCtrl.text = t.coverUrl;
      _presentationVideoCtrl.text = t.presentationVideoUrl;
      _category = t.category;
      _level = t.level;
      _objectives = List.from(t.objectives);
      _modules = t.modules.map((m) => m.copyWith(
        id: 'm_${DateTime.now().millisecondsSinceEpoch}_${m.id}',
        lessons: m.lessons.map((l) => l.copyWith(id: 'l_${DateTime.now().millisecondsSinceEpoch}_${l.id}')).toList(),
      )).toList();
    }

    if (updateState) {
      setState(() {
        apply();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✨ Modèle "${t.label}" chargé avec succès ! Vous pouvez le personnaliser.'),
          backgroundColor: AppTheme.emeraldGreenDark,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      apply();
    }
  }

  void _clearToBlank() {
    setState(() {
      _titleCtrl.clear();
      _priceCtrl.text = '25000';
      _descCtrl.clear();
      _coverUrlCtrl.clear();
      _presentationVideoCtrl.clear();
      _objectives.clear();
      _modules.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Canevas vierge réinitialisé. À vous de jouer !'),
        backgroundColor: Colors.black87,
      ),
    );
  }

  int get _totalLessonsCount {
    return _modules.fold(0, (sum, m) => sum + m.lessons.length);
  }

  String get _calculatedDuration {
    int totalMinutes = 0;
    for (final m in _modules) {
      for (final l in m.lessons) {
        final parts = l.duration.split(':');
        if (parts.length >= 2) {
          final mins = int.tryParse(parts[0]) ?? 10;
          totalMinutes += mins;
        } else {
          totalMinutes += 15;
        }
      }
    }
    if (totalMinutes == 0) return '${_modules.length * 30} min';
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (h > 0) {
      return '${h}h ${m > 0 ? '${m}m' : ''}';
    }
    return '$m min';
  }

  bool get _hasFreePreview {
    for (final m in _modules) {
      for (final l in m.lessons) {
        if (l.isFreePreview) return true;
      }
    }
    return false;
  }

  void _addObjective() {
    final text = _objectiveInputCtrl.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _objectives.add(text);
        _objectiveInputCtrl.clear();
      });
    }
  }

  void _removeObjective(int index) {
    setState(() {
      _objectives.removeAt(index);
    });
  }

  // Dupliquer une leçon dans le même module
  void _duplicateLesson(int moduleIndex, int lessonIndex) {
    final original = _modules[moduleIndex].lessons[lessonIndex];
    final copy = original.copyWith(
      id: 'l_${DateTime.now().millisecondsSinceEpoch}',
      title: '${original.title} (Copie)',
      order: _modules[moduleIndex].lessons.length + 1,
    );
    setState(() {
      _modules[moduleIndex].lessons.insert(lessonIndex + 1, copy);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Leçon "${original.title}" dupliquée.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Déplacer une leçon vers le haut
  void _moveLessonUp(int moduleIndex, int lessonIndex) {
    if (lessonIndex > 0) {
      setState(() {
        final l = _modules[moduleIndex].lessons.removeAt(lessonIndex);
        _modules[moduleIndex].lessons.insert(lessonIndex - 1, l);
      });
    }
  }

  // Déplacer une leçon vers le bas
  void _moveLessonDown(int moduleIndex, int lessonIndex) {
    if (lessonIndex < _modules[moduleIndex].lessons.length - 1) {
      setState(() {
        final l = _modules[moduleIndex].lessons.removeAt(lessonIndex);
        _modules[moduleIndex].lessons.insert(lessonIndex + 1, l);
      });
    }
  }

  Future<void> _saveCourse({required bool isDraft}) async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le titre de la formation est requis'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    if (_modules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez ajouter au moins une section avec ses leçons'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final user = _authService.currentUser ?? UserModel.demoTeacher;
      final courseId = widget.existingCourse?.id ?? 'course_${DateTime.now().millisecondsSinceEpoch}';

      String coverUrl = _coverUrlCtrl.text.trim().isNotEmpty
          ? _coverUrlCtrl.text.trim()
          : (widget.existingCourse?.image ?? 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=800');

      String? presentationVideoUrl = _presentationVideoCtrl.text.trim().isNotEmpty
          ? _presentationVideoCtrl.text.trim()
          : widget.existingCourse?.presentationVideoUrl;

      final flatLessons = _modules.expand((m) => m.lessons).toList();

      final course = CourseModel(
        id: courseId,
        title: title,
        trainerName: user.displayName,
        trainerAvatar: user.photoUrl ?? 'assets/images/student-man.jpeg',
        trainerRole: 'Formateur Expert',
        category: _category,
        price: int.tryParse(_priceCtrl.text.trim()) ?? 25000,
        originalPrice: 0,
        rating: widget.existingCourse?.rating ?? 5.0,
        reviewsCount: widget.existingCourse?.reviewsCount ?? 0,
        studentsCount: widget.existingCourse?.studentsCount ?? 0,
        image: coverUrl,
        duration: _calculatedDuration,
        lessonsCount: flatLessons.length,
        level: _level,
        isPopular: true,
        description: _descCtrl.text.trim(),
        whatYouWillLearn: _objectives,
        teacherId: user.uid,
        isPublished: !isDraft,
        publicationStatus: isDraft ? 'Brouillon' : 'Publiée',
        presentationVideoUrl: presentationVideoUrl,
        modules: _modules,
        flatLessons: flatLessons,
      );

      if (widget.existingCourse == null) {
        await _courseService.createCourse(course);
      } else {
        await _courseService.updateCourse(course);
      }

      // Log d'audit
      await SystemLogService().logEvent(
        action: isDraft ? 'Brouillon de formation enregistré' : 'Formation publiée',
        details: 'Formation "$title" (${_modules.length} sections, ${flatLessons.length} leçons).',
        category: 'course',
        level: 'success',
        actorName: user.displayName,
        actorRole: 'Formateur',
        metadata: {
          'courseId': courseId,
          'prix': '${course.price} FCFA',
          'sections': _modules.length,
          'lecons': flatLessons.length,
        },
      );

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isDraft ? 'Brouillon sauvegardé avec succès !' : '🎉 Formation publiée avec succès !'),
          backgroundColor: AppTheme.emeraldGreenDark,
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sauvegarde: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // Section Management Dialog
  void _showSectionDialog({int? editIndex}) {
    final isEdit = editIndex != null;
    final titleCtrl = TextEditingController(text: isEdit ? _modules[editIndex].title : '');
    final descCtrl = TextEditingController(text: isEdit ? _modules[editIndex].description : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const StudioSvgIcon(iconKey: StudioSvgIcon.folder, color: AppTheme.emeraldGreenDark, size: 22),
            const SizedBox(width: 10),
            Text(isEdit ? 'Modifier la section' : 'Nouvelle section / module',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Titre de la section *',
                  hintText: 'Ex: Module 1 — Fondations et notions clés',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description de la section (optionnel)',
                  hintText: 'Ce que l\'étudiant va voir dans cette partie...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emeraldGreenDark,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final t = titleCtrl.text.trim();
              if (t.isEmpty) return;

              setState(() {
                if (isEdit) {
                  final old = _modules[editIndex];
                  _modules[editIndex] = old.copyWith(title: t, description: descCtrl.text.trim());
                } else {
                  _modules.add(CourseModule(
                    id: 'm_${DateTime.now().millisecondsSinceEpoch}',
                    title: t,
                    description: descCtrl.text.trim(),
                    lessonsCount: 0,
                    duration: '0 min',
                    lessons: [],
                  ));
                }
              });
              Navigator.pop(ctx);
            },
            child: Text(isEdit ? 'Enregistrer' : 'Créer la section'),
          ),
        ],
      ),
    );
  }

  // Lesson Management Dialog avec exemples de leçons intégrés
  void _showLessonDialog({required int moduleIndex, int? editLessonIndex}) {
    final isEdit = editLessonIndex != null;
    final existing = isEdit ? _modules[moduleIndex].lessons[editLessonIndex] : null;

    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final durationCtrl = TextEditingController(text: existing?.duration ?? '15:00');
    final urlCtrl = TextEditingController(
      text: existing?.videoUrl ?? 'https://www.youtube.com/watch?v=1xipg02Wu8s',
    );
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    bool isFreePreview = existing?.isFreePreview ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              const StudioSvgIcon(iconKey: StudioSvgIcon.video, color: AppTheme.emeraldGreenDark, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isEdit ? 'Modifier la leçon' : 'Ajouter une leçon vidéo',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exemples de titres de leçons en 1 clic
                  if (!isEdit) ...[
                    Row(
                      children: [
                        const StudioSvgIcon(iconKey: StudioSvgIcon.sparkles, color: Color(0xFFF59E0B), size: 14),
                        const SizedBox(width: 6),
                        Text('Idées de leçons types :', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.ink)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildLessonSuggestionChip(
                            label: '🎯 Introduction & Objectifs',
                            onTap: () {
                              setDialogState(() {
                                titleCtrl.text = '1. Introduction et vue d\'ensemble';
                                durationCtrl.text = '10:00';
                                descCtrl.text = 'Présentation des concepts clés et du déroulement de la session.';
                                isFreePreview = true;
                              });
                            },
                          ),
                          _buildLessonSuggestionChip(
                            label: '⚙️ Configuration & Outils',
                            onTap: () {
                              setDialogState(() {
                                titleCtrl.text = '2. Installation et paramétrage des outils';
                                durationCtrl.text = '15:00';
                                descCtrl.text = 'Guide pratique pour installer et configurer tout l\'environnement.';
                              });
                            },
                          ),
                          _buildLessonSuggestionChip(
                            label: '💻 Atelier Pratique Pas à Pas',
                            onTap: () {
                              setDialogState(() {
                                titleCtrl.text = '3. Atelier pratique guidé pas à pas';
                                durationCtrl.text = '25:00';
                                descCtrl.text = 'Mise en application immédiate des concepts sur un projet réel.';
                              });
                            },
                          ),
                          _buildLessonSuggestionChip(
                            label: '📝 Exercice d\'Application',
                            onTap: () {
                              setDialogState(() {
                                titleCtrl.text = '4. Exercice pratique et validation';
                                durationCtrl.text = '20:00';
                                descCtrl.text = 'Défi autonome pour ancrer les compétences acquises.';
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Titre de la leçon *',
                      hintText: 'Ex: 1. Présentation des outils indispensables',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: durationCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Durée (mm:ss) *',
                            hintText: '14:30',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: InkWell(
                          onTap: () {
                            final testUrl = urlCtrl.text.trim();
                            if (testUrl.isNotEmpty) {
                              VideoPreviewDialog.show(
                                context,
                                videoUrl: testUrl,
                                title: titleCtrl.text.isNotEmpty ? titleCtrl.text : 'Aperçu vidéo',
                                duration: durationCtrl.text,
                                isFreePreview: isFreePreview,
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppTheme.paleMint,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.mintAccent),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                StudioSvgIcon(iconKey: StudioSvgIcon.play, color: AppTheme.emeraldGreenDark, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'Tester la vidéo',
                                  style: TextStyle(
                                    color: AppTheme.emeraldGreenDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: urlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'URL Vidéo (YouTube / MP4 / Cloud) *',
                      hintText: 'https://www.youtube.com/watch?v=...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notes ou description de la leçon',
                      hintText: 'Points clés abordés dans cette vidéo...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: isFreePreview,
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: AppTheme.emeraldGreenDark,
                    title: Text(
                      'Aperçu gratuit (Leçon découverte)',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    subtitle: const Text(
                      'Permet aux futurs étudiants de visionner cette leçon avant de s\'inscrire.',
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                    onChanged: (val) {
                      setDialogState(() {
                        isFreePreview = val;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emeraldGreenDark,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final t = titleCtrl.text.trim();
                if (t.isEmpty) return;

                final lesson = CourseLesson(
                  id: existing?.id ?? 'l_${DateTime.now().millisecondsSinceEpoch}',
                  title: t,
                  duration: durationCtrl.text.trim().isEmpty ? '10:00' : durationCtrl.text.trim(),
                  videoUrl: urlCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  isFreePreview: isFreePreview,
                  order: isEdit ? existing!.order : _modules[moduleIndex].lessons.length + 1,
                );

                setState(() {
                  if (isEdit) {
                    _modules[moduleIndex].lessons[editLessonIndex] = lesson;
                  } else {
                    _modules[moduleIndex].lessons.add(lesson);
                  }
                });
                Navigator.pop(ctx);
              },
              child: Text(isEdit ? 'Mettre à jour' : 'Ajouter la leçon'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonSuggestionChip({required String label, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFFF1F5F9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: AppTheme.cardBorder),
        onPressed: onTap,
      ),
    );
  }

  // Full Preview Modal for Teacher (Vue Apprenant)
  void _showStudentPreview() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          width: 720,
          constraints: const BoxConstraints(maxHeight: 700),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const StudioSvgIcon(iconKey: StudioSvgIcon.eye, color: AppTheme.emeraldGreenDark, size: 22),
                      const SizedBox(width: 10),
                      Text('Aperçu du cours (Vue Apprenant)',
                          style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  IconButton(
                    icon: const StudioSvgIcon(iconKey: StudioSvgIcon.close, size: 18),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_titleCtrl.text.isNotEmpty ? _titleCtrl.text : 'Titre de la formation',
                          style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.ink)),
                      const SizedBox(height: 6),
                      Text('$_category • $_level • ${_priceCtrl.text} FCFA',
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                      const SizedBox(height: 16),
                      if (_descCtrl.text.isNotEmpty) ...[
                        Text('À propos de cette formation :',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(_descCtrl.text, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
                        const SizedBox(height: 16),
                      ],
                      Text('Programme complet ($_totalLessonsCount leçons • $_calculatedDuration) :',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 12),
                      ..._modules.asMap().entries.map((e) {
                        final mIdx = e.key;
                        final m = e.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.cardBorder),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Section ${mIdx + 1} : ${m.title}',
                                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
                                    Text('${m.lessons.length} leçons',
                                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                  ],
                                ),
                              ),
                              ...m.lessons.asMap().entries.map((lEntry) {
                                final lIdx = lEntry.key;
                                final l = lEntry.value;
                                return ListTile(
                                  dense: true,
                                  leading: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: AppTheme.paleMint,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${lIdx + 1}',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.emeraldGreenDark),
                                      ),
                                    ),
                                  ),
                                  title: Text(l.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  subtitle: l.description.isNotEmpty ? Text(l.description, style: const TextStyle(fontSize: 11)) : null,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (l.isFreePreview)
                                        Container(
                                          margin: const EdgeInsets.only(right: 8),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFDCFCE7),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text('Gratuit',
                                              style: TextStyle(fontSize: 10, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                                        ),
                                      Text(l.duration, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.existingCourse == null ? 'Studio de Création de Formation' : 'Modifier la formation',
          style: GoogleFonts.plusJakartaSans(color: AppTheme.ink, fontWeight: FontWeight.w800, fontSize: 17),
        ),
        actions: [
          TextButton.icon(
            onPressed: _showStudentPreview,
            icon: const StudioSvgIcon(iconKey: StudioSvgIcon.eye, size: 16, color: AppTheme.emeraldGreenDark),
            label: const Text('Aperçu Apprenant', style: TextStyle(color: AppTheme.emeraldGreenDark, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: _isSaving ? null : () => _saveCourse(isDraft: true),
            icon: const StudioSvgIcon(iconKey: StudioSvgIcon.check, size: 16, color: AppTheme.textMuted),
            label: Text('Brouillon', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Summary Banner
                _buildSummaryBanner(),
                const SizedBox(height: 20),

                // BARRE D'EXEMPLES CLÉS EN MAIN (TEMPLATES)
                if (widget.existingCourse == null) ...[
                  _buildTemplatesSelector(),
                  const SizedBox(height: 24),
                ],

                // 1. INFORMATIONS ESSENTIELLES
                _buildSectionHeader('1. INFORMATIONS GÉNÉRALES & TARIF', StudioSvgIcon.info),
                const SizedBox(height: 12),
                _buildGeneralInfoCard(),
                const SizedBox(height: 28),

                // 2. OBJECTIFS DU COURS
                _buildSectionHeader('2. CE QUE L\'ÉTUDIANT VA APPRENDRE', StudioSvgIcon.target),
                const SizedBox(height: 12),
                _buildObjectivesCard(),
                const SizedBox(height: 28),

                // 3. PROGRAMME & LEÇONS COMPLÈTES
                _buildSectionHeader('3. PROGRAMME DÉTAILLÉ & LEÇONS VIDÉO', StudioSvgIcon.video),
                const SizedBox(height: 12),
                _buildCurriculumCard(),
                const SizedBox(height: 28),

                // 4. CHECKLIST DE CONFORMITÉ
                _buildReadinessChecklist(),
                const SizedBox(height: 24),

                // 5. ACTION PUBLICATION
                _buildPublishButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Barre de sélection des modèles types d'exemples
  Widget _buildTemplatesSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const StudioSvgIcon(iconKey: StudioSvgIcon.sparkles, color: Color(0xFFF59E0B), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Modèles types d\'exemples (Clés en main) :',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppTheme.ink),
                  ),
                ],
              ),
              TextButton.icon(
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                icon: const StudioSvgIcon(iconKey: StudioSvgIcon.refresh, size: 13, color: AppTheme.textMuted),
                label: const Text('Canevas vierge', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                onPressed: _clearToBlank,
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Choisissez un modèle prédéfini pour remplir automatiquement le plan, les leçons et les vidéos d\'exemples :',
            style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _templates.asMap().entries.map((entry) {
                final idx = entry.key;
                final t = entry.value;
                final isSelected = _selectedTemplateIndex == idx;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(
                      t.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? Colors.white : AppTheme.ink,
                      ),
                    ),
                    selectedColor: AppTheme.emeraldGreenDark,
                    backgroundColor: const Color(0xFFF1F5F9),
                    side: BorderSide(color: isSelected ? AppTheme.emeraldGreenDark : AppTheme.cardBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    onSelected: (_) {
                      setState(() => _selectedTemplateIndex = idx);
                      _applyTemplate(t);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF062C32), Color(0xFF0E4D6E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF062C32).withAlpha(50),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.existingCourse?.publicationStatus ?? 'Nouveau cours',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$_category • $_level',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _titleCtrl.text.isNotEmpty ? _titleCtrl.text : 'Titre de votre formation',
                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.emeraldGreenDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_priceCtrl.text.isNotEmpty ? _priceCtrl.text : '25000'} FCFA',
                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricItem(StudioSvgIcon.folder, '${_modules.length}', 'Sections'),
              _buildMetricItem(StudioSvgIcon.video, '$_totalLessonsCount', 'Leçons vidéo'),
              _buildMetricItem(StudioSvgIcon.clock, _calculatedDuration, 'Durée totale'),
              _buildMetricItem(StudioSvgIcon.target, '${_objectives.length}', 'Compétences'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String iconKey, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StudioSvgIcon(iconKey: iconKey, color: AppTheme.mintAccent, size: 15),
            const SizedBox(width: 6),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String iconKey) {
    return Row(
      children: [
        StudioSvgIcon(iconKey: iconKey, size: 18, color: AppTheme.emeraldGreenDark),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppTheme.emeraldGreenDark, letterSpacing: 0.5),
        ),
      ],
    );
  }

  Widget _buildGeneralInfoCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleCtrl,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Titre de la formation *',
              hintText: 'Ex: Algèbre linéaire & Calcul matriciel avancé',
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Catégorie *'),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) => setState(() => _category = v!),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _level,
                  decoration: const InputDecoration(labelText: 'Niveau d\'étude *'),
                  items: _levels.map((l) => DropdownMenuItem(value: l, child: Text(l, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) => setState(() => _level = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _priceCtrl,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Frais d\'inscription / Prix de la formation (FCFA) *',
              hintText: 'Ex: 25000',
              suffixText: 'FCFA',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description complète de la formation',
              hintText: 'Présentez la valeur pédagogique, les prérequis et ce que l\'étudiant va acquérir...',
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _coverUrlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Image de couverture (URL)',
                    hintText: 'https://images.unsplash.com/...',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (_coverUrlCtrl.text.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _coverUrlCtrl.text,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 48,
                      height: 48,
                      color: const Color(0xFFF1F5F9),
                      child: const Center(child: StudioSvgIcon(iconKey: StudioSvgIcon.eye, color: AppTheme.textMuted, size: 20)),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _presentationVideoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Vidéo d\'introduction / Teaser (URL YouTube ou MP4)',
                    hintText: 'https://www.youtube.com/watch?v=...',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const StudioSvgIcon(iconKey: StudioSvgIcon.playFilled, color: AppTheme.emeraldGreenDark, size: 28),
                tooltip: 'Tester la vidéo d\'introduction',
                onPressed: () {
                  final url = _presentationVideoCtrl.text.trim();
                  if (url.isNotEmpty) {
                    VideoPreviewDialog.show(
                      context,
                      videoUrl: url,
                      title: 'Vidéo de présentation du cours',
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildObjectivesCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _objectiveInputCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Ajouter une compétence ou un objectif pédagogique',
                    hintText: 'Ex: Savoir résoudre un système matriciel 3x3',
                  ),
                  onSubmitted: (_) => _addObjective(),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emeraldGreenDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onPressed: _addObjective,
                icon: const StudioSvgIcon(iconKey: StudioSvgIcon.plus, size: 16, color: Colors.white),
                label: const Text('Ajouter'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_objectives.isEmpty)
            const Text(
              'Aucun objectif renseigné pour l\'instant.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            )
          else
            Column(
              children: _objectives.asMap().entries.map((entry) {
                final idx = entry.key;
                final obj = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const StudioSvgIcon(iconKey: StudioSvgIcon.check, color: AppTheme.emeraldGreenDark, size: 16),
                      const SizedBox(width: 10),
                      Expanded(child: Text(obj, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                      IconButton(
                        icon: const StudioSvgIcon(iconKey: StudioSvgIcon.close, size: 14, color: Colors.redAccent),
                        onPressed: () => _removeObjective(idx),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildCurriculumCard() {
    return Container(
      padding: const EdgeInsets.all(22),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Structure des sections & leçons', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('${_modules.length} modules • $_totalLessonsCount leçons au total',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showSectionDialog(),
                icon: const StudioSvgIcon(iconKey: StudioSvgIcon.plus, size: 16, color: Colors.white),
                label: const Text('Ajouter une section'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emeraldGreenDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_modules.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: Column(
                  children: [
                    const StudioSvgIcon(iconKey: StudioSvgIcon.folder, size: 44, color: AppTheme.textMuted),
                    const SizedBox(height: 12),
                    Text('Aucune section dans cette formation',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: AppTheme.ink)),
                    const SizedBox(height: 4),
                    const Text('Cliquez sur "Ajouter une section" ci-dessus ou choisissez un modèle clé en main.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  ],
                ),
              ),
            )
          else
            Column(
              children: _modules.asMap().entries.map((mEntry) {
                final mIdx = mEntry.key;
                final module = mEntry.value;
                return _buildModuleCard(mIdx, module);
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildModuleCard(int mIdx, CourseModule module) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de la section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.paleMint,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Section ${mIdx + 1}',
                    style: const TextStyle(color: AppTheme.emeraldGreenDark, fontWeight: FontWeight.w800, fontSize: 11),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        module.title,
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.ink),
                      ),
                      if (module.description.isNotEmpty)
                        Text(
                          module.description,
                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                    ],
                  ),
                ),
                Text(
                  '${module.lessons.length} leçons',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const StudioSvgIcon(iconKey: StudioSvgIcon.edit, size: 16, color: AppTheme.emeraldGreenDark),
                  tooltip: 'Modifier la section',
                  onPressed: () => _showSectionDialog(editIndex: mIdx),
                ),
                IconButton(
                  icon: const StudioSvgIcon(iconKey: StudioSvgIcon.trash, size: 16, color: Colors.redAccent),
                  tooltip: 'Supprimer la section',
                  onPressed: () {
                    setState(() {
                      _modules.removeAt(mIdx);
                    });
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Liste des leçons (sans duplication d'icônes !)
          if (module.lessons.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Aucune leçon vidéo dans cette section pour le moment.',
                  style: TextStyle(color: AppTheme.textMuted.withAlpha(180), fontSize: 12),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: module.lessons.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
              itemBuilder: (context, lIdx) {
                final lesson = module.lessons[lIdx];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  // Pastille numérique unique à gauche (aucune duplication d'icône play)
                  leading: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppTheme.paleMint,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '#${lIdx + 1}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emeraldGreenDark, fontSize: 11),
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          lesson.title,
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                      if (lesson.isFreePreview)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Aperçu gratuit',
                              style: TextStyle(fontSize: 10, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    'Durée : ${lesson.duration} ${lesson.description.isNotEmpty ? '• ${lesson.description}' : ''}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Actions à droite : 1 seul bouton Tester (SVG Play), réordonner, modifier, supprimer
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tester vidéo
                      IconButton(
                        icon: const StudioSvgIcon(iconKey: StudioSvgIcon.play, color: AppTheme.emeraldGreenDark, size: 18),
                        tooltip: 'Tester la vidéo',
                        onPressed: () {
                          VideoPreviewDialog.show(
                            context,
                            videoUrl: lesson.videoUrl,
                            title: lesson.title,
                            duration: lesson.duration,
                            isFreePreview: lesson.isFreePreview,
                          );
                        },
                      ),
                      // Dupliquer leçon
                      IconButton(
                        icon: const StudioSvgIcon(iconKey: StudioSvgIcon.copy, color: AppTheme.textMuted, size: 16),
                        tooltip: 'Dupliquer cette leçon',
                        onPressed: () => _duplicateLesson(mIdx, lIdx),
                      ),
                      // Monter
                      if (lIdx > 0)
                        IconButton(
                          icon: const StudioSvgIcon(iconKey: StudioSvgIcon.arrowUp, color: AppTheme.textMuted, size: 15),
                          tooltip: 'Monter',
                          onPressed: () => _moveLessonUp(mIdx, lIdx),
                        ),
                      // Descendre
                      if (lIdx < module.lessons.length - 1)
                        IconButton(
                          icon: const StudioSvgIcon(iconKey: StudioSvgIcon.arrowDown, color: AppTheme.textMuted, size: 15),
                          tooltip: 'Descendre',
                          onPressed: () => _moveLessonDown(mIdx, lIdx),
                        ),
                      // Modifier
                      IconButton(
                        icon: const StudioSvgIcon(iconKey: StudioSvgIcon.edit, color: AppTheme.ink, size: 16),
                        tooltip: 'Modifier',
                        onPressed: () => _showLessonDialog(moduleIndex: mIdx, editLessonIndex: lIdx),
                      ),
                      // Supprimer
                      IconButton(
                        icon: const StudioSvgIcon(iconKey: StudioSvgIcon.trash, color: Colors.redAccent, size: 16),
                        tooltip: 'Supprimer',
                        onPressed: () {
                          setState(() {
                            module.lessons.removeAt(lIdx);
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),

          // Bouton Ajouter une leçon
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextButton.icon(
              onPressed: () => _showLessonDialog(moduleIndex: mIdx),
              icon: const StudioSvgIcon(iconKey: StudioSvgIcon.plus, size: 14, color: AppTheme.emeraldGreenDark),
              label: Text(
                'Ajouter une leçon dans la Section ${mIdx + 1}',
                style: const TextStyle(color: AppTheme.emeraldGreenDark, fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Checklist de publication en direct
  Widget _buildReadinessChecklist() {
    final titleOk = _titleCtrl.text.trim().length >= 5;
    final modulesOk = _modules.isNotEmpty;
    final lessonsOk = _totalLessonsCount >= 1;
    final priceOk = (int.tryParse(_priceCtrl.text.trim()) ?? 0) > 0;
    final previewOk = _hasFreePreview;

    final allChecks = [titleOk, modulesOk, lessonsOk, priceOk, previewOk];
    final passedCount = allChecks.where((c) => c).length;
    final percentage = (passedCount / allChecks.length * 100).toInt();

    return Container(
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
                  const StudioSvgIcon(iconKey: StudioSvgIcon.check, color: AppTheme.emeraldGreenDark, size: 18),
                  const SizedBox(width: 8),
                  Text('État de préparation du cours ($percentage%)',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.ink)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: percentage == 100 ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  percentage == 100 ? '✅ Prêt à publier' : '⚠️ En cours de saisie',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: percentage == 100 ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildCheckItem('Titre clair (min 5 caractères)', titleOk),
              _buildCheckItem('Au moins 1 section structurée', modulesOk),
              _buildCheckItem('Au moins 1 leçon vidéo ajoutée', lessonsOk),
              _buildCheckItem('Tarif valide en FCFA', priceOk),
              _buildCheckItem('Au moins 1 leçon en aperçu gratuit', previewOk),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String label, bool isOk) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StudioSvgIcon(
          iconKey: isOk ? StudioSvgIcon.check : StudioSvgIcon.info,
          color: isOk ? const Color(0xFF10B981) : AppTheme.textMuted,
          size: 14,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isOk ? FontWeight.w600 : FontWeight.normal,
            color: isOk ? AppTheme.ink : AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildPublishButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : () => _saveCourse(isDraft: false),
        icon: _isSaving
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const StudioSvgIcon(iconKey: StudioSvgIcon.rocket, size: 20, color: Colors.white),
        label: Text(
          _isSaving ? 'Publication en cours...' : '🚀 Publier la formation (Mettre en ligne)',
          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.emeraldGreenDark,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
        ),
      ),
    );
  }
}

class _CourseExampleTemplate {
  final String label;
  final String category;
  final String level;
  final int price;
  final String title;
  final String description;
  final String coverUrl;
  final String presentationVideoUrl;
  final List<String> objectives;
  final List<CourseModule> modules;

  const _CourseExampleTemplate({
    required this.label,
    required this.category,
    required this.level,
    required this.price,
    required this.title,
    required this.description,
    required this.coverUrl,
    required this.presentationVideoUrl,
    required this.objectives,
    required this.modules,
  });
}
