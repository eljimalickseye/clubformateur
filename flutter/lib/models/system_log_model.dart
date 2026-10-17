import 'package:cloud_firestore/cloud_firestore.dart';

class SystemLogModel {
  final String id;
  final DateTime timestamp;
  final String level; // 'info', 'success', 'warning', 'error'
  final String category; // 'auth', 'payment', 'course', 'live', 'system'
  final String action;
  final String actorName;
  final String actorRole; // 'Étudiant', 'Formateur', 'Super Admin', 'Système'
  final String details;
  final Map<String, dynamic> metadata;
  final String ipAddress;
  final String platform;

  SystemLogModel({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.category,
    required this.action,
    required this.actorName,
    required this.actorRole,
    required this.details,
    this.metadata = const {},
    this.ipAddress = '196.207.249.12',
    this.platform = 'Web (Chrome / Windows)',
  });

  factory SystemLogModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime dt = DateTime.now();
    if (data['timestamp'] is Timestamp) {
      dt = (data['timestamp'] as Timestamp).toDate();
    } else if (data['timestamp'] is String) {
      dt = DateTime.tryParse(data['timestamp']) ?? DateTime.now();
    } else if (data['timestamp'] is int) {
      dt = DateTime.fromMillisecondsSinceEpoch(data['timestamp']);
    }

    return SystemLogModel(
      id: id,
      timestamp: dt,
      level: data['level']?.toString() ?? 'info',
      category: data['category']?.toString() ?? 'system',
      action: data['action']?.toString() ?? 'Action système',
      actorName: data['actorName']?.toString() ?? 'Système',
      actorRole: data['actorRole']?.toString() ?? 'Système',
      details: data['details']?.toString() ?? '',
      metadata: data['metadata'] is Map ? Map<String, dynamic>.from(data['metadata']) : {},
      ipAddress: data['ipAddress']?.toString() ?? '196.207.249.12',
      platform: data['platform']?.toString() ?? 'Web',
    );
  }

  factory SystemLogModel.fromFirestore(DocumentSnapshot doc) {
    return SystemLogModel.fromMap(
      doc.data() as Map<String, dynamic>? ?? {},
      doc.id,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'level': level,
      'category': category,
      'action': action,
      'actorName': actorName,
      'actorRole': actorRole,
      'details': details,
      'metadata': metadata,
      'ipAddress': ipAddress,
      'platform': platform,
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'timestamp': Timestamp.fromDate(timestamp),
      'level': level,
      'category': category,
      'action': action,
      'actorName': actorName,
      'actorRole': actorRole,
      'details': details,
      'metadata': metadata,
      'ipAddress': ipAddress,
      'platform': platform,
    };
  }
}
