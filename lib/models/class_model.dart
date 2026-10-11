import 'package:cloud_firestore/cloud_firestore.dart';

class ClassScheduleSlot {
  final String dayOfWeek; // Lundi, Mardi, Mercredi, Jeudi, Vendredi, Samedi
  final String startTime; // ex: '10:00'
  final String endTime;   // ex: '12:00'
  final String subject;   // ex: 'Algorithmique & Structures de données'
  final String roomOrLink;
  final String type;      // 'Cours magistral (Titulaire)', 'Travaux dirigés (Correcteur)', 'Live Q&A'

  ClassScheduleSlot({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.subject,
    this.roomOrLink = 'Salle Virtuelle Live',
    this.type = 'Cours magistral (Titulaire)',
  });

  factory ClassScheduleSlot.fromMap(Map<String, dynamic> map) {
    return ClassScheduleSlot(
      dayOfWeek: map['dayOfWeek'] ?? 'Lundi',
      startTime: map['startTime'] ?? '09:00',
      endTime: map['endTime'] ?? '11:00',
      subject: map['subject'] ?? 'Session de cours',
      roomOrLink: map['roomOrLink'] ?? 'Salle Virtuelle Live',
      type: map['type'] ?? 'Cours magistral (Titulaire)',
    );
  }

  Map<String, dynamic> toMap() => {
    'dayOfWeek': dayOfWeek,
    'startTime': startTime,
    'endTime': endTime,
    'subject': subject,
    'roomOrLink': roomOrLink,
    'type': type,
  };
}

class ClassCohortModel {
  final String id;
  final String name;
  final String courseId;
  final String courseName;
  final int maxCapacity; // 100 étudiants
  final List<String> studentIds;
  final Map<String, String> studentNames;
  final Map<String, String> studentEmails;
  final Map<String, String> studentPhones;
  final String teacherId; // Formateur Titulaire
  final String teacherName;
  final String correctorId; // Correcteur Dédié
  final String correctorName;
  final String academicYear;
  final List<ClassScheduleSlot> schedule;
  final DateTime createdAt;

  ClassCohortModel({
    required this.id,
    required this.name,
    required this.courseId,
    required this.courseName,
    this.maxCapacity = 100,
    this.studentIds = const [],
    this.studentNames = const {},
    this.studentEmails = const {},
    this.studentPhones = const {},
    required this.teacherId,
    required this.teacherName,
    required this.correctorId,
    required this.correctorName,
    this.academicYear = '2026-2027',
    this.schedule = const [],
    required this.createdAt,
  });

  int get studentCount => studentIds.length;
  bool get isFull => studentCount >= maxCapacity;

  factory ClassCohortModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    final rawSchedule = map['schedule'];
    List<ClassScheduleSlot> scheduleList = [];
    if (rawSchedule is List) {
      scheduleList = rawSchedule
          .map((s) => ClassScheduleSlot.fromMap(Map<String, dynamic>.from(s as Map)))
          .toList();
    }

    return ClassCohortModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      name: map['name'] ?? 'Classe sans nom',
      courseId: map['courseId'] ?? '',
      courseName: map['courseName'] ?? 'Formation',
      maxCapacity: (map['maxCapacity'] as num?)?.toInt() ?? 100,
      studentIds: map['studentIds'] is List ? List<String>.from(map['studentIds']) : [],
      studentNames: map['studentNames'] is Map
          ? Map<String, String>.from(map['studentNames'] as Map)
          : {},
      studentEmails: map['studentEmails'] is Map
          ? Map<String, String>.from(map['studentEmails'] as Map)
          : {},
      studentPhones: map['studentPhones'] is Map
          ? Map<String, String>.from(map['studentPhones'] as Map)
          : {},
      teacherId: map['teacherId'] ?? '',
      teacherName: map['teacherName'] ?? 'Professeur Titulaire',
      correctorId: map['correctorId'] ?? '',
      correctorName: map['correctorName'] ?? 'Correcteur Dédié',
      academicYear: map['academicYear'] ?? '2026-2027',
      schedule: scheduleList,
      createdAt: parseDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'courseId': courseId,
    'courseName': courseName,
    'maxCapacity': maxCapacity,
    'studentIds': studentIds,
    'studentNames': studentNames,
    'studentEmails': studentEmails,
    'studentPhones': studentPhones,
    'teacherId': teacherId,
    'teacherName': teacherName,
    'correctorId': correctorId,
    'correctorName': correctorName,
    'academicYear': academicYear,
    'schedule': schedule.map((s) => s.toMap()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };
}
