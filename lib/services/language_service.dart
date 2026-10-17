import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  static LanguageService get instance => _instance;

  LanguageService._internal() {
    _loadLanguage();
  }

  static const String _storageKey = 'app_language_code';

  /// 'fr' or 'en'
  final ValueNotifier<String> currentLanguageNotifier = ValueNotifier<String>('fr');

  String get currentLanguage => currentLanguageNotifier.value;
  bool get isFrench => currentLanguage == 'fr';
  bool get isEnglish => currentLanguage == 'en';

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_storageKey);
      if (saved != null && (saved == 'fr' || saved == 'en')) {
        currentLanguageNotifier.value = saved;
      }
    } catch (e) {
      debugPrint('Error loading language: $e');
    }
  }

  Future<void> setLanguage(String code) async {
    if (code != 'fr' && code != 'en') return;
    currentLanguageNotifier.value = code;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, code);
    } catch (e) {
      debugPrint('Error saving language: $e');
    }
  }

  void toggleLanguage() {
    setLanguage(isFrench ? 'en' : 'fr');
  }

  /// Dynamic inline translation helper
  String t({required String fr, required String en}) {
    return isEnglish ? en : fr;
  }

  /// Key-based dictionary lookup with fallback
  String tr(String key, {String? defaultFr}) {
    final lang = currentLanguage;
    final map = _dict[lang];
    if (map != null && map.containsKey(key)) {
      return map[key]!;
    }
    if (defaultFr != null) {
      return isEnglish ? (_dict['en']?[key] ?? defaultFr) : defaultFr;
    }
    return _dict['en']?[key] ?? _dict['fr']?[key] ?? key;
  }

  static final Map<String, Map<String, String>> _dict = {
    'fr': {
      // Navigation
      'nav_home': 'Accueil',
      'nav_courses': 'Formations',
      'nav_trainers': 'Formateurs',
      'nav_about': 'À propos',
      'nav_contact': 'Contact',
      'nav_login': 'Se connecter',
      'nav_register': 'S\'inscrire',
      'nav_dashboard': 'Mon Espace',
      'nav_logout': 'Se déconnecter',
      'nav_search': 'Rechercher',
      'nav_back': 'Retour',
      'nav_back_home': 'Retour à l\'accueil',
      'nav_menu': 'Menu',

      // Mobile Menu
      'menu_title': 'Navigation',
      'menu_subtitle': 'Club des Formateurs',
      'menu_courses_sub': 'Explorez nos formations certifiantes',
      'menu_trainers_sub': 'Experts pédagogiques et mentors',
      'menu_about_sub': 'Notre mission et méthodologie',
      'menu_contact_sub': 'Assistance et partenariats',
      'menu_my_dashboard': 'Mon Tableau de Bord',
      'menu_switch_lang': 'Changer la langue',
      'menu_official_docs': 'Documents Officiels',
      'menu_official_docs_sub': 'Règlement & Contrat',

      // Hero
      'hero_badge': 'PLATEFORME PÉDAGOGIQUE',
      'hero_title_1': 'Apprenez.',
      'hero_title_2': 'Partagez.',
      'hero_title_3': 'Progressez ensemble.',
      'hero_subtitle': 'La plateforme qui connecte les apprenants aux formateurs et experts pour développer les compétences de demain.',
      'hero_cta_explore': 'Explorer les formations',
      'hero_cta_teach': 'Devenir formateur',
      'hero_card_courses': 'Formations Certifiantes',
      'hero_card_students': 'Apprenants Actifs',
      'hero_card_support': 'Accompagnement Continu',
      'hero_stat_quality_title': 'Des formations',
      'hero_stat_quality_sub': 'de qualité',
      'hero_stat_experts_title': 'Des formateurs',
      'hero_stat_experts_sub': 'experts',
      'hero_stat_growth_title': 'Un développement',
      'hero_stat_growth_sub': 'vers le niveau',
      'hero_badge_skills': 'Des compétences pour un meilleur avenir !',
      'hero_badge_teach': 'Former aujourd\'hui.\nConstruire demain !',
      'hero_badge_learn_limitless': 'Apprendre sans limites',
      'hero_badge_create_ideas': 'Créer en 365 idées',
      'hero_badge_train_today': 'Se former aujourd’hui',

      // Search Area
      'search_placeholder': 'Que souhaitez-vous apprendre ?',
      'search_banner_placeholder': 'Rechercher une formation, un formateur, une compétence...',
      'search_all_cats': 'Toutes les catégories',
      'search_btn': 'Rechercher',
      'search_cat_popular': 'Formations populaires',
      'search_cat_it': 'Informatique',
      'search_cat_marketing': 'Marketing',
      'search_cat_design': 'Design',
      'search_cat_business': 'Business',
      'search_cat_personal_dev': 'Développement personnel',

      // Stats
      'stat_learners': 'Apprenants actifs',
      'stat_learners_students': 'Apprenants & Étudiants',
      'stat_courses': 'Formations publiées',
      'stat_teachers': 'Professeurs inscrits',
      'stat_interactive': 'Interactif & Lives',
      'stat_success': 'Taux de satisfaction',
      'stat_experts': 'Formateurs experts',
      'stat_band_title': 'Une plateforme vivante et interactive',
      'stat_band_sub': 'Suivi en temps réel des professeurs inscrits, des cours publiés et de la communauté étudiante.',

      // Sections
      'sec_popular_courses': 'Formations disponibles',
      'sec_popular_courses_tag': 'COURS DES PROFESSEURS',
      'sec_popular_courses_sub': 'Les cours réellement créés par les professeurs et formateurs de la plateforme',
      'sec_all_courses': 'Voir tout le catalogue',
      'sec_view_all': 'Voir tout',
      'sec_trainers': 'Professeurs & Formateurs en direct',
      'sec_trainers_tag': 'CORPS ENSEIGNANT',
      'sec_trainers_sub': 'Découvrez nos professeurs ayant publié des formations avec leur vidéo de présentation',
      'sec_all_trainers': 'Voir tous les formateurs',
      'sec_why_us': 'Pourquoi choisir Club des Formateurs ?',
      'sec_why_us_sub': 'Une pédagogie innovante basée sur la pratique, le mentorat et l\'excellence.',
      'sec_testimonials': 'Témoignages de nos Apprenants',

      // Dual CTA
      'cta_ready_tag': 'PRÊT À COMMENCER ?',
      'cta_main_title': 'Rejoignez dès maintenant\nClub des Formateurs',
      'cta_main_sub': 'Apprenez de nouvelles compétences ou partagez votre expertise avec une communauté engagée.',
      'cta_student_title': 'Vous êtes apprenant ?',
      'cta_student_desc': 'Accédez à des formations de qualité et développez vos compétences.',
      'cta_student_btn': 'Créer un compte',
      'cta_teacher_title': 'Vous êtes formateur ?',
      'cta_teacher_desc': 'Partagez votre savoir et inspirez des milliers d\'apprenants.',
      'cta_teacher_btn': 'Devenir formateur',

      // Cards
      'card_free': 'Gratuit',
      'card_students': 'inscrits',
      'card_lessons': 'leçons',
      'card_chapters': 'chapitres',
      'card_hours': 'heures',
      'card_view': 'Voir le cours',
      'card_trainer_profile': 'Voir le profil',
      'card_contact': 'Message',
      'card_teaching_level': 'Niveau enseigné :',
      'card_live': 'En direct',
      'card_online': 'En ligne',
      'card_enroll': 'S\'inscrire',

      // Catalog
      'cat_title': 'Catalogue des formations',
      'cat_hero_tag': 'CATALOGUE DES FORMATIONS',
      'cat_hero_title': 'Développez vos compétences avec les meilleurs formateurs',
      'cat_hero_subtitle': 'Découvrez des formations de qualité pour aujourd\'hui et pour demain.',
      'cat_search': 'Rechercher un cours...',
      'cat_all_categories': 'Toutes catégories',
      'cat_all_levels': 'Tous niveaux',
      'cat_filter': 'Filtrer',
      'cat_empty': 'Aucune formation trouvée.',

      // Trainers Screen
      'trainers_screen_tag': 'NOS FORMATEURS',
      'trainers_screen_title': 'Des experts passionnés pour vous accompagner',
      'trainers_screen_subtitle': 'Apprenez auprès de professionnels reconnus, en direct ou à votre rythme, partout en Afrique et dans le monde.',
      'trainers_search': 'Rechercher un formateur...',
      'trainers_teaching_level': 'Niveau enseigné :',
      'trainers_courses_offered': 'Formations proposées',
      'trainers_empty': 'Aucun formateur trouvé.',

      // Footer
      'footer_desc': 'Club des Formateurs est la première plateforme d\'apprentissage combinant formations d\'élite, accompagnement par correcteurs dédiés et sessions interactives.',
      'footer_quick_links': 'Liens rapides',
      'footer_resources': 'Ressources',
      'footer_contact': 'Contact & Support',
      'footer_newsletter_title': 'Restez informé',
      'footer_newsletter_sub': 'Recevez nos nouveautés, offres et masterclasses directement dans votre boîte mail.',
      'footer_newsletter_placeholder': 'Votre adresse email...',
      'footer_newsletter_btn': 'S\'abonner',
      'footer_rights': '© 2026 Club des Formateurs. Tous droits réservés.',
      'footer_tagline': 'Apprendre aujourd\'hui, Construire demain !',
      'footer_privacy': 'Politique de confidentialité',
      'footer_terms': 'Conditions Générales d\'Utilisation',

      // Actions / Common
      'btn_confirm': 'Confirmer',
      'btn_cancel': 'Annuler',
      'btn_close': 'Fermer',
      'btn_save': 'Enregistrer',
      'btn_reload': 'Actualiser la page',
      'role_student': 'Apprenant',
      'role_teacher': 'Formateur',
      'role_corrector': 'Correcteur',
      'role_admin': 'Administrateur',
    },
    'en': {
      // Navigation
      'nav_home': 'Home',
      'nav_courses': 'Courses',
      'nav_trainers': 'Trainers',
      'nav_about': 'About',
      'nav_contact': 'Contact',
      'nav_login': 'Sign In',
      'nav_register': 'Sign Up',
      'nav_dashboard': 'My Dashboard',
      'nav_logout': 'Sign Out',
      'nav_search': 'Search',
      'nav_back': 'Back',
      'nav_back_home': 'Back to Home',
      'nav_menu': 'Menu',

      // Mobile Menu
      'menu_title': 'Navigation',
      'menu_subtitle': 'Trainers Club',
      'menu_courses_sub': 'Explore our certified courses',
      'menu_trainers_sub': 'Educational experts and mentors',
      'menu_about_sub': 'Our mission and learning approach',
      'menu_contact_sub': 'Support and partnerships',
      'menu_my_dashboard': 'My Dashboard',
      'menu_switch_lang': 'Switch language',
      'menu_official_docs': 'Official Documents',
      'menu_official_docs_sub': 'Terms & Agreements',

      // Hero
      'hero_badge': 'LEARNING PLATFORM',
      'hero_title_1': 'Learn.',
      'hero_title_2': 'Share.',
      'hero_title_3': 'Grow together.',
      'hero_subtitle': 'The platform connecting learners with trainers and experts to build the skills of tomorrow.',
      'hero_cta_explore': 'Explore courses',
      'hero_cta_teach': 'Become a trainer',
      'hero_card_courses': 'Certified Courses',
      'hero_card_students': 'Active Learners',
      'hero_card_support': 'Continuous Support',
      'hero_stat_quality_title': 'High quality',
      'hero_stat_quality_sub': 'courses',
      'hero_stat_experts_title': 'Expert',
      'hero_stat_experts_sub': 'trainers',
      'hero_stat_growth_title': 'Step by step',
      'hero_stat_growth_sub': 'progression',
      'hero_badge_skills': 'Skills for a brighter future!',
      'hero_badge_teach': 'Teaching today.\nBuilding tomorrow!',
      'hero_badge_learn_limitless': 'Learn without limits',
      'hero_badge_create_ideas': 'Create with 365 ideas',
      'hero_badge_train_today': 'Level up today',

      // Search Area
      'search_placeholder': 'What do you want to learn?',
      'search_banner_placeholder': 'Search for a course, a trainer, a skill...',
      'search_all_cats': 'All categories',
      'search_btn': 'Search',
      'search_cat_popular': 'Popular courses',
      'search_cat_it': 'Computer Science',
      'search_cat_marketing': 'Marketing',
      'search_cat_design': 'Design',
      'search_cat_business': 'Business',
      'search_cat_personal_dev': 'Personal Development',

      // Stats
      'stat_learners': 'Active learners',
      'stat_learners_students': 'Learners & Students',
      'stat_courses': 'Published courses',
      'stat_teachers': 'Registered teachers',
      'stat_interactive': 'Interactive & Live',
      'stat_success': 'Satisfaction rate',
      'stat_experts': 'Expert trainers',
      'stat_band_title': 'A dynamic and interactive platform',
      'stat_band_sub': 'Real-time tracking of certified instructors, published courses and our student community.',

      // Sections
      'sec_popular_courses': 'Available Courses',
      'sec_popular_courses_tag': 'COURSES BY TEACHERS',
      'sec_popular_courses_sub': 'Courses genuinely crafted by platform professors and instructors',
      'sec_all_courses': 'Browse full catalog',
      'sec_view_all': 'View all',
      'sec_trainers': 'Live Professors & Instructors',
      'sec_trainers_tag': 'FACULTY & TRAINERS',
      'sec_trainers_sub': 'Discover our teachers with published courses and introductory presentation videos',
      'sec_all_trainers': 'View all faculty',
      'sec_why_us': 'Why Choose Trainers Club?',
      'sec_why_us_sub': 'An innovative learning method based on hands-on practice, mentorship and excellence.',
      'sec_testimonials': 'Student Testimonials',

      // Dual CTA
      'cta_ready_tag': 'READY TO START?',
      'cta_main_title': 'Join Trainers Club\ntoday',
      'cta_main_sub': 'Learn new high-demand skills or share your expertise with an engaged community.',
      'cta_student_title': 'Are you a learner?',
      'cta_student_desc': 'Access top-tier courses and level up your practical skills.',
      'cta_student_btn': 'Create an account',
      'cta_teacher_title': 'Are you a trainer?',
      'cta_teacher_desc': 'Share your expertise and inspire thousands of students worldwide.',
      'cta_teacher_btn': 'Become a trainer',

      // Cards
      'card_free': 'Free',
      'card_students': 'students',
      'card_lessons': 'lessons',
      'card_chapters': 'chapters',
      'card_hours': 'hours',
      'card_view': 'View course',
      'card_trainer_profile': 'View profile',
      'card_contact': 'Message',
      'card_teaching_level': 'Teaching level:',
      'card_live': 'Live',
      'card_online': 'Online',
      'card_enroll': 'Enroll now',

      // Catalog
      'cat_title': 'Course Catalog',
      'cat_hero_tag': 'COURSE CATALOG',
      'cat_hero_title': 'Level up your skills with leading instructors',
      'cat_hero_subtitle': 'Discover certified, world-class courses designed for tomorrow\'s economy.',
      'cat_search': 'Search courses...',
      'cat_all_categories': 'All categories',
      'cat_all_levels': 'All levels',
      'cat_filter': 'Filters',
      'cat_empty': 'No courses found.',

      // Trainers Screen
      'trainers_screen_tag': 'OUR FACULTY',
      'trainers_screen_title': 'Passionate experts to mentor you',
      'trainers_screen_subtitle': 'Learn directly from certified professionals, live or at your own pace, across Africa and worldwide.',
      'trainers_search': 'Search a trainer...',
      'trainers_teaching_level': 'Teaching level:',
      'trainers_courses_offered': 'Offered courses',
      'trainers_empty': 'No trainers found.',

      // Footer
      'footer_desc': 'Trainers Club is the premier learning platform blending elite courses, dedicated corrector feedback, and live sessions.',
      'footer_quick_links': 'Quick Links',
      'footer_resources': 'Resources',
      'footer_contact': 'Contact & Support',
      'footer_newsletter_title': 'Stay Updated',
      'footer_newsletter_sub': 'Receive our newest courses, announcements and masterclasses in your inbox.',
      'footer_newsletter_placeholder': 'Your email address...',
      'footer_newsletter_btn': 'Subscribe',
      'footer_rights': '© 2026 Trainers Club. All rights reserved.',
      'footer_tagline': 'Learn today, Build tomorrow!',
      'footer_privacy': 'Privacy Policy',
      'footer_terms': 'Terms of Service',

      // Actions / Common
      'btn_confirm': 'Confirm',
      'btn_cancel': 'Cancel',
      'btn_close': 'Close',
      'btn_save': 'Save',
      'btn_reload': 'Reload page',
      'role_student': 'Learner',
      'role_teacher': 'Trainer',
      'role_corrector': 'Corrector',
      'role_admin': 'Administrator',
    },
  };
}
