import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherStudentRegistrationModel {
  final String id;
  final String registrationNumber; // Ex: INS-2026-8921
  final String teacherId;
  final String teacherName;
  final String teacherPhoto;
  final String subject; // Matière (ex: Mathématiques)
  final String studentId;
  final String studentLastName;
  final String studentFirstName;
  final String birthDate; // JJ/MM/AAAA
  final String birthPlace; // Lieu de naissance
  final String phone;
  final String email;
  final String studyLevel; // L1, L2, L3, Master 1, Master 2
  final String fieldOfStudy; // Filière
  final String academicYear; // Ex: 2026-2027
  final String proposedSchedule; // Emploi du temps proposé
  final int fee; // Montant payé en FCFA
  final String paymentMethod; // Wave, Orange Money, etc.
  final String paymentStatus; // 'Paiement confirmé'
  final String status; // 'Inscription confirmée'
  final DateTime createdAt;

  TeacherStudentRegistrationModel({
    required this.id,
    required this.registrationNumber,
    required this.teacherId,
    required this.teacherName,
    this.teacherPhoto = '',
    required this.subject,
    required this.studentId,
    required this.studentLastName,
    required this.studentFirstName,
    required this.birthDate,
    required this.birthPlace,
    required this.phone,
    required this.email,
    required this.studyLevel,
    required this.fieldOfStudy,
    this.academicYear = '2026-2027',
    required this.proposedSchedule,
    required this.fee,
    this.paymentMethod = 'Wave',
    this.paymentStatus = 'Paiement confirmé',
    this.status = 'Inscription confirmée',
    required this.createdAt,
  });

  String get studentFullName => '$studentFirstName $studentLastName'.trim();

  factory TeacherStudentRegistrationModel.fromFirestore(DocumentSnapshot doc) {
    return TeacherStudentRegistrationModel.fromMap(
      doc.data() as Map<String, dynamic>? ?? {},
      doc.id,
    );
  }

  factory TeacherStudentRegistrationModel.fromMap(
    Map<String, dynamic> data,
    String id,
  ) {
    DateTime date = DateTime.now();
    if (data['createdAt'] is Timestamp) {
      date = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] != null) {
      date = DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now();
    }

    return TeacherStudentRegistrationModel(
      id: id.isNotEmpty ? id : (data['id']?.toString() ?? ''),
      registrationNumber: data['registrationNumber']?.toString() ??
          'INS-${date.year}-${id.length >= 4 ? id.substring(0, 4).toUpperCase() : "1001"}',
      teacherId: data['teacherId']?.toString() ?? '',
      teacherName: data['teacherName']?.toString() ?? 'Professeur',
      teacherPhoto: data['teacherPhoto']?.toString() ?? '',
      subject: data['subject']?.toString() ?? 'Matière générale',
      studentId: data['studentId']?.toString() ?? data['userId']?.toString() ?? '',
      studentLastName: data['studentLastName']?.toString() ?? '',
      studentFirstName: data['studentFirstName']?.toString() ?? '',
      birthDate: data['birthDate']?.toString() ?? '',
      birthPlace: data['birthPlace']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      studyLevel: data['studyLevel']?.toString() ?? 'L1',
      fieldOfStudy: data['fieldOfStudy']?.toString() ?? 'Générale',
      academicYear: data['academicYear']?.toString() ?? '2026-2027',
      proposedSchedule: data['proposedSchedule']?.toString() ?? 'Samedi & Dimanche : 10h00 - 12h30',
      fee: (data['fee'] as num?)?.toInt() ?? 25000,
      paymentMethod: data['paymentMethod']?.toString() ?? 'Wave',
      paymentStatus: data['paymentStatus']?.toString() ?? 'Paiement confirmé',
      status: data['status']?.toString() ?? 'Inscription confirmée',
      createdAt: date,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'registrationNumber': registrationNumber,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'teacherPhoto': teacherPhoto,
      'subject': subject,
      'studentId': studentId,
      'studentLastName': studentLastName,
      'studentFirstName': studentFirstName,
      'studentFullName': studentFullName,
      'birthDate': birthDate,
      'birthPlace': birthPlace,
      'phone': phone,
      'email': email,
      'studyLevel': studyLevel,
      'fieldOfStudy': fieldOfStudy,
      'academicYear': academicYear,
      'proposedSchedule': proposedSchedule,
      'fee': fee,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
