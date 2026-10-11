import 'package:cloud_firestore/cloud_firestore.dart';

class HomeworkModel {
  final String id;
  final String courseId;
  final String courseName;
  final String teacherId;
  final String teacherName;
  final String title;
  final String description;
  final DateTime deadline;
  final List<String> attachmentUrls;
  final List<String> attachmentNames;
  final int points;
  final List<String> allowedSubmissionTypes;
  final DateTime createdAt;

  HomeworkModel({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.teacherId,
    required this.teacherName,
    required this.title,
    required this.description,
    required this.deadline,
    this.attachmentUrls = const [],
    this.attachmentNames = const [],
    this.points = 20,
    this.allowedSubmissionTypes = const ['blank_page', 'photo_sheet', 'word_document'],
    required this.createdAt,
  });

  String get instructions => description;

  String getAttachmentName(int index) {
    if (index >= 0 && index < attachmentNames.length && attachmentNames[index].isNotEmpty) {
      return attachmentNames[index];
    }
    if (index >= 0 && index < attachmentUrls.length) {
      return extractFileName(attachmentUrls[index]);
    }
    return 'Fichier joint';
  }

  static String extractFileName(String url) {
    if (url.startsWith('data:')) {
      return 'Fichier_joint';
    }
    try {
      final uri = Uri.parse(url);
      final lastSegment = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'document';
      final clean = Uri.decodeComponent(lastSegment);
      if (clean.contains('_')) {
        final parts = clean.split('_');
        if (parts.length > 1 && int.tryParse(parts[0]) != null) {
          return parts.sublist(1).join('_');
        }
      }
      return clean;
    } catch (_) {
      return 'document';
    }
  }

  factory HomeworkModel.fromMap(Map<String, dynamic> d, String id) {
    DateTime parseDate(dynamic v, [DateTime? fallback]) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? (fallback ?? DateTime.now());
      return fallback ?? DateTime.now();
    }

    final rawUrls = d['attachmentUrls'] is List
        ? List<String>.from(d['attachmentUrls'])
        : (d['submission_url'] != null && d['submission_url'].toString().isNotEmpty
            ? [d['submission_url'].toString()]
            : <String>[]);

    final rawNames = d['attachmentNames'] is List
        ? List<String>.from(d['attachmentNames'])
        : rawUrls.map(extractFileName).toList();

    final allowed = d['allowedSubmissionTypes'] is List
        ? List<String>.from(d['allowedSubmissionTypes'])
        : const ['blank_page', 'photo_sheet', 'word_document'];

    return HomeworkModel(
      id: id,
      courseId: d['courseId']?.toString() ?? d['course_id']?.toString() ?? '',
      courseName: d['courseName']?.toString() ?? d['course_title']?.toString() ?? 'Formation',
      teacherId: d['teacherId']?.toString() ?? d['teacher_id']?.toString() ?? '',
      teacherName: d['teacherName']?.toString() ?? 'Formateur',
      title: d['title']?.toString() ?? 'Devoir pratique',
      description: d['description']?.toString() ?? '',
      deadline: parseDate(d['deadline'], DateTime.now().add(const Duration(days: 7))),
      attachmentUrls: rawUrls,
      attachmentNames: rawNames,
      points: (d['points'] as num?)?.toInt() ?? 20,
      allowedSubmissionTypes: allowed,
      createdAt: parseDate(d['createdAt'] ?? d['created_at']),
    );
  }

  factory HomeworkModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return HomeworkModel.fromMap(d, doc.id);
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'courseId': courseId,
        'courseName': courseName,
        'teacherId': teacherId,
        'teacherName': teacherName,
        'title': title,
        'description': description,
        'deadline': deadline.toIso8601String(),
        'attachmentUrls': attachmentUrls,
        'attachmentNames': attachmentNames,
        'points': points,
        'allowedSubmissionTypes': allowedSubmissionTypes,
        'createdAt': createdAt.toIso8601String(),
      };
}

class HomeworkSubmissionModel {
  final String id;
  final String homeworkId;
  final String studentId;
  final String studentName;
  final List<String> fileUrls;
  final String status; // 'pending' | 'corrected'
  final DateTime submittedAt;
  final String submissionType; // 'blank_page' | 'photo_sheet' | 'word_document'
  final String? blankPageContent; // Contenu rédigé sur la page blanche numérique
  final String? attachmentName; // Nom du fichier photo/word
  final double? grade; // Note sur 20
  final String? feedback; // Appréciation du correcteur
  final String? correctedBy;
  final DateTime? correctedAt;

  HomeworkSubmissionModel({
    required this.id,
    required this.homeworkId,
    required this.studentId,
    required this.studentName,
    this.fileUrls = const [],
    this.status = 'pending',
    required this.submittedAt,
    this.submissionType = 'blank_page',
    this.blankPageContent,
    this.attachmentName,
    this.grade,
    this.feedback,
    this.correctedBy,
    this.correctedAt,
  });

  double? get note => grade;
  String? get comment => feedback;
  String? get fileUrl => fileUrls.isNotEmpty ? fileUrls.first : null;

  factory HomeworkSubmissionModel.fromMap(Map<String, dynamic> d, String id) {
    DateTime parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return HomeworkSubmissionModel(
      id: id,
      homeworkId: d['homeworkId']?.toString() ?? '',
      studentId: d['studentId']?.toString() ?? d['student_id']?.toString() ?? '',
      studentName: d['studentName']?.toString() ?? d['student_name']?.toString() ?? 'Élève',
      fileUrls: d['fileUrls'] is List ? List<String>.from(d['fileUrls']) : [],
      status: d['status']?.toString() ?? 'pending',
      submittedAt: parseDate(d['submittedAt'] ?? d['submitted_at']),
      submissionType: d['submissionType']?.toString() ?? (d['blankPageContent'] != null ? 'blank_page' : 'photo_sheet'),
      blankPageContent: d['blankPageContent']?.toString(),
      attachmentName: d['attachmentName']?.toString(),
      grade: (d['grade'] as num?)?.toDouble() ?? (d['note'] as num?)?.toDouble(),
      feedback: d['feedback']?.toString() ?? d['comment']?.toString(),
      correctedBy: d['correctedBy']?.toString() ?? d['correctorName']?.toString(),
      correctedAt: d['correctedAt'] != null ? parseDate(d['correctedAt']) : null,
    );
  }

  factory HomeworkSubmissionModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return HomeworkSubmissionModel.fromMap(d, doc.id);
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'homeworkId': homeworkId,
        'studentId': studentId,
        'studentName': studentName,
        'fileUrls': fileUrls,
        'status': status,
        'submittedAt': submittedAt.toIso8601String(),
        'submissionType': submissionType,
        'blankPageContent': blankPageContent,
        'attachmentName': attachmentName,
        'grade': grade,
        'feedback': feedback,
        'correctedBy': correctedBy,
        'correctedAt': correctedAt?.toIso8601String(),
      };
}

class CorrectionModel {
  final String id;
  final String submissionId;
  final String homeworkId;
  final String correctorId;
  final String correctorName;
  final String studentId;
  final double? note;
  final String comment;
  final String? correctedFileUrl;
  final DateTime correctedAt;

  CorrectionModel({
    required this.id,
    required this.submissionId,
    required this.homeworkId,
    required this.correctorId,
    required this.correctorName,
    required this.studentId,
    this.note,
    this.comment = '',
    this.correctedFileUrl,
    required this.correctedAt,
  });

  factory CorrectionModel.fromMap(Map<String, dynamic> d, String id) {
    DateTime parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return CorrectionModel(
      id: id,
      submissionId: d['submissionId']?.toString() ?? '',
      homeworkId: d['homeworkId']?.toString() ?? '',
      correctorId: d['correctorId']?.toString() ?? d['corrector_id']?.toString() ?? '',
      correctorName: d['correctorName']?.toString() ?? d['corrector_name']?.toString() ?? 'Correcteur',
      studentId: d['studentId']?.toString() ?? d['student_id']?.toString() ?? '',
      note: (d['note'] as num?)?.toDouble() ?? (d['score'] as num?)?.toDouble(),
      comment: d['comment']?.toString() ?? d['feedback']?.toString() ?? '',
      correctedFileUrl: d['correctedFileUrl']?.toString(),
      correctedAt: parseDate(d['correctedAt'] ?? d['corrected_at']),
    );
  }

  factory CorrectionModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return CorrectionModel.fromMap(d, doc.id);
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'submissionId': submissionId,
        'homeworkId': homeworkId,
        'correctorId': correctorId,
        'correctorName': correctorName,
        'studentId': studentId,
        'note': note,
        'comment': comment,
        'correctedFileUrl': correctedFileUrl,
        'correctedAt': correctedAt.toIso8601String(),
      };
}
