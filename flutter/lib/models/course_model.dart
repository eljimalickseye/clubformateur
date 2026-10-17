import 'package:cloud_firestore/cloud_firestore.dart';

class CourseLiveReplay {
  final String id;
  final String title;
  final String replayUrl;
  final String duration;
  final DateTime date;

  CourseLiveReplay({
    required this.id,
    required this.title,
    required this.replayUrl,
    required this.duration,
    required this.date,
  });

  factory CourseLiveReplay.fromMap(Map<String, dynamic> data, String id) {
    DateTime dt = DateTime.now();
    if (data['date'] is Timestamp) {
      dt = (data['date'] as Timestamp).toDate();
    } else if (data['date'] != null) {
      dt = DateTime.tryParse(data['date'].toString()) ?? DateTime.now();
    }
    return CourseLiveReplay(
      id: id,
      title: data['title'] ?? 'Replay de session live',
      replayUrl: data['replayUrl'] ?? '',
      duration: data['duration'] ?? '45:00',
      date: dt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'replayUrl': replayUrl,
      'duration': duration,
      'date': date.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'title': title,
      'replayUrl': replayUrl,
      'duration': duration,
      'date': Timestamp.fromDate(date),
    };
  }
}

class CourseLesson {
  final String id;
  final String title;
  final String duration;
  final bool isCompleted;
  final String videoUrl;
  final String description;
  final int order;
  final bool isFreePreview;

  CourseLesson({
    required this.id,
    required this.title,
    required this.duration,
    this.isCompleted = false,
    this.videoUrl = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    this.description = '',
    this.order = 1,
    this.isFreePreview = false,
  });

  factory CourseLesson.fromMap(Map<String, dynamic> data, String id) {
    return CourseLesson(
      id: id,
      title: data['title'] ?? 'Leçon',
      duration: data['duration'] ?? '10:00',
      isCompleted: data['isCompleted'] ?? false,
      videoUrl: data['videoUrl'] ?? 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      description: data['description'] ?? '',
      order: (data['order'] as num?)?.toInt() ?? 1,
      isFreePreview: data['isFreePreview'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'duration': duration,
      'isCompleted': isCompleted,
      'videoUrl': videoUrl,
      'description': description,
      'order': order,
      'isFreePreview': isFreePreview,
    };
  }

  CourseLesson copyWith({
    String? id,
    String? title,
    String? duration,
    bool? isCompleted,
    String? videoUrl,
    String? description,
    int? order,
    bool? isFreePreview,
  }) {
    return CourseLesson(
      id: id ?? this.id,
      title: title ?? this.title,
      duration: duration ?? this.duration,
      isCompleted: isCompleted ?? this.isCompleted,
      videoUrl: videoUrl ?? this.videoUrl,
      description: description ?? this.description,
      order: order ?? this.order,
      isFreePreview: isFreePreview ?? this.isFreePreview,
    );
  }
}

class CourseModule {
  final String id;
  final String title;
  final String description;
  final int lessonsCount;
  final String duration;
  final List<CourseLesson> lessons;

  CourseModule({
    required this.id,
    required this.title,
    this.description = '',
    required this.lessonsCount,
    required this.duration,
    required this.lessons,
  });

  factory CourseModule.fromMap(Map<String, dynamic> data, String id) {
    final list = (data['lessons'] is List)
        ? (data['lessons'] as List)
            .map((l) => CourseLesson.fromMap(Map<String, dynamic>.from(l), l['id'] ?? ''))
            .toList()
        : <CourseLesson>[];
    return CourseModule(
      id: id,
      title: data['title'] ?? 'Section',
      description: data['description'] ?? '',
      lessonsCount: (data['lessonsCount'] as num?)?.toInt() ?? list.length,
      duration: data['duration'] ?? '45:00',
      lessons: list,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'lessonsCount': lessons.isNotEmpty ? lessons.length : lessonsCount,
      'duration': duration,
      'lessons': lessons.map((l) => l.toMap()).toList(),
    };
  }

  CourseModule copyWith({
    String? id,
    String? title,
    String? description,
    int? lessonsCount,
    String? duration,
    List<CourseLesson>? lessons,
  }) {
    return CourseModule(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      lessonsCount: lessonsCount ?? this.lessonsCount,
      duration: duration ?? this.duration,
      lessons: lessons ?? this.lessons,
    );
  }
}

class CourseModel {
  final String id;
  final String title;
  final String trainerName;
  final String? trainerAvatar;
  final String trainerRole;
  final String category;
  final int price; // in FCFA
  final int originalPrice;
  final int discountPercent;
  final double rating;
  final int reviewsCount;
  final int studentsCount;
  final String image;
  final String duration;
  final int lessonsCount;
  final String level;
  final bool isPopular;
  final String? badge; // 'Bestseller', 'Populaire', 'Nouveau'
  final String description;
  final List<String> whatYouWillLearn;
  final List<CourseModule> modules;
  final String teacherId;
  final bool isPublished;
  final String publicationStatus; // 'draft' or 'published'
  final String? thumbnailUrl;
  final String? presentationVideoUrl;
  final List<CourseLiveReplay> replays;
  final List<CourseLesson> flatLessons;

  CourseModel({
    required this.id,
    required this.title,
    required this.trainerName,
    this.trainerAvatar,
    this.trainerRole = 'Formateur Expert',
    required this.category,
    required this.price,
    this.originalPrice = 0,
    this.discountPercent = 0,
    required this.rating,
    this.reviewsCount = 0,
    this.studentsCount = 0,
    required this.image,
    required this.duration,
    this.lessonsCount = 0,
    this.level = 'Tous niveaux',
    this.isPopular = false,
    this.badge,
    this.description = '',
    this.whatYouWillLearn = const [],
    this.modules = const [],
    this.teacherId = '',
    this.isPublished = true,
    this.publicationStatus = 'published',
    this.thumbnailUrl,
    this.presentationVideoUrl,
    this.replays = const [],
    this.flatLessons = const [],
  });

  String get formattedPrice {
    final s = price.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(s[i]);
    }
    return '${buffer.toString()} FCFA';
  }

  String get formattedOriginalPrice {
    if (originalPrice <= 0) return '';
    final s = originalPrice.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(s[i]);
    }
    return '${buffer.toString()} FCFA';
  }

  String get trainerId => teacherId;

  factory CourseModel.fromMap(Map<String, dynamic> data, String id) {
    int parseNumToInt(dynamic v, [int fallback = 0]) {
      if (v == null) return fallback;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? fallback;
    }

    double parseNumToDouble(dynamic v, [double fallback = 0.0]) {
      if (v == null) return fallback;
      if (v is double) return v;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? fallback;
    }

    List<String> parseList(dynamic list, [List<String> fallback = const []]) {
      if (list is List) {
        return list.where((e) => e != null).map((e) => e.toString()).toList();
      }
      return fallback;
    }

    return CourseModel(
      id: id,
      title: data['title']?.toString() ?? data['name']?.toString() ?? 'Formation',
      trainerName: data['trainerName']?.toString() ?? data['instructorName']?.toString() ?? data['teacherName']?.toString() ?? 'Formateur Expert',
      trainerAvatar: data['trainerAvatar']?.toString() ?? data['teacherPhoto']?.toString(),
      trainerRole: data['trainerRole']?.toString() ?? 'Formateur Certifié',
      category: data['category']?.toString() ?? 'Informatique',
      price: parseNumToInt(data['price']),
      originalPrice: parseNumToInt(data['originalPrice']),
      discountPercent: parseNumToInt(data['discountPercent']),
      rating: parseNumToDouble(data['rating'], 0.0),
      reviewsCount: parseNumToInt(data['reviewsCount'] ?? data['totalReviews']),
      studentsCount: parseNumToInt(data['studentsCount'] ?? data['enrolledStudentsCount']),
      image: data['image']?.toString() ?? data['thumbnailUrl']?.toString() ?? 'assets/images/student-man.jpeg',
      duration: data['duration']?.toString() ?? 'À votre rythme',
      lessonsCount: parseNumToInt(data['lessonsCount']),
      level: data['level']?.toString() ?? 'Tous niveaux',
      isPopular: data['isPopular'] == true || data['isPopular'] == null,
      badge: data['badge']?.toString(),
      description: data['description']?.toString() ?? '',
      whatYouWillLearn: parseList(data['whatYouWillLearn']),
      teacherId: data['teacherId']?.toString() ?? '',
      isPublished: data['isPublished'] ?? (data['status'] == 'Publiée' || data['status'] == 'published' || true),
      publicationStatus: data['status']?.toString() ?? (data['isPublished'] == false ? 'draft' : 'published'),
      thumbnailUrl: data['thumbnailUrl']?.toString() ?? data['image']?.toString(),
      presentationVideoUrl: data['presentationVideoUrl']?.toString() ?? data['promoVideoUrl']?.toString() ?? data['trailerUrl']?.toString(),
      replays: (data['replays'] is List)
          ? (data['replays'] as List)
              .whereType<Map>()
              .map((r) => CourseLiveReplay.fromMap(Map<String, dynamic>.from(r), r['id']?.toString() ?? ''))
              .toList()
          : [],
      modules: (data['modules'] is List)
          ? (data['modules'] as List)
              .whereType<Map>()
              .map((m) => CourseModule.fromMap(Map<String, dynamic>.from(m), m['id']?.toString() ?? ''))
              .toList()
          : [],
      flatLessons: (data['lessons'] is List && (data['lessons'] as List).isNotEmpty)
          ? (data['lessons'] as List)
              .whereType<Map>()
              .map((l) => CourseLesson.fromMap(Map<String, dynamic>.from(l), l['id']?.toString() ?? ''))
              .toList()
          : ((data['modules'] is List)
              ? (data['modules'] as List)
                  .whereType<Map>()
                  .expand((m) => ((m['lessons'] is List)
                      ? (m['lessons'] as List)
                          .whereType<Map>()
                          .map((l) => CourseLesson.fromMap(Map<String, dynamic>.from(l), l['id']?.toString() ?? ''))
                      : <CourseLesson>[]))
                  .toList()
              : []),
    );
  }


  CourseModel copyWith({
    String? title,
    String? trainerName,
    String? trainerAvatar,
    String? trainerRole,
    String? category,
    int? price,
    int? originalPrice,
    int? discountPercent,
    double? rating,
    int? reviewsCount,
    int? studentsCount,
    String? image,
    String? duration,
    int? lessonsCount,
    String? level,
    bool? isPopular,
    String? badge,
    String? description,
    List<String>? whatYouWillLearn,
    List<CourseModule>? modules,
    String? teacherId,
    bool? isPublished,
    String? publicationStatus,
    String? thumbnailUrl,
    String? presentationVideoUrl,
    List<CourseLiveReplay>? replays,
    List<CourseLesson>? flatLessons,
  }) {
    return CourseModel(
      id: id,
      title: title ?? this.title,
      trainerName: trainerName ?? this.trainerName,
      trainerAvatar: trainerAvatar ?? this.trainerAvatar,
      trainerRole: trainerRole ?? this.trainerRole,
      category: category ?? this.category,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      discountPercent: discountPercent ?? this.discountPercent,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      studentsCount: studentsCount ?? this.studentsCount,
      image: image ?? this.image,
      duration: duration ?? this.duration,
      lessonsCount: lessonsCount ?? this.lessonsCount,
      level: level ?? this.level,
      isPopular: isPopular ?? this.isPopular,
      badge: badge ?? this.badge,
      description: description ?? this.description,
      whatYouWillLearn: whatYouWillLearn ?? this.whatYouWillLearn,
      modules: modules ?? this.modules,
      teacherId: teacherId ?? this.teacherId,
      isPublished: isPublished ?? this.isPublished,
      publicationStatus: publicationStatus ?? this.publicationStatus,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      presentationVideoUrl: presentationVideoUrl ?? this.presentationVideoUrl,
      replays: replays ?? this.replays,
      flatLessons: flatLessons ?? this.flatLessons,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'trainerName': trainerName,
      'trainerAvatar': trainerAvatar,
      'trainerRole': trainerRole,
      'category': category,
      'price': price,
      'originalPrice': originalPrice,
      'discountPercent': discountPercent,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'studentsCount': studentsCount,
      'image': image,
      'duration': duration,
      'lessonsCount': lessonsCount,
      'level': level,
      'isPopular': isPopular,
      'badge': badge,
      'description': description,
      'whatYouWillLearn': whatYouWillLearn,
      'teacherId': teacherId,
      'isPublished': isPublished,
      'status': publicationStatus,
      'thumbnailUrl': thumbnailUrl ?? image,
      'presentationVideoUrl': presentationVideoUrl,
      'promoVideoUrl': presentationVideoUrl,
      'modules': modules.map((m) => m.toMap()).toList(),
      'replays': replays.map((r) => r.toMap()).toList(),
      'lessons': flatLessons.isNotEmpty
          ? flatLessons.map((l) => l.toMap()).toList()
          : modules.expand((m) => m.lessons).map((l) => l.toMap()).toList(),
    };
  }

  // 8 Formations complètes exactement conformes aux maquettes Catalogue & Détail
  static List<CourseModel> get showcaseCourses => [
    CourseModel(
      id: 'react',
      title: 'Développement Web Moderne avec React',
      trainerName: 'Par Cheikh Diop',
      trainerAvatar: 'assets/images/student-man.jpeg',
      trainerRole: 'Expert en développement web et technologies JavaScript',
      category: 'Informatique',
      price: 40000,
      originalPrice: 60000,
      discountPercent: 33,
      rating: 4.8,
      reviewsCount: 410,
      studentsCount: 1250,
      image: 'assets/images/student-library.jpeg',
      duration: '5h 20min',
      lessonsCount: 42,
      level: 'Intermédiaire',
      isPopular: true,
      badge: 'Bestseller',
      presentationVideoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      description: 'React est l\'une des bibliothèques JavaScript les plus populaires pour construire des interfaces modernes et interactives. Cette formation vous guide pas à pas, de l\'installation aux concepts avancés, avec des exemples concrets et des projets réels.',
      whatYouWillLearn: [
        'Maîtriser les bases et les concepts avancés de React',
        'Créer des applications web complètes et performantes',
        'Comprendre la gestion d\'état et les hooks',
        'Travailler avec des API et des données réelles',
        'Déployer votre application en ligne',
        'Les composants et les props',
        'Le routage avec React Router',
        'Réalisation d\'un projet complet',
      ],
      modules: [
        CourseModule(
          id: 'm1',
          title: 'Module 1 : Introduction à React',
          lessonsCount: 6,
          duration: '45min',
          lessons: [
            CourseLesson(id: 'l1', title: '1. Qu\'est-ce que React ?', duration: '08:12'),
            CourseLesson(id: 'l2', title: '2. Installation et environnement de développement', duration: '10:24'),
            CourseLesson(id: 'l3', title: '3. Premier composant React', duration: '15:20'),
            CourseLesson(id: 'l4', title: '4. JSX et rendu conditionnel', duration: '11:45'),
            CourseLesson(id: 'l5', title: '5. Les props et la réutilisation', duration: '09:30'),
            CourseLesson(id: 'l6', title: '6. Mini projet : carte de profil', duration: '14:15'),
          ],
        ),
        CourseModule(
          id: 'm2',
          title: 'Module 2 : Les hooks en profondeur',
          lessonsCount: 7,
          duration: '1h 05min',
          lessons: [
            CourseLesson(id: 'l7', title: '1. Découverte de useState', duration: '12:10'),
            CourseLesson(id: 'l8', title: '2. Effets de bord avec useEffect', duration: '16:40'),
            CourseLesson(id: 'l9', title: '3. Optimisation avec useMemo et useCallback', duration: '14:20'),
            CourseLesson(id: 'l10', title: '4. Création de hooks personnalisés', duration: '18:15'),
          ],
        ),
      ],
    ),
    CourseModel(
      id: 'marketing',
      title: 'Stratégie Marketing Digital de A à Z',
      trainerName: 'Par Awa Ndiaye',
      trainerAvatar: 'assets/images/student-woman.jpeg',
      trainerRole: 'Spécialiste Marketing Digital & Réseaux Sociaux',
      category: 'Marketing',
      price: 30000,
      originalPrice: 45000,
      discountPercent: 33,
      rating: 4.7,
      reviewsCount: 280,
      studentsCount: 980,
      image: 'assets/images/student-woman.jpeg',
      duration: '3h 15min',
      lessonsCount: 36,
      level: 'Débutant',
      isPopular: true,
      badge: 'Populaire',
      description: 'Apprenez à définir une stratégie digitale percutante, lancer des campagnes publicitaires rentables et développer votre visibilité sur les réseaux sociaux.',
      whatYouWillLearn: [
        'Définir sa cible et ses personas',
        'Créer des campagnes Meta Ads et Google Ads',
        'Optimiser le référencement naturel (SEO)',
        'Analyser le ROI de ses campagnes',
      ],
    ),
    CourseModel(
      id: 'gestion',
      title: 'Entrepreneuriat et gestion de projet',
      trainerName: 'Par Mamadou Fall',
      trainerAvatar: 'assets/images/student-man.jpeg',
      trainerRole: 'Expert en Gestion d\'Entreprise & Systèmes d\'Information',
      category: 'Business',
      price: 35000,
      originalPrice: 50000,
      discountPercent: 30,
      rating: 4.9,
      reviewsCount: 320,
      studentsCount: 1500,
      image: 'assets/images/student-school.jpeg',
      duration: '4h 30min',
      lessonsCount: 38,
      level: 'Intermédiaire',
      isPopular: true,
      badge: 'Bestseller',
      description: 'De l\'idée au plan d\'affaires : maîtrisez les outils de gestion agile, la planification budgétaire et le pilotage d\'équipes pluridisciplinaires.',
      whatYouWillLearn: [
        'Méthodologie Scrum et Kanban',
        'Gestion des risques et des coûts',
        'Pitch investisseurs et business plan',
      ],
    ),
    CourseModel(
      id: 'figma',
      title: 'Graphisme et UI/UX Design avec Figma',
      trainerName: 'Par Fatou Sarr',
      trainerAvatar: 'assets/images/student-green.jpeg',
      trainerRole: 'Designer UI/UX & Directrice Artistique',
      category: 'Design',
      price: 40000,
      originalPrice: 55000,
      discountPercent: 27,
      rating: 4.8,
      reviewsCount: 190,
      studentsCount: 860,
      image: 'assets/images/student-library.jpeg',
      duration: '6h 10min',
      lessonsCount: 45,
      level: 'Débutant à Avancé',
      isPopular: true,
      description: 'Concevez des interfaces web et mobiles modernes, interactives et esthétiques en maîtrisant les design systems, l\'auto-layout et le prototypage.',
      whatYouWillLearn: [
        'Maîtrise de Figma de A à Z',
        'Création de Design Systems complets',
        'Prototypage animé et tests utilisateurs',
      ],
    ),
    CourseModel(
      id: 'confiance',
      title: 'Confiance en soi et efficacité personnelle',
      trainerName: 'Par Awa Ndiaye',
      trainerAvatar: 'assets/images/student-woman.jpeg',
      category: 'Développement personnel',
      price: 25000,
      originalPrice: 35000,
      discountPercent: 28,
      rating: 4.9,
      reviewsCount: 450,
      studentsCount: 2100,
      image: 'assets/images/student-green.jpeg',
      duration: '2h 50min',
      lessonsCount: 24,
      level: 'Tous niveaux',
      isPopular: true,
      description: 'Libérez votre plein potentiel, améliorez votre prise de parole en public et apprenez à gérer efficacement votre temps et vos priorités.',
    ),
    CourseModel(
      id: 'anglais',
      title: 'Anglais professionnel pour tous',
      trainerName: 'Par Fallou Sy',
      trainerAvatar: 'assets/images/student-school.jpeg',
      category: 'Langues',
      price: 35000,
      originalPrice: 45000,
      discountPercent: 22,
      rating: 4.7,
      reviewsCount: 300,
      studentsCount: 1300,
      image: 'assets/images/student-child.jpeg',
      duration: '8h 00min',
      lessonsCount: 50,
      level: 'Intermédiaire',
      isPopular: false,
      description: 'Améliorez votre expression orale et écrite en anglais dans un contexte professionnel : réunions, présentations, négociations et emails.',
    ),
    CourseModel(
      id: 'excel',
      title: 'Maîtriser Excel de A à Z',
      trainerName: 'Par Mamadou Fall',
      trainerAvatar: 'assets/images/student-man.jpeg',
      category: 'Business',
      price: 25000,
      originalPrice: 35000,
      discountPercent: 28,
      rating: 4.8,
      reviewsCount: 520,
      studentsCount: 2400,
      image: 'assets/images/student-man.jpeg',
      duration: '3h 30min',
      lessonsCount: 35,
      level: 'Tous niveaux',
      isPopular: true,
      badge: 'Bestseller',
      description: 'Tableaux croisés dynamiques, formules complexes, macros et visualisations professionnelles pour booster votre productivité au quotidien.',
    ),
    CourseModel(
      id: 'cyber',
      title: 'Cybersécurité : bases et bonnes pratiques',
      trainerName: 'Par Cheikh Diop',
      trainerAvatar: 'assets/images/student-man.jpeg',
      category: 'Informatique',
      price: 30000,
      originalPrice: 45000,
      discountPercent: 33,
      rating: 4.6,
      reviewsCount: 180,
      studentsCount: 720,
      image: 'assets/images/student-library.jpeg',
      duration: '4h 20min',
      lessonsCount: 30,
      level: 'Débutant',
      isPopular: false,
      badge: 'Nouveau',
      description: 'Comprendre les menaces cyber, sécuriser vos données et applications, et adopter les réflexes essentiels de protection numérique.',
    ),
  ];
}
