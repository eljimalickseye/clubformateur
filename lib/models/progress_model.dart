import 'package:cloud_firestore/cloud_firestore.dart';

class StudentProgressModel {
  final String courseId;
  final String userId;
  final List<String> completedLessonIds;
  final String? lastWatchedLessonId;
  final double progressPercentage;
  final DateTime lastUpdatedAt;

  StudentProgressModel({
    required this.courseId,
    required this.userId,
    this.completedLessonIds = const [],
    this.lastWatchedLessonId,
    this.progressPercentage = 0.0,
    required this.lastUpdatedAt,
  });

  bool isLessonCompleted(String lessonId) => completedLessonIds.contains(lessonId);

  factory StudentProgressModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    DateTime updated = DateTime.now();
    if (data['lastUpdatedAt'] is Timestamp) {
      updated = (data['lastUpdatedAt'] as Timestamp).toDate();
    }

    return StudentProgressModel(
      courseId: data['courseId'] ?? doc.id,
      userId: data['userId'] ?? '',
      completedLessonIds: List<String>.from(data['completedLessonIds'] ?? []),
      lastWatchedLessonId: data['lastWatchedLessonId'],
      progressPercentage: (data['progressPercentage'] as num?)?.toDouble() ?? 0.0,
      lastUpdatedAt: updated,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'userId': userId,
      'completedLessonIds': completedLessonIds,
      'lastWatchedLessonId': lastWatchedLessonId,
      'progressPercentage': progressPercentage,
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    };
  }
}
