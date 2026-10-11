import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  // 'student' | 'teacher' | 'corrector' | 'super_admin'
  final String role;
  final String? phoneNumber;
  final List<String> interests;
  final List<String> expertises;
  final String? photoUrl;
  final int onboardingStep;
  final bool isEmailVerified;
  final DateTime? createdAt;
  final String? linkedTeacherId;
  final String? linkedCorrectorId;
  final Map<String, String> legalAcceptances;
  final String? experienceYears;
  final String? bio;
  final String? speciality;
  final String? quote;
  final List<String> skills;
  final List<Map<String, dynamic>> weeklySchedule;
  final bool isApproved;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.phoneNumber,
    this.interests = const [],
    this.expertises = const [],
    this.photoUrl,
    this.onboardingStep = 1,
    this.isEmailVerified = false,
    this.createdAt,
    this.linkedTeacherId,
    this.linkedCorrectorId,
    this.legalAcceptances = const {},
    this.experienceYears,
    this.bio,
    this.speciality,
    this.quote,
    this.skills = const [],
    this.weeklySchedule = const [],
    this.isApproved = true,
  });

  bool get isTeacher    => role == 'teacher';
  bool get isStudent    => role == 'student';
  bool get isCorrector  => role == 'corrector';
  bool get isSuperAdmin => role == 'super_admin';
  bool get isVerified   => isApproved;

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    int parseStep(dynamic s) {
      if (s == null) return 3;
      if (s is int) return s;
      if (s is num) return s.toInt();
      return int.tryParse(s.toString()) ?? 3;
    }

    DateTime? parseDate(dynamic d) {
      if (d == null) return null;
      if (d is DateTime) return d;
      if (d is Timestamp) return d.toDate();
      return DateTime.tryParse(d.toString());
    }

    List<String> parseList(dynamic l) {
      if (l is List) {
        return l.where((e) => e != null).map((e) => e.toString()).toList();
      }
      return const [];
    }

    Map<String, String> parseMap(dynamic m) {
      if (m is Map) {
        final res = <String, String>{};
        m.forEach((k, v) {
          if (k != null && v != null) {
            res[k.toString()] = v.toString();
          }
        });
        return res;
      }
      return const {};
    }

    return UserModel(
      uid: uid,
      email: data['email']?.toString() ?? '',
      displayName: data['displayName']?.toString() ?? 'Utilisateur',
      role: data['role']?.toString() ?? 'student',
      phoneNumber: data['phoneNumber']?.toString(),
      interests: parseList(data['interests']),
      expertises: parseList(data['expertises']),
      photoUrl: data['photoUrl']?.toString() ?? data['photoURL']?.toString(),
      onboardingStep: parseStep(data['onboardingStep']),
      isEmailVerified: data['isEmailVerified'] == true || data['isEmailVerified'] == null,
      createdAt: parseDate(data['createdAt']),
      linkedTeacherId: data['linkedTeacherId']?.toString(),
      linkedCorrectorId: data['linkedCorrectorId']?.toString(),
      legalAcceptances: parseMap(data['legalAcceptances']),
      experienceYears: data['experienceYears']?.toString(),
      bio: data['bio']?.toString(),
      speciality: data['speciality']?.toString(),
      quote: data['quote']?.toString(),
      skills: parseList(data['skills'] ?? data['expertises']),
      weeklySchedule: (data['weeklySchedule'] is List)
          ? (data['weeklySchedule'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : [],
      isApproved: data['isApproved'] == true || data['isVerified'] == true || (data['role'] != 'teacher'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role,
      'phoneNumber': phoneNumber,
      'interests': interests,
      'expertises': expertises,
      'photoUrl': photoUrl,
      'onboardingStep': onboardingStep,
      'isEmailVerified': isEmailVerified,
      'isApproved': isApproved,
      'isVerified': isApproved,
      if (linkedTeacherId != null) 'linkedTeacherId': linkedTeacherId,
      if (linkedCorrectorId != null) 'linkedCorrectorId': linkedCorrectorId,
      'legalAcceptances': legalAcceptances,
      if (experienceYears != null) 'experienceYears': experienceYears,
      if (bio != null) 'bio': bio,
      if (speciality != null) 'speciality': speciality,
      if (quote != null) 'quote': quote,
      if (skills.isNotEmpty) 'skills': skills,
      if (weeklySchedule.isNotEmpty) 'weeklySchedule': weeklySchedule,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  UserModel copyWith({
    String? displayName,
    String? phoneNumber,
    List<String>? interests,
    List<String>? expertises,
    String? photoUrl,
    int? onboardingStep,
    bool? isEmailVerified,
    String? role,
    String? linkedTeacherId,
    String? linkedCorrectorId,
    Map<String, String>? legalAcceptances,
    String? experienceYears,
    String? bio,
    String? speciality,
    String? quote,
    List<String>? skills,
    List<Map<String, dynamic>>? weeklySchedule,
    bool? isApproved,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      interests: interests ?? this.interests,
      expertises: expertises ?? this.expertises,
      photoUrl: photoUrl ?? this.photoUrl,
      onboardingStep: onboardingStep ?? this.onboardingStep,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt,
      linkedTeacherId: linkedTeacherId ?? this.linkedTeacherId,
      linkedCorrectorId: linkedCorrectorId ?? this.linkedCorrectorId,
      legalAcceptances: legalAcceptances ?? this.legalAcceptances,
      isApproved: isApproved ?? this.isApproved,
      experienceYears: experienceYears ?? this.experienceYears,
      bio: bio ?? this.bio,
      speciality: speciality ?? this.speciality,
      quote: quote ?? this.quote,
      skills: skills ?? this.skills,
      weeklySchedule: weeklySchedule ?? this.weeklySchedule,
    );
  }

  static UserModel get demoStudent => UserModel(
        uid: 'demo_student_moussa',
        email: 'moussa.ndiaye@gmail.com',
        displayName: 'Moussa Ndiaye',
        role: 'student',
        phoneNumber: '+221 77 123 45 67',
        interests: ['Informatique', 'Marketing', 'Business'],
        photoUrl: 'assets/images/student-man.jpeg',
        onboardingStep: 3,
        isEmailVerified: true,
      );

  static UserModel get demoTeacher => UserModel(
        uid: 'demo_teacher_cheikh',
        email: 'cheikh.diop@club-des-formateurs.sn',
        displayName: 'Cheikh Diop',
        role: 'teacher',
        phoneNumber: '+221 78 456 78 90',
        expertises: ['Informatique', 'Developpement web', 'React', 'Node.js'],
        photoUrl: 'assets/images/student-library.jpeg',
        onboardingStep: 3,
        isEmailVerified: true,
        linkedCorrectorId: 'demo_corrector_aminata',
      );

  static UserModel get demoCorrector => UserModel(
        uid: 'demo_corrector_aminata',
        email: 'aminata.fall@club-des-formateurs.sn',
        displayName: 'Aminata Fall',
        role: 'corrector',
        phoneNumber: '+221 76 987 65 43',
        expertises: ['Correction', 'Pedagogie', 'Evaluation'],
        photoUrl: 'assets/images/student-man.jpeg',
        onboardingStep: 3,
        isEmailVerified: true,
        linkedTeacherId: 'demo_teacher_cheikh',
      );

  static UserModel get demoAdmin => UserModel(
        uid: 'admin_master_1',
        email: 'admin@clubdesformateurs.com',
        displayName: 'Administrateur Général',
        role: 'super_admin',
        phoneNumber: '+221 77 000 00 00',
        expertises: ['Administration', 'Supervision'],
        photoUrl: 'assets/images/student-man.jpeg',
        onboardingStep: 3,
        isEmailVerified: true,
        isApproved: true,
      );
}
