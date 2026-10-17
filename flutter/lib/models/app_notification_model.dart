import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type; // 'enrollment', 'live_started', 'homework_submitted', 'homework_graded', 'chat_message', 'system'
  final DateTime timestamp;
  final bool isRead;
  final String? actionRoute;
  final Map<String, dynamic> data;

  const AppNotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.actionRoute,
    this.data = const {},
  });

  AppNotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    String? type,
    DateTime? timestamp,
    bool? isRead,
    String? actionRoute,
    Map<String, dynamic>? data,
  }) {
    return AppNotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      actionRoute: actionRoute ?? this.actionRoute,
      data: data ?? this.data,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'actionRoute': actionRoute,
      'data': data,
    };
  }

  factory AppNotificationModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parsedDate;
    final rawTs = map['timestamp'];
    if (rawTs is Timestamp) {
      parsedDate = rawTs.toDate();
    } else if (rawTs is String) {
      parsedDate = DateTime.tryParse(rawTs) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return AppNotificationModel(
      id: docId ?? map['id'] ?? 'notif_${DateTime.now().millisecondsSinceEpoch}',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? 'system',
      timestamp: parsedDate,
      isRead: map['isRead'] == true,
      actionRoute: map['actionRoute'],
      data: map['data'] is Map ? Map<String, dynamic>.from(map['data']) : {},
    );
  }

  factory AppNotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AppNotificationModel.fromMap(data, doc.id);
  }
}
