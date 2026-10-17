import 'package:cloud_firestore/cloud_firestore.dart';

class LiveSessionModel {
  final String id;
  final String courseId;
  final String courseName;
  final String title;
  final String teacherId;
  final String teacherName;
  final String teacherPhotoUrl;
  final String status;
  final String roomName;
  final bool hasReplay;
  final String? replayUrl;
  final String? replayDuration;
  final int participantCount;
  final List<String> connectedParticipants;
  final DateTime scheduledAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  // teacher_live | corrector_live
  final String sessionType;
  // teacher | corrector
  final String hostRole;
  // interactive | exercises
  final String phase;
  final DateTime? phaseSwitchedAt;
  final String? liveKitRoomUrl;
  final String? liveKitToken;

  LiveSessionModel({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.title,
    required this.teacherId,
    required this.teacherName,
    this.teacherPhotoUrl = '',
    required this.status,
    required this.roomName,
    this.hasReplay = false,
    this.replayUrl,
    this.replayDuration,
    this.participantCount = 0,
    this.connectedParticipants = const [],
    required this.scheduledAt,
    this.startedAt,
    this.endedAt,
    this.sessionType = 'teacher_live',
    this.hostRole = 'teacher',
    this.phase = 'interactive',
    this.phaseSwitchedAt,
    this.liveKitRoomUrl,
    this.liveKitToken,
  });

  bool get isLive => status == 'live';
  bool get isEnded => status == 'ended';
  bool get isCorrectorLive => sessionType == 'corrector_live';
  int get activeViewersCount => participantCount > 0 ? participantCount : 1;
  int get totalDurationMinutes => 90;
  int get interactiveDurationMinutes => isCorrectorLive ? 0 : 60;
  int get exercisesDurationMinutes => isCorrectorLive ? 90 : 30;

  LiveSessionModel copyWith({
    String? status,
    String? phase,
    bool? hasReplay,
    String? replayUrl,
    String? replayDuration,
    int? participantCount,
    List<String>? connectedParticipants,
    DateTime? endedAt,
  }) {
    return LiveSessionModel(
      id: id,
      courseId: courseId,
      courseName: courseName,
      title: title,
      teacherId: teacherId,
      teacherName: teacherName,
      teacherPhotoUrl: teacherPhotoUrl,
      status: status ?? this.status,
      roomName: roomName,
      hasReplay: hasReplay ?? this.hasReplay,
      replayUrl: replayUrl ?? this.replayUrl,
      replayDuration: replayDuration ?? this.replayDuration,
      participantCount: participantCount ?? this.participantCount,
      connectedParticipants: connectedParticipants ?? this.connectedParticipants,
      scheduledAt: scheduledAt,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      sessionType: sessionType,
      hostRole: hostRole,
      phase: phase ?? this.phase,
      phaseSwitchedAt: phaseSwitchedAt,
      liveKitRoomUrl: liveKitRoomUrl,
      liveKitToken: liveKitToken,
    );
  }

  factory LiveSessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return LiveSessionModel.fromJson(data, doc.id);
  }

  factory LiveSessionModel.fromJson(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic val, DateTime fallback) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val) ?? fallback;
      return fallback;
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final effectiveId = id.isNotEmpty ? id : (data['id']?.toString() ?? 'live_default');

    return LiveSessionModel(
      id: effectiveId,
      courseId: data['courseId']?.toString() ?? '',
      courseName: data['courseName']?.toString() ?? 'Formation',
      title: data['title']?.toString() ?? 'Session en direct',
      teacherId: data['teacherId']?.toString() ?? '',
      teacherName: data['teacherName']?.toString() ?? 'Formateur',
      teacherPhotoUrl: (data['teacherPhotoURL'] ?? data['teacherPhotoUrl'] ?? '').toString(),
      status: data['status']?.toString() ?? 'scheduled',
      roomName: data['roomName']?.toString() ?? effectiveId,
      hasReplay: data['hasReplay'] == true,
      replayUrl: data['replayUrl']?.toString(),
      replayDuration: data['replayDuration']?.toString(),
      participantCount: (data['participantCount'] as num?)?.toInt() ?? 1,
      connectedParticipants: (data['connectedParticipants'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      scheduledAt: parseDate(data['scheduledAt'], DateTime.now()),
      startedAt: parseNullableDate(data['startedAt']),
      endedAt: parseNullableDate(data['endedAt']),
      sessionType: data['sessionType']?.toString() ?? 'teacher_live',
      hostRole: data['hostRole']?.toString() ?? 'teacher',
      phase: data['phase']?.toString() ?? 'interactive',
      phaseSwitchedAt: parseNullableDate(data['phaseSwitchedAt']),
      liveKitRoomUrl: data['liveKitRoomUrl']?.toString(),
      liveKitToken: data['liveKitToken']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'courseName': courseName,
      'title': title,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'teacherPhotoUrl': teacherPhotoUrl,
      'status': status,
      'roomName': roomName,
      'hasReplay': hasReplay,
      'replayUrl': replayUrl,
      'replayDuration': replayDuration,
      'participantCount': participantCount,
      'connectedParticipants': connectedParticipants,
      'scheduledAt': scheduledAt.toIso8601String(),
      if (startedAt != null) 'startedAt': startedAt!.toIso8601String(),
      if (endedAt != null) 'endedAt': endedAt!.toIso8601String(),
      'sessionType': sessionType,
      'hostRole': hostRole,
      'phase': phase,
      if (phaseSwitchedAt != null) 'phaseSwitchedAt': phaseSwitchedAt!.toIso8601String(),
      if (liveKitRoomUrl != null) 'liveKitRoomUrl': liveKitRoomUrl,
      if (liveKitToken != null) 'liveKitToken': liveKitToken,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'courseName': courseName,
      'title': title,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'teacherPhotoURL': teacherPhotoUrl,
      'status': status,
      'roomName': roomName,
      'hasReplay': hasReplay,
      'replayUrl': replayUrl,
      'replayDuration': replayDuration,
      'participantCount': participantCount,
      'connectedParticipants': connectedParticipants,
      'scheduledAt': scheduledAt,
      if (startedAt != null) 'startedAt': startedAt,
      if (endedAt != null) 'endedAt': endedAt,
      'sessionType': sessionType,
      'hostRole': hostRole,
      'phase': phase,
      if (phaseSwitchedAt != null) 'phaseSwitchedAt': phaseSwitchedAt,
      if (liveKitRoomUrl != null) 'liveKitRoomUrl': liveKitRoomUrl,
      if (liveKitToken != null) 'liveKitToken': liveKitToken,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
