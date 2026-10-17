class AppointmentModel {
  final String id;
  final String teacherId;
  final String teacherName;
  final String? teacherPhoto;
  final String studentId;
  final String studentName;
  final String? studentEmail;
  final String? studentPhone;
  final DateTime date;
  final String timeSlot;
  final String sessionType;
  final String notes;
  final String status; // 'CONFIRMED', 'PENDING', 'CANCELLED'
  final DateTime createdAt;

  AppointmentModel({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    this.teacherPhoto,
    required this.studentId,
    required this.studentName,
    this.studentEmail,
    this.studentPhone,
    required this.date,
    required this.timeSlot,
    required this.sessionType,
    this.notes = '',
    this.status = 'CONFIRMED',
    required this.createdAt,
  });

  factory AppointmentModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic val) {
      if (val is DateTime) return val;
      if (val != null) {
        final parsed = DateTime.tryParse(val.toString());
        if (parsed != null) return parsed;
      }
      return DateTime.now();
    }

    return AppointmentModel(
      id: id.isNotEmpty ? id : (data['id']?.toString() ?? ''),
      teacherId: data['teacherId']?.toString() ?? '',
      teacherName: data['teacherName']?.toString() ?? 'Formateur',
      teacherPhoto: data['teacherPhoto']?.toString(),
      studentId: data['studentId']?.toString() ?? '',
      studentName: data['studentName']?.toString() ?? 'Apprenant',
      studentEmail: data['studentEmail']?.toString(),
      studentPhone: data['studentPhone']?.toString(),
      date: parseDate(data['date']),
      timeSlot: data['timeSlot']?.toString() ?? '10:00 - 11:00',
      sessionType: data['sessionType']?.toString() ?? 'Mentorat individuel',
      notes: data['notes']?.toString() ?? '',
      status: data['status']?.toString() ?? 'CONFIRMED',
      createdAt: parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'teacherPhoto': teacherPhoto,
      'studentId': studentId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'studentPhone': studentPhone,
      'date': date.toIso8601String(),
      'timeSlot': timeSlot,
      'sessionType': sessionType,
      'notes': notes,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
