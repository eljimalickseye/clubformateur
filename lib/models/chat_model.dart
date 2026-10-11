import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, audio, link, file }

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String senderPhotoUrl;
  final String senderRole; // 'teacher', 'student', 'corrector', 'admin'
  final String content;
  final MessageType type;
  final String? fileUrl;
  final String? fileName;
  final int? audioDuration; // in seconds
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl = '',
    required this.senderRole,
    required this.content,
    this.type = MessageType.text,
    this.fileUrl,
    this.fileName,
    this.audioDuration,
    required this.createdAt,
  });

  bool get isAudio => type == MessageType.audio;
  bool get isImage => type == MessageType.image;
  bool get isLink => type == MessageType.link;

  factory MessageModel.fromMap(Map<String, dynamic> data, [String? docId]) {
    MessageType msgType = MessageType.text;
    final typeStr = data['type'] as String? ?? 'text';
    if (typeStr == 'image') msgType = MessageType.image;
    else if (typeStr == 'audio') msgType = MessageType.audio;
    else if (typeStr == 'link') msgType = MessageType.link;
    else if (typeStr == 'file') msgType = MessageType.file;

    DateTime date = DateTime.now();
    if (data['createdAt'] is Timestamp) {
      date = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      date = DateTime.tryParse(data['createdAt'] as String) ?? DateTime.now();
    } else if (data['createdAt'] is int) {
      date = DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int);
    }

    return MessageModel(
      id: docId ?? data['id'] ?? 'msg_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: data['conversationId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Utilisateur',
      senderPhotoUrl: data['senderPhotoURL'] ?? data['senderPhotoUrl'] ?? '',
      senderRole: data['senderRole'] ?? 'student',
      content: data['content'] ?? '',
      type: msgType,
      fileUrl: data['fileUrl'] ?? data['audioUrl'] ?? data['imageUrl'],
      fileName: data['fileName'],
      audioDuration: (data['audioDuration'] as num?)?.toInt(),
      createdAt: date,
    );
  }

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MessageModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoURL': senderPhotoUrl,
      'senderRole': senderRole,
      'content': content,
      'type': type.name,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'audioDuration': audioDuration,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toLocalMap() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoURL': senderPhotoUrl,
      'senderRole': senderRole,
      'content': content,
      'type': type.name,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'audioDuration': audioDuration,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? senderPhotoUrl,
    String? senderRole,
    String? content,
    MessageType? type,
    String? fileUrl,
    String? fileName,
    int? audioDuration,
    DateTime? createdAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
      senderRole: senderRole ?? this.senderRole,
      content: content ?? this.content,
      type: type ?? this.type,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      audioDuration: audioDuration ?? this.audioDuration,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ConversationModel {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final Map<String, String> participantPhotos;
  final String lastMessage;
  final DateTime lastMessageAt;
  final Map<String, int> unreadCount;
  final String courseName;
  final String? courseId;

  ConversationModel({
    required this.id,
    required this.participants,
    required this.participantNames,
    required this.participantPhotos,
    required this.lastMessage,
    required this.lastMessageAt,
    this.unreadCount = const {},
    this.courseName = 'Général',
    this.courseId,
  });

  String getOtherUserId(String currentUserId) {
    return participants.firstWhere((p) => p != currentUserId, orElse: () => participants.isNotEmpty ? participants.first : '');
  }

  String getOtherUserName(String currentUserId) {
    final otherId = getOtherUserId(currentUserId);
    return participantNames[otherId] ?? 'Interlocuteur';
  }

  String getOtherUserPhoto(String currentUserId) {
    final otherId = getOtherUserId(currentUserId);
    return participantPhotos[otherId] ?? '';
  }

  factory ConversationModel.fromMap(Map<String, dynamic> data, [String? docId]) {
    DateTime lastAt = DateTime.now();
    if (data['lastMessageAt'] is Timestamp) {
      lastAt = (data['lastMessageAt'] as Timestamp).toDate();
    } else if (data['lastMessageAt'] is String) {
      lastAt = DateTime.tryParse(data['lastMessageAt'] as String) ?? DateTime.now();
    } else if (data['createdAt'] is Timestamp) {
      lastAt = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      lastAt = DateTime.tryParse(data['createdAt'] as String) ?? DateTime.now();
    }

    final pNames = <String, String>{};
    if (data['participantNames'] is Map) {
      (data['participantNames'] as Map).forEach((k, v) => pNames[k.toString()] = v.toString());
    }

    final pPhotos = <String, String>{};
    if (data['participantPhotos'] is Map) {
      (data['participantPhotos'] as Map).forEach((k, v) => pPhotos[k.toString()] = v.toString());
    }

    final unread = <String, int>{};
    if (data['unreadCount'] is Map) {
      (data['unreadCount'] as Map).forEach((k, v) => unread[k.toString()] = (v as num).toInt());
    }

    return ConversationModel(
      id: docId ?? data['id'] ?? 'conv_${DateTime.now().millisecondsSinceEpoch}',
      participants: List<String>.from(data['participants'] ?? []),
      participantNames: pNames,
      participantPhotos: pPhotos,
      lastMessage: data['lastMessage'] ?? '',
      lastMessageAt: lastAt,
      unreadCount: unread,
      courseName: data['courseName'] ?? 'Formation',
      courseId: data['courseId'],
    );
  }

  factory ConversationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ConversationModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'participantNames': participantNames,
      'participantPhotos': participantPhotos,
      'lastMessage': lastMessage,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCount': unreadCount,
      'courseName': courseName,
      if (courseId != null) 'courseId': courseId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toLocalMap() {
    return {
      'id': id,
      'participants': participants,
      'participantNames': participantNames,
      'participantPhotos': participantPhotos,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt.toIso8601String(),
      'unreadCount': unreadCount,
      'courseName': courseName,
      'courseId': courseId,
    };
  }

  ConversationModel copyWith({
    String? id,
    List<String>? participants,
    Map<String, String>? participantNames,
    Map<String, String>? participantPhotos,
    String? lastMessage,
    DateTime? lastMessageAt,
    Map<String, int>? unreadCount,
    String? courseName,
    String? courseId,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      participantNames: participantNames ?? this.participantNames,
      participantPhotos: participantPhotos ?? this.participantPhotos,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      courseName: courseName ?? this.courseName,
      courseId: courseId ?? this.courseId,
    );
  }
}
