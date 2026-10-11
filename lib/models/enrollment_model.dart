import 'package:cloud_firestore/cloud_firestore.dart';

class EnrollmentModel {
  final String id;
  final String studentId;
  final String studentName;
  final String courseId;
  final String courseTitle;
  final String courseImage;
  final String trainerName;
  final String category;
  final int price;
  final String paymentMethod;
  final String status; // 'active', 'completed'
  final DateTime enrolledAt;

  EnrollmentModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.courseId,
    required this.courseTitle,
    required this.courseImage,
    required this.trainerName,
    required this.category,
    required this.price,
    this.paymentMethod = 'Wave',
    this.status = 'active',
    required this.enrolledAt,
  });

  factory EnrollmentModel.fromFirestore(DocumentSnapshot doc) {
    return EnrollmentModel.fromMap(doc.data() as Map<String, dynamic>? ?? {}, doc.id);
  }

  factory EnrollmentModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime date = DateTime.now();
    if (data['enrolledAt'] is Timestamp) {
      date = (data['enrolledAt'] as Timestamp).toDate();
    } else if (data['enrolledAt'] != null) {
      date = DateTime.tryParse(data['enrolledAt'].toString()) ?? DateTime.now();
    }

    return EnrollmentModel(
      id: id.isNotEmpty ? id : (data['id']?.toString() ?? ''),
      studentId: data['studentId'] ?? data['userId'] ?? '',
      studentName: data['studentName'] ?? data['userName'] ?? 'Apprenant',
      courseId: data['courseId'] ?? '',
      courseTitle: data['courseTitle'] ?? 'Formation',
      courseImage: data['courseImage'] ?? '',
      trainerName: data['trainerName'] ?? 'Formateur Expert',
      category: data['category'] ?? 'Formation',
      price: (data['price'] as num?)?.toInt() ?? 25000,
      paymentMethod: data['paymentMethod'] ?? 'Wave',
      status: data['status'] ?? 'active',
      enrolledAt: date,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'userId': studentId,
      'studentName': studentName,
      'courseId': courseId,
      'courseTitle': courseTitle,
      'courseImage': courseImage,
      'trainerName': trainerName,
      'category': category,
      'price': price,
      'paymentMethod': paymentMethod,
      'status': status,
      'enrolledAt': FieldValue.serverTimestamp(),
    };
  }
}
