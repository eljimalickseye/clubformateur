class TrainerExperience {
  final String period;
  final String title;
  final String organization;
  final String description;

  TrainerExperience({
    required this.period,
    required this.title,
    required this.organization,
    required this.description,
  });

  factory TrainerExperience.fromMap(Map<String, dynamic> data) {
    return TrainerExperience(
      period: data['period'] ?? '',
      title: data['title'] ?? '',
      organization: data['organization'] ?? '',
      description: data['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'period': period,
    'title': title,
    'organization': organization,
    'description': description,
  };
}

class TrainerCertification {
  final String title;
  final String issuer;
  final String year;
  final String iconKey;

  TrainerCertification({
    required this.title,
    required this.issuer,
    required this.year,
    required this.iconKey,
  });

  factory TrainerCertification.fromMap(Map<String, dynamic> data) {
    return TrainerCertification(
      title: data['title'] ?? '',
      issuer: data['issuer'] ?? '',
      year: data['year'] ?? '',
      iconKey: data['iconKey'] ?? 'default',
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'issuer': issuer,
    'year': year,
    'iconKey': iconKey,
  };
}

class TrainerReview {
  final String author;
  final String avatar;
  final double rating;
  final String comment;
  final String date;

  TrainerReview({
    required this.author,
    required this.avatar,
    required this.rating,
    required this.comment,
    required this.date,
  });

  factory TrainerReview.fromMap(Map<String, dynamic> data) {
    return TrainerReview(
      author: data['author'] ?? 'Apprenant',
      avatar: data['avatar'] ?? 'assets/images/student-woman.jpeg',
      rating: (data['rating'] is num) ? (data['rating'] as num).toDouble() : 5.0,
      comment: data['comment'] ?? '',
      date: data['date'] ?? 'Récemment',
    );
  }
}

class TrainerModel {
  final String id;
  final String name;
  final String role;
  final double rating;
  final int reviewsCount;
  final int coursesCount;
  final int studentsCount;
  final String image;
  final bool isVerified;
  final List<String> tags;
  final String bio;
  final String quote;
  final String headline;
  final String presentation;
  final String experienceYears;
  final String satisfactionRate;
  final List<String> skills;
  final List<TrainerExperience> experiences;
  final List<TrainerCertification> certifications;
  final List<String> availableFor;
  final List<TrainerReview> reviews;
  final List<Map<String, dynamic>> weeklySchedule;
  final String? presentationVideoUrl;
  final String subject;
  final List<String> levels;
  final String availability;
  final String schedule;
  final int registrationFee;

  TrainerModel({
    required this.id,
    required this.name,
    required this.role,
    required this.rating,
    this.reviewsCount = 0,
    required this.coursesCount,
    this.studentsCount = 0,
    required this.image,
    this.isVerified = true,
    this.tags = const [],
    this.bio = '',
    this.quote = 'Transmettre mes compétences aujourd\'hui pour un meilleur avenir demain.',
    this.headline = 'Développeur Full Stack | Formateur passionné | Accompagne vers l\'emploi',
    this.presentation = 'Développeur full-stack et formateur passionné, j\'accompagne depuis plus de 5 ans des apprenants dans l\'acquisition de compétences en développement web. Mon objectif est de rendre la technologie accessible à tous, avec une approche pratique et orientée projet.',
    this.experienceYears = '5+ ans',
    this.satisfactionRate = '95%',
    this.skills = const [
      'HTML', 'CSS', 'JavaScript', 'React', 'Node.js', 'MongoDB', 'Firebase',
      'Développement d\'applications', 'Bonnes pratiques', 'Projets réels',
      'Déploiement', 'Accompagnement vers l\'emploi'
    ],
    this.experiences = const [],
    this.certifications = const [],
    this.availableFor = const [
      'Formations en ligne',
      'Formations en présentiel',
      'Mentorat personnalisé',
      'Projets d\'entreprise'
    ],
    this.reviews = const [],
    this.weeklySchedule = const [],
    this.presentationVideoUrl,
    this.subject = 'Mathématiques & Informatique',
    this.levels = const ['L1', 'L2', 'L3', 'Master'],
    this.availability = 'Inscriptions ouvertes pour l\'année 2026-2027',
    this.schedule = 'Samedi & Dimanche : 10h00 - 12h30',
    this.registrationFee = 25000,
  });

  factory TrainerModel.fromMap(Map<String, dynamic> data, String id) {
    int parseNumToInt(dynamic v, [int fallback = 0]) {
      if (v == null) return fallback;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? fallback;
    }

    double parseNumToDouble(dynamic v, [double fallback = 5.0]) {
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

    final photo = data['photoUrl'] ?? data['photoURL'] ?? data['avatar'] ?? data['image'] ?? '';
    final expYears = data['experienceYears']?.toString() ?? '';
    final spec = data['speciality']?.toString() ?? data['role']?.toString() ?? 'Professeur certifié';

    final sub = data['subject']?.toString() ??
        (data['speciality'] != null ? data['speciality'].toString() : null) ??
        (data['tags'] is List && (data['tags'] as List).isNotEmpty ? data['tags'][0]?.toString() : null) ??
        spec;

    final levs = parseList(data['levels'], const ['L1', 'L2', 'L3', 'Master']);
    final avail = data['availability']?.toString() ?? 'Inscriptions 2026-2027 ouvertes';
    final sched = data['schedule']?.toString() ?? 'Samedi & Dimanche : 10h00 - 12h30';
    final fee = parseNumToInt(data['registrationFee'] ?? data['monthlyFee'], 25000);

    return TrainerModel(
      id: id,
      name: data['displayName']?.toString() ?? data['name']?.toString() ?? 'Professeur',
      role: spec,
      rating: parseNumToDouble(data['rating'], 5.0),
      reviewsCount: parseNumToInt(data['reviewsCount'], 0),
      coursesCount: parseNumToInt(data['coursesCount'], 0),
      studentsCount: parseNumToInt(data['studentsCount'], 0),
      image: photo.toString(),
      isVerified: data['isVerified'] == true || data['isVerified'] == null,
      tags: parseList(data['tags'] ?? (data['expertises'] ?? [])),
      bio: data['bio']?.toString() ?? '',
      quote: data['quote']?.toString() ?? 'Transmettre le savoir et former l\'excellence.',
      headline: data['headline']?.toString() ?? spec,
      presentation: data['presentation']?.toString() ?? (data['bio']?.toString() ?? ''),
      experienceYears: expYears,
      satisfactionRate: data['satisfactionRate']?.toString() ?? '100%',
      skills: parseList(data['skills'] ?? (data['expertises'] ?? [])),
      experiences: (data['experiences'] is List)
          ? (data['experiences'] as List)
              .whereType<Map>()
              .map((e) => TrainerExperience.fromMap(Map<String, dynamic>.from(e)))
              .toList()
          : [],
      certifications: (data['certifications'] is List)
          ? (data['certifications'] as List)
              .whereType<Map>()
              .map((e) => TrainerCertification.fromMap(Map<String, dynamic>.from(e)))
              .toList()
          : [],
      availableFor: parseList(data['availableFor'], const [
        'Formations en direct',
        'Sessions interactives',
        'Mentorat individuel',
        'Accompagnement pratique'
      ]),
      reviews: (data['reviews'] is List)
          ? (data['reviews'] as List)
              .whereType<Map>()
              .map((e) => TrainerReview.fromMap(Map<String, dynamic>.from(e)))
              .toList()
          : [],
      weeklySchedule: (data['weeklySchedule'] is List)
          ? (data['weeklySchedule'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : [],
      presentationVideoUrl: data['presentationVideoUrl']?.toString() ??
          data['videoUrl']?.toString() ??
          data['introVideoUrl']?.toString(),
      subject: sub,
      levels: levs,
      availability: avail,
      schedule: sched,
      registrationFee: fee,
    );
  }

  static List<TrainerModel> get showcaseTrainers => [
    TrainerModel(
      id: 'ndiaye',
      name: 'M. Mamadou Ndiaye',
      role: 'Professeur de Mathématiques & Algèbre',
      subject: 'Mathématiques',
      levels: ['L1', 'L2', 'L3'],
      availability: 'Inscriptions ouvertes pour l\'année 2026-2027',
      schedule: 'Samedi & Dimanche : 10h00 - 12h30',
      registrationFee: 25000,
      rating: 4.9,
      reviewsCount: 380,
      coursesCount: 15,
      studentsCount: 14500,
      image: 'assets/images/student-man.jpeg',
      isVerified: true,
      tags: ['Mathématiques', 'Algèbre', 'Analyse', 'Probabilités', 'L1', 'L2', 'L3'],
      bio: 'Enseignant-chercheur agrégé en mathématiques appliquées avec plus de 10 ans d\'expérience dans l\'enseignement supérieur.',
      quote: 'Démystifier les mathématiques pour que chaque étudiant réussisse son parcours universitaire.',
      headline: 'Professeur de Mathématiques | Accompagnement L1, L2, L3',
      presentation: 'Spécialiste de la préparation aux examens et concours universitaires en mathématiques. Méthode pédagogique claire, exercices ciblés et suivi rigoureux.',
      experienceYears: '10+ ans',
      satisfactionRate: '98%',
      skills: [
        'Analyse mathématique', 'Algèbre linéaire', 'Probabilités & Statistiques',
        'Préparation aux examens', 'Travaux dirigés', 'Résolution de problèmes'
      ],
      experiences: [
        TrainerExperience(
          period: '2016 - Aujourd\'hui',
          title: 'Professeur Titulaire de Mathématiques',
          organization: 'Université Cheikh Anta Diop & Club des Formateurs',
          description: 'Enseignement de l\'analyse, de l\'algèbre et des mathématiques appliquées aux étudiants de licence.',
        ),
        TrainerExperience(
          period: '2012 - 2016',
          title: 'Assistant de recherche en Mathématiques',
          organization: 'Laboratoire d\'Analyse Numérique',
          description: 'Recherche appliquée et encadrement des travaux dirigés pour les cycles L1 et L2.',
        ),
      ],
      certifications: [
        TrainerCertification(
          title: 'Agrégation de Mathématiques',
          issuer: 'Ministère de l\'Enseignement Supérieur',
          year: '2015',
          iconKey: 'education',
        ),
      ],
      reviews: [
        TrainerReview(
          author: 'Fatou Sow',
          avatar: 'assets/images/student-woman.jpeg',
          rating: 5.0,
          comment: 'Grâce à M. Ndiaye, j\'ai validé mon semestre de Mathématiques L2 avec mention. Ses explications sont lumineuses !',
          date: '15 Sep 2026',
        ),
        TrainerReview(
          author: 'Abdoulaye Ba',
          avatar: 'assets/images/student-library.jpeg',
          rating: 5.0,
          comment: 'Professeur très rigoureux et bienveillant. L\'emploi du temps le week-end est parfait pour concilier les révisions.',
          date: '02 Oct 2026',
        ),
      ],
    ),
    TrainerModel(
      id: 'awa',
      name: 'Awa Ndiaye',
      role: 'Spécialiste Marketing Digital',
      subject: 'Marketing Digital & E-commerce',
      levels: ['L2', 'L3', 'Master 1', 'Master 2'],
      availability: 'Inscriptions ouvertes pour l\'année 2026-2027',
      schedule: 'Mardi & Jeudi : 18h00 - 20h00',
      registrationFee: 30000,
      rating: 4.7,
      reviewsCount: 280,
      coursesCount: 10,
      studentsCount: 8200,
      image: 'assets/images/student-woman.jpeg',
      isVerified: true,
      tags: ['Marketing', 'Réseaux sociaux', 'Stratégie', 'SEO'],
      bio: 'Experte en stratégie d\'acquisition, growth marketing et gestion de communautés.',
      quote: 'Faire rayonner les marques africaines grâce aux opportunités du numérique.',
      headline: 'Consultante Growth Marketing | Formatrice certifiée Google & Meta',
    ),
    TrainerModel(
      id: 'cheikh',
      name: 'Cheikh Diop',
      role: 'Développeur Full Stack',
      subject: 'Informatique & Génie Logiciel',
      levels: ['L1', 'L2', 'L3', 'Master'],
      availability: 'Inscriptions ouvertes pour l\'année 2026-2027',
      schedule: 'Mercredi & Vendredi : 17h30 - 20h00',
      registrationFee: 25000,
      rating: 4.8,
      reviewsCount: 320,
      coursesCount: 14,
      studentsCount: 2480,
      image: 'assets/images/student-library.jpeg',
      isVerified: true,
      tags: ['Informatique', 'JavaScript', 'React', 'Node.js'],
      bio: 'Développeur Full-Stack passionné par l\'écosystème web moderne et l\'enseignement.',
      quote: 'Transformer des débutants motivés en développeurs de haut niveau.',
      headline: 'Lead Developer | Auteur de cours React & Node.js',
    ),
  ];
}
