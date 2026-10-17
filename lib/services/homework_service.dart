import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/homework_model.dart';
import 'app_notification_service.dart';
import 'laravel_api_service.dart';
import 'system_log_service.dart';

class HomeworkService {
  static final HomeworkService _instance = HomeworkService._internal();
  factory HomeworkService() => _instance;
  HomeworkService._internal();

  static const String _hwCacheKey = 'local_homeworks_v1';
  static const String _subCacheKey = 'local_hw_submissions_v1';
  static const String _corrCacheKey = 'local_hw_corrections_v1';

  final LaravelApiService _api = LaravelApiService();
  final StreamController<List<HomeworkModel>> _hwController =
      StreamController<List<HomeworkModel>>.broadcast();
  final StreamController<List<HomeworkSubmissionModel>> _subController =
      StreamController<List<HomeworkSubmissionModel>>.broadcast();
  final StreamController<List<CorrectionModel>> _corrController =
      StreamController<List<CorrectionModel>>.broadcast();

  List<HomeworkModel> _cachedHomeworks = [];
  List<HomeworkSubmissionModel> _cachedSubmissions = [];
  List<CorrectionModel> _cachedCorrections = [];
  bool _initialized = false;

  FirebaseFirestore? get _db {
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('Firestore error HomeworkService: $e');
    }
    return null;
  }

  Future<void> _initCache() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final hwRaw = prefs.getString(_hwCacheKey);
      if (hwRaw != null && hwRaw.isNotEmpty) {
        _cachedHomeworks = (jsonDecode(hwRaw) as List)
            .map((e) {
              final m = Map<String, dynamic>.from(e as Map);
              return HomeworkModel.fromMap(m, m['id']?.toString() ?? '');
            })
            .toList();
      }

      final subRaw = prefs.getString(_subCacheKey);
      if (subRaw != null && subRaw.isNotEmpty) {
        _cachedSubmissions = (jsonDecode(subRaw) as List)
            .map((e) {
              final m = Map<String, dynamic>.from(e as Map);
              return HomeworkSubmissionModel.fromMap(m, m['id']?.toString() ?? '');
            })
            .toList();
      }

      final corrRaw = prefs.getString(_corrCacheKey);
      if (corrRaw != null && corrRaw.isNotEmpty) {
        _cachedCorrections = (jsonDecode(corrRaw) as List)
            .map((e) {
              final m = Map<String, dynamic>.from(e as Map);
              return CorrectionModel.fromMap(m, m['id']?.toString() ?? '');
            })
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading HomeworkService cache: $e');
    }

    if (_cachedHomeworks.isEmpty) {
      _cachedHomeworks = List<HomeworkModel>.from(_defaultHomeworks);
      await _saveCache();
    }
    if (_cachedSubmissions.isEmpty) {
      _cachedSubmissions = List<HomeworkSubmissionModel>.from(_defaultSubmissions);
      await _saveCache();
    }
    if (_cachedCorrections.isEmpty) {
      _cachedCorrections = List<CorrectionModel>.from(_defaultCorrections);
      await _saveCache();
    }

    _broadcastAll();
    unawaited(_syncRemote());
  }

  void _broadcastAll() {
    _hwController.add(_cachedHomeworks);
    _subController.add(_cachedSubmissions);
    _corrController.add(_cachedCorrections);
  }

  Future<void> _saveCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _hwCacheKey,
        jsonEncode(_cachedHomeworks.map((h) => h.toMap()).toList()),
      );
      await prefs.setString(
        _subCacheKey,
        jsonEncode(_cachedSubmissions.map((s) => s.toMap()).toList()),
      );
      await prefs.setString(
        _corrCacheKey,
        jsonEncode(_cachedCorrections.map((c) => c.toMap()).toList()),
      );
    } catch (e) {
      debugPrint('Error saving HomeworkService cache: $e');
    }
  }

  Future<void> _syncRemote() async {
    try {
      final res = await _api.get('/homeworks');
      final rawList = (res?['homeworks'] ?? res?['data']) as List?;
      if (rawList != null) {
        final list = rawList.map((item) {
          final m = Map<String, dynamic>.from(item as Map);
          return HomeworkModel.fromMap(m, m['id']?.toString() ?? '');
        }).toList();
        if (list.isNotEmpty) {
          final existingIds = _cachedHomeworks.map((h) => h.id).toSet();
          for (final h in list) {
            if (!existingIds.contains(h.id)) {
              _cachedHomeworks.add(h);
            }
          }
          await _saveCache();
          _broadcastAll();
        }
      }
    } catch (_) {}
  }

  // ── Devoirs ─────────────────────────────────────────────────────

  Future<String> createHomework({
    required String courseId,
    required String courseName,
    required String teacherId,
    required String teacherName,
    required String title,
    required String description,
    required DateTime deadline,
    List<String> attachmentUrls = const [],
    List<String> attachmentNames = const [],
    int points = 20,
    List<String> allowedSubmissionTypes = const ['blank_page', 'photo_sheet', 'word_document'],
  }) async {
    await _initCache();
    final id = 'hw_${DateTime.now().millisecondsSinceEpoch}';
    final hw = HomeworkModel(
      id: id,
      courseId: courseId,
      courseName: courseName,
      teacherId: teacherId,
      teacherName: teacherName,
      title: title,
      description: description,
      deadline: deadline,
      attachmentUrls: attachmentUrls,
      attachmentNames: attachmentNames,
      points: points,
      allowedSubmissionTypes: allowedSubmissionTypes,
      createdAt: DateTime.now(),
    );

    _cachedHomeworks = [hw, ..._cachedHomeworks];
    await _saveCache();
    _broadcastAll();

    unawaited(_api.post('/homeworks', {
      'courseId': courseId,
      'title': title,
      'instructions': description,
      if (attachmentUrls.isNotEmpty) 'attachmentUrl': attachmentUrls.first,
    }));

    try {
      final db = _db;
      if (db != null) {
        await db
            .collection('homeworks')
            .doc(id)
            .set(hw.toMap())
            .timeout(const Duration(seconds: 3));
      }
    } catch (_) {}

    // Notifier tous les étudiants de la formation en temps réel
    unawaited(
      AppNotificationService().notifyCourseStudents(
        courseId: courseId,
        title: 'Nouveau devoir assigné 📝',
        message: 'Le professeur $teacherName a publié "$title" (barème : $points pts, date limite : ${deadline.day}/${deadline.month}).',
        type: 'homework_assigned',
        actionRoute: '/homeworks',
        data: {'homeworkId': id, 'courseId': courseId, 'title': title},
      ),
    );

    // Notifier le correcteur attitré
    unawaited(
      AppNotificationService().notifyLinkedCorrector(
        teacherId: teacherId,
        title: 'Nouveau devoir à suivre 📋',
        message: 'Le formateur $teacherName a assigné "$title" pour "$courseName".',
        type: 'homework_assigned',
        actionRoute: '/homeworks',
        data: {'homeworkId': id, 'courseId': courseId, 'title': title},
      ),
    );

    // Traçabilité d'audit
    unawaited(
      SystemLogService().logEvent(
        action: 'Devoir assigné',
        details: 'Le formateur $teacherName a assigné le devoir "$title" ($courseName, $points pts, ${attachmentUrls.length} fichier(s) joint(s)).',
        category: 'homework',
        level: 'info',
        actorName: teacherName,
        actorRole: 'Formateur',
        metadata: {
          'homeworkId': id,
          'courseId': courseId,
          'points': points,
          'attachmentsCount': attachmentUrls.length,
        },
      ),
    );

    return id;
  }

  Future<String> publishHomework({
    required String title,
    required String courseId,
    required String courseName,
    required String teacherId,
    required String teacherName,
    required String instructions,
    required DateTime deadline,
    List<String> attachmentUrls = const [],
    List<String> attachmentNames = const [],
    int points = 20,
    List<String> allowedSubmissionTypes = const ['blank_page', 'photo_sheet', 'word_document'],
  }) => createHomework(
    title: title,
    courseId: courseId,
    courseName: courseName,
    teacherId: teacherId,
    teacherName: teacherName,
    description: instructions,
    deadline: deadline,
    attachmentUrls: attachmentUrls,
    attachmentNames: attachmentNames,
    points: points,
    allowedSubmissionTypes: allowedSubmissionTypes,
  );

  Stream<List<HomeworkModel>> getHomeworksByTeacherStream(String teacherId) async* {
    await _initCache();
    bool matches(HomeworkModel h) {
      if (teacherId.isEmpty || teacherId.startsWith('demo_') || teacherId == 'user_cheikh') {
        return true;
      }
      return h.teacherId == teacherId || h.teacherId == 'demo_teacher_cheikh';
    }

    yield _cachedHomeworks.where(matches).toList();
    yield* _hwController.stream.map((list) => list.where(matches).toList());
  }

  Stream<List<HomeworkModel>> getHomeworksStream() async* {
    await _initCache();
    yield _cachedHomeworks;
    yield* _hwController.stream;
  }

  Stream<List<HomeworkModel>> getHomeworksByCourseStream(String courseId) async* {
    await _initCache();
    bool matches(HomeworkModel h) =>
        courseId.isEmpty || h.courseId == courseId || h.courseId == 'react';

    yield _cachedHomeworks.where(matches).toList();
    yield* _hwController.stream.map((list) => list.where(matches).toList());
  }

  Future<void> deleteHomework(String homeworkId) async {
    await _initCache();
    _cachedHomeworks = _cachedHomeworks.where((h) => h.id != homeworkId).toList();
    await _saveCache();
    _broadcastAll();

    try {
      await _db
          ?.collection('homeworks')
          .doc(homeworkId)
          .delete()
          .timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  // ── Soumissions ─────────────────────────────────────────────────

  Future<String> submitHomework({
    required String homeworkId,
    required String studentId,
    required String studentName,
    List<String> fileUrls = const [],
    String? fileUrl,
    String submissionType = 'blank_page',
    String? blankPageContent,
    String? attachmentName,
  }) async {
    await _initCache();
    final effectiveUrls = [
      ...fileUrls,
      if (fileUrl != null && fileUrl.isNotEmpty) fileUrl,
    ];
    final id = '${homeworkId}_$studentId';
    final sub = HomeworkSubmissionModel(
      id: id,
      homeworkId: homeworkId,
      studentId: studentId,
      studentName: studentName,
      fileUrls: effectiveUrls,
      status: 'pending',
      submittedAt: DateTime.now(),
      submissionType: submissionType,
      blankPageContent: blankPageContent,
      attachmentName: attachmentName,
    );

    _cachedSubmissions = [
      sub,
      ..._cachedSubmissions.where((s) => s.id != id),
    ];
    await _saveCache();
    _broadcastAll();

    final hw = _cachedHomeworks.where((h) => h.id == homeworkId).firstOrNull;
    final targetCourseId = hw?.courseId ?? homeworkId;
    final hwTitle = hw?.title ?? 'Soumission devoir $homeworkId';
    final hwInstructions = hw?.description ?? '';

    unawaited(_api.post('/homeworks', {
      'courseId': targetCourseId,
      'title': hwTitle,
      'instructions': hwInstructions,
      'submissionText': blankPageContent,
      if (fileUrls.isNotEmpty) 'attachmentUrl': fileUrls.first,
    }));

    try {
      final db = _db;
      if (db != null) {
        await db
            .collection('homeworks')
            .doc(homeworkId)
            .collection('submissions')
            .doc(studentId)
            .set(sub.toMap())
            .timeout(const Duration(seconds: 3));
      }
    } catch (_) {}

    // Notifier le correcteur et le professeur
    final teacherId = hw?.teacherId ?? 'demo_teacher_cheikh';

    unawaited(
      AppNotificationService().notifyLinkedCorrector(
        teacherId: teacherId,
        title: 'Nouveau devoir à corriger 📝',
        message: '$studentName a rendu son devoir pour "$hwTitle".',
        type: 'homework_submitted',
        actionRoute: '/homeworks',
        data: {'homeworkId': homeworkId, 'studentId': studentId},
      ),
    );

    unawaited(
      AppNotificationService().notifyTeacher(
        teacherId: teacherId,
        title: 'Devoir rendu par un étudiant 📚',
        message: '$studentName a déposé sa copie pour "$hwTitle".',
        type: 'homework_submitted',
        actionRoute: '/homeworks',
        data: {'homeworkId': homeworkId, 'studentId': studentId},
      ),
    );

    unawaited(
      SystemLogService().logEvent(
        action: 'Devoir soumis',
        details: '$studentName a soumis son devoir pour "$hwTitle".',
        category: 'course',
        level: 'info',
        actorName: studentName,
        actorRole: 'Étudiant',
        metadata: {'homeworkId': homeworkId, 'studentId': studentId},
      ),
    );

    return id;
  }

  Stream<List<HomeworkSubmissionModel>> getAllSubmissionsStream() async* {
    await _initCache();
    yield _cachedSubmissions;
    yield* _subController.stream;
  }

  Stream<List<HomeworkSubmissionModel>> getSubmissionsStream(String homeworkId) async* {
    await _initCache();
    List<HomeworkSubmissionModel> filter(List<HomeworkSubmissionModel> all) =>
        all.where((s) => s.homeworkId == homeworkId).toList();

    yield filter(_cachedSubmissions);
    yield* _subController.stream.map(filter);
  }

  Stream<List<HomeworkSubmissionModel>> getStudentSubmissionsStream(String studentId) async* {
    await _initCache();
    bool matches(HomeworkSubmissionModel s) =>
        s.studentId == studentId || studentId.startsWith('demo_') || studentId.isEmpty;
    yield _cachedSubmissions.where(matches).toList();
    yield* _subController.stream.map((list) => list.where(matches).toList());
  }

  Future<HomeworkSubmissionModel?> getStudentSubmission(
      String homeworkId, String studentId) async {
    await _initCache();
    for (final s in _cachedSubmissions) {
      if (s.homeworkId == homeworkId &&
          (s.studentId == studentId || studentId.startsWith('demo_'))) {
        return s;
      }
    }
    return null;
  }

  // ── Corrections ─────────────────────────────────────────────────

  Future<void> submitCorrection({
    required String submissionId,
    required String homeworkId,
    required String correctorId,
    required String correctorName,
    required String studentId,
    double? note,
    String comment = '',
    String? correctedFileUrl,
  }) async {
    await _initCache();
    final corrId = '${homeworkId}_$studentId';
    final correction = CorrectionModel(
      id: corrId,
      submissionId: submissionId,
      homeworkId: homeworkId,
      correctorId: correctorId,
      correctorName: correctorName,
      studentId: studentId,
      note: note,
      comment: comment,
      correctedFileUrl: correctedFileUrl,
      correctedAt: DateTime.now(),
    );

    _cachedCorrections = [
      correction,
      ..._cachedCorrections.where((c) => c.id != corrId),
    ];

    _cachedSubmissions = _cachedSubmissions.map((s) {
      if (s.homeworkId == homeworkId && s.studentId == studentId) {
        return HomeworkSubmissionModel(
          id: s.id,
          homeworkId: s.homeworkId,
          studentId: s.studentId,
          studentName: s.studentName,
          fileUrls: s.fileUrls,
          status: 'corrected',
          submittedAt: s.submittedAt,
          submissionType: s.submissionType,
          blankPageContent: s.blankPageContent,
          attachmentName: s.attachmentName,
          grade: note,
          feedback: comment,
          correctedBy: correctorName,
          correctedAt: DateTime.now(),
        );
      }
      return s;
    }).toList();

    await _saveCache();
    _broadcastAll();

    unawaited(_api.patch('/homeworks/$homeworkId/grade', {
      'grade': (note ?? 16).toDouble(),
      if (comment.isNotEmpty) 'feedback': comment,
    }));

    try {
      final db = _db;
      if (db != null) {
        await db
            .collection('corrections')
            .doc(corrId)
            .set(correction.toMap())
            .timeout(const Duration(seconds: 3));

        await db
            .collection('homeworks')
            .doc(homeworkId)
            .collection('submissions')
            .doc(studentId)
            .set({
              'id': submissionId,
              'homeworkId': homeworkId,
              'studentId': studentId,
              'status': 'corrected',
              'grade': note,
              'note': note,
              'feedback': comment,
              'comment': comment,
              'correctedBy': correctorName,
              'correctedAt': DateTime.now().toIso8601String(),
            }, SetOptions(merge: true))
            .timeout(const Duration(seconds: 3));
      }
    } catch (_) {}

    // Notifier l'étudiant de sa note et de ses remarques
    unawaited(
      AppNotificationService().sendNotification(
        userId: studentId,
        title: 'Devoir corrigé ! ⭐',
        message: 'Votre travail a été noté : ${(note ?? 16).toStringAsFixed(1)}/20 par le correcteur $correctorName.',
        type: 'homework_graded',
        actionRoute: '/homeworks',
        data: {'homeworkId': homeworkId, 'submissionId': submissionId, 'note': note},
      ),
    );
  }

  Future<void> requestRevision({
    required String submissionId,
    required String feedback,
  }) async {
    await _initCache();
    _cachedSubmissions = _cachedSubmissions.map((s) {
      if (s.id == submissionId) {
        return HomeworkSubmissionModel(
          id: s.id,
          homeworkId: s.homeworkId,
          studentId: s.studentId,
          studentName: s.studentName,
          fileUrls: s.fileUrls,
          status: 'revision_requested',
          submittedAt: s.submittedAt,
          submissionType: s.submissionType,
          attachmentName: s.attachmentName,
          blankPageContent: s.blankPageContent,
          grade: s.grade,
          feedback: feedback,
        );
      }
      return s;
    }).toList();
    await _saveCache();
    _broadcastAll();

    final db = _db;
    if (db != null) {
      try {
        await db.collection('submissions').doc(submissionId).set({
          'status': 'revision_requested',
          'feedback': feedback,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error updating submission in Firestore: $e');
      }
    }
  }

  Stream<List<CorrectionModel>> getStudentCorrectionsStream(String studentId) async* {
    await _initCache();
    bool matches(CorrectionModel c) =>
        studentId.startsWith('demo_') || c.studentId == studentId || c.studentId == 'demo_student_moussa';

    yield _cachedCorrections.where(matches).toList();
    yield* _corrController.stream.map((list) => list.where(matches).toList());
  }

  Stream<List<CorrectionModel>> getCorrectorCorrectionsStream(String correctorId) async* {
    await _initCache();
    bool matches(CorrectionModel c) =>
        correctorId.startsWith('demo_') || c.correctorId == correctorId || c.correctorId == 'demo_corrector_ibrahima';

    yield _cachedCorrections.where(matches).toList();
    yield* _corrController.stream.map((list) => list.where(matches).toList());
  }

  Future<CorrectionModel?> getCorrection(
      String homeworkId, String studentId) async {
    await _initCache();
    for (final c in _cachedCorrections) {
      if (c.homeworkId == homeworkId &&
          (c.studentId == studentId || studentId.startsWith('demo_'))) {
        return c;
      }
    }
    return null;
  }

  static final List<HomeworkModel> _defaultHomeworks = [
    HomeworkModel(
      id: 'hw_react_hooks',
      courseId: 'react',
      courseName: 'Développement Web Moderne avec React',
      teacherId: 'demo_teacher_cheikh',
      teacherName: 'Cheikh Diop',
      title: 'TP 1 : Créer un Panier E-commerce avec useReducer & Context API',
      description:
          'Implémentez un panier dynamique avec ajout, suppression, calcul du total en FCFA et sauvegarde dans localStorage.',
      deadline: DateTime.now().add(const Duration(days: 5)),
      attachmentUrls: const ['https://club-des-formateurs.web.app/specs/tp1-react.pdf'],
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    HomeworkModel(
      id: 'hw_marketing_audit',
      courseId: 'marketing',
      courseName: 'Stratégie Marketing Digital de A à Z',
      teacherId: 'demo_teacher_cheikh',
      teacherName: 'Cheikh Diop',
      title: 'TP 2 : Plan Média & Campagne Acquisition Wave / Meta Ads',
      description:
          'Rédigez une stratégie d\'acquisition sur 30 jours avec répartition budgétaire et KPIs de conversion.',
      deadline: DateTime.now().add(const Duration(days: 10)),
      attachmentUrls: const [],
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
  ];

  static final List<HomeworkSubmissionModel> _defaultSubmissions = [
    HomeworkSubmissionModel(
      id: 'hw_react_hooks_demo_student_moussa',
      homeworkId: 'hw_react_hooks',
      studentId: 'demo_student_moussa',
      studentName: 'Moussa Ndiaye',
      fileUrls: const ['https://github.com/moussa-ndiaye/react-cart-tp1.zip'],
      status: 'pending',
      submissionType: 'blank_page',
      blankPageContent: '// TP 1 : Panier E-commerce React avec useReducer\nimport React, { useReducer } from "react";\n\nconst initialState = { items: [], total: 0 };\nfunction cartReducer(state, action) {\n  switch (action.type) {\n    case "ADD_ITEM":\n      return { ...state, items: [...state.items, action.payload], total: state.total + action.payload.price };\n    case "REMOVE_ITEM":\n      return { ...state, items: state.items.filter(i => i.id !== action.payload.id), total: state.total - action.payload.price };\n    default:\n      return state;\n  }\n}\n\nexport default function CartComponent() {\n  const [state, dispatch] = useReducer(cartReducer, initialState);\n  return (\n    <div className="p-4 bg-white rounded-xl shadow">\n      <h2 className="text-xl font-bold">Mon Panier d\'achats ({state.items.length})</h2>\n      <p className="mt-2 text-emerald-600 font-semibold">Total : {state.total.toLocaleString()} FCFA</p>\n    </div>\n  );\n}',
      submittedAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    HomeworkSubmissionModel(
      id: 'hw_marketing_audit_demo_student_awa',
      homeworkId: 'hw_marketing_audit',
      studentId: 'demo_student_awa',
      studentName: 'Awa Diop',
      fileUrls: const ['https://club-des-formateurs.web.app/docs/plan-media-awa.pdf'],
      attachmentName: 'Plan_Media_Campagne_Wave_Awa_Diop.pdf',
      status: 'pending',
      submissionType: 'attachment',
      blankPageContent: 'Synthèse de ma stratégie d\'acquisition pour le lancement sur Dakar :\n1. Objectif : Générer 500 nouveaux utilisateurs qualifiés en 30 jours.\n2. Canaux : Meta Ads (70% budget) + Partenariats influenceurs locaux (30% budget).\n3. Offre de bienvenue avec réduction de 15% via Wave QR code.\n4. CAC estimé : 1 200 FCFA avec un LTV projeté à 18 500 FCFA.',
      submittedAt: DateTime.now().subtract(const Duration(hours: 12)),
    ),
  ];

  static final List<CorrectionModel> _defaultCorrections = [
    CorrectionModel(
      id: 'hw_marketing_audit_demo_student_moussa',
      submissionId: 'hw_marketing_audit_demo_student_moussa',
      homeworkId: 'hw_marketing_audit',
      correctorId: 'demo_corrector_ibrahima',
      correctorName: 'Ibrahima Fall',
      studentId: 'demo_student_moussa',
      note: 17.5,
      comment: 'Excellent travail sur le ciblage et le calcul du CAC !',
      correctedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];
}
