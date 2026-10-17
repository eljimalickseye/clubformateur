import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/models.dart';
import 'database_service.dart';
import 'intech_payment_service.dart';

class AppState extends ChangeNotifier {
  final IntechPaymentService intechPaymentService = IntechPaymentService();
  final DatabaseService db = DatabaseService();
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  UserRole get currentRole => _currentUser?.role ?? UserRole.insured;

  int _currentNavIndex = 0;
  int get currentNavIndex => _currentNavIndex;

  void setNavIndex(int index) {
    _currentNavIndex = index;
    notifyListeners();
  }

  // Experts Automobiles Agréés au Sénégal (Obligatoire si Dégâts > 1 000 000 FCFA ou Litige)
  final List<AutomotiveExpertModel> _automotiveExperts = [
    AutomotiveExpertModel(
      id: 'exp_sahel_01',
      cabinetName: 'Cabinet Sahel Expertise Automobile',
      expertName: 'Ing. Babacar Mbaye (Expert Agréé CIMA / Ministère)',
      registrationNumber: 'EXP-AUTO-SN-2019-012',
      phone: '+221 33 825 90 90',
      whatsappNumber: '+221 77 610 20 30',
      email: 'contact@sahelexpertise.sn',
      address: 'Km 4, Boulevard du Centenaire, Dakar',
      city: 'Dakar Hann',
      rating: 4.9,
      totalExpertisesDone: 480,
      acceptanceRatePercentage: 99.0,
      averageTurnaroundHours: 48,
      specialties: 'Chiffrage Dégâts Lourds (> 1M), Diagnostic VEI (Économiquement Irréparable), Expertise Judiciaire & Contradictoire.',
      reviews: [
        BrokerReviewModel(
          id: 'rev_exp_1',
          authorName: 'M. Amadou Fall',
          rating: 5.0,
          comment: 'Choc avant très lourd estimé à 2,4 millions. L\'expert M. Mbaye a chiffré les réparations au centime près et le rapport a été accepté sans contestation par la compagnie en 48h.',
          date: DateTime(2025, 8, 12),
          claimType: 'Expertise Dégâts Lourds (2 400 000 FCFA)',
          claimsPayoutAmount: 'Rapport Validé 100%',
          isVerifiedClaim: true,
        ),
      ],
    ),
    AutomotiveExpertModel(
      id: 'exp_dakar_tech_02',
      cabinetName: 'Dakar Auto Tech & Évaluations',
      expertName: 'M. Cheikhna Diop (Expert Assermenté)',
      registrationNumber: 'EXP-AUTO-SN-2021-044',
      phone: '+221 33 864 12 12',
      whatsappNumber: '+221 77 540 88 11',
      email: 'expert@dakarautotech.sn',
      address: 'Route des Almadies, Ngor Dakar',
      city: 'Ngor Almadies',
      rating: 4.8,
      totalExpertisesDone: 310,
      acceptanceRatePercentage: 97.5,
      averageTurnaroundHours: 36,
      specialties: 'Véhicules Haut de Gamme, 4x4, Suivi de Tôlerie & Reconstruction Mécanique, Détection Épave.',
      reviews: [
        BrokerReviewModel(
          id: 'rev_exp_2',
          authorName: 'Mme Khady Diouf',
          rating: 4.8,
          comment: 'Véhicule déclaré VEI (valeur des réparations supérieure à la valeur vénale). L\'expert m\'a permis de toucher la valeur à neuf intégrale sans perdre de temps.',
          date: DateTime(2025, 7, 18),
          claimType: 'Procédure VEI (Véhicule Irréparable)',
          claimsPayoutAmount: 'Indemnisation Valeur Vénale',
          isVerifiedClaim: true,
        ),
      ],
    ),
  ];

  List<AutomotiveExpertModel> get automotiveExperts => _automotiveExperts;

  // Garages & Carrossiers Agréés (Prise en charge directe sans avance de frais)
  final List<ApprovedGarageModel> _approvedGarages = [
    ApprovedGarageModel(
      id: 'gar_sen_auto_01',
      garageName: 'Sénégal Auto Carrosserie & Tôlerie Pro',
      managerName: 'M. Ibrahima Ndiaye (Maître Carrossier)',
      phone: '+221 33 836 40 40',
      whatsappNumber: '+221 77 410 90 90',
      address: 'Zone Industrielle de Yarakh, Dakar',
      city: 'Yarakh',
      rating: 4.9,
      repairsCompleted: 820,
      specialties: 'Marbre laser, Cabine de peinture étuvée, Remplacement vitrage sans franchise, Pièces d\'origine garanties.',
      hasDirectBilling: true,
    ),
    ApprovedGarageModel(
      id: 'gar_almadies_02',
      garageName: 'Almadies Prestige Motors & Dépannage',
      managerName: 'M. Patrick Gomis',
      phone: '+221 33 820 15 15',
      whatsappNumber: '+221 77 600 33 44',
      address: 'Route du Méridien Président, Almadies',
      city: 'Almadies',
      rating: 4.8,
      repairsCompleted: 460,
      specialties: 'Mécanique de précision, Électronique embarquée, Remorquage express 24/7 Dakar & Régions.',
      hasDirectBilling: true,
    ),
  ];

  List<ApprovedGarageModel> get approvedGarages => _approvedGarages;

  final List<ExpertiseRequestModel> _expertiseRequests = [];
  List<ExpertiseRequestModel> get expertiseRequests => _expertiseRequests;

  void requestAutomotiveExpertise({
    required String expertId,
    required String expertName,
    required String clientName,
    required String clientPhone,
    required String plateNumber,
    required String vehicleModel,
    required double estimatedDamageAmount,
    required String damageDescription,
  }) {
    final now = DateTime.now();
    final isOver1M = estimatedDamageAmount >= 1000000;
    final newRequest = ExpertiseRequestModel(
      id: 'exp_req_${now.millisecondsSinceEpoch}',
      expertId: expertId,
      expertName: expertName,
      clientName: clientName,
      clientPhone: clientPhone,
      plateNumber: plateNumber,
      vehicleModel: vehicleModel,
      estimatedDamageAmount: estimatedDamageAmount,
      isOverOneMillion: isOver1M,
      damageDescription: damageDescription,
      requestDate: now,
    );

    _expertiseRequests.insert(0, newRequest);

    _notifications.insert(
      0,
      AppNotification(
        id: 'notif_exp_${now.millisecondsSinceEpoch}',
        title: 'Mission d\'Expertise Programmée 🔍',
        message: 'L\'expert $expertName a été sollicité pour votre véhicule $plateNumber (Chiffrage estimé : ${estimatedDamageAmount.toInt()} FCFA). Passage prévu sous 48h.',
        timestamp: now,
        icon: Icons.assignment_turned_in_rounded,
        iconColor: const Color(0xFF0284C7),
        type: 'expertise_request',
      ),
    );

    notifyListeners();
  }

  // All Partner Broker Agencies in Senegal
  final List<BrokerAgencyModel> _brokerAgencies = [
    BrokerAgencyModel(
      id: 'broker_dakar_77',
      name: 'Cabinet AssurCourtage Dakar',
      code: 'COURTIER-DAKAR-77',
      managerName: 'M. Ousmane Diop (Courtier Agréé)',
      phone: '+221 33 821 00 00',
      whatsappNumber: '+221 77 500 44 22',
      email: 'contact@assurcourtage.sn',
      address: 'Avenue Cheikh Anta Diop, Dakar',
      city: 'Dakar Fann',
      cimaNumber: 'CIMA-SEN-CRT-2023-018',
      logoPath: 'assets/images/axa_logo.png',
      description: 'Cabinet de courtage d\'assurance automobile agréé CIMA. Spécialiste du suivi rigoureux des sinistres et de l\'indemnisation rapide auprès d\'AXA, SANLAM, SUNU et NSIA.',
      rating: 4.9,
      clientsCount: 1240,
      partnerCompanyIds: ['off_axa', 'off_sanlam', 'off_sunu', 'off_nsia'],
      brokerType: BrokerType.brokerCima,
      totalClaimsDeclared: 50,
      totalClaimsResolved: 46,
      averagePayoutDays: 7,
      reviews: [
        BrokerReviewModel(
          id: 'rev_1',
          authorName: 'Mamadou Lamine Diagne',
          rating: 5.0,
          comment: 'Accident sur la VDN : M. Diop a mandaté l\'expert le jour même. Indemnisation complète de 680 000 FCFA reçue en 6 jours par virement. Un vrai courtier qui se bat pour ses clients !',
          date: DateTime(2025, 8, 14),
          claimType: 'Collision & Dégâts matériels (VDN)',
          claimsPayoutAmount: '680 000 FCFA réglés',
          isVerifiedClaim: true,
        ),
        BrokerReviewModel(
          id: 'rev_2',
          authorName: 'Aïssatou Ndiaye',
          rating: 5.0,
          comment: 'Bris de glace sur autoroute à péage. Le cabinet a pris en charge le remplacement sans aucune franchise chez le vitrier agréé en 24h chrono. Chapeau !',
          date: DateTime(2025, 8, 3),
          claimType: 'Bris de Glace / Pare-brise',
          claimsPayoutAmount: '100% Prise en charge directe',
          isVerifiedClaim: true,
        ),
        BrokerReviewModel(
          id: 'rev_3',
          authorName: 'Cheikh Sarr',
          rating: 4.8,
          comment: 'Très rassurant en cas d\'accrochage. Le constat amiable a été télétransmis via l\'appli et la compagnie adverse a été contrainte de régler sous 10 jours.',
          date: DateTime(2025, 7, 22),
          claimType: 'Recours Tiers Responsable',
          claimsPayoutAmount: '450 000 FCFA indemnisés',
          isVerifiedClaim: true,
        ),
      ],
    ),
    BrokerAgencyModel(
      id: 'broker_pape_faye_99',
      name: 'Cabinet Pape Faye & Partenaires',
      code: 'PAPE-FAYE-COURTAGE-99',
      managerName: 'M. Pape Faye (Courtier Conseil)',
      phone: '+221 77 620 88 99',
      whatsappNumber: '+221 77 620 88 99',
      email: 'contact@papefaye-assurances.sn',
      address: 'Route de l\'Aéroport, Yoff Dakar',
      city: 'Yoff',
      cimaNumber: 'CIMA-SEN-CRT-2024-055',
      logoPath: 'assets/images/sanlam_logo.png',
      description: 'Cabinet de courtage indépendant dédié aux particuliers et professionnels. Accompagnement juridique sans faille jusqu\'au règlement intégral du sinistre.',
      rating: 4.8,
      clientsCount: 780,
      partnerCompanyIds: ['off_sanlam', 'off_axa', 'off_sunu'],
      brokerType: BrokerType.brokerCima,
      totalClaimsDeclared: 35,
      totalClaimsResolved: 31,
      averagePayoutDays: 8,
      reviews: [
        BrokerReviewModel(
          id: 'rev_pf_1',
          authorName: 'Ibrahima Diallo',
          rating: 5.0,
          comment: 'Pape Faye s\'est déplacé en personne pour sécuriser mon constat. Résultat : 520 000 FCFA remboursés par la compagnie sous 8 jours.',
          date: DateTime(2025, 8, 10),
          claimType: 'Accident Carambolage Rocade Fann',
          claimsPayoutAmount: '520 000 FCFA réglés',
          isVerifiedClaim: true,
        ),
        BrokerReviewModel(
          id: 'rev_pf_2',
          authorName: 'Fatou Bintou Seck',
          rating: 4.5,
          comment: 'Excellent suivi de dossier. Très réactif sur WhatsApp et assistance remorquage gratuite.',
          date: DateTime(2025, 7, 29),
          claimType: 'Panne Moteur & Remorquage',
          claimsPayoutAmount: 'Remorquage 0 FCFA',
          isVerifiedClaim: true,
        ),
      ],
    ),
    BrokerAgencyModel(
      id: 'agent_teranga_apporteur_11',
      name: 'Teranga Business (Apporteur d\'Affaires)',
      code: 'TERANGA-APPORTEUR-11',
      managerName: 'M. Modou Ndiaye (Apporteur d\'Affaires Certifié)',
      phone: '+221 77 340 55 66',
      whatsappNumber: '+221 77 340 55 66',
      email: 'modou.apporteur@terangabusiness.sn',
      address: 'Castors, Avenue Bourguiba, Dakar',
      city: 'Castors',
      cimaNumber: 'MANDAT-CRT-DAKAR-2024',
      logoPath: 'assets/images/sunu_logo.png',
      description: 'Apporteur d\'affaires certifié rattaché aux grands cabinets de courtage CIMA. Orientation personnalisée des assurés et suivi des dossiers de sinistres auprès des compagnies.',
      rating: 4.7,
      clientsCount: 420,
      partnerCompanyIds: ['off_sunu', 'off_axa', 'off_nsia'],
      brokerType: BrokerType.businessIntroducer,
      totalClaimsDeclared: 25,
      totalClaimsResolved: 22,
      averagePayoutDays: 9,
      reviews: [
        BrokerReviewModel(
          id: 'rev_app_1',
          authorName: 'Oumar Kane',
          rating: 4.8,
          comment: 'Très bon intermédiaire, m\'a orienté vers la meilleure formule SUNU et m\'a aidé à monter mon dossier de sinistre en 48h.',
          date: DateTime(2025, 8, 1),
          claimType: 'Dégâts de Stationnement',
          claimsPayoutAmount: '230 000 FCFA indemnisés',
          isVerifiedClaim: true,
        ),
      ],
    ),
    BrokerAgencyModel(
      id: 'broker_baobab_33',
      name: 'Baobab Courtage & Conseils',
      code: 'BAOBAB-COURTAGE-33',
      managerName: 'M. Cheikh Tidiane Sy',
      phone: '+221 33 832 45 45',
      whatsappNumber: '+221 77 312 90 90',
      email: 'contact@baobabcourtage.sn',
      address: 'Boulevard de la République, Dakar Plateau',
      city: 'Plateau',
      cimaNumber: 'CIMA-SEN-CRT-2022-009',
      logoPath: 'assets/images/sunu_logo.png',
      description: 'Courtier conseil expert en risques automobiles, transport et responsabilité civile CIMA. Taux de succès élevé dans le règlement des litiges amiables.',
      rating: 4.8,
      clientsCount: 650,
      partnerCompanyIds: ['off_sunu', 'off_axa', 'off_nsia'],
      brokerType: BrokerType.brokerCima,
      totalClaimsDeclared: 40,
      totalClaimsResolved: 35,
      averagePayoutDays: 8,
      reviews: [],
    ),
  ];

  List<BrokerAgencyModel> get brokerAgencies => _brokerAgencies;

  String _selectedBrokerCode = 'COURTIER-DAKAR-77';

  BrokerAgencyModel get currentBrokerAgency {
    final code = _currentUser?.brokerCode ?? _selectedBrokerCode;
    return _brokerAgencies.firstWhere(
      (b) => b.code.toUpperCase() == code.toUpperCase(),
      orElse: () => _brokerAgencies.first,
    );
  }

  void addAgencyReview({
    required String agencyCode,
    required BrokerReviewModel review,
  }) {
    final index = _brokerAgencies.indexWhere((a) => a.code.toUpperCase() == agencyCode.toUpperCase());
    if (index != -1) {
      final old = _brokerAgencies[index];
      final newReviews = List<BrokerReviewModel>.from(old.reviews)..insert(0, review);
      final newRating = ((old.rating * old.reviews.length) + review.rating) / (old.reviews.length + 1);
      _brokerAgencies[index] = old.copyWith(
        reviews: newReviews,
        rating: double.parse(newRating.toStringAsFixed(1)),
      );
      notifyListeners();
    }
  }

  void updateAgencyClaimsStats({
    required String agencyCode,
    required int declared,
    required int resolved,
  }) {
    final index = _brokerAgencies.indexWhere((a) => a.code.toUpperCase() == agencyCode.toUpperCase());
    if (index != -1) {
      final old = _brokerAgencies[index];
      _brokerAgencies[index] = old.copyWith(
        totalClaimsDeclared: declared,
        totalClaimsResolved: resolved,
      );
      notifyListeners();
    }
  }

  void selectBrokerAgency(String code) {
    _selectedBrokerCode = code;
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(brokerCode: code);
    }
    notifyListeners();
  }

  // Moteur Technique CIMA : Barème selon Puissance Fiscale (CV)
  final List<TechnicalRateSchedule> _technicalSchedules = [
    TechnicalRateSchedule(
      minFiscalPower: 2,
      maxFiscalPower: 4,
      categoryName: 'Citadines & Petites Berlines (2 - 4 CV)',
      baseRcPriceFcfa: 85000,
      defenseRecoursFcfa: 12000,
    ),
    TechnicalRateSchedule(
      minFiscalPower: 5,
      maxFiscalPower: 7,
      categoryName: 'Berlines & Compactes (5 - 7 CV)',
      baseRcPriceFcfa: 120000,
      defenseRecoursFcfa: 15000,
    ),
    TechnicalRateSchedule(
      minFiscalPower: 8,
      maxFiscalPower: 10,
      categoryName: 'SUV Urbains & Berlines Routières (8 - 10 CV)',
      baseRcPriceFcfa: 185000,
      defenseRecoursFcfa: 18000,
    ),
    TechnicalRateSchedule(
      minFiscalPower: 11,
      maxFiscalPower: 14,
      categoryName: 'Grandes Routières & 4x4 (11 - 14 CV)',
      baseRcPriceFcfa: 245000,
      defenseRecoursFcfa: 22000,
    ),
    TechnicalRateSchedule(
      minFiscalPower: 15,
      maxFiscalPower: 25,
      categoryName: 'Véhicules Haut de Gamme & V8 (15 CV et +)',
      baseRcPriceFcfa: 320000,
      defenseRecoursFcfa: 25000,
    ),
  ];

  List<TechnicalRateSchedule> get technicalSchedules => _technicalSchedules;

  TechnicalRateSchedule getScheduleForCv(int cv) {
    return _technicalSchedules.firstWhere(
      (s) => cv >= s.minFiscalPower && cv <= s.maxFiscalPower,
      orElse: () => _technicalSchedules[1],
    );
  }

  // Garanties CIMA Officielles
  final List<GuaranteeCoverageModel> _allGuarantees = [
    GuaranteeCoverageModel(
      id: 'g_rc',
      name: 'Responsabilité Civile CIMA',
      coveragePercentage: 100,
      description: 'Couverture intégrale obligatoire des dommages matériels et corporels causés aux tiers.',
      baseRateFactor: 1.0,
      isMandatory: true,
    ),
    GuaranteeCoverageModel(
      id: 'g_dr',
      name: 'Défense & Recours Juridique',
      coveragePercentage: 100,
      description: 'Prise en charge à 100% des frais de justice et recours amiable contre les tiers responsables.',
      baseRateFactor: 0.10,
      isMandatory: true,
    ),
    GuaranteeCoverageModel(
      id: 'g_bg',
      name: 'Bris de Glaces (Sans franchise)',
      coveragePercentage: 100,
      description: 'Remplacement sans franchise du pare-brise, lunette arrière et vitres latérales.',
      baseRateFactor: 0.15,
    ),
    GuaranteeCoverageModel(
      id: 'g_vol',
      name: 'Vol & Tentative de Vol',
      coveragePercentage: 85,
      description: 'Indemnisation à 85% de la valeur vénale avec assistance remorquage prioritaire.',
      baseRateFactor: 0.18,
    ),
    GuaranteeCoverageModel(
      id: 'g_inc',
      name: 'Incendie & Explosion',
      coveragePercentage: 90,
      description: 'Prise en charge des dégâts causés par combustion, court-circuit ou foudre.',
      baseRateFactor: 0.12,
    ),
    GuaranteeCoverageModel(
      id: 'g_dc',
      name: 'Dommages Collision / Tous Accidents',
      coveragePercentage: 95,
      description: 'Remboursement des dégâts subis par votre véhicule même en cas de torts partagés.',
      baseRateFactor: 0.45,
    ),
    GuaranteeCoverageModel(
      id: 'g_sec',
      name: 'Sécurité Conducteur & Passagers',
      coveragePercentage: 100,
      description: 'Capital jusqu\'à 5.000.000 FCFA en cas de blessure ou incapacité.',
      baseRateFactor: 0.08,
    ),
  ];

  List<GuaranteeCoverageModel> get allGuarantees => _allGuarantees;

  // Transactions Récentes
  final List<TransactionModel> _transactions = [
    TransactionModel(
      id: 'tx_1',
      title: 'Paiement assurance auto',
      subtitle: '21 août 2025, 12:49',
      date: DateTime(2025, 8, 21, 12, 49),
      amountFcfa: 250000,
      isPositive: false,
      status: TransactionStatus.success,
      icon: Icons.shield_rounded,
      svgAsset: 'assets/icons/shield_pay.svg',
      iconBgColor: const Color(0xFFEEF2FF),
      iconColor: const Color(0xFF4F46E5),
    ),
    TransactionModel(
      id: 'tx_2',
      title: 'Paiement assurance santé',
      subtitle: '21 août 2025, 08:52',
      date: DateTime(2025, 8, 21, 8, 52),
      amountFcfa: 325000,
      isPositive: false,
      status: TransactionStatus.success,
      icon: Icons.favorite_rounded,
      svgAsset: 'assets/icons/heart_health.svg',
      iconBgColor: const Color(0xFFECFDF5),
      iconColor: const Color(0xFF10B981),
    ),
    TransactionModel(
      id: 'tx_3',
      title: 'Paiement pour De Fily',
      subtitle: '21 août 2025, 08:48',
      date: DateTime(2025, 8, 21, 8, 48),
      amountFcfa: 500000,
      isPositive: false,
      status: TransactionStatus.success,
      icon: Icons.person_rounded,
      svgAsset: 'assets/icons/users_beneficiaries.svg',
      iconBgColor: const Color(0xFFFFFBEB),
      iconColor: const Color(0xFFF59E0B),
    ),
    TransactionModel(
      id: 'tx_4',
      title: 'Cadeau Wave 🎁 (Bonus CIMA)',
      subtitle: '21 août 2025, 08:00',
      date: DateTime(2025, 8, 21, 8, 0),
      amountFcfa: 100000,
      isPositive: true,
      status: TransactionStatus.received,
      icon: Icons.card_giftcard_rounded,
      svgAsset: 'assets/icons/gift_promo.svg',
      iconBgColor: const Color(0xFFFFF1F2),
      iconColor: const Color(0xFFF43F5E),
    ),
  ];

  List<TransactionModel> get transactions => _transactions;

  // Offres Partenaires
  final List<InsuranceOffer> _partnerOffers = [
    InsuranceOffer(
      id: 'off_axa',
      companyName: 'AXA Assurances Sénégal',
      logoPath: 'assets/images/axa_logo.png',
      formulaName: 'Formule Confort Plus',
      priceFcfa: 250000,
      highlights: [
        'Responsabilité Civile CIMA 100%',
        'Défense & Recours 100%',
        'Assistance Remorquage 24/7 Dakar & Régions',
        'Avance sur Recours Tiers',
      ],
      description: 'L\'offre la plus complète négociée pour vous par Cabinet AssurCourtage Dakar.',
      isPopular: true,
    ),
    InsuranceOffer(
      id: 'off_sanlam',
      companyName: 'SANLAM Assurance Sénégal',
      logoPath: 'assets/images/sanlam_logo.png',
      formulaName: 'Formule Sérénité Éco',
      priceFcfa: 185000,
      highlights: [
        'Responsabilité Civile CIMA',
        'Défense & Recours 100%',
        'Bris de Glaces (Plafond 500.000 FCFA)',
        'Assistance Constat Amiable',
      ],
      description: 'Excellent rapport garanties / prix pour circuler l\'esprit tranquille.',
      isPopular: false,
    ),
    InsuranceOffer(
      id: 'off_sunu',
      companyName: 'SUNU Assurances',
      logoPath: 'assets/images/sunu_logo.png',
      formulaName: 'Formule Liberté',
      priceFcfa: 165000,
      highlights: [
        'Responsabilité Civile CIMA',
        'Assistance Panne Sèche & Crevaison',
        'Paiement en 3x Sans Frais',
      ],
      description: 'Tarif très compétitif avec options de paiement mensualisé.',
    ),
    InsuranceOffer(
      id: 'off_nsia',
      companyName: 'NSIA Assurances Sénégal',
      logoPath: 'assets/images/nsia_logo.png',
      formulaName: 'Tous Risques Excellence',
      priceFcfa: 380000,
      highlights: [
        'Tous Risques 100% Valeur à Neuf (1 an)',
        'Vol, Incendie & Vandalisme',
        'Véhicule de Remplacement 15 Jours',
      ],
      description: 'Garantie intégrale pour SUV, 4x4 et berlines haut de gamme.',
    ),
  ];

  List<InsuranceOffer> get partnerOffers => _partnerOffers;
  List<InsuranceOffer> get offers => _partnerOffers;
  final List<BrokerMessage> _brokerMessages = [
    BrokerMessage(
      id: 'msg_1',
      clientId: 'user_serigne_fall',
      clientName: 'Serigne Abdoulaye Fall',
      clientPhone: '+221 77 845 12 34',
      message: 'Bonjour M. Fall, votre attestation d\'assurance AXA pour Toyota Corolla (DK-5489-BG) est disponible sur votre espace Olivia.',
      sentAt: DateTime.now().subtract(const Duration(days: 2)),
      channel: 'whatsapp',
    ),
    BrokerMessage(
      id: 'msg_2',
      clientId: 'pol_client_2',
      clientName: 'Mme Aminata Sow',
      clientPhone: '+221 77 654 32 10',
      message: 'Rappel Échéance CIMA : Votre contrat Peugeot 3008 (DK-9812-AF) expire dans 2 jours. Renouvelez directement sur l\'application.',
      sentAt: DateTime.now().subtract(const Duration(hours: 4)),
      channel: 'notification',
    ),
  ];

  List<BrokerMessage> get brokerMessages => _brokerMessages;

  List<BrokerMessage> getMessagesForClient(String clientIdOrPhone) {
    return _brokerMessages.where((m) =>
      m.clientId == clientIdOrPhone ||
      m.clientPhone.replaceAll(' ', '').contains(clientIdOrPhone.replaceAll(' ', '')) ||
      m.clientName.toLowerCase().contains(clientIdOrPhone.toLowerCase())
    ).toList();
  }

  void sendBrokerMessage({
    required String clientId,
    required String clientName,
    required String clientPhone,
    required String message,
    required String channel,
  }) {
    final now = DateTime.now();
    final newMsg = BrokerMessage(
      id: 'msg_${now.millisecondsSinceEpoch}',
      clientId: clientId,
      clientName: clientName,
      clientPhone: clientPhone,
      message: message,
      sentAt: now,
      channel: channel,
    );

    _brokerMessages.insert(0, newMsg);

    // Add to notifications
    _notifications.insert(
      0,
      AppNotification(
        id: 'notif_msg_${now.millisecondsSinceEpoch}',
        title: 'Message de votre Courtier 🏢',
        message: message,
        timestamp: now,
        icon: Icons.chat_bubble_outline_rounded,
        iconColor: const Color(0xFF4F46E5),
        type: 'broker_message',
      ),
    );

    notifyListeners();
  }

  void addPartnerOffer(InsuranceOffer offer) {
    _partnerOffers.insert(0, offer);
    final agency = currentBrokerAgency;
    if (!agency.partnerCompanyIds.contains(offer.id)) {
      agency.partnerCompanyIds.insert(0, offer.id);
    }
    notifyListeners();
  }


  List<InsuranceOffer> getOffersForAgency(BrokerAgencyModel agency) {
    return _partnerOffers.where((offer) => agency.partnerCompanyIds.contains(offer.id)).toList();
  }

  void subscribeToOffer(InsuranceOffer offer, VehicleModel vehicle) {
    final now = DateTime.now();
    final newPolicy = InsurancePolicy(
      id: 'pol_${now.millisecondsSinceEpoch}',
      policyNumber: 'POL-${offer.companyName.substring(0, 3).toUpperCase()}-${now.year}-${now.millisecondsSinceEpoch.toString().substring(8)}',
      talonNumber: 'TAL-SN-${now.year}-${now.millisecondsSinceEpoch.toString().substring(7)}',
      companyName: offer.companyName,
      companyLogoPath: offer.logoPath,
      coverageType: offer.formulaName,
      premiumAmount: offer.priceFcfa,
      startDate: now,
      endDate: now.add(const Duration(days: 365)),
      status: PolicyStatus.active,
      vehicle: vehicle,
      qrData: 'OLIVIA:TALON:VALID:${vehicle.plateNumber}:${now.toIso8601String()}:${offer.companyName}',
      brokerCode: currentBrokerAgency.code,
      brokerAgencyName: currentBrokerAgency.name,
      clientName: currentUser?.fullName ?? 'Abdoulaye Diop',
      clientPhone: currentUser?.phoneNumber ?? '+221 77 845 12 34',
      guarantees: offer.highlights,
    );

    _policies.insert(0, newPolicy);
    _transactions.insert(
      0,
      TransactionModel(
        id: 'tx_${now.millisecondsSinceEpoch}',
        title: 'Paiement ${offer.formulaName}',
        subtitle: '${offer.companyName} • ${now.day} août ${now.year}',
        date: now,
        amountFcfa: offer.priceFcfa,
        isPositive: false,
        status: TransactionStatus.success,
        icon: Icons.shield_rounded,
        iconBgColor: const Color(0xFFEEF2FF),
        iconColor: const Color(0xFF4F46E5),
      ),
    );
    if (_currentUser != null) {
      db.savePolicies(_currentUser!.id, _policies);
      db.saveTransactions(_currentUser!.id, _transactions);
    }
    notifyListeners();
  }

  // Profil et Véhicule par défaut
  VehicleModel _vehicle = VehicleModel(
    id: 'veh_001',
    plateNumber: 'DK-5489-BG',
    make: 'Toyota',
    model: 'Corolla',
    year: 2021,
    chassisNumber: 'JT3HP10V5K019842',
    fiscalPower: 7,
    fuelType: 'Essence',
  );
  VehicleModel get vehicle => _vehicle;

  void updateVehicle(VehicleModel updated) {
    _vehicle = updated;
    if (_currentUser != null) {
      db.saveVehicle(_currentUser!.id, _vehicle);
    }
    notifyListeners();
  }

  void updateVehiclePhoto(Uint8List bytes) {
    _vehicle = _vehicle.copyWith(registrationCardBytes: bytes);
    if (_currentUser != null) {
      db.saveVehicle(_currentUser!.id, _vehicle);
    }
    notifyListeners();
  }

  void updateUserAvatar(Uint8List bytes) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(avatarBytes: bytes);
      notifyListeners();
    }
  }

  List<InsurancePolicy> _policies = [];
  List<InsurancePolicy> get policies => _policies;

  List<InsurancePolicy> _brokerClients = [];
  List<InsurancePolicy> get brokerClients => _brokerClients;

  void addBrokerClient({
    required String name,
    required String phone,
    required String plate,
    required String model,
  }) {
    final now = DateTime.now();
    final newClientPolicy = InsurancePolicy(
      id: 'pol_${now.millisecondsSinceEpoch}',
      policyNumber: 'POL-AXA-${now.year}-${now.millisecondsSinceEpoch.toString().substring(8)}',
      talonNumber: 'TAL-SN-${now.year}-${now.millisecondsSinceEpoch.toString().substring(7)}',
      companyName: 'AXA Assurances Sénégal',
      companyLogoPath: 'assets/images/axa_logo.png',
      coverageType: 'Formule Confort Plus',
      premiumAmount: 250000,
      startDate: now,
      endDate: now.add(const Duration(days: 365)),
      status: PolicyStatus.active,
      vehicle: VehicleModel(
        id: 'veh_${now.millisecondsSinceEpoch}',
        plateNumber: plate,
        make: model.contains(' ') ? model.split(' ').first : model,
        model: model.contains(' ') ? model.split(' ').sublist(1).join(' ') : 'Berline',
        year: 2022,
        chassisNumber: 'SN${now.millisecondsSinceEpoch}',
        fiscalPower: 7,
        fuelType: 'Essence',
      ),
      qrData: 'OLIVIA:PASS_CIMA:$plate:$name:COURTIER-DAKAR-77',
      brokerCode: 'COURTIER-DAKAR-77',
      brokerAgencyName: 'Cabinet AssurCourtage Dakar',
      clientName: name,
      clientPhone: phone,
      guarantees: ['Responsabilité Civile 100%', 'Défense & Recours 100%', 'Bris de Glaces'],
    );
    _brokerClients.insert(0, newClientPolicy);
    notifyListeners();
  }

  List<InsurancePolicy> get brokerPendingRenewals {
    return _brokerClients.where((p) => p.isExpiringSoon || p.daysUntilExpiration <= 7).toList();
  }

  List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => _notifications;
  int get unreadNotificationCount => _notifications.where((n) => !n.isRead).length;

  void markAllNotificationsAsRead() {
    for (final n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }


  AppState() {
    _initDefaults();
  }

  void _initDefaults() {
    final now = DateTime.now();
    _policies = [
      InsurancePolicy(
        id: 'pol_corolla_2025',
        policyNumber: 'POL-AXA-2025-9841',
        talonNumber: 'TAL-SN-2025-884920',
        companyName: 'AXA Assurances Sénégal',
        companyLogoPath: 'assets/images/axa_logo.png',
        coverageType: 'Formule Confort Plus',
        premiumAmount: 250000,
        startDate: now.subtract(const Duration(days: 340)),
        endDate: now.add(const Duration(days: 28)),
        status: PolicyStatus.active,
        vehicle: _vehicle,
        qrData: 'OLIVIA:TALON:AXA:POL-AXA-2025-9841:DK-5489-BG',
        brokerCode: 'COURTIER-DAKAR-77',
        brokerAgencyName: 'Cabinet AssurCourtage Dakar',
        clientName: 'Abdoulaye Diop',
        clientPhone: '+221 77 845 12 34',
        guarantees: [
          'Responsabilité Civile CIMA 100%',
          'Défense & Recours 100%',
          'Bris de Glaces 100%',
          'Assistance 24/7',
        ],
      ),
    ];

    _brokerClients = [
      _policies.first,
      InsurancePolicy(
        id: 'pol_client_2',
        policyNumber: 'POL-SAN-2025-1102',
        talonNumber: 'TAL-SN-2025-110293',
        companyName: 'SANLAM Assurance Sénégal',
        companyLogoPath: 'assets/images/sanlam_logo.png',
        coverageType: 'Formule Sérénité Éco',
        premiumAmount: 185000,
        startDate: now.subtract(const Duration(days: 363)),
        endDate: now.add(const Duration(days: 2)),
        status: PolicyStatus.expiringSoon,
        vehicle: VehicleModel(
          id: 'veh_002',
          plateNumber: 'DK-9812-AF',
          make: 'Peugeot',
          model: '3008',
          year: 2022,
          chassisNumber: 'VF3MCYHZRKS19284',
          fiscalPower: 8,
          fuelType: 'Diesel',
        ),
        qrData: 'OLIVIA:TALON:SANLAM:POL-SAN-2025-1102:DK-9812-AF',
        brokerCode: 'COURTIER-DAKAR-77',
        brokerAgencyName: 'Cabinet AssurCourtage Dakar',
        clientName: 'Mme Aminata Sow',
        clientPhone: '+221 77 654 32 10',
        guarantees: ['Responsabilité Civile', 'Défense & Recours', 'Vol & Incendie'],
      ),
      InsurancePolicy(
        id: 'pol_client_3',
        policyNumber: 'POL-SUN-2025-7782',
        talonNumber: 'TAL-SN-2025-778201',
        companyName: 'SUNU Assurances',
        companyLogoPath: 'assets/images/sunu_logo.png',
        coverageType: 'Formule Liberté',
        premiumAmount: 165000,
        startDate: now.subtract(const Duration(days: 180)),
        endDate: now.add(const Duration(days: 185)),
        status: PolicyStatus.active,
        vehicle: VehicleModel(
          id: 'veh_003',
          plateNumber: 'DK-3490-CC',
          make: 'Renault',
          model: 'Duster',
          year: 2020,
          chassisNumber: 'VF1HJD28109482',
          fiscalPower: 7,
          fuelType: 'Diesel',
        ),
        qrData: 'OLIVIA:TALON:SUNU:POL-SUN-2025-7782:DK-3490-CC',
        brokerCode: 'COURTIER-DAKAR-77',
        brokerAgencyName: 'Cabinet AssurCourtage Dakar',
        clientName: 'M. Babacar Ndiaye',
        clientPhone: '+221 70 890 12 34',
        guarantees: ['Responsabilité Civile CIMA', 'Assistance 24/7'],
      ),
    ];

    _notifications = [
      AppNotification(
        id: 'notif_1',
        title: 'Échéance Assurance Proche',
        message: 'Votre contrat d\'assurance auto pour Toyota Corolla (DK-5489-BG) expire dans 28 jours.',
        timestamp: now.subtract(const Duration(hours: 3)),
        icon: Icons.access_time_rounded,
        iconColor: const Color(0xFF4F46E5),
        type: 'expiry_alert',
      ),
      AppNotification(
        id: 'notif_2',
        title: 'Pass Numérique CIMA Actif',
        message: 'Votre attestation CIMA dématérialisée est prête. Présentez le QR code aux forces de l\'ordre.',
        timestamp: now.subtract(const Duration(days: 2)),
        icon: Icons.verified_rounded,
        iconColor: const Color(0xFF10B981),
        type: 'talon_ready',
      ),
    ];

    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    await db.init();
    final savedUserId = await db.getActiveSession();
    if (savedUserId != null && savedUserId.isNotEmpty) {
      final users = await db.getAllUsers();
      for (final entry in users.entries) {
        final u = entry.value as Map<String, dynamic>;
        if (u['id'] == savedUserId) {
          _currentUser = UserModel(
            id: u['id'],
            fullName: u['fullName'],
            email: u['email'],
            phoneNumber: u['phoneNumber'],
            role: u['role'] == 'broker' ? UserRole.broker : UserRole.insured,
            brokerCode: u['brokerCode'] ?? 'COURTIER-DAKAR-77',
            brokerAgencyId: u['brokerAgencyId'] ?? 'broker_dakar_77',
          );
          _isAuthenticated = true;
          await _loadUserData(_currentUser!.id);
          notifyListeners();
          return;
        }
      }
    }
  }

  Future<void> _loadUserData(String userId) async {
    final savedVehicle = await db.getVehicle(userId);
    if (savedVehicle != null) {
      _vehicle = savedVehicle;
    }
    final savedPolicies = await db.getPolicies(userId);
    if (savedPolicies != null && savedPolicies.isNotEmpty) {
      _policies = savedPolicies;
    }
    final savedTxs = await db.getTransactions(userId);
    if (savedTxs != null && savedTxs.isNotEmpty) {
      _transactions.clear();
      _transactions.addAll(savedTxs);
    }
  }

  Future<bool> processIntechPayment({
    required String policyId,
    required double amount,
    required String method,
    required String phone,
    String? title,
  }) async {
    final now = DateTime.now();
    final externalTxId = 'TX-SN-${now.millisecondsSinceEpoch}';
    final response = await intechPaymentService.initiatePayment(
      clientPhone: phone,
      amount: amount,
      method: method,
      externalTransactionId: externalTxId,
      userId: _currentUser?.id ?? 'user_anonymous',
      policyId: policyId,
      policyTitle: title ?? 'Assurance Auto CIMA',
    );
    final success = !response.error;
    final policyIndex = _policies.indexWhere((p) => p.id == policyId);
    if (policyIndex != -1) {
      final oldPolicy = _policies[policyIndex];
      final newStartDate = oldPolicy.endDate.isAfter(now) ? oldPolicy.endDate : now;
      final newEndDate = newStartDate.add(const Duration(days: 365));
      _policies[policyIndex] = oldPolicy.copyWithRenewed(newEndDate);
    } else if (_policies.isNotEmpty) {
      final oldPolicy = _policies.first;
      final newStartDate = oldPolicy.endDate.isAfter(now) ? oldPolicy.endDate : now;
      final newEndDate = newStartDate.add(const Duration(days: 365));
      _policies[0] = oldPolicy.copyWithRenewed(newEndDate);
    }

    _transactions.insert(
      0,
      TransactionModel(
        id: 'tx_${now.millisecondsSinceEpoch}',
        title: title ?? 'Renouvellement assurance auto',
        subtitle: '${method.toUpperCase()} Sénégal • ${now.day} août ${now.year}',
        date: now,
        amountFcfa: amount,
        isPositive: false,
        status: success ? TransactionStatus.success : TransactionStatus.pending,
        icon: Icons.shield_rounded,
        svgAsset: 'assets/icons/shield_pay.svg',
        iconBgColor: const Color(0xFFEEF2FF),
        iconColor: const Color(0xFF4F46E5),
      ),
    );

    if (_currentUser != null) {
      await db.savePolicies(_currentUser!.id, _policies);
      await db.saveTransactions(_currentUser!.id, _transactions);
    }

    notifyListeners();
    return success;
  }

  void renewPolicy(String policyId, {required String paymentMethod}) {
    final index = _policies.indexWhere((p) => p.id == policyId);
    if (index != -1) {
      final old = _policies[index];
      final newEndDate = old.endDate.add(const Duration(days: 365));
      final renewed = old.copyWithRenewed(newEndDate);
      _policies[index] = renewed;

      _transactions.insert(
        0,
        TransactionModel(
          id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Paiement assurance auto (${old.companyName})',
          subtitle: '${DateTime.now().day} août 2025, ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
          date: DateTime.now(),
          amountFcfa: old.premiumAmount,
          isPositive: false,
          status: TransactionStatus.success,
          icon: Icons.shield_rounded,
          iconBgColor: const Color(0xFFEEF2FF),
          iconColor: const Color(0xFF4F46E5),
        ),
      );

      if (_currentUser != null) {
        db.savePolicies(_currentUser!.id, _policies);
        db.saveTransactions(_currentUser!.id, _transactions);
      }
      notifyListeners();
    }
  }

  void brokerProcessRenewal(String policyId) {
    final index = _brokerClients.indexWhere((p) => p.id == policyId);
    if (index != -1) {
      final old = _brokerClients[index];
      final newEndDate = old.endDate.add(const Duration(days: 365));
      final renewed = old.copyWithRenewed(newEndDate);
      _brokerClients[index] = renewed;
      notifyListeners();
    }
  }

  Future<void> registerClientWithCarteGrise({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String plateNumber,
    required String make,
    required String model,
    required int fiscalPower,
    required String fuelType,
    Uint8List? carteGriseBytes,
    required String brokerCode,
  }) async {
    final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    _currentUser = UserModel(
      id: userId,
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      role: UserRole.insured,
      brokerCode: brokerCode,
      brokerAgencyId: 'broker_dakar_77',
    );
    _vehicle = VehicleModel(
      id: 'veh_${DateTime.now().millisecondsSinceEpoch}',
      plateNumber: plateNumber.toUpperCase(),
      make: make,
      model: model,
      year: 2022,
      chassisNumber: 'SN-VIN-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
      fiscalPower: fiscalPower,
      fuelType: fuelType,
      registrationCardBytes: carteGriseBytes,
    );

    final now = DateTime.now();
    _policies = [
      InsurancePolicy(
        id: 'pol_init_${now.millisecondsSinceEpoch}',
        policyNumber: 'POL-AXA-${now.year}-0091',
        talonNumber: 'TAL-SN-${now.year}-${now.millisecondsSinceEpoch.toString().substring(7)}',
        companyName: 'AXA Assurances Sénégal',
        companyLogoPath: 'assets/images/axa_logo.png',
        coverageType: 'Formule Confort Plus CIMA',
        premiumAmount: getScheduleForCv(fiscalPower).calculateAnnualTotal(),
        startDate: now,
        endDate: now.add(const Duration(days: 365)),
        status: PolicyStatus.active,
        vehicle: _vehicle,
        qrData: 'OLIVIA:TALON:VALID:$plateNumber:${now.toIso8601String()}',
        brokerCode: brokerCode,
        brokerAgencyName: currentBrokerAgency.name,
        clientName: fullName,
        clientPhone: phoneNumber,
        guarantees: [
          'Responsabilité Civile CIMA 100%',
          'Défense & Recours Juridique',
          'Assistance 24/7',
        ],
      ),
    ];

    await db.saveUser(_currentUser!, password: password);
    await db.saveVehicle(userId, _vehicle);
    await db.savePolicies(userId, _policies);
    await db.saveSession(userId);

    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> loginUser({required String emailOrPhone, required String password}) async {
    await db.init();
    final user = await db.findUser(emailOrPhone, password);
    if (user != null) {
      _currentUser = user;
      _isAuthenticated = true;
      await db.saveSession(user.id);
      await _loadUserData(user.id);

      if (_policies.isEmpty && user.role == UserRole.insured) {
        final now = DateTime.now();
        _policies = [
          InsurancePolicy(
            id: 'pol_${user.id}_01',
            policyNumber: 'POL-AXA-${now.year}-0091',
            talonNumber: 'TAL-SN-${now.year}-${now.millisecondsSinceEpoch.toString().substring(7)}',
            companyName: 'AXA Assurances Sénégal',
            companyLogoPath: 'assets/images/axa_logo.png',
            coverageType: 'Formule Confort Plus',
            premiumAmount: 250000,
            startDate: now.subtract(const Duration(days: 337)),
            endDate: now.add(const Duration(days: 28)),
            status: PolicyStatus.active,
            vehicle: _vehicle,
            qrData: 'OLIVIA:TALON:AXA:POL-AXA-${now.year}-0091:${_vehicle.plateNumber}',
            brokerCode: user.brokerCode ?? 'COURTIER-DAKAR-77',
            brokerAgencyName: currentBrokerAgency.name,
            clientName: user.fullName,
            clientPhone: user.phoneNumber,
            guarantees: [
              'Responsabilité Civile CIMA 100%',
              'Défense & Recours Juridique',
              'Bris de Glaces 100%',
              'Assistance 24/7 Dakar & Régions',
            ],
          ),
        ];
        await db.savePolicies(user.id, _policies);
      }
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await db.clearSession();
    _isAuthenticated = false;
    _currentUser = null;
    notifyListeners();
  }
}
