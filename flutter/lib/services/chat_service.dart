import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_model.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  FirebaseFirestore? get _firestore {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
    } catch (e) {
      debugPrint('Firestore error in ChatService: $e');
    }
    return null;
  }

  // In-memory reactive streams and caches
  final Map<String, List<MessageModel>> _cachedMessages = {};
  final Map<String, StreamController<List<MessageModel>>> _messageControllers = {};

  final Map<String, List<ConversationModel>> _cachedConversations = {};
  final Map<String, StreamController<List<ConversationModel>>> _convControllers = {};

  final Set<String> _seededUsers = {};

  StreamController<List<MessageModel>> _getMessageController(String conversationId) {
    if (!_messageControllers.containsKey(conversationId) || _messageControllers[conversationId]!.isClosed) {
      _messageControllers[conversationId] = StreamController<List<MessageModel>>.broadcast();
    }
    return _messageControllers[conversationId]!;
  }

  StreamController<List<ConversationModel>> _getConvController(String userId) {
    if (!_convControllers.containsKey(userId) || _convControllers[userId]!.isClosed) {
      _convControllers[userId] = StreamController<List<ConversationModel>>.broadcast();
    }
    return _convControllers[userId]!;
  }

  // -------------------------------------------------------------
  // PERSISTENCE (SharedPreferences)
  // -------------------------------------------------------------
  Future<void> _saveMessagesLocally(String conversationId, List<MessageModel> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = messages.map((m) => m.toLocalMap()).toList();
      await prefs.setString('chat_messages_$conversationId', jsonEncode(list));
    } catch (e) {
      debugPrint('Error saving messages locally: $e');
    }
  }

  Future<List<MessageModel>> _loadMessagesLocally(String conversationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('chat_messages_$conversationId');
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        return decoded.map((item) => MessageModel.fromMap(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Error loading messages locally: $e');
    }
    return [];
  }

  Future<void> _saveConversationsLocally(String userId, List<ConversationModel> conversations) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = conversations.map((c) => c.toLocalMap()).toList();
      await prefs.setString('chat_conversations_$userId', jsonEncode(list));
    } catch (e) {
      debugPrint('Error saving conversations locally: $e');
    }
  }

  Future<List<ConversationModel>> _loadConversationsLocally(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('chat_conversations_$userId');
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        return decoded.map((item) => ConversationModel.fromMap(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Error loading conversations locally: $e');
    }
    return [];
  }

  // -------------------------------------------------------------
  // SEED INITIAL CONVERSATIONS & MESSAGES
  // -------------------------------------------------------------
  Future<void> _seedDefaultDataIfNeeded(String userId) async {
    if (_seededUsers.contains(userId)) return;
    _seededUsers.add(userId);

    final storedConvs = await _loadConversationsLocally(userId);
    if (storedConvs.isNotEmpty) {
      _cachedConversations[userId] = storedConvs;
      _getConvController(userId).add(storedConvs);
      return;
    }

    // Determine initial conversations based on standard roles
    final now = DateTime.now();
    final isTeacher = userId.contains('teacher') || userId.contains('formateur');
    final isCorrector = userId.contains('corrector') || userId.contains('correcteur');

    List<ConversationModel> initialConvs = [];

    if (isCorrector) {
      // Corrector initial convs
      final c1 = ConversationModel(
        id: 'conv_corr_mamadou',
        participants: [userId, 'teacher_mamadou'],
        participantNames: {userId: 'Correcteur Dédié', 'teacher_mamadou': 'Mamadou Fall'},
        participantPhotos: {userId: 'assets/images/trainer-mamadou.png', 'teacher_mamadou': 'assets/images/trainer-mamadou.png'},
        lastMessage: 'Bien reçu, je m\'occupe des corrections des devoirs Flutter dès cet après-midi.',
        lastMessageAt: now.subtract(const Duration(minutes: 25)),
        unreadCount: {userId: 0},
        courseName: 'Canal Professeur-Correcteur',
      );
      final c2 = ConversationModel(
        id: 'conv_corr_moussa',
        participants: [userId, 'student_moussa'],
        participantNames: {userId: 'Correcteur Dédié', 'student_moussa': 'Moussa Ndiaye'},
        participantPhotos: {userId: 'assets/images/trainer-mamadou.png', 'student_moussa': 'assets/images/student-man.jpeg'},
        lastMessage: 'Super travail Moussa ! Ton devoir est validé avec 19/20.',
        lastMessageAt: now.subtract(const Duration(hours: 3)),
        unreadCount: {userId: 0},
        courseName: 'Suivi Devoir Module 2',
      );
      initialConvs = [c1, c2];

      _initSeedMessages('conv_corr_mamadou', [
        MessageModel(
          id: 'msg_corr_1',
          conversationId: 'conv_corr_mamadou',
          senderId: 'teacher_mamadou',
          senderName: 'Mamadou Fall',
          senderRole: 'teacher',
          content: 'Bonjour Abdoulaye, j\'ai mis à disposition les critères de notation du devoir Flutter.',
          createdAt: now.subtract(const Duration(hours: 1)),
        ),
        MessageModel(
          id: 'msg_corr_2',
          conversationId: 'conv_corr_mamadou',
          senderId: userId,
          senderName: 'Correcteur Dédié',
          senderRole: 'corrector',
          content: 'Bien reçu, je m\'occupe des corrections des devoirs Flutter dès cet après-midi.',
          createdAt: now.subtract(const Duration(minutes: 25)),
        ),
      ]);

      _initSeedMessages('conv_corr_moussa', [
        MessageModel(
          id: 'msg_corr_m1',
          conversationId: 'conv_corr_moussa',
          senderId: 'student_moussa',
          senderName: 'Moussa Ndiaye',
          senderRole: 'student',
          content: 'Bonjour, j\'ai corrigé les erreurs signalées dans mon devoir sur les StatefulWidgets.',
          createdAt: now.subtract(const Duration(hours: 4)),
        ),
        MessageModel(
          id: 'msg_corr_m2',
          conversationId: 'conv_corr_moussa',
          senderId: userId,
          senderName: 'Correcteur Dédié',
          senderRole: 'corrector',
          content: 'Super travail Moussa ! Ton devoir est validé avec 19/20.',
          createdAt: now.subtract(const Duration(hours: 3)),
        ),
      ]);

    } else if (isTeacher) {
      // Teacher initial convs
      final c1 = ConversationModel(
        id: 'demo_conv_moussa',
        participants: [userId, 'student_moussa'],
        participantNames: {userId: 'Mamadou Fall', 'student_moussa': 'Moussa Ndiaye'},
        participantPhotos: {userId: 'assets/images/trainer-mamadou.png', 'student_moussa': 'assets/images/student-man.jpeg'},
        lastMessage: 'Merci pour ces explications, je vais tester avec SharedPreferences !',
        lastMessageAt: now.subtract(const Duration(minutes: 15)),
        unreadCount: {userId: 0},
        courseName: 'Flutter & Dart Masterclass',
      );
      final c2 = ConversationModel(
        id: 'demo_conv_awa',
        participants: [userId, 'student_awa'],
        participantNames: {userId: 'Mamadou Fall', 'student_awa': 'Awa Ndiaye'},
        participantPhotos: {userId: 'assets/images/trainer-mamadou.png', 'student_awa': 'assets/images/student-girl-clean.jpeg'},
        lastMessage: 'Merci pour vos explications limpides en vidéo !',
        lastMessageAt: now.subtract(const Duration(hours: 5)),
        unreadCount: {userId: 0},
        courseName: 'Web & Mobile Pro',
      );
      final c3 = ConversationModel(
        id: 'conv_teacher_abdoulaye',
        participants: [userId, 'corrector_abdoulaye'],
        participantNames: {userId: 'Mamadou Fall', 'corrector_abdoulaye': 'Abdoulaye Ndiaye (Correcteur)'},
        participantPhotos: {userId: 'assets/images/trainer-mamadou.png', 'corrector_abdoulaye': 'assets/images/trainer-mamadou.png'},
        lastMessage: 'Parfait, les devoirs corrigés sont validés.',
        lastMessageAt: now.subtract(const Duration(hours: 12)),
        unreadCount: {userId: 0},
        courseName: 'Coordination Pédagogique',
      );
      initialConvs = [c1, c2, c3];

      _initSeedMessages('demo_conv_moussa', [
        MessageModel(
          id: 'msg_tm_1',
          conversationId: 'demo_conv_moussa',
          senderId: 'student_moussa',
          senderName: 'Moussa Ndiaye',
          senderRole: 'student',
          content: 'Bonjour M. Fall, comment persistez-vous les données hors-ligne dans Flutter ?',
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
        MessageModel(
          id: 'msg_tm_2',
          conversationId: 'demo_conv_moussa',
          senderId: userId,
          senderName: 'Mamadou Fall',
          senderRole: 'teacher',
          content: 'Bonjour Moussa ! Pour des paires clé-valeur simples, utilise SharedPreferences. Pour des données complexes, Firestore ou SQLite sont parfaits.',
          createdAt: now.subtract(const Duration(hours: 1)),
        ),
        MessageModel(
          id: 'msg_tm_3',
          conversationId: 'demo_conv_moussa',
          senderId: 'student_moussa',
          senderName: 'Moussa Ndiaye',
          senderRole: 'student',
          content: 'Merci pour ces explications, je vais tester avec SharedPreferences !',
          createdAt: now.subtract(const Duration(minutes: 15)),
        ),
      ]);

      _initSeedMessages('demo_conv_awa', [
        MessageModel(
          id: 'msg_ta_1',
          conversationId: 'demo_conv_awa',
          senderId: 'student_awa',
          senderName: 'Awa Ndiaye',
          senderRole: 'student',
          content: 'Bonjour Professeur ! Le dernier cours en direct était passionnant.',
          createdAt: now.subtract(const Duration(hours: 6)),
        ),
        MessageModel(
          id: 'msg_ta_2',
          conversationId: 'demo_conv_awa',
          senderId: 'student_awa',
          senderName: 'Awa Ndiaye',
          senderRole: 'student',
          content: 'Merci pour vos explications limpides en vidéo !',
          createdAt: now.subtract(const Duration(hours: 5)),
        ),
      ]);

      _initSeedMessages('conv_teacher_abdoulaye', [
        MessageModel(
          id: 'msg_tab_1',
          conversationId: 'conv_teacher_abdoulaye',
          senderId: 'corrector_abdoulaye',
          senderName: 'Abdoulaye Ndiaye',
          senderRole: 'corrector',
          content: 'Bonjour Professeur, j\'ai fini la correction des 12 devoirs du module 3.',
          createdAt: now.subtract(const Duration(hours: 14)),
        ),
        MessageModel(
          id: 'msg_tab_2',
          conversationId: 'conv_teacher_abdoulaye',
          senderId: userId,
          senderName: 'Mamadou Fall',
          senderRole: 'teacher',
          content: 'Parfait, les devoirs corrigés sont validés.',
          createdAt: now.subtract(const Duration(hours: 12)),
        ),
      ]);

    } else {
      // Student / Learner initial convs
      final c1 = ConversationModel(
        id: 'conv_student_mamadou',
        participants: [userId, 'teacher_mamadou'],
        participantNames: {userId: 'Apprenant', 'teacher_mamadou': 'Mamadou Fall'},
        participantPhotos: {userId: 'assets/images/student-woman.jpeg', 'teacher_mamadou': 'assets/images/trainer-mamadou.png'},
        lastMessage: 'Parfait ! Pose-moi ta question ici ou rejoins le prochain live ce samedi à 15h.',
        lastMessageAt: now.subtract(const Duration(minutes: 30)),
        unreadCount: {userId: 0},
        courseName: 'Flutter & Dart Masterclass',
      );
      final c2 = ConversationModel(
        id: 'conv_student_abdoulaye',
        participants: [userId, 'corrector_abdoulaye'],
        participantNames: {userId: 'Apprenant', 'corrector_abdoulaye': 'Abdoulaye Ndiaye (Correcteur)'},
        participantPhotos: {userId: 'assets/images/student-woman.jpeg', 'corrector_abdoulaye': 'assets/images/trainer-mamadou.png'},
        lastMessage: 'Ton devoir sur les formulaires réactifs est validé avec 18/20. Bravo !',
        lastMessageAt: now.subtract(const Duration(hours: 2)),
        unreadCount: {userId: 0},
        courseName: 'Suivi des Devoirs & Exercices',
      );
      final c3 = ConversationModel(
        id: 'conv_student_fatou',
        participants: [userId, 'teacher_fatou'],
        participantNames: {userId: 'Apprenant', 'teacher_fatou': 'Fatou Sow'},
        participantPhotos: {userId: 'assets/images/student-woman.jpeg', 'teacher_fatou': 'assets/images/trainer-fatou.png'},
        lastMessage: 'Super rendu sur Figma ! Prends bien en compte le contraste des couleurs pour l\'accessibilité.',
        lastMessageAt: now.subtract(const Duration(days: 1)),
        unreadCount: {userId: 0},
        courseName: 'UI/UX Design Mobile & Web',
      );
      initialConvs = [c1, c2, c3];

      _initSeedMessages('conv_student_mamadou', [
        MessageModel(
          id: 'msg_sm_1',
          conversationId: 'conv_student_mamadou',
          senderId: 'teacher_mamadou',
          senderName: 'Mamadou Fall',
          senderRole: 'teacher',
          content: 'Bonjour et bienvenue dans la formation Flutter ! As-tu réussi à configurer Flutter SDK et ton émulateur ?',
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
        MessageModel(
          id: 'msg_sm_2',
          conversationId: 'conv_student_mamadou',
          senderId: userId,
          senderName: 'Apprenant',
          senderRole: 'student',
          content: 'Bonjour Monsieur Fall, oui tout fonctionne parfaitement. J\'ai une question sur la gestion d\'état avec Riverpod.',
          createdAt: now.subtract(const Duration(hours: 1)),
        ),
        MessageModel(
          id: 'msg_sm_3',
          conversationId: 'conv_student_mamadou',
          senderId: 'teacher_mamadou',
          senderName: 'Mamadou Fall',
          senderRole: 'teacher',
          content: 'Parfait ! Pose-moi ta question ici ou rejoins le prochain live ce samedi à 15h.',
          createdAt: now.subtract(const Duration(minutes: 30)),
        ),
      ]);

      _initSeedMessages('conv_student_abdoulaye', [
        MessageModel(
          id: 'msg_sa_1',
          conversationId: 'conv_student_abdoulaye',
          senderId: 'corrector_abdoulaye',
          senderName: 'Abdoulaye Ndiaye',
          senderRole: 'corrector',
          content: 'Bonjour ! Je suis ton correcteur dédié pour les devoirs pratiques. Tu peux soumettre tes fichiers ici ou dans l\'espace devoirs.',
          createdAt: now.subtract(const Duration(hours: 4)),
        ),
        MessageModel(
          id: 'msg_sa_2',
          conversationId: 'conv_student_abdoulaye',
          senderId: userId,
          senderName: 'Apprenant',
          senderRole: 'student',
          content: 'Bonjour Abdoulaye, j\'ai déposé le lien de mon projet GitHub.',
          createdAt: now.subtract(const Duration(hours: 3)),
        ),
        MessageModel(
          id: 'msg_sa_3',
          conversationId: 'conv_student_abdoulaye',
          senderId: 'corrector_abdoulaye',
          senderName: 'Abdoulaye Ndiaye',
          senderRole: 'corrector',
          content: 'Ton devoir sur les formulaires réactifs est validé avec 18/20. Bravo !',
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
      ]);

      _initSeedMessages('conv_student_fatou', [
        MessageModel(
          id: 'msg_sf_1',
          conversationId: 'conv_student_fatou',
          senderId: 'teacher_fatou',
          senderName: 'Fatou Sow',
          senderRole: 'teacher',
          content: 'Bonjour ! N\'hésite pas à m\'envoyer ton lien Figma pour une relecture design.',
          createdAt: now.subtract(const Duration(days: 1, hours: 2)),
        ),
        MessageModel(
          id: 'msg_sf_2',
          conversationId: 'conv_student_fatou',
          senderId: userId,
          senderName: 'Apprenant',
          senderRole: 'student',
          content: 'Merci Fatou, voici la maquette du Dashboard que j\'ai finalisée.',
          createdAt: now.subtract(const Duration(days: 1, hours: 1)),
        ),
        MessageModel(
          id: 'msg_sf_3',
          conversationId: 'conv_student_fatou',
          senderId: 'teacher_fatou',
          senderName: 'Fatou Sow',
          senderRole: 'teacher',
          content: 'Super rendu sur Figma ! Prends bien en compte le contraste des couleurs pour l\'accessibilité.',
          createdAt: now.subtract(const Duration(days: 1)),
        ),
      ]);
    }

    _cachedConversations[userId] = initialConvs;
    await _saveConversationsLocally(userId, initialConvs);
    _getConvController(userId).add(initialConvs);
  }

  void _initSeedMessages(String conversationId, List<MessageModel> list) async {
    _cachedMessages[conversationId] = list;
    await _saveMessagesLocally(conversationId, list);
    _getMessageController(conversationId).add(list);
  }

  // -------------------------------------------------------------
  // GET REAL-TIME MESSAGES (HYBRID CACHE + FIRESTORE)
  // -------------------------------------------------------------
  Stream<List<MessageModel>> getMessagesStream(String conversationId) {
    final controller = _getMessageController(conversationId);

    // 1. Immediately emit memory cache or load from local storage
    if (_cachedMessages.containsKey(conversationId) && _cachedMessages[conversationId]!.isNotEmpty) {
      Timer.run(() => controller.add(List<MessageModel>.from(_cachedMessages[conversationId]!)));
    } else {
      _loadMessagesLocally(conversationId).then((localMsgs) {
        if (localMsgs.isNotEmpty) {
          _cachedMessages[conversationId] = localMsgs;
          controller.add(localMsgs);
        }
      });
    }

    // 2. Also listen to Firestore in real-time if available
    final db = _firestore;
    if (db != null) {
      try {
        db
            .collection('conversations')
            .doc(conversationId)
            .collection('messages')
            .orderBy('createdAt', descending: false)
            .snapshots()
            .listen((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final remoteMsgs = snapshot.docs.map((doc) => MessageModel.fromFirestore(doc)).toList();
            // Merge with local messages to prevent duplicates
            final local = _cachedMessages[conversationId] ?? [];
            final Set<String> existingIds = local.map((m) => m.id).toSet();
            final merged = List<MessageModel>.from(local);
            for (final rm in remoteMsgs) {
              if (!existingIds.contains(rm.id)) {
                merged.add(rm);
                existingIds.add(rm.id);
              }
            }
            merged.sort((a, b) => a.createdAt.compareTo(b.createdAt));
            _cachedMessages[conversationId] = merged;
            _saveMessagesLocally(conversationId, merged);
            controller.add(merged);
          }
        }, onError: (e) => debugPrint('Firestore messages stream error: $e'));
      } catch (e) {
        debugPrint('Firestore stream exception: $e');
      }
    }

    return controller.stream;
  }

  // -------------------------------------------------------------
  // GET REAL-TIME USER CONVERSATIONS (HYBRID CACHE + FIRESTORE)
  // -------------------------------------------------------------
  Stream<List<ConversationModel>> getUserConversationsStream(String userId) {
    final controller = _getConvController(userId);

    // 1. Load seed or local storage immediately
    _seedDefaultDataIfNeeded(userId).then((_) {
      final list = _cachedConversations[userId] ?? [];
      controller.add(List<ConversationModel>.from(list));
    });

    // 2. Listen to Firestore conversations
    final db = _firestore;
    if (db != null) {
      try {
        db
            .collection('conversations')
            .where('participants', arrayContains: userId)
            .snapshots()
            .listen((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final remote = snapshot.docs.map((doc) => ConversationModel.fromFirestore(doc)).toList();
            final local = _cachedConversations[userId] ?? [];
            final Map<String, ConversationModel> map = {for (final c in local) c.id: c};
            for (final rc in remote) {
              map[rc.id] = rc;
            }
            final merged = map.values.toList();
            merged.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
            _cachedConversations[userId] = merged;
            _saveConversationsLocally(userId, merged);
            controller.add(merged);
          }
        }, onError: (e) => debugPrint('Firestore conv stream error: $e'));
      } catch (e) {
        debugPrint('Firestore conv listen exception: $e');
      }
    }

    return controller.stream;
  }

  // -------------------------------------------------------------
  // GET OR CREATE CONVERSATION
  // -------------------------------------------------------------
  Future<String> getOrCreateConversation({
    required String currentUserId,
    required String currentUserName,
    String currentUserPhoto = '',
    required String targetUserId,
    required String targetUserName,
    String targetUserPhoto = '',
    String courseName = 'Formation générale',
    String? courseId,
  }) async {
    // 1. Check local cache
    await _seedDefaultDataIfNeeded(currentUserId);
    final userConvs = _cachedConversations[currentUserId] ?? [];
    for (final c in userConvs) {
      if (c.participants.contains(targetUserId)) {
        return c.id;
      }
    }

    // 2. Check Firestore
    final db = _firestore;
    if (db != null) {
      try {
        final query = await db
            .collection('conversations')
            .where('participants', arrayContains: currentUserId)
            .get();
        for (final doc in query.docs) {
          final participants = List<String>.from(doc.data()['participants'] ?? []);
          if (participants.contains(targetUserId)) {
            return doc.id;
          }
        }
      } catch (e) {
        debugPrint('Firestore query conv error: $e');
      }
    }

    // 3. Create new conversation
    final convId = 'conv_${currentUserId}_${targetUserId}_${DateTime.now().millisecondsSinceEpoch}';
    final newConv = ConversationModel(
      id: convId,
      participants: [currentUserId, targetUserId],
      participantNames: {
        currentUserId: currentUserName,
        targetUserId: targetUserName,
      },
      participantPhotos: {
        currentUserId: currentUserPhoto,
        targetUserId: targetUserPhoto,
      },
      lastMessage: 'Début de la conversation',
      lastMessageAt: DateTime.now(),
      unreadCount: {
        currentUserId: 0,
        targetUserId: 0,
      },
      courseName: courseName,
      courseId: courseId,
    );

    // Save locally
    final updatedList = [newConv, ...userConvs];
    _cachedConversations[currentUserId] = updatedList;
    await _saveConversationsLocally(currentUserId, updatedList);
    _getConvController(currentUserId).add(updatedList);

    // Also update target user list locally
    final targetList = _cachedConversations[targetUserId] ?? [];
    _cachedConversations[targetUserId] = [newConv, ...targetList];
    await _saveConversationsLocally(targetUserId, _cachedConversations[targetUserId]!);
    _getConvController(targetUserId).add(_cachedConversations[targetUserId]!);

    // Save to Firestore
    if (db != null) {
      try {
        await db.collection('conversations').doc(convId).set(newConv.toMap());
      } catch (e) {
        debugPrint('Firestore create conv error: $e');
      }
    }

    return convId;
  }

  // -------------------------------------------------------------
  // SEND MESSAGE (INSTANT REACTIVE + LOCAL CACHE + FIRESTORE + AUTO-REPLY)
  // -------------------------------------------------------------
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    String senderPhotoUrl = '',
    required String senderRole, // 'teacher', 'student', 'corrector'
    required String content,
    MessageType type = MessageType.text,
    String? fileUrl,
    String? fileName,
    int? audioDuration,
  }) async {
    // Role check: students cannot send audio notes
    if (type == MessageType.audio && senderRole != 'teacher' && senderRole != 'corrector') {
      throw Exception('Permission refusée : Les messages vocaux sont réservés aux formateurs et correcteurs.');
    }

    MessageType finalType = type;
    if (type == MessageType.text &&
        (content.trim().startsWith('http://') || content.trim().startsWith('https://'))) {
      finalType = MessageType.link;
    }

    final now = DateTime.now();
    final messageId = 'msg_${now.millisecondsSinceEpoch}_${senderId.hashCode.abs()}';

    final msg = MessageModel(
      id: messageId,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      senderRole: senderRole,
      content: content,
      type: finalType,
      fileUrl: fileUrl,
      fileName: fileName,
      audioDuration: audioDuration,
      createdAt: now,
    );

    // 1. Immediately append to memory cache
    final currentList = List<MessageModel>.from(_cachedMessages[conversationId] ?? []);
    currentList.add(msg);
    _cachedMessages[conversationId] = currentList;

    // 2. Broadcast immediately on stream (0 ms latency)
    _getMessageController(conversationId).add(currentList);

    // 3. Persist locally to SharedPreferences
    await _saveMessagesLocally(conversationId, currentList);

    // 4. Update parent conversation lastMessage
    String preview = content;
    if (finalType == MessageType.image) preview = '📷 Photo';
    if (finalType == MessageType.audio) preview = '🎤 Note vocale';
    if (finalType == MessageType.link) preview = '🔗 Lien';
    if (finalType == MessageType.file) preview = '📎 Fichier';

    _updateConversationLastMessage(conversationId, preview, now);

    // 5. Asynchronously persist to Firestore
    final db = _firestore;
    if (db != null) {
      try {
        await db
            .collection('conversations')
            .doc(conversationId)
            .collection('messages')
            .doc(messageId)
            .set(msg.toMap());

        await db.collection('conversations').doc(conversationId).set({
          'lastMessage': preview,
          'lastMessageAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore sendMessage error: $e');
      }
    }

    // Note: Automatic canned replies removed to ensure 100% genuine real-time interactions between real users
  }

  void _updateConversationLastMessage(String conversationId, String preview, DateTime time) {
    for (final userId in _cachedConversations.keys) {
      final convs = _cachedConversations[userId] ?? [];
      final idx = convs.indexWhere((c) => c.id == conversationId);
      if (idx != -1) {
        final conv = convs[idx];
        final updated = conv.copyWith(
          lastMessage: preview,
          lastMessageAt: time,
        );
        convs.removeAt(idx);
        convs.insert(0, updated);
        _cachedConversations[userId] = convs;
        _saveConversationsLocally(userId, convs);
        _getConvController(userId).add(List<ConversationModel>.from(convs));
      }
    }
  }


  // -------------------------------------------------------------
  // STUDY GROUPS
  // -------------------------------------------------------------
  Stream<List<MessageModel>> getGroupMessagesStream(String groupId) {
    return getMessagesStream(groupId);
  }

  Future<void> sendGroupMessage({
    required String groupId,
    required String senderId,
    required String senderName,
    String senderPhotoUrl = '',
    required String senderRole,
    required String content,
    MessageType type = MessageType.text,
    String? fileUrl,
    int? audioDuration,
  }) async {
    await sendMessage(
      conversationId: groupId,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      senderRole: senderRole,
      content: content,
      type: type,
      fileUrl: fileUrl,
      audioDuration: audioDuration,
    );
  }
}
