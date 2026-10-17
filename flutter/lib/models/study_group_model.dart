import 'package:cloud_firestore/cloud_firestore.dart';

class GroupJoinRequestModel {
  final String id;
  final String groupId;
  final String userId;
  final String userName;
  final String userPhoto;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime requestedAt;

  GroupJoinRequestModel({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.userName,
    this.userPhoto = '',
    this.status = 'pending',
    required this.requestedAt,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';

  factory GroupJoinRequestModel.fromMap(Map<String, dynamic> data, String id, String groupId) {
    DateTime reqDate = DateTime.now();
    if (data['requestedAt'] is Timestamp) {
      reqDate = (data['requestedAt'] as Timestamp).toDate();
    } else if (data['requestedAt'] != null) {
      reqDate = DateTime.tryParse(data['requestedAt'].toString()) ?? DateTime.now();
    }

    return GroupJoinRequestModel(
      id: id,
      groupId: groupId,
      userId: data['userId']?.toString() ?? '',
      userName: data['userName']?.toString() ?? 'Étudiant',
      userPhoto: data['userPhoto']?.toString() ?? '',
      status: data['status']?.toString() ?? 'pending',
      requestedAt: reqDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'userId': userId,
      'userName': userName,
      'userPhoto': userPhoto,
      'status': status,
      'requestedAt': requestedAt.toIso8601String(),
    };
  }
}

class StudyGroupModel {
  final String id;
  final String name;
  final String description;
  final String courseId;
  final String courseTitle;
  final String creatorId;
  final String creatorName;
  final String creatorPhoto;
  final List<String> members;
  final Map<String, String> memberNames;
  final Map<String, String> memberPhotos;
  final int maxMembers;
  final String joinMode; // 'open' or 'request'
  final List<GroupJoinRequestModel> joinRequests;
  final String status; // 'open' or 'full'
  final DateTime createdAt;

  StudyGroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.courseId,
    required this.courseTitle,
    required this.creatorId,
    required this.creatorName,
    this.creatorPhoto = '',
    required this.members,
    this.memberNames = const {},
    this.memberPhotos = const {},
    this.maxMembers = 5,
    this.joinMode = 'open',
    this.joinRequests = const [],
    this.status = 'open',
    required this.createdAt,
  });

  bool get isFull => members.length >= maxMembers || status == 'full';
  bool isMember(String userId) => members.contains(userId);
  bool isCreator(String userId) => creatorId == userId;

  factory StudyGroupModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime created = DateTime.now();
    if (data['createdAt'] is Timestamp) {
      created = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      created = DateTime.tryParse(data['createdAt']) ?? DateTime.now();
    }

    final pNames = <String, String>{};
    if (data['memberNames'] is Map) {
      (data['memberNames'] as Map).forEach((k, v) => pNames[k.toString()] = v.toString());
    }

    final pPhotos = <String, String>{};
    if (data['memberPhotos'] is Map) {
      (data['memberPhotos'] as Map).forEach((k, v) => pPhotos[k.toString()] = v.toString());
    }

    final reqs = <GroupJoinRequestModel>[];
    if (data['joinRequests'] is List) {
      for (final r in (data['joinRequests'] as List)) {
        if (r is Map) {
          final rm = Map<String, dynamic>.from(r);
          reqs.add(GroupJoinRequestModel.fromMap(rm, rm['id']?.toString() ?? rm['userId']?.toString() ?? '', id));
        }
      }
    }

    final memberList = data['members'] is List
        ? List<String>.from(data['members'])
        : data['member_ids'] is List
            ? List<String>.from(data['member_ids'])
            : <String>[];

    return StudyGroupModel(
      id: id,
      name: data['name']?.toString() ?? 'Groupe d\'étude',
      description: data['description']?.toString() ?? '',
      courseId: data['courseId']?.toString() ?? data['course_id']?.toString() ?? '',
      courseTitle: data['courseTitle']?.toString() ?? data['category']?.toString() ?? 'Formation',
      creatorId: data['creatorId']?.toString() ?? data['creator_id']?.toString() ?? '',
      creatorName: data['creatorName']?.toString() ?? data['creator_name']?.toString() ?? 'Étudiant',
      creatorPhoto: data['creatorPhoto']?.toString() ?? '',
      members: memberList,
      memberNames: pNames,
      memberPhotos: pPhotos,
      maxMembers: (data['maxMembers'] as num?)?.toInt() ?? 6,
      joinMode: data['joinMode']?.toString() ?? 'open',
      joinRequests: reqs,
      status: data['status']?.toString() ?? 'open',
      createdAt: created,
    );
  }

  factory StudyGroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return StudyGroupModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'courseId': courseId,
      'courseTitle': courseTitle,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'creatorPhoto': creatorPhoto,
      'members': members,
      'memberNames': memberNames,
      'memberPhotos': memberPhotos,
      'maxMembers': maxMembers,
      'joinMode': joinMode,
      'joinRequests': joinRequests.map((r) => r.toMap()).toList(),
      'status': isFull ? 'full' : 'open',
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
