import 'package:cloud_firestore/cloud_firestore.dart';

class StudentPaymentModel {
  final String id;
  final String studentId;
  final String studentName;
  final String courseId;
  final String courseTitle;
  final String monthLabel; // ex: 'Octobre 2026'
  final int amount; // in FCFA
  final String paymentMethod; // Wave, Orange Money, Carte Bancaire, Free Money
  final String transactionRef;
  final String receiptNumber;
  final String status; // 'COMPLETED', 'PENDING'
  final DateTime paidAt;
  final bool isMonthlyFee;

  StudentPaymentModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.courseId,
    required this.courseTitle,
    required this.monthLabel,
    required this.amount,
    required this.paymentMethod,
    required this.transactionRef,
    required this.receiptNumber,
    this.status = 'COMPLETED',
    required this.paidAt,
    this.isMonthlyFee = true,
  });

  factory StudentPaymentModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return StudentPaymentModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? 'Apprenant',
      courseId: map['courseId'] ?? '',
      courseTitle: map['courseTitle'] ?? 'Formation & Scolarité',
      monthLabel: map['monthLabel'] ?? 'Mois en cours',
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      paymentMethod: map['paymentMethod'] ?? 'Wave Sénégal',
      transactionRef: map['transactionRef'] ?? 'TRX-DEFAULT',
      receiptNumber: map['receiptNumber'] ?? 'REC-DEFAULT',
      status: map['status'] ?? 'COMPLETED',
      paidAt: parseDate(map['paidAt']),
      isMonthlyFee: map['isMonthlyFee'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'studentId': studentId,
    'studentName': studentName,
    'courseId': courseId,
    'courseTitle': courseTitle,
    'monthLabel': monthLabel,
    'amount': amount,
    'paymentMethod': paymentMethod,
    'transactionRef': transactionRef,
    'receiptNumber': receiptNumber,
    'status': status,
    'paidAt': paidAt.toIso8601String(),
    'isMonthlyFee': isMonthlyFee,
  };
}
