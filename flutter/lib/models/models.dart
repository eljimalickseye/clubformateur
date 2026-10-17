import 'dart:typed_data';
import 'package:flutter/material.dart';

enum UserRole {
  insured,
  broker,
}

enum PolicyStatus {
  active,
  expiringSoon,
  expired,
  renewed,
}

enum TransactionStatus {
  success,
  received,
  pending,
  failed,
}

class TransactionModel {
  final String id;
  final String title;
  final String subtitle;
  final DateTime date;
  final double amountFcfa;
  final bool isPositive;
  final TransactionStatus status;
  final IconData icon;
  final String? svgAsset;
  final Color iconBgColor;
  final Color iconColor;

  TransactionModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.amountFcfa,
    required this.isPositive,
    required this.status,
    required this.icon,
    this.svgAsset,
    required this.iconBgColor,
    required this.iconColor,
  });

  String get formattedAmount {
    final prefix = isPositive ? '+' : '-';
    final formatted = amountFcfa.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
    return '$prefix$formatted FCFA';
  }

  String get formattedStatus {
    switch (status) {
      case TransactionStatus.success:
        return 'Réussi';
      case TransactionStatus.received:
        return 'Reçu';
      case TransactionStatus.pending:
        return 'En attente';
      case TransactionStatus.failed:
        return 'Échoué';
    }
  }

  Color get statusColor {
    switch (status) {
      case TransactionStatus.success:
        return const Color(0xFF4F46E5);
      case TransactionStatus.received:
        return const Color(0xFF10B981);
      case TransactionStatus.pending:
        return const Color(0xFFF59E0B);
      case TransactionStatus.failed:
        return const Color(0xFFEF4444);
    }
  }
}

class GuaranteeCoverageModel {
  final String id;
  final String name;
  final double coveragePercentage;
  final String description;
  final double baseRateFactor;
  final bool isMandatory;

  GuaranteeCoverageModel({
    required this.id,
    required this.name,
    required this.coveragePercentage,
    required this.description,
    required this.baseRateFactor,
    this.isMandatory = false,
  });
}

class TechnicalRateSchedule {
  final int minFiscalPower;
  final int maxFiscalPower;
  final String categoryName;
  final double baseRcPriceFcfa;
  final double defenseRecoursFcfa;
  final double fgaRatePercentage;
  final double taxRegistrationPercentage;

  TechnicalRateSchedule({
    required this.minFiscalPower,
    required this.maxFiscalPower,
    required this.categoryName,
    required this.baseRcPriceFcfa,
    this.defenseRecoursFcfa = 15000,
    this.fgaRatePercentage = 2.5,
    this.taxRegistrationPercentage = 10.0,
  });

  double calculateAnnualTotal({
    bool includeVolIncendie = false,
    bool includeBrisDeGlace = false,
    bool includeTousRisques = false,
  }) {
    double total = baseRcPriceFcfa + defenseRecoursFcfa;
    if (includeVolIncendie) total += baseRcPriceFcfa * 0.18;
    if (includeBrisDeGlace) total += 25000;
    if (includeTousRisques) total += baseRcPriceFcfa * 0.65;

    final fga = total * (fgaRatePercentage / 100);
    final taxes = total * (taxRegistrationPercentage / 100);
    return (total + fga + taxes + 5000).roundToDouble();
  }
}

class DynamicPhoto {
  final String id;
  final String? assetPath;
  final Uint8List? bytes;
  final String fileName;
  final DateTime createdAt;

  DynamicPhoto({
    required this.id,
    this.assetPath,
    this.bytes,
    required this.fileName,
    required this.createdAt,
  });

  bool get isBytes => bytes != null && bytes!.isNotEmpty;
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final IconData icon;
  final String? svgAsset;
  final Color iconColor;
  final String type;
  bool isRead;
  final String? actionRoute;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.icon,
    this.svgAsset,
    required this.iconColor,
    required this.type,
    this.isRead = false,
    this.actionRoute,
  });
}

enum BrokerType {
  brokerCima,
  businessIntroducer,
}

class BrokerReviewModel {
  final String id;
  final String authorName;
  final double rating;
  final String comment;
  final DateTime date;
  final String claimType;
  final String claimsPayoutAmount;
  final bool isVerifiedClaim;

  BrokerReviewModel({
    required this.id,
    required this.authorName,
    required this.rating,
    required this.comment,
    required this.date,
    required this.claimType,
    required this.claimsPayoutAmount,
    this.isVerifiedClaim = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorName': authorName,
        'rating': rating,
        'comment': comment,
        'date': date.toIso8601String(),
        'claimType': claimType,
        'claimsPayoutAmount': claimsPayoutAmount,
        'isVerifiedClaim': isVerifiedClaim,
      };

  factory BrokerReviewModel.fromJson(Map<String, dynamic> json) => BrokerReviewModel(
        id: json['id'] ?? '',
        authorName: json['authorName'] ?? '',
        rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : 5.0,
        comment: json['comment'] ?? '',
        date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
        claimType: json['claimType'] ?? 'Sinistre Auto CIMA',
        claimsPayoutAmount: json['claimsPayoutAmount'] ?? 'Règlement Intégral',
        isVerifiedClaim: json['isVerifiedClaim'] ?? true,
      );
}

class BrokerAgencyModel {
  final String id;
  final String name;
  final String code;
  final String managerName;
  final String phone;
  final String whatsappNumber;
  final String email;
  final String address;
  final String city;
  final String cimaNumber;
  final String logoPath;
  final String description;
  final double rating;
  final int clientsCount;
  final List<String> partnerCompanyIds;
  final BrokerType brokerType;
  final int totalClaimsDeclared;
  final int totalClaimsResolved;
  final int averagePayoutDays;
  final List<BrokerReviewModel> reviews;

  BrokerAgencyModel({
    required this.id,
    required this.name,
    required this.code,
    required this.managerName,
    required this.phone,
    required this.whatsappNumber,
    required this.email,
    required this.address,
    required this.city,
    required this.cimaNumber,
    required this.logoPath,
    required this.description,
    this.rating = 4.9,
    this.clientsCount = 850,
    required this.partnerCompanyIds,
    this.brokerType = BrokerType.brokerCima,
    this.totalClaimsDeclared = 50,
    this.totalClaimsResolved = 46,
    this.averagePayoutDays = 8,
    this.reviews = const [],
  });

  double get claimsResolutionRate => totalClaimsDeclared > 0
      ? (totalClaimsResolved / totalClaimsDeclared) * 100.0
      : 0.0;

  bool get isPlatformCertified => claimsResolutionRate >= 80.0;

  String get typeLabel => brokerType == BrokerType.brokerCima
      ? 'Courtier Agréé CIMA'
      : 'Apporteur d\'Affaires';

  String get inviteUrl => 'https://olivia-sn.web.app/?broker=${Uri.encodeComponent(code)}';
  String get inviteQrData => 'OLIVIA:INVITE:BROKER:$code:$name:$cimaNumber';

  BrokerAgencyModel copyWith({
    String? name,
    double? rating,
    int? totalClaimsDeclared,
    int? totalClaimsResolved,
    List<BrokerReviewModel>? reviews,
    BrokerType? brokerType,
  }) {
    return BrokerAgencyModel(
      id: id,
      name: name ?? this.name,
      code: code,
      managerName: managerName,
      phone: phone,
      whatsappNumber: whatsappNumber,
      email: email,
      address: address,
      city: city,
      cimaNumber: cimaNumber,
      logoPath: logoPath,
      description: description,
      rating: rating ?? this.rating,
      clientsCount: clientsCount,
      partnerCompanyIds: partnerCompanyIds,
      brokerType: brokerType ?? this.brokerType,
      totalClaimsDeclared: totalClaimsDeclared ?? this.totalClaimsDeclared,
      totalClaimsResolved: totalClaimsResolved ?? this.totalClaimsResolved,
      averagePayoutDays: averagePayoutDays,
      reviews: reviews ?? this.reviews,
    );
  }
}

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final UserRole role;
  final String? brokerCode;
  final String? brokerAgencyId;
  final Uint8List? avatarBytes;
  final String? clientAccessToken;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.role = UserRole.insured,
    this.brokerCode,
    this.brokerAgencyId,
    this.avatarBytes,
    this.clientAccessToken,
  });

  UserModel copyWith({
    String? fullName,
    String? email,
    String? phoneNumber,
    UserRole? role,
    String? brokerCode,
    String? brokerAgencyId,
    Uint8List? avatarBytes,
    String? clientAccessToken,
  }) {
    return UserModel(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      brokerCode: brokerCode ?? this.brokerCode,
      brokerAgencyId: brokerAgencyId ?? this.brokerAgencyId,
      avatarBytes: avatarBytes ?? this.avatarBytes,
      clientAccessToken: clientAccessToken ?? this.clientAccessToken,
    );
  }
}

class VehicleModel {
  final String id;
  final String plateNumber;
  final String make;
  final String model;
  final int year;
  final String chassisNumber;
  final int fiscalPower;
  final String fuelType;
  final String registrationCardImage;
  final Uint8List? registrationCardBytes;

  VehicleModel({
    required this.id,
    required this.plateNumber,
    required this.make,
    required this.model,
    required this.year,
    required this.chassisNumber,
    required this.fiscalPower,
    required this.fuelType,
    this.registrationCardImage = '',
    this.registrationCardBytes,
  });

  VehicleModel copyWith({
    String? plateNumber,
    String? make,
    String? model,
    int? year,
    String? chassisNumber,
    int? fiscalPower,
    String? fuelType,
    String? registrationCardImage,
    Uint8List? registrationCardBytes,
  }) {
    return VehicleModel(
      id: id,
      plateNumber: plateNumber ?? this.plateNumber,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      chassisNumber: chassisNumber ?? this.chassisNumber,
      fiscalPower: fiscalPower ?? this.fiscalPower,
      fuelType: fuelType ?? this.fuelType,
      registrationCardImage: registrationCardImage ?? this.registrationCardImage,
      registrationCardBytes: registrationCardBytes ?? this.registrationCardBytes,
    );
  }
}

class InsurancePolicy {
  final String id;
  final String policyNumber;
  final String talonNumber;
  final String companyName;
  final String companyLogoPath;
  final String coverageType;
  final double premiumAmount;
  final DateTime startDate;
  final DateTime endDate;
  final PolicyStatus status;
  final VehicleModel vehicle;
  final String qrData;
  final String? brokerCode;
  final String? brokerAgencyName;
  final String? clientName;
  final String? clientPhone;
  final List<String> guarantees;

  InsurancePolicy({
    required this.id,
    required this.policyNumber,
    required this.talonNumber,
    required this.companyName,
    required this.companyLogoPath,
    required this.coverageType,
    required this.premiumAmount,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.vehicle,
    required this.qrData,
    this.brokerCode,
    this.brokerAgencyName,
    this.clientName,
    this.clientPhone,
    required this.guarantees,
  });

  int get daysUntilExpiration {
    final now = DateTime.now();
    return endDate.difference(now).inDays;
  }

  bool get isExpiringSoon => daysUntilExpiration <= 7 && daysUntilExpiration >= 0;

  String get clientCompleteQrData {
    return 'OLIVIA:PASS_CIMA_NUMERIQUE\n'
        'Nom: ${clientName ?? "Abdoulaye Diop"}\n'
        'Tél: ${clientPhone ?? "+221 77 845 12 34"}\n'
        'Immatriculation: ${vehicle.plateNumber}\n'
        'Véhicule: ${vehicle.make} ${vehicle.model} (${vehicle.year})\n'
        'Châssis VIN: ${vehicle.chassisNumber}\n'
        'Puissance: ${vehicle.fiscalPower} CV | ${vehicle.fuelType}\n'
        'Courtier: ${brokerAgencyName ?? "Cabinet AssurCourtage Dakar"} (${brokerCode ?? "COURTIER-DAKAR-77"})\n'
        'Assureur: $companyName\n'
        'Contrat: $policyNumber\n'
        'Talon CIMA: $talonNumber\n'
        'Garanties: ${guarantees.join(", ")}\n'
        'Validité: ${endDate.day}/${endDate.month}/${endDate.year}';
  }

  InsurancePolicy copyWithRenewed(DateTime newEndDate) {
    return InsurancePolicy(
      id: id,
      policyNumber: policyNumber,
      talonNumber: 'TAL-SN-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      companyName: companyName,
      companyLogoPath: companyLogoPath,
      coverageType: coverageType,
      premiumAmount: premiumAmount,
      startDate: endDate,
      endDate: newEndDate,
      status: PolicyStatus.active,
      vehicle: vehicle,
      qrData: 'OLIVIA:TALON:VALID:$policyNumber:${vehicle.plateNumber}:${newEndDate.toIso8601String()}:$companyName',
      brokerCode: brokerCode,
      brokerAgencyName: brokerAgencyName,
      clientName: clientName,
      clientPhone: clientPhone,
      guarantees: guarantees,
    );
  }
}

class InsuranceOffer {
  final String id;
  final String companyName;
  final String logoPath;
  final String formulaName;
  final double priceFcfa;
  final List<String> highlights;
  final String description;
  final bool isPopular;

  InsuranceOffer({
    required this.id,
    required this.companyName,
    required this.logoPath,
    required this.formulaName,
    required this.priceFcfa,
    required this.highlights,
    required this.description,
    this.isPopular = false,
  });
}

class BrokerMessage {
  final String id;
  final String clientId;
  final String clientName;
  final String clientPhone;
  final String message;
  final DateTime sentAt;
  final String channel;
  final bool isDelivered;

  BrokerMessage({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.clientPhone,
    required this.message,
    required this.sentAt,
    required this.channel,
    this.isDelivered = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientId': clientId,
        'clientName': clientName,
        'clientPhone': clientPhone,
        'message': message,
        'sentAt': sentAt.toIso8601String(),
        'channel': channel,
        'isDelivered': isDelivered,
      };

  factory BrokerMessage.fromJson(Map<String, dynamic> json) => BrokerMessage(
        id: json['id'] ?? '',
        clientId: json['clientId'] ?? '',
        clientName: json['clientName'] ?? '',
        clientPhone: json['clientPhone'] ?? '',
        message: json['message'] ?? '',
        sentAt: DateTime.tryParse(json['sentAt'] ?? '') ?? DateTime.now(),
        channel: json['channel'] ?? 'whatsapp',
        isDelivered: json['isDelivered'] ?? true,
      );
}


enum ActorCategory {
  broker,
  automotiveExpert,
  businessIntroducer,
  approvedGarage,
}

class AutomotiveExpertModel {
  final String id;
  final String cabinetName;
  final String expertName;
  final String registrationNumber;
  final String phone;
  final String whatsappNumber;
  final String email;
  final String address;
  final String city;
  final double rating;
  final int totalExpertisesDone;
  final double acceptanceRatePercentage;
  final int averageTurnaroundHours;
  final String specialties;
  final List<BrokerReviewModel> reviews;

  AutomotiveExpertModel({
    required this.id,
    required this.cabinetName,
    required this.expertName,
    required this.registrationNumber,
    required this.phone,
    required this.whatsappNumber,
    required this.email,
    required this.address,
    required this.city,
    this.rating = 4.9,
    this.totalExpertisesDone = 320,
    this.acceptanceRatePercentage = 98.0,
    this.averageTurnaroundHours = 48,
    required this.specialties,
    this.reviews = const [],
  });
}

class ApprovedGarageModel {
  final String id;
  final String garageName;
  final String managerName;
  final String phone;
  final String whatsappNumber;
  final String address;
  final String city;
  final double rating;
  final int repairsCompleted;
  final String specialties;
  final bool hasDirectBilling;

  ApprovedGarageModel({
    required this.id,
    required this.garageName,
    required this.managerName,
    required this.phone,
    required this.whatsappNumber,
    required this.address,
    required this.city,
    this.rating = 4.8,
    this.repairsCompleted = 540,
    required this.specialties,
    this.hasDirectBilling = true,
  });
}

class ExpertiseRequestModel {
  final String id;
  final String expertId;
  final String expertName;
  final String clientName;
  final String clientPhone;
  final String plateNumber;
  final String vehicleModel;
  final double estimatedDamageAmount;
  final bool isOverOneMillion;
  final String damageDescription;
  final DateTime requestDate;
  final String status;

  ExpertiseRequestModel({
    required this.id,
    required this.expertId,
    required this.expertName,
    required this.clientName,
    required this.clientPhone,
    required this.plateNumber,
    required this.vehicleModel,
    required this.estimatedDamageAmount,
    required this.isOverOneMillion,
    required this.damageDescription,
    required this.requestDate,
    this.status = 'En attente de visite technique',
  });
}
