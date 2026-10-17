import '../../widgets/marketing_section_header.dart';
import '../../widgets/legal_documents_widget.dart';
import '../../widgets/privacy_settings_card.dart';
import '../../widgets/voice_message_widgets.dart';
import '../../models/teacher_registration_model.dart';
import '../../services/teacher_registration_service.dart';
import '../../widgets/student_registration_card_dialog.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/chat_model.dart';
import '../../models/course_model.dart';
import '../../models/live_session_model.dart';
import '../../models/trainer_model.dart';
import '../../models/user_model.dart';
import '../../services/audio_recording_service.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/course_service.dart';
import '../../services/firebase_storage_service.dart';
import '../../services/live_session_service.dart';
import '../../services/livekit_service.dart';
import '../../services/intech_payment_service.dart';
import '../../models/class_model.dart';
import '../../services/class_service.dart';
import '../../services/corrector_service.dart';
import '../../models/homework_model.dart';
import '../../services/homework_service.dart';
import '../../services/trainer_review_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/livekit_webrtc_view.dart';
import '../../widgets/homework_assignment_dialog.dart';
import '../../utils/file_download_helper.dart';
import '../teacher/course_creation_studio_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  final AuthService _authService = AuthService();
  final CourseService _courseService = CourseService();
  final ChatService _chatService = ChatService();
  final AudioRecordingService _audioService = AudioRecordingService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  final LiveSessionService _liveService = LiveSessionService();
  final IntechPaymentService _intechService = IntechPaymentService();
  final ClassService _classService = ClassService();
  final HomeworkService _homeworkService = HomeworkService();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _activeMenu = 'Tableau de bord';
  final _searchController = TextEditingController();

  // Active live session tracking
  LiveSessionModel? _activeLive;
  StreamSubscription? _liveSubscription;

  // Active chat conversation
  String? _selectedConversationId;
  String _selectedStudentName = 'Apprenant';
  bool _showMobileChatThread = false;
  final TextEditingController _chatMessageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  // Earnings & Intech Withdrawals
  List<IntechTransaction> _withdrawalTransactions = [];
  int _teacherBalance = 0;

  // Real-time notification tracking (offline-first & resilient)
  Set<String> _readNotificationIds = {};

  @override
  void initState() {
    super.initState();
    _audioService.init();
    _listenToActiveLives();
    _loadWithdrawals();
    final user = _authService.currentUser ?? UserModel.demoTeacher;
    _loadReadNotifications(user.uid);
  }

  Future<void> _loadReadNotifications(String teacherId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('teacher_read_notifications_$teacherId') ?? [];
      if (mounted) {
        setState(() {
          _readNotificationIds = list.toSet();
        });
      }
    } catch (_) {}
  }

  Future<void> _markNotificationAsRead(String teacherId, String notifId) async {
    try {
      _readNotificationIds.add(notifId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('teacher_read_notifications_$teacherId', _readNotificationIds.toList());
      if (mounted) setState(() {});

      if (Firebase.apps.isNotEmpty) {
        FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: teacherId)
            .where('registrationId', isEqualTo: notifId)
            .get()
            .timeout(const Duration(seconds: 3))
            .then((snap) {
              for (final doc in snap.docs) {
                doc.reference.update({'isRead': true}).catchError((_) {});
              }
            })
            .catchError((_) {});
      }
    } catch (_) {}
  }

  Future<void> _markAllNotificationsAsRead(String teacherId, List<TeacherStudentRegistrationModel> list) async {
    try {
      for (final item in list) {
        _readNotificationIds.add(item.id);
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('teacher_read_notifications_$teacherId', _readNotificationIds.toList());
      if (mounted) setState(() {});

      if (Firebase.apps.isNotEmpty) {
        FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: teacherId)
            .get()
            .timeout(const Duration(seconds: 3))
            .then((snap) {
              for (final doc in snap.docs) {
                doc.reference.update({'isRead': true}).catchError((_) {});
              }
            })
            .catchError((_) {});
      }
    } catch (_) {}
  }

  void _loadWithdrawals() async {
    final list = await _intechService.getWithdrawalHistory();
    if (mounted) {
      setState(() {
        _withdrawalTransactions = list;
      });
    }
  }

  void _listenToActiveLives() {
    _liveSubscription = _liveService.getActiveLiveSessionsStream().listen((lives) {
      if (mounted) {
        setState(() {
          final user = _authService.currentUser ?? UserModel.demoTeacher;
          _activeLive = lives.where((l) => l.teacherId == user.uid || l.teacherName == user.displayName).firstOrNull;
        });
      }
    });
  }

  @override
  void dispose() {
    _liveSubscription?.cancel();
    _chatMessageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ==========================================
  // 1. COURSE CREATION & EDITING (FULL-SCREEN OPENCLASSROOMS STUDIO)
  // ==========================================
  void _showCreateCourseModal({CourseModel? existingCourse}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CourseCreationStudioScreen(existingCourse: existingCourse),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  // ==========================================
  // 2. LESSONS & VIDEO MANAGEMENT MODAL
  // ==========================================
  void _showManageLessonsModal(CourseModel course) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLessonsState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 600,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gestion des leçons vidéo',
                            style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.ink),
                          ),
                          Text(
                            course.title,
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Button to add new lesson
                ElevatedButton.icon(
                  icon: const Icon(Icons.video_call_rounded, size: 18),
                  label: const Text('Ajouter une nouvelle leçon vidéo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emeraldGreenDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _showAddLessonDialog(course, setLessonsState),
                ),
                const SizedBox(height: 16),

                // Real-time lessons list
                Expanded(
                  child: StreamBuilder<List<CourseLesson>>(
                    stream: _courseService.getCourseLessonsStream(course.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: AppTheme.emeraldGreen));
                      }
                      final lessons = snapshot.data ?? [];
                      if (lessons.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.play_circle_outline_rounded, size: 48, color: AppTheme.textMuted),
                              const SizedBox(height: 10),
                              Text('Aucune leçon pour le moment.', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted)),
                              const SizedBox(height: 4),
                              const Text('Cliquez sur le bouton ci-dessus pour ajouter votre première vidéo.', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: lessons.length,
                        separatorBuilder: (_, __) => const Divider(height: 12),
                        itemBuilder: (context, index) {
                          final lesson = lessons[index];
                          return ListTile(
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppTheme.paleMint,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.play_arrow_rounded, color: AppTheme.emeraldGreenDark),
                            ),
                            title: Text(
                              lesson.title,
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            subtitle: Text(
                              'Durée : ${lesson.duration} • ${lesson.videoUrl.startsWith('http') ? 'Vidéo prête' : 'Lien configuré'}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.launch_rounded, size: 18, color: AppTheme.emeraldGreenDark),
                              tooltip: 'Tester la vidéo',
                              onPressed: () async {
                                final uri = Uri.parse(lesson.videoUrl);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                }
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddLessonDialog(CourseModel course, StateSetter parentSetState) {
    final titleCtrl = TextEditingController();
    final durationCtrl = TextEditingController(text: '12:30');
    final descCtrl = TextEditingController();
    final videoUrlCtrl = TextEditingController(text: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4');
    Uint8List? videoBytes;
    String? videoFileName;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Nouvelle leçon vidéo', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700)),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Titre de la leçon *', hintText: 'Ex: 1. Introduction et bases'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: durationCtrl,
                    decoration: const InputDecoration(labelText: 'Durée estimée *', hintText: 'Ex: 15:40'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Brève description', hintText: 'Résumé de ce cours'),
                  ),
                  const SizedBox(height: 14),

                  // Option A: Upload video file
                  OutlinedButton.icon(
                    icon: const Icon(Icons.upload_file_rounded),
                    label: Text(videoFileName ?? 'Uploader un fichier vidéo (MP4)'),
                    onPressed: () async {
                      final res = await FilePicker.platform.pickFiles(type: FileType.video, withData: true);
                      if (res != null && res.files.single.bytes != null) {
                        setDialogState(() {
                          videoBytes = res.files.single.bytes;
                          videoFileName = res.files.single.name;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  const Text('OU entrer une URL directe de vidéo :', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: videoUrlCtrl,
                    decoration: const InputDecoration(labelText: 'URL de la vidéo', hintText: 'https://.../video.mp4'),
                  ),
                  if (isUploading) ...[
                    const SizedBox(height: 12),
                    const CircularProgressIndicator(color: AppTheme.emeraldGreen),
                  ],
                ],
              ),
            ),
          ),
        ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emeraldGreenDark,
                foregroundColor: Colors.white,
              ),
              onPressed: isUploading ? null : () async {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) return;

                setDialogState(() => isUploading = true);
                final lessonId = 'lesson_${DateTime.now().millisecondsSinceEpoch}';
                String finalVideoUrl = videoUrlCtrl.text.trim();

                if (videoBytes != null) {
                  final uploaded = await _storageService.uploadLessonVideo(
                    courseId: course.id,
                    lessonId: lessonId,
                    bytes: videoBytes!,
                    fileName: videoFileName ?? 'lesson.mp4',
                  );
                  if (uploaded != null) finalVideoUrl = uploaded;
                }

                final lesson = CourseLesson(
                  id: lessonId,
                  title: title,
                  duration: durationCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  videoUrl: finalVideoUrl,
                  order: DateTime.now().millisecondsSinceEpoch,
                );

                await _courseService.addLessonToCourse(courseId: course.id, lesson: lesson);
                parentSetState(() {});

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Leçon "$title" ajoutée !'), backgroundColor: AppTheme.emeraldGreen),
                  );
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 3. LIVE SESSION MODAL
  // ==========================================
  void _showStartLiveModal({CourseModel? selectedCourse}) async {
    final user = _authService.currentUser ?? UserModel.demoTeacher;
    final courses = await _courseService.getTeacherCourses(user.uid);
    CourseModel? currentCourse = selectedCourse ?? (courses.isNotEmpty ? courses.first : null);

    String defaultTitle = 'Session Interactive Formateur';
    if (currentCourse != null) {
      defaultTitle = 'Session Live : ${currentCourse.title}';
    }
    final titleCtrl = TextEditingController(text: defaultTitle);
    bool isScheduled = false;
    DateTime scheduledDate = DateTime.now().add(const Duration(hours: 2));
    TimeOfDay scheduledTime = TimeOfDay.fromDateTime(scheduledDate);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final formattedScheduledDateTime =
              '${DateFormat("EEEE d MMMM yyyy", 'fr_FR').format(scheduledDate)} à ${scheduledTime.hour.toString().padLeft(2, '0')}h${scheduledTime.minute.toString().padLeft(2, '0')}';

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isScheduled ? const Color(0xFFEFF6FF) : const Color(0xFFFEF2F2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isScheduled ? Icons.calendar_month_rounded : Icons.sensors_rounded,
                    color: isScheduled ? const Color(0xFF2563EB) : const Color(0xFFDC2626),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isScheduled ? 'Programmer un direct' : 'Lancer un direct en continu',
                    style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mode Selector Toggle
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => isScheduled = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: !isScheduled ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9),
                                  boxShadow: !isScheduled
                                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '🔴 Direct Immédiat',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: !isScheduled ? FontWeight.w800 : FontWeight.w600,
                                    color: !isScheduled ? const Color(0xFFDC2626) : AppTheme.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => isScheduled = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: isScheduled ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9),
                                  boxShadow: isScheduled
                                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '📅 Programmer pour plus tard',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isScheduled ? FontWeight.w800 : FontWeight.w600,
                                    color: isScheduled ? const Color(0xFF2563EB) : AppTheme.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      isScheduled
                          ? 'Les apprenants inscrits recevront une notification avec la date et l\'heure de diffusion.'
                          : 'La salle LiveKit sera lancée instantanément et accessible à vos apprenants.',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 16),

                    // Titre
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Titre de la session Live *',
                        hintText: 'Ex: Masterclass architecture & bonnes pratiques',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cours associé dropdown
                    if (courses.isNotEmpty) ...[
                      DropdownButtonFormField<CourseModel>(
                        value: currentCourse,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Formation associée *',
                          border: OutlineInputBorder(),
                        ),
                        items: courses.map((c) {
                          return DropdownMenuItem<CourseModel>(
                            value: c,
                            child: Text(
                              c.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setModalState(() {
                            currentCourse = val;
                            if (val != null && titleCtrl.text.trim().startsWith('Session Live')) {
                              titleCtrl.text = 'Session Live : ${val.title}';
                            }
                          });
                        },
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: const Text('Formation générale (aucune formation spécifique créée)', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                      ),
                    ],

                    // If scheduled: date & time pickers
                    if (isScheduled) ...[
                      const SizedBox(height: 16),
                      Text('Date et heure de diffusion *', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.ink)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.event_note_rounded, size: 20, color: Color(0xFF2563EB)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                formattedScheduledDateTime,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                              label: const Text('Modifier', style: TextStyle(fontSize: 12)),
                              onPressed: () async {
                                final pickedDate = await showDatePicker(
                                  context: ctx,
                                  initialDate: scheduledDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (pickedDate != null) {
                                  final pickedTime = await showTimePicker(
                                    context: ctx,
                                    initialTime: scheduledTime,
                                  );
                                  if (pickedTime != null) {
                                    setModalState(() {
                                      scheduledDate = pickedDate;
                                      scheduledTime = pickedTime;
                                    });
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isScheduled ? const Color(0xFF2563EB) : const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final finalTitle = titleCtrl.text.trim().isEmpty ? 'Direct Formateur' : titleCtrl.text.trim();
                  final cId = currentCourse?.id ?? 'react';
                  final cName = currentCourse?.title ?? 'Formation générale';

                  if (isScheduled) {
                    final finalScheduledAt = DateTime(
                      scheduledDate.year,
                      scheduledDate.month,
                      scheduledDate.day,
                      scheduledTime.hour,
                      scheduledTime.minute,
                    );

                    await _liveService.scheduleLiveSession(
                      courseId: cId,
                      courseName: cName,
                      title: finalTitle,
                      teacherId: user.uid,
                      teacherName: user.displayName,
                      teacherPhotoUrl: user.photoUrl ?? '',
                      scheduledAt: finalScheduledAt,
                    );

                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Session "$finalTitle" programmée pour le $formattedScheduledDateTime !'),
                          backgroundColor: AppTheme.emeraldGreenDark,
                        ),
                      );
                    }
                  } else {
                    final sessionId = await _liveService.startLiveSession(
                      courseId: cId,
                      courseName: cName,
                      title: finalTitle,
                      teacherId: user.uid,
                      teacherName: user.displayName,
                      teacherPhotoUrl: user.photoUrl ?? '',
                    );

                    final session = LiveSessionModel(
                      id: sessionId,
                      courseId: cId,
                      courseName: cName,
                      title: finalTitle,
                      teacherId: user.uid,
                      teacherName: user.displayName,
                      teacherPhotoUrl: user.photoUrl ?? '',
                      status: 'live',
                      roomName: 'club_live_${cId}_${DateTime.now().millisecondsSinceEpoch}',
                      scheduledAt: DateTime.now(),
                    );

                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      _openLiveStudio(session, user);
                    }
                  }
                },
                child: Text(isScheduled ? 'Enregistrer la programmation' : 'Lancer le direct maintenant'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openLiveStudio(LiveSessionModel live, UserModel user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => TeacherLiveStudioDialog(
        live: live,
        currentUser: user,
        onEndLive: () {
          Navigator.pop(ctx);
          _showEndLiveModal(live);
        },
      ),
    );
  }

  void _showEndLiveModal(LiveSessionModel live) {
    final replayCtrl = TextEditingController(text: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Terminer la session en direct'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Voulez-vous sauvegarder l\'enregistrement de cette session en tant que replay pour le cours ?', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: replayCtrl,
              decoration: const InputDecoration(labelText: 'URL du replay vidéo'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldGreenDark, foregroundColor: Colors.white),
            onPressed: () async {
              await _liveService.endLiveSession(
                sessionId: live.id,
                courseId: live.courseId,
                title: live.title,
                replayUrl: replayCtrl.text.trim(),
              );
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Direct terminé et replay ajouté au cours !'), backgroundColor: AppTheme.emeraldGreen),
                );
              }
            },
            child: const Text('Terminer et enregistrer le replay'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 4. MAIN BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1024;
    final user = _authService.currentUser ?? UserModel.demoTeacher;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: !isDesktop ? Drawer(child: _buildSidebar(isMobileDrawer: true)) : null,
      bottomNavigationBar: !isDesktop ? _buildTeacherBottomNavBar() : null,
      floatingActionButton: LegalDocumentsFAB(userId: user.uid),
      body: Row(
        children: [
          if (isDesktop) SizedBox(width: 240, child: _buildSidebar()),
          Expanded(
            child: Column(
              children: [
                _buildTopHeader(context, user, isDesktop),
                if (_activeLive != null) _buildLiveBanner(_activeLive!),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16, vertical: 24),
                    child: _buildDynamicBody(user, isDesktop),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherBottomNavBar() {
    final navItems = [
      {'title': 'Tableau de bord', 'icon': Icons.dashboard_rounded, 'label': 'Accueil'},
      {'title': 'Mes formations', 'icon': Icons.auto_stories_rounded, 'label': 'Formations'},
      {'title': 'Sessions Live', 'icon': Icons.sensors_rounded, 'label': 'Lives'},
      {'title': 'Messages', 'icon': Icons.chat_bubble_outline_rounded, 'label': 'Messages'},
      {'title': 'Menu', 'icon': Icons.grid_view_rounded, 'label': 'Plus'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
        border: const Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: navItems.map((item) {
              final isMenu = item['title'] == 'Menu';
              final isSelected = !isMenu && _activeMenu == item['title'];
              return InkWell(
                onTap: () {
                  if (isMenu) {
                    _scaffoldKey.currentState?.openDrawer();
                  } else {
                    setState(() {
                      _activeMenu = item['title'] as String;
                    });
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        color: isSelected ? AppTheme.emeraldGreenDark : AppTheme.textMuted,
                        size: 22,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item['label'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                          color: isSelected ? AppTheme.emeraldGreenDark : AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveBanner(LiveSessionModel live) {
    final user = _authService.currentUser ?? UserModel.demoTeacher;
    return Container(
      width: double.infinity,
      color: const Color(0xFFDC2626),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.sensors_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '🔴 EN DIRECT : "${live.title}" (${live.participantCount} participant${live.participantCount > 1 ? 's' : ''})',
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.red[800],
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            ),
            icon: const Icon(Icons.videocam_rounded, size: 16),
            label: const Text('Ouvrir le Studio Live', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            onPressed: () => _openLiveStudio(live, user),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white70),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            onPressed: () => _showEndLiveModal(live),
            child: const Text('Terminer', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBackBanner() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          setState(() {
            if (_activeMenu != 'Tableau de bord') {
              _activeMenu = 'Tableau de bord';
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushNamed(context, '/');
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_back_rounded, size: 18, color: AppTheme.emeraldGreenDark),
              const SizedBox(width: 8),
              Text(
                _activeMenu != 'Tableau de bord' ? 'Retour au tableau de bord' : 'Retour à l\'accueil',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.emeraldGreenDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicBody(UserModel user, bool isDesktop) {
    Widget content;
    switch (_activeMenu) {
      case 'Mes formations':
        content = _buildFullCoursesView();
        break;
      case 'Étudiants Inscrits':
        content = _buildTeacherRegistrationsView(user);
        break;
      case 'Classes (100 Étudiants)':
        content = _buildClassesView(user);
        break;
      case 'Emploi du temps':
        content = _buildTimetableView(user);
        break;
      case 'Devoirs envoyés':
        content = _buildHomeworksSentView(user);
        break;
      case 'Sessions Live':
        content = _buildLiveSessionsView(user, isDesktop);
        break;
      case 'Revenus & Retraits':
        content = _buildEarningsAndWithdrawalsView(user, isDesktop);
        break;
      case 'Messages':
        content = _buildMessagesView(user);
        break;
      case 'Règlement & Documents':
        content = LegalDocumentsView(userId: user.uid);
        break;
      case 'Paramètres':
        content = _buildSettingsView(user);
        break;
      case 'Tableau de bord':
      default:
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreetingBanner(user),
            const SizedBox(height: 24),
            _buildStatCards(user),
            const SizedBox(height: 28),
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 7, child: _buildCoursesTableSection(user)),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        _buildStatsChartSection(user),
                        const SizedBox(height: 24),
                        _buildRecentReviewsSection(user),
                      ],
                    ),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCoursesTableSection(user),
                  const SizedBox(height: 24),
                  _buildStatsChartSection(user),
                  const SizedBox(height: 24),
                  _buildRecentReviewsSection(user),
                ],
              ),
          ],
        );
    }

    if (!isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMobileBackBanner(),
          content,
        ],
      );
    }
    return content;
  }

  // ==========================================
  // 5. MESSAGES VIEW (WITH TEACHER AUDIO NOTES)
  // ==========================================
  Widget _buildMessagesView(UserModel user) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    final convsListWidget = SizedBox(
      width: isMobile ? double.infinity : 285,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.forum_rounded, color: AppTheme.emeraldGreenDark, size: 20),
                    const SizedBox(width: 8),
                    Text('Discussions', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.ink)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.add_comment_rounded, color: AppTheme.emeraldGreenDark, size: 20),
                  tooltip: 'Nouvelle discussion',
                  onPressed: () => _showNewTeacherConversationDialog(user),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.cardBorder),
          Expanded(
            child: StreamBuilder<List<ConversationModel>>(
              stream: _chatService.getUserConversationsStream(user.uid),
              builder: (context, snapshot) {
                final conversations = snapshot.data ?? [];
                if (_selectedConversationId == null && conversations.isNotEmpty && !isMobile) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _selectedConversationId == null) {
                      setState(() {
                        _selectedConversationId = conversations.first.id;
                        _selectedStudentName = conversations.first.getOtherUserName(user.uid);
                      });
                    }
                  });
                }
                if (conversations.isEmpty) {
                  return ListView(
                    children: [
                      _buildConvTile(
                        id: 'demo_conv_moussa',
                        name: 'Moussa Ndiaye',
                        preview: 'Bonjour M. Diop, j\'ai une question sur React',
                        time: '10:45',
                        isSelected: _selectedConversationId == 'demo_conv_moussa',
                        onTap: () => setState(() {
                          _selectedConversationId = 'demo_conv_moussa';
                          _selectedStudentName = 'Moussa Ndiaye';
                          if (isMobile) _showMobileChatThread = true;
                        }),
                      ),
                      _buildConvTile(
                        id: 'demo_conv_awa',
                        name: 'Awa Ndiaye',
                        preview: 'Merci pour vos explications en vidéo !',
                        time: 'Hier',
                        isSelected: _selectedConversationId == 'demo_conv_awa',
                        onTap: () => setState(() {
                          _selectedConversationId = 'demo_conv_awa';
                          _selectedStudentName = 'Awa Ndiaye';
                          if (isMobile) _showMobileChatThread = true;
                        }),
                      ),
                    ],
                  );
                }

                return ListView.builder(
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final conv = conversations[index];
                    final otherName = conv.participantNames.entries
                        .firstWhere((e) => e.key != user.uid, orElse: () => const MapEntry('', 'Apprenant'))
                        .value;
                    return _buildConvTile(
                      id: conv.id,
                      name: otherName,
                      preview: conv.lastMessage,
                      time: 'Récemment',
                      isSelected: _selectedConversationId == conv.id,
                      onTap: () => setState(() {
                        _selectedConversationId = conv.id;
                        _selectedStudentName = otherName;
                        if (isMobile) _showMobileChatThread = true;
                      }),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );

    final chatBoxWidget = _selectedConversationId == null
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.forum_outlined, size: 48, color: AppTheme.textMuted),
                const SizedBox(height: 12),
                Text('Sélectionnez une conversation pour échanger.', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted)),
              ],
            ),
          )
        : Column(
            children: [
              // Chat Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  children: [
                    if (isMobile) ...[
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.ink, size: 20),
                        tooltip: 'Retour aux discussions',
                        onPressed: () => setState(() => _showMobileChatThread = false),
                      ),
                      const SizedBox(width: 4),
                    ],
                    CircleAvatar(
                      backgroundColor: AppTheme.paleMint,
                      child: Text(_selectedStudentName.isNotEmpty ? _selectedStudentName.substring(0, 1).toUpperCase() : 'A', style: const TextStyle(color: AppTheme.emeraldGreenDark, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_selectedStudentName, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14)),
                        const Text('En ligne • Apprenant', style: TextStyle(fontSize: 11, color: AppTheme.emeraldGreenDark)),
                      ],
                    ),
                  ],
                ),
              ),

              // Messages Stream
              Expanded(
                child: StreamBuilder<List<MessageModel>>(
                  stream: _chatService.getMessagesStream(_selectedConversationId!),
                  builder: (context, snapshot) {
                    final messages = snapshot.data ?? [];
                    if (messages.isEmpty) {
                      return Center(
                        child: Text('Aucun message encore. Envoyez votre premier message !', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                      );
                    }

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_chatScrollController.hasClients) {
                        _chatScrollController.jumpTo(_chatScrollController.position.maxScrollExtent);
                      }
                    });

                    return ListView.builder(
                      controller: _chatScrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg.senderId == user.uid || msg.senderRole == 'teacher';
                        return _buildMessageBubble(msg, isMe);
                      },
                    );
                  },
                ),
              ),

              // Dedicated VoiceRecordingBar with preview and audio upload fallback
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: VoiceRecordingBar(
                  conversationId: _selectedConversationId!,
                  onAudioSent: (audioUrl, duration) async {
                    await _chatService.sendMessage(
                      conversationId: _selectedConversationId!,
                      senderId: user.uid,
                      senderName: user.displayName.isNotEmpty ? user.displayName : 'Formateur',
                      senderRole: 'teacher',
                      content: 'Note vocale (${duration}s)',
                      type: MessageType.audio,
                      fileUrl: audioUrl,
                      audioDuration: duration,
                    );
                  },
                  child: Row(
                    children: [
                      // Attach Image
                      IconButton(
                        icon: const Icon(Icons.image_outlined, color: AppTheme.emeraldGreenDark),
                        tooltip: 'Envoyer une photo',
                        onPressed: () async {
                          final res = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
                          if (res != null && res.files.single.bytes != null) {
                            final url = await _storageService.uploadChatMedia(
                              conversationId: _selectedConversationId!,
                              bytes: res.files.single.bytes!,
                              fileName: res.files.single.name,
                            );
                            if (url != null) {
                              await _chatService.sendMessage(
                                conversationId: _selectedConversationId!,
                                senderId: user.uid,
                                senderName: user.displayName,
                                senderRole: 'teacher',
                                content: 'Photo envoyée',
                                type: MessageType.image,
                                fileUrl: url,
                              );
                            }
                          }
                        },
                      ),
                      // Text input
                      Expanded(
                        child: TextField(
                          controller: _chatMessageController,
                          decoration: InputDecoration(
                            hintText: 'Écrivez votre message ou collez un lien...',
                            hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                          ),
                          onSubmitted: (_) => _sendTextMessage(user),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Send Text Button
                      IconButton(
                        icon: const Icon(Icons.send_rounded, color: AppTheme.emeraldGreenDark),
                        onPressed: () => _sendTextMessage(user),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );

    return Container(
      height: 650,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: isMobile
          ? (_showMobileChatThread && _selectedConversationId != null ? chatBoxWidget : convsListWidget)
          : Row(
              children: [
                convsListWidget,
                const VerticalDivider(width: 1),
                Expanded(child: chatBoxWidget),
              ],
            ),
    );
  }

  void _showNewTeacherConversationDialog(UserModel user) {
    final contacts = [
      {
        'id': 'student_moussa',
        'name': 'Moussa Ndiaye',
        'role': 'Apprenant • Flutter & Dart',
        'avatar': 'assets/images/student-man.jpeg',
        'course': 'Flutter & Dart Masterclass',
      },
      {
        'id': 'student_awa',
        'name': 'Awa Ndiaye',
        'role': 'Apprenante • Web React',
        'avatar': 'assets/images/student-girl-clean.jpeg',
        'course': 'Web & Mobile Pro',
      },
      {
        'id': 'corrector_abdoulaye',
        'name': 'Abdoulaye Ndiaye',
        'role': 'Correcteur Dédié',
        'avatar': 'assets/images/trainer-mamadou.png',
        'course': 'Coordination Devoirs & Live',
      },
      {
        'id': 'student_aminata',
        'name': 'Aminata Diallo',
        'role': 'Apprenante • UI/UX Design',
        'avatar': 'assets/images/student-woman.jpeg',
        'course': 'Design & Prototypage',
      },
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.add_comment_rounded, color: AppTheme.emeraldGreenDark),
            const SizedBox(width: 8),
            Text('Nouvelle discussion', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sélectionnez un apprenant ou votre correcteur lié pour échanger :',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: contacts.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final c = contacts[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.paleMint,
                        child: Text(c['name']![0], style: const TextStyle(color: AppTheme.emeraldGreenDark, fontWeight: FontWeight.w700)),
                      ),
                      title: Text(c['name']!, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
                      subtitle: Text(c['role']!, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                      onTap: () async {
                        Navigator.pop(ctx);
                        final convId = await _chatService.getOrCreateConversation(
                          currentUserId: user.uid,
                          currentUserName: user.displayName,
                          currentUserPhoto: user.photoUrl ?? '',
                          targetUserId: c['id']!,
                          targetUserName: c['name']!,
                          targetUserPhoto: c['avatar']!,
                          courseName: c['course']!,
                        );
                        setState(() {
                          _selectedConversationId = convId;
                          _selectedStudentName = c['name']!;
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _sendTextMessage(UserModel user) async {
    final text = _chatMessageController.text.trim();
    if (text.isEmpty || _selectedConversationId == null) return;
    _chatMessageController.clear();

    await _chatService.sendMessage(
      conversationId: _selectedConversationId!,
      senderId: user.uid,
      senderName: user.displayName,
      senderRole: 'teacher',
      content: text,
      type: (text.startsWith('http://') || text.startsWith('https://')) ? MessageType.link : MessageType.text,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildConvTile({
    required String id,
    required String name,
    required String preview,
    required String time,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      selected: isSelected,
      selectedTileColor: const Color(0xFFF1F5F9),
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppTheme.paleMint,
        child: Text(name.substring(0, 1), style: const TextStyle(color: AppTheme.emeraldGreenDark, fontWeight: FontWeight.w700)),
      ),
      title: Text(name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
      subtitle: Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      trailing: Text(time, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
    );
  }

  Widget _buildMessageBubble(MessageModel msg, bool isMe) {
    if (msg.isAudio) {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: AudioMessageBubble(
          audioUrl: msg.fileUrl ?? '',
          durationSeconds: msg.audioDuration ?? 10,
          isMe: isMe,
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.emeraldGreenDark : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.isImage && msg.fileUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(msg.fileUrl!, width: 200, height: 140, fit: BoxFit.cover),
              ),
              const SizedBox(height: 4),
            ] else if (msg.isLink) ...[
              InkWell(
                onTap: () async {
                  final uri = Uri.parse(msg.content);
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                },
                child: Text(
                  msg.content,
                  style: TextStyle(color: isMe ? Colors.white : Colors.blue[700], decoration: TextDecoration.underline, fontSize: 13),
                ),
              ),
            ] else ...[
              Text(
                msg.content,
                style: TextStyle(color: isMe ? Colors.white : AppTheme.ink, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 6. PROFILE SETTINGS VIEW
  // ==========================================
  Widget _buildSettingsView(UserModel user) {
    final nameCtrl = TextEditingController(text: user.displayName);
    final phoneCtrl = TextEditingController(text: user.phoneNumber ?? '');
    final specialityCtrl = TextEditingController(text: user.speciality ?? (user.expertises.isNotEmpty ? user.expertises.first : 'Formateur Expert'));
    final experienceCtrl = TextEditingController(text: user.experienceYears ?? '');
    final bioCtrl = TextEditingController(text: user.bio ?? '');
    final quoteCtrl = TextEditingController(text: user.quote ?? '');
    final photoUrlCtrl = TextEditingController(text: user.photoUrl ?? '');
    Uint8List? avatarBytes;
    bool isSaving = false;

    return StatefulBuilder(
      builder: (context, setSettingsState) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Mon Profil & Paramètres Formateur', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.ink)),
                OutlinedButton.icon(
                  icon: const Icon(Icons.visibility_rounded, size: 16),
                  label: const Text('Voir mon profil public'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.emeraldGreenDark,
                    side: const BorderSide(color: AppTheme.emeraldGreen),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    final trainerModel = TrainerModel(
                      id: user.uid,
                      name: user.displayName,
                      role: user.speciality ?? (user.expertises.isNotEmpty ? user.expertises.join(', ') : 'Formateur Expert'),
                      rating: 5.0,
                      coursesCount: 0,
                      image: user.photoUrl ?? '',
                      bio: user.bio ?? '',
                      quote: user.quote ?? '',
                      experienceYears: user.experienceYears ?? '',
                    );
                    Navigator.pushNamed(context, '/trainer-profile', arguments: trainerModel);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Profile photo upload
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: avatarBytes != null
                      ? Image.memory(avatarBytes!, width: 80, height: 80, fit: BoxFit.cover)
                      : (photoUrlCtrl.text.trim().isNotEmpty
                          ? (photoUrlCtrl.text.trim().startsWith('http')
                              ? Image.network(photoUrlCtrl.text.trim(), width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 80, height: 80, color: AppTheme.paleMint, child: const Icon(Icons.person, size: 40, color: AppTheme.emeraldGreenDark)))
                              : Image.asset(photoUrlCtrl.text.trim(), width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 80, height: 80, color: AppTheme.paleMint, child: const Icon(Icons.person, size: 40, color: AppTheme.emeraldGreenDark))))
                          : Container(width: 80, height: 80, color: AppTheme.paleMint, child: const Icon(Icons.person, size: 40, color: AppTheme.emeraldGreenDark))),
                ),
                const SizedBox(width: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.camera_alt_rounded, size: 16),
                      label: const Text('Téléverser une photo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.paleMint,
                        foregroundColor: AppTheme.emeraldGreenDark,
                        elevation: 0,
                      ),
                      onPressed: () async {
                        final res = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
                        if (res != null && res.files.single.bytes != null) {
                          setSettingsState(() => avatarBytes = res.files.single.bytes);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: photoUrlCtrl,
              decoration: const InputDecoration(
                labelText: 'Ou URL directe de votre photo (facultatif)',
                hintText: 'https://mon-domaine.com/ma-photo.jpg',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link_rounded),
              ),
              onChanged: (_) => setSettingsState(() {}),
            ),
            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nom complet', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(labelText: 'Numéro de téléphone', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: specialityCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Spécialité / Titre d\'enseignement',
                      hintText: 'Ex: Enseignant en Informatique & Web',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: experienceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Années d\'expérience réelle',
                      hintText: 'Ex: 5 ans, 8 ans, 12 ans',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.workspace_premium_outlined),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            TextField(
              controller: quoteCtrl,
              decoration: const InputDecoration(
                labelText: 'Votre devise ou citation',
                hintText: 'Ex: Transmettre le savoir avec rigueur et bienveillance.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: bioCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Biographie & Présentation pour vos étudiants',
                hintText: 'Expliquez votre parcours, vos compétences et votre pédagogie...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              icon: const Icon(Icons.save_rounded, size: 18),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emeraldGreenDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isSaving ? null : () async {
                setSettingsState(() => isSaving = true);
                final updatedPhoto = photoUrlCtrl.text.trim().isNotEmpty ? photoUrlCtrl.text.trim() : null;
                await _authService.updateUserProfile(
                  displayName: nameCtrl.text.trim(),
                  phoneNumber: phoneCtrl.text.trim(),
                  photoUrl: updatedPhoto,
                  avatarBytes: avatarBytes,
                  avatarFileName: 'teacher_avatar.jpg',
                  speciality: specialityCtrl.text.trim(),
                  experienceYears: experienceCtrl.text.trim(),
                  bio: bioCtrl.text.trim(),
                  quote: quoteCtrl.text.trim(),
                );
                setSettingsState(() => isSaving = false);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profil formateur mis à jour avec succès !'), backgroundColor: AppTheme.emeraldGreen),
                  );
                }
              },
              label: isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Sauvegarder mon profil formateur'),
            ),
            const PrivacySettingsCard(),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 7. COURSES TABLE & FULL VIEW (WITH REAL STREAM)
  // ==========================================
  Widget _buildCoursesTableSection(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mes formations', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.ink)),
              TextButton(
                onPressed: () => setState(() => _activeMenu = 'Mes formations'),
                child: Text('Gérer tout', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.emeraldGreenDark)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          StreamBuilder<List<CourseModel>>(
            stream: _courseService.getTeacherCoursesStream(user.uid),
            builder: (context, snapshot) {
              final courses = snapshot.data ?? [];
              if (courses.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('Aucune formation créée pour le moment.', style: TextStyle(color: AppTheme.textMuted))),
                );
              }

              return Column(
                children: courses.take(5).map((course) => _buildCourseRow(course)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ÉTUDIANTS INSCRITS DIRECTEMENT AUPRÈS DU PROFESSEUR
  // ==========================================
  Widget _buildTeacherRegistrationsView(UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MarketingSectionHeader(
            badge: 'INSCRIPTIONS ÉTUDIANTS',
            title: 'Étudiants inscrits à vos cours',
            subtitle: 'Consultez la liste des étudiants inscrits directement auprès de vous, leurs fiches et emplois du temps.',
          ),
          const SizedBox(height: 24),
          StreamBuilder<List<TeacherStudentRegistrationModel>>(
            stream: TeacherRegistrationService().getTeacherRegistrationsStream(user.uid),
            builder: (context, snapshot) {
              final list = snapshot.data ?? [];
              if (snapshot.connectionState == ConnectionState.waiting && list.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AppTheme.emeraldGreen),
                  ),
                );
              }

              if (list.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: const BoxDecoration(
                          color: AppTheme.paleMint,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.people_outline_rounded, size: 54, color: AppTheme.emeraldGreenDark),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun étudiant inscrit pour l\'instant',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Les étudiants qui s\'inscrivent directement auprès de vous depuis la liste des formateurs apparaîtront ici.',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: list.map((reg) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10233F).withValues(alpha: 0.04),
                          blurRadius: 14,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppTheme.paleMint,
                              child: Text(
                                reg.studentFirstName.isNotEmpty ? reg.studentFirstName[0].toUpperCase() : 'E',
                                style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.emeraldGreenDark, fontSize: 16),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          reg.studentFullName,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.ink,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDCFCE7),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xFF86EFAC)),
                                        ),
                                        child: Text(
                                          reg.studyLevel,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF166534),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Matière : ${reg.subject} • N° Inscription : ${reg.registrationNumber}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5,
                                      color: AppTheme.textMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.access_time_filled_rounded, size: 14, color: Color(0xFF0F766E)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Emploi du temps : ${reg.proposedSchedule}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF334155),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF64748B)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Date d\'inscription : ${DateFormat("dd/MM/yyyy à HH:mm").format(reg.createdAt)}',
                                    style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                                  ),
                                  const SizedBox(width: 16),
                                  if (reg.phone.isNotEmpty) ...[
                                    const Icon(Icons.phone_rounded, size: 13, color: Color(0xFF16A34A)),
                                    const SizedBox(width: 6),
                                    Text(
                                      reg.phone,
                                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF16A34A), fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(width: 12),
                                  ],
                                  if (reg.email.isNotEmpty) ...[
                                    const Icon(Icons.email_outlined, size: 13, color: Color(0xFF64748B)),
                                    const SizedBox(width: 6),
                                    Text(
                                      reg.email,
                                      style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                StudentRegistrationCardDialog.show(context, registration: reg);
                              },
                              icon: const Icon(Icons.assignment_rounded, size: 15, color: Colors.white),
                              label: const Text('Consulter la fiche d\'inscription'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.emeraldGreenDark,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _activeMenu = 'Messages';
                                  _selectedStudentName = reg.studentFullName;
                                });
                              },
                              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15),
                              label: const Text('Contacter l\'étudiant'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.ink,
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showNotificationsDialog(UserModel user, List<TeacherStudentRegistrationModel> regs) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final unreadCount = regs.where((r) => !_readNotificationIds.contains(r.id)).length;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.notifications_rounded, color: AppTheme.emeraldGreenDark, size: 22),
                    const SizedBox(width: 8),
                    Text('Notifications', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16)),
                  ],
                ),
                if (regs.isNotEmpty && unreadCount > 0)
                  TextButton(
                    onPressed: () async {
                      await _markAllNotificationsAsRead(user.uid, regs);
                      setDialogState(() {});
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Tout marquer lu', style: TextStyle(fontSize: 12, color: AppTheme.emeraldGreenDark)),
                  ),
              ],
            ),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 440,
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: regs.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Center(
                        child: Text('Aucune notification pour le moment', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: regs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (dialogContext, i) {
                        final reg = regs[i];
                        final isRead = _readNotificationIds.contains(reg.id);

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          leading: CircleAvatar(
                            backgroundColor: isRead ? AppTheme.paleMint : const Color(0xFFDCFCE7),
                            child: Icon(
                              Icons.school_rounded,
                              color: isRead ? AppTheme.emeraldGreenDark : const Color(0xFF16A34A),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            'Nouvel étudiant inscrit ! 🎓',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                              fontSize: 13.5,
                              color: AppTheme.ink,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text(
                                '${reg.studentFullName} s\'est inscrit à vos cours de ${reg.subject} (${reg.studyLevel}).',
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF475569)),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () {
                                  _markNotificationAsRead(user.uid, reg.id);
                                  Navigator.pop(ctx);
                                  StudentRegistrationCardDialog.show(context, registration: reg);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.paleMint,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppTheme.mintAccent),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.assignment_rounded, size: 14, color: AppTheme.emeraldGreenDark),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Consulter la fiche de l\'étudiant',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.emeraldGreenDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            _markNotificationAsRead(user.uid, reg.id);
                            Navigator.pop(ctx);
                            StudentRegistrationCardDialog.show(context, registration: reg);
                          },
                        );
                      },
                    ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationBell(UserModel user) {
    return StreamBuilder<List<TeacherStudentRegistrationModel>>(
      stream: TeacherRegistrationService().getTeacherRegistrationsStream(user.uid),
      builder: (context, snapshot) {
        final regs = snapshot.data ?? [];
        final unreadCount = regs.where((r) => !_readNotificationIds.contains(r.id)).length;

        return Stack(
          alignment: Alignment.topRight,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: AppTheme.ink, size: 24),
              tooltip: 'Notifications',
              onPressed: () => _showNotificationsDialog(user, regs),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // ==========================================
  // CLASSES (100 ÉTUDIANTS MAX, TITULAIRE & CORRECTEUR)
  // ==========================================
  Widget _buildClassesView(UserModel user) {
    return StreamBuilder<List<ClassCohortModel>>(
      stream: _classService.getTeacherClassesStream(user.uid),
      builder: (context, snapshot) {
        final classes = snapshot.data ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gestion des Classes (Jusqu\'à 100 Étudiants)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Chaque classe regroupe jusqu\'à 100 étudiants, supervisée par un Titulaire et un Correcteur attitré.',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                    label: const Text('Créer une classe'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emeraldGreenDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _showCreateClassModal(user),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              StreamBuilder<List<TeacherStudentRegistrationModel>>(
                stream: TeacherRegistrationService().getTeacherRegistrationsStream(user.uid),
                builder: (context, regSnap) {
                  final regs = regSnap.data ?? [];
                  if (regs.isEmpty) return const SizedBox.shrink();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.how_to_reg_rounded, color: Color(0xFF16A34A), size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${regs.length} étudiant${regs.length > 1 ? "s" : ""} inscrit${regs.length > 1 ? "s" : ""} directement auprès de vous',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF166534),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Consultez les fiches d\'inscription officielles et assignez-les à vos cohortes.',
                                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF15803D)),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => setState(() => _activeMenu = 'Étudiants Inscrits'),
                          icon: const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
                          label: const Text('Voir la liste', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              if (classes.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.groups_outlined, size: 48, color: AppTheme.textMuted),
                      const SizedBox(height: 12),
                      Text('Aucune classe créée pour l\'instant', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.ink)),
                      const SizedBox(height: 4),
                      const Text('Créez votre première cohorte d\'étudiants (capacité 100 apprenants).', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    ],
                  ),
                )
              else
                Column(
                  children: classes.map((cohort) {
                    final percent = (cohort.studentIds.length / cohort.maxCapacity).clamp(0.0, 1.0);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 18),
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.cardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppTheme.paleMint,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.school_rounded, color: AppTheme.emeraldGreenDark, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            cohort.courseName,
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEFF6FF),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'Capacité : ${cohort.maxCapacity} max',
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      cohort.name,
                                      style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.ink),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Roles & Supervisors
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFA7F3D0)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.stars_rounded, color: Color(0xFF059669), size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Titulaire : ${cohort.teacherName}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF065F46)),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFC7D2FE)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.rate_review_rounded, color: Color(0xFF4F46E5), size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Correcteur : ${cohort.correctorName}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF3730A3)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Gauge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Inscriptions : ${cohort.studentIds.length} / ${cohort.maxCapacity} étudiants',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.ink),
                              ),
                              Text(
                                '${(percent * 100).toInt()}% rempli',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.emeraldGreenDark),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: percent,
                              minHeight: 8,
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                percent >= 0.9 ? const Color(0xFFDC2626) : AppTheme.emeraldGreenDark,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1, color: AppTheme.cardBorder),
                          const SizedBox(height: 12),

                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                icon: const Icon(Icons.people_outline_rounded, size: 16),
                                label: Text('Voir les ${cohort.studentIds.length} étudiants'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.ink,
                                  side: const BorderSide(color: AppTheme.cardBorder),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => _showCohortRosterModal(cohort, user),
                              ),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.assignment_add, size: 16),
                                label: const Text('Envoyer un devoir à cette classe'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.emeraldGreenDark,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => _showPublishHomeworkModal(user, presetClass: cohort),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showCreateClassModal(UserModel user) {
    final nameCtrl = TextEditingController();
    final courseCtrl = TextEditingController(text: 'Architecture logicielle & Flutter');

    // Chargement du correcteur lié à ce prof
    UserModel? linkedCorrector;
    bool loadingCorrector = true;
    String correctorError = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          // Charger le correcteur lié une seule fois
          if (loadingCorrector && linkedCorrector == null && correctorError.isEmpty) {
            CorrectorService().getLinkedCorrector(user.uid).then((corr) {
              if (ctx.mounted) {
                setModalState(() {
                  linkedCorrector = corr;
                  loadingCorrector = false;
                });
              }
            }).catchError((_) {
              if (ctx.mounted) {
                setModalState(() {
                  loadingCorrector = false;
                  correctorError = 'Aucun correcteur lié à votre compte';
                });
              }
            });
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Nouvelle Classe (Max 100 étudiants)', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16)),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: SingleChildScrollView(
                  child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nom de la classe / promotion',
                      hintText: 'Ex: Promo Alpha 2026 - Master 1',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: courseCtrl,
                    decoration: InputDecoration(
                      labelText: 'Matière / Formation associée',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bloc correcteur lié (lecture seule)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFC7D2FE)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.rate_review_rounded, color: Color(0xFF4F46E5), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: loadingCorrector
                            ? const Text('Chargement du correcteur…', style: TextStyle(fontSize: 12, color: Color(0xFF4F46E5)))
                            : correctorError.isNotEmpty
                              ? Text(correctorError, style: const TextStyle(fontSize: 12, color: Colors.red))
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Correcteur attitré :', style: TextStyle(fontSize: 11, color: Color(0xFF6366F1))),
                                    Text(
                                      linkedCorrector?.displayName ?? 'Non assigné',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF3730A3)),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                  if (correctorError.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Demandez à l\'admin d\'assigner un correcteur à votre compte.',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldGreenDark, foregroundColor: Colors.white),
                onPressed: loadingCorrector ? null : () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  // Utilise l'UID réel du correcteur lié, pas un ID générique
                  final corrId = linkedCorrector?.uid ?? 'corrector_${user.uid}';
                  final corrName = linkedCorrector?.displayName ?? 'Correcteur attitré';
                  await _classService.createClassCohort(
                    name: nameCtrl.text.trim(),
                    courseId: 'course_${DateTime.now().millisecondsSinceEpoch}',
                    courseName: courseCtrl.text.trim(),
                    teacherId: user.uid,
                    teacherName: user.displayName,
                    correctorId: corrId,
                    correctorName: corrName,
                  );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Classe créée ! Correcteur assigné : $corrName')),
                    );
                  }
                },
                child: const Text('Créer la classe'),
              ),
            ],
          );
        },
      ),
    );
  }


  void _showCohortRosterModal(ClassCohortModel cohort, UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Effectif : ${cohort.name}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text('Formation : ${cohort.courseName}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.paleMint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${cohort.studentIds.length} / ${cohort.maxCapacity}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.emeraldGreenDark),
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 520,
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: cohort.studentIds.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people_outline_rounded, size: 48, color: AppTheme.textMuted),
                      const SizedBox(height: 8),
                      Text('Aucun apprenant n\'a encore rejoint cette classe.', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 13)),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: cohort.studentIds.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final id = cohort.studentIds[i];
                    final name = cohort.studentNames[id] ?? 'Étudiant #${i + 1}';
                    final email = cohort.studentEmails[id] ?? '';
                    final phone = cohort.studentPhones[id] ?? '';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppTheme.paleMint,
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'E',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.emeraldGreenDark),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppTheme.ink)),
                                const SizedBox(height: 2),
                                if (email.isNotEmpty)
                                  Row(
                                    children: [
                                      const Icon(Icons.email_outlined, size: 12, color: AppTheme.textMuted),
                                      const SizedBox(width: 4),
                                      Flexible(child: Text(email, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted), overflow: TextOverflow.ellipsis)),
                                    ],
                                  ),
                                if (phone.isNotEmpty)
                                  Row(
                                    children: [
                                      const Icon(Icons.phone_outlined, size: 12, color: Color(0xFF16A34A)),
                                      const SizedBox(width: 4),
                                      Text(phone, style: const TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                if (email.isEmpty && phone.isEmpty)
                                  Text('Matricule : $id', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Bouton Discuter avec l'étudiant
                          IconButton(
                            icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.emeraldGreenDark, size: 20),
                            tooltip: 'Discuter avec l\'apprenant',
                            onPressed: () async {
                              Navigator.pop(ctx);
                              final convId = await _chatService.getOrCreateConversation(
                                currentUserId: user.uid,
                                currentUserName: user.displayName,
                                targetUserId: id,
                                targetUserName: name,
                                courseName: cohort.courseName,
                              );
                              setState(() {
                                _activeMenu = 'Messages';
                                _selectedConversationId = convId;
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldGreenDark, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // EMPLOI DU TEMPS DU PROFESSEUR
  // ==========================================
  Widget _buildTimetableView(UserModel user) {
    return StreamBuilder<List<ClassCohortModel>>(
      stream: _classService.getTeacherClassesStream(user.uid),
      builder: (context, snapshot) {
        final classes = snapshot.data ?? [];
        final allSlots = <ClassScheduleSlot>[];
        for (var c in classes) {
          allSlots.addAll(c.schedule);
        }
        final personalSlots = user.weeklySchedule.map((m) => ClassScheduleSlot.fromMap(m)).toList();
        allSlots.addAll(personalSlots);

        final days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Emploi du Temps Hebdomadaire',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Planning des cours magistraux, disponibilités d\'encadrement et sessions interactives.',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.more_time_rounded, size: 16),
                        label: const Text('Planifier un créneau', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.emeraldGreenDark,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        onPressed: () => _showAddScheduleSlotModal(user),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.paleMint,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.calendar_today_rounded, size: 16, color: AppTheme.emeraldGreenDark),
                            SizedBox(width: 6),
                            Text(
                              'Semaine Active',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.emeraldGreenDark),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Column(
                children: days.map((day) {
                  final daySlots = allSlots.where((s) => s.dayOfWeek.toLowerCase() == day.toLowerCase()).toList();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 18),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.emeraldGreenDark,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  day,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.ink),
                                ),
                              ],
                            ),
                            Text(
                              '${daySlots.length} créneau(x)',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        if (daySlots.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('Aucun cours prévu ce jour.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontStyle: FontStyle.italic)),
                          )
                        else
                          Column(
                            children: daySlots.map((slot) {
                              final isMagistral = slot.type.contains('Titulaire');
                              final isPersonal = personalSlots.any((ps) =>
                                  ps.dayOfWeek == slot.dayOfWeek &&
                                  ps.startTime == slot.startTime &&
                                  ps.subject == slot.subject);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.cardBorder),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppTheme.cardBorder),
                                      ),
                                      child: Text(
                                        '${slot.startTime} - ${slot.endTime}',
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.ink),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            slot.subject,
                                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.ink),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Lieu / Lien : ${slot.roomOrLink}',
                                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isMagistral ? AppTheme.paleMint : const Color(0xFFEEF2FF),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        slot.type,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: isMagistral ? AppTheme.emeraldGreenDark : const Color(0xFF4F46E5),
                                        ),
                                      ),
                                    ),
                                    if (isPersonal)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                        tooltip: 'Supprimer ce créneau',
                                        onPressed: () => _deleteScheduleSlot(user, slot),
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddScheduleSlotModal(UserModel user) {
    String selectedDay = 'Lundi';
    String selectedType = 'Cours magistral (Titulaire)';
    final startCtrl = TextEditingController(text: '09:00');
    final endCtrl = TextEditingController(text: '11:00');
    final subjectCtrl = TextEditingController(text: 'Permanence & Tutorat');
    final roomCtrl = TextEditingController(text: 'Salle Virtuelle Live');
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.emeraldGreen.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.more_time_rounded, color: AppTheme.emeraldGreenDark, size: 22),
              ),
              const SizedBox(width: 12),
              Text('Planifier un créneau', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16)),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Jour de la semaine', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.ink)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedDay,
                    items: const [
                      DropdownMenuItem(value: 'Lundi', child: Text('Lundi')),
                      DropdownMenuItem(value: 'Mardi', child: Text('Mardi')),
                      DropdownMenuItem(value: 'Mercredi', child: Text('Mercredi')),
                      DropdownMenuItem(value: 'Jeudi', child: Text('Jeudi')),
                      DropdownMenuItem(value: 'Vendredi', child: Text('Vendredi')),
                      DropdownMenuItem(value: 'Samedi', child: Text('Samedi')),
                      DropdownMenuItem(value: 'Dimanche', child: Text('Dimanche')),
                    ],
                    onChanged: (v) => setModalState(() => selectedDay = v ?? 'Lundi'),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Heure début', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.ink)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: startCtrl,
                              decoration: InputDecoration(
                                hintText: '09:00',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Heure fin', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.ink)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: endCtrl,
                              decoration: InputDecoration(
                                hintText: '11:00',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text('Intitulé du cours / Disponibilité', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.ink)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: subjectCtrl,
                    decoration: InputDecoration(
                      hintText: 'Ex: Développement Web & Mobile',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Type de session', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.ink)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    items: const [
                      DropdownMenuItem(value: 'Cours magistral (Titulaire)', child: Text('Cours magistral (Titulaire)')),
                      DropdownMenuItem(value: 'Permanence Enseignant', child: Text('Permanence Enseignant')),
                      DropdownMenuItem(value: 'Séance TD (Correcteur)', child: Text('Séance TD (Correcteur)')),
                      DropdownMenuItem(value: 'Session Live & Exercices', child: Text('Session Live & Exercices')),
                    ],
                    onChanged: (v) => setModalState(() => selectedType = v ?? 'Cours magistral (Titulaire)'),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Lieu ou lien de visioconférence', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.ink)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: roomCtrl,
                    decoration: InputDecoration(
                      hintText: 'Ex: Salle Virtuelle Live ou Salle A101',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emeraldGreenDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isSaving
                  ? null
                  : () async {
                      if (subjectCtrl.text.trim().isEmpty) return;
                      setModalState(() => isSaving = true);
                      final newSlot = {
                        'dayOfWeek': selectedDay,
                        'startTime': startCtrl.text.trim().isEmpty ? '09:00' : startCtrl.text.trim(),
                        'endTime': endCtrl.text.trim().isEmpty ? '11:00' : endCtrl.text.trim(),
                        'subject': subjectCtrl.text.trim(),
                        'type': selectedType,
                        'roomOrLink': roomCtrl.text.trim().isEmpty ? 'Salle Virtuelle Live' : roomCtrl.text.trim(),
                      };
                      final updated = List<Map<String, dynamic>>.from(user.weeklySchedule)..add(newSlot);
                      try {
                        if (Firebase.apps.isNotEmpty) {
                          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                            'weeklySchedule': updated,
                            'updatedAt': FieldValue.serverTimestamp(),
                          });
                        }
                      } catch (_) {}
                      final updatedUser = user.copyWith(weeklySchedule: updated);
                      _authService.updateCurrentUser(updatedUser);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Créneau ajouté à l\'emploi du temps !'), backgroundColor: AppTheme.emeraldGreenDark),
                        );
                      }
                    },
              child: isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Enregistrer le créneau'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteScheduleSlot(UserModel user, ClassScheduleSlot slot) async {
    final updated = List<Map<String, dynamic>>.from(user.weeklySchedule);
    updated.removeWhere((m) =>
        m['dayOfWeek'] == slot.dayOfWeek &&
        m['startTime'] == slot.startTime &&
        m['subject'] == slot.subject);
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'weeklySchedule': updated,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {}
    final updatedUser = user.copyWith(weeklySchedule: updated);
    _authService.updateCurrentUser(updatedUser);
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Créneau supprimé.'), backgroundColor: AppTheme.emeraldGreenDark),
      );
    }
  }

  // ==========================================
  // DEVOIRS ENVOYÉS PAR LE TITULAIRE
  // ==========================================
  Widget _buildHomeworksSentView(UserModel user) {
    return StreamBuilder<List<HomeworkModel>>(
      stream: _homeworkService.getHomeworksByTeacherStream(user.uid),
      builder: (context, snapshot) {
        final homeworks = snapshot.data ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Devoirs & Sujets Assignés',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Publiez des devoirs pour vos promotions. Les étudiants composent sur page blanche ou feuille propre, et le correcteur attribue les notes.',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_task_rounded, size: 18),
                    label: const Text('Assigner un devoir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emeraldGreenDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _showPublishHomeworkModal(user),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (homeworks.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.assignment_late_outlined, size: 48, color: AppTheme.textMuted),
                      const SizedBox(height: 12),
                      Text('Aucun devoir envoyé pour l\'instant', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.ink)),
                      const SizedBox(height: 4),
                      const Text('Cliquez sur "Assigner un devoir" pour envoyer un nouveau sujet à vos étudiants.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    ],
                  ),
                )
              else
                Column(
                  children: homeworks.map((hw) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(hw.courseName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                              ),
                              Text(
                                'Délai : ${hw.deadline.day.toString().padLeft(2, '0')}/${hw.deadline.month.toString().padLeft(2, '0')}/${hw.deadline.year}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(hw.title, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.ink)),
                          const SizedBox(height: 6),
                          Text(hw.instructions, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                          const SizedBox(height: 14),
                          const Divider(height: 1, color: AppTheme.cardBorder),
                          const SizedBox(height: 12),

                          StreamBuilder<List<HomeworkSubmissionModel>>(
                            stream: _homeworkService.getSubmissionsStream(hw.id),
                            builder: (context, subSnap) {
                              final subs = subSnap.data ?? [];
                              final correctedCount = subs.where((s) => s.status == 'corrected').length;

                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${subs.length} copie(s) rendue(s) • $correctedCount corrigée(s)',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.emeraldGreenDark),
                                  ),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.remove_red_eye_rounded, size: 14),
                                    label: const Text('Voir les copies remises'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.ink,
                                      side: const BorderSide(color: AppTheme.cardBorder),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () => _showSubmissionsListModal(hw, subs),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showPublishHomeworkModal(UserModel user, {ClassCohortModel? presetClass}) {
    HomeworkAssignmentDialog.show(
      context,
      user: user,
      presetCourseId: presetClass?.courseId,
      presetCourseName: presetClass?.courseName,
    );
  }

  void _showSubmissionsListModal(HomeworkModel hw, List<HomeworkSubmissionModel> subs) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment_turned_in_rounded, color: AppTheme.emeraldGreenDark, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Copies remises : ${hw.title}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('${hw.courseName} • Barème : ${hw.points} points', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            if (hw.attachmentUrls.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (int i = 0; i < hw.attachmentUrls.length; i++)
                    ActionChip(
                      avatar: Icon(FileDownloadHelper.getFileIcon(hw.getAttachmentName(i)), size: 14, color: AppTheme.emeraldGreenDark),
                      label: Text('Sujet : ${hw.getAttachmentName(i)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      backgroundColor: AppTheme.paleMint,
                      onPressed: () => FileDownloadHelper.downloadOrOpenFile(hw.attachmentUrls[i], fileName: hw.getAttachmentName(i)),
                    ),
                ],
              ),
            ],
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 580,
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: subs.isEmpty
              ? const Center(child: Text('Aucune copie rendue pour le moment.', style: TextStyle(color: AppTheme.textMuted)))
              : ListView.separated(
                  itemCount: subs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final sub = subs[i];
                    final isCorrected = sub.status == 'corrected';
                    final hasFile = sub.fileUrls.isNotEmpty || (sub.fileUrl != null && sub.fileUrl!.isNotEmpty);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      title: Text(sub.studentName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rendu le ${sub.submittedAt.day.toString().padLeft(2, '0')}/${sub.submittedAt.month.toString().padLeft(2, '0')} • Type : ${sub.submissionType}',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                          if (sub.feedback != null && sub.feedback!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text('Remarque : "${sub.feedback}"', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF047857))),
                          ],
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasFile)
                            IconButton(
                              icon: const Icon(Icons.download_rounded, color: AppTheme.emeraldGreenDark, size: 20),
                              tooltip: 'Télécharger le fichier rendu',
                              onPressed: () {
                                final targetUrl = sub.fileUrls.isNotEmpty ? sub.fileUrls.first : sub.fileUrl!;
                                final targetName = sub.attachmentName ?? '${sub.studentName}_copie';
                                FileDownloadHelper.downloadOrOpenFile(targetUrl, fileName: targetName);
                              },
                            ),
                          if (sub.blankPageContent != null && sub.blankPageContent!.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.menu_book_rounded, color: Color(0xFF2563EB), size: 20),
                              tooltip: 'Lire la copie rédigée',
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    title: Text('Copie de ${sub.studentName}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15)),
                                    content: SingleChildScrollView(
                                      child: SelectableText(sub.blankPageContent!, style: const TextStyle(fontSize: 13, height: 1.5)),
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(c), child: const Text('Fermer')),
                                    ],
                                  ),
                                );
                              },
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isCorrected ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isCorrected ? '${(sub.grade ?? sub.note ?? 18).toStringAsFixed(1)}/${hw.points}' : 'À corriger',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isCorrected ? const Color(0xFF059669) : const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldGreenDark, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildFullCoursesView() {
    final user = _authService.currentUser ?? UserModel.demoTeacher;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Toutes mes formations', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.ink)),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded),
                label: const Text('+ Créer une formation'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldGreenDark, foregroundColor: Colors.white),
                onPressed: () => _showCreateCourseModal(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          StreamBuilder<List<CourseModel>>(
            stream: _courseService.getTeacherCoursesStream(user.uid),
            builder: (context, snapshot) {
              final courses = snapshot.data ?? [];
              if (courses.isEmpty) {
                return const Center(child: Text('Aucune formation créée.'));
              }

              return Column(
                children: courses.map((course) => _buildCourseRow(course)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCourseRow(CourseModel course) {
    final isPublished = course.publicationStatus == 'Publiée' || course.isPublished;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 620;
        if (isMobile) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: course.image.startsWith('http')
                      ? Image.network(course.image, width: 50, height: 50, fit: BoxFit.cover)
                      : Image.asset(course.image, width: 50, height: 50, fit: BoxFit.cover),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.ink),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${course.category} • ${course.formattedPrice}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          InkWell(
                            onTap: () => _courseService.togglePublishStatus(course.id, isPublished),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isPublished ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isPublished ? 'Publiée' : 'Brouillon',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isPublished ? const Color(0xFF065F46) : const Color(0xFFB45309),
                                ),
                              ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.people_outline_rounded, size: 13, color: AppTheme.textMuted),
                              const SizedBox(width: 3),
                              Text('${course.studentsCount} élèves', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 13),
                              const SizedBox(width: 2),
                              Text('${course.rating}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildCoursePopupMenu(course, isPublished),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: course.image.startsWith('http')
                          ? Image.network(course.image, width: 42, height: 42, fit: BoxFit.cover)
                          : Image.asset(course.image, width: 42, height: 42, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(course.title, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.ink), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('${course.category} • ${course.formattedPrice}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text('${course.studentsCount} élèves', style: const TextStyle(fontSize: 12)),
              ),
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 14),
                    const SizedBox(width: 2),
                    Text('${course.rating}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: InkWell(
                  onTap: () => _courseService.togglePublishStatus(course.id, isPublished),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPublished ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isPublished ? 'Publiée' : 'Brouillon',
                      style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: isPublished ? const Color(0xFF065F46) : const Color(0xFFB45309)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              _buildCoursePopupMenu(course, isPublished),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCoursePopupMenu(CourseModel course, bool isPublished) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppTheme.textMuted),
      onSelected: (action) {
        if (action == 'lessons') {
          _showManageLessonsModal(course);
        } else if (action == 'live') {
          _showStartLiveModal(selectedCourse: course);
        } else if (action == 'edit') {
          _showCreateCourseModal(existingCourse: course);
        } else if (action == 'toggle') {
          _courseService.togglePublishStatus(course.id, isPublished);
        } else if (action == 'delete') {
          _courseService.deleteCourse(course.id);
        }
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(value: 'lessons', child: Row(children: [Icon(Icons.video_library_rounded, size: 16), SizedBox(width: 8), Text('Gérer les leçons / vidéos')])),
        const PopupMenuItem(value: 'live', child: Row(children: [Icon(Icons.sensors_rounded, size: 16, color: Colors.redAccent), SizedBox(width: 8), Text('Lancer un Live')])),
        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, size: 16), SizedBox(width: 8), Text('Modifier les informations')])),
        PopupMenuItem(value: 'toggle', child: Row(children: [Icon(isPublished ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 16), SizedBox(width: 8), Text(isPublished ? 'Passer en brouillon' : 'Publier')])),
        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_forever_rounded, size: 16, color: Colors.red), SizedBox(width: 8), Text('Supprimer', style: TextStyle(color: Colors.red))])),
      ],
    );
  }

  // ==========================================
  // 8. SIDEBAR, HEADER & REMAINING WIDGETS
  // ==========================================
  Widget _buildTopHeader(BuildContext context, UserModel user, bool isDesktop) {
    if (!isDesktop) {
      final screenWidth = MediaQuery.of(context).size.width;
      final isVerySmall = screenWidth < 420;
      return Container(
        color: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: isVerySmall ? 4 : 8, vertical: 10),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.ink, size: 20),
              tooltip: 'Retour',
              onPressed: () {
                setState(() {
                  if (_activeMenu != 'Tableau de bord') {
                    _activeMenu = 'Tableau de bord';
                  } else if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushNamed(context, '/');
                  }
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: AppTheme.ink, size: 26),
              tooltip: 'Menu',
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.sensors_rounded, color: Colors.white, size: 15),
              label: isVerySmall
                  ? const SizedBox.shrink()
                  : const Text('Live', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: isVerySmall ? 8 : 10, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _showStartLiveModal(),
            ),
            const SizedBox(width: 4),
            _buildNotificationBell(user),
            const SizedBox(width: 4),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
              label: Text(
                screenWidth < 500 ? 'Créer' : '+ Créer une formation',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emeraldGreenDark,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: isVerySmall ? 8 : 10, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _showCreateCourseModal(),
            ),
          ],
        ),
      );
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.ink, size: 22),
            tooltip: _activeMenu != 'Tableau de bord' ? 'Retour au tableau de bord' : 'Retour à l\'accueil',
            onPressed: () {
              setState(() {
                if (_activeMenu != 'Tableau de bord') {
                  _activeMenu = 'Tableau de bord';
                } else if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacementNamed(context, '/');
                }
              });
            },
          ),
          InkWell(
            onTap: () {
              setState(() {
                if (_activeMenu != 'Tableau de bord') {
                  _activeMenu = 'Tableau de bord';
                } else if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacementNamed(context, '/');
                }
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Text(
                _activeMenu != 'Tableau de bord' ? 'Tableau de bord' : 'Accueil site',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.emeraldGreenDark,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher une formation, un apprenant...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          _buildNotificationBell(user),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.sensors_rounded, color: Colors.white, size: 16),
            label: const Text('Démarrer un Live'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => _showStartLiveModal(),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
            label: const Text('+ Créer une formation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emeraldGreenDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => _showCreateCourseModal(),
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingBanner(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF07251F),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bonjour, ${user.displayName} 👋', style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 6),
                const Text('Voici un aperçu de vos cours, apprenants et sessions en direct.', style: TextStyle(color: Color(0xFFC7DFD9), fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards(UserModel user) {
    return StreamBuilder<List<CourseModel>>(
      stream: _courseService.getTeacherCoursesStream(user.uid),
      builder: (context, courseSnap) {
        final courses = courseSnap.data ?? [];
        final totalCourses = courses.length;
        final totalStudents = courses.fold<int>(0, (acc, c) => acc + c.studentsCount);

        return StreamBuilder<List<TrainerReviewItem>>(
          stream: TrainerReviewService().getTeacherReviewsStream(user.uid),
          builder: (context, reviewSnap) {
            final reviews = reviewSnap.data ?? [];
            final String avgRatingStr;
            if (reviews.isNotEmpty) {
              final sumRating = reviews.fold<double>(0.0, (acc, r) => acc + r.rating);
              avgRatingStr = (sumRating / reviews.length).toStringAsFixed(1);
            } else if (courses.any((c) => c.rating > 0)) {
              final rated = courses.where((c) => c.rating > 0).toList();
              avgRatingStr = (rated.fold<double>(0.0, (s, c) => s + c.rating) / rated.length).toStringAsFixed(1);
            } else {
              avgRatingStr = 'N/A';
            }

            return StreamBuilder<List<LiveSessionModel>>(
              stream: _liveService.getActiveLiveSessionsStream(),
              builder: (context, liveSnap) {
                final activeLives = (liveSnap.data ?? [])
                    .where((l) => l.isLive && (l.teacherId == user.uid || l.teacherName == user.displayName))
                    .toList();
                final hasActiveLive = activeLives.isNotEmpty;

                return LayoutBuilder(builder: (context, constraints) {
                  final isVeryCompact = constraints.maxWidth < 400;
                  final isCompact = constraints.maxWidth < 640;
                  final w = isVeryCompact ? constraints.maxWidth : (isCompact ? (constraints.maxWidth - 16) / 2 : (constraints.maxWidth - 48) / 4);
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildStatCard(
                        width: w,
                        icon: Icons.auto_stories_rounded,
                        color: AppTheme.emeraldGreenDark,
                        bg: AppTheme.paleMint,
                        val: '$totalCourses',
                        label: 'Formation${totalCourses > 1 ? 's' : ''} créée${totalCourses > 1 ? 's' : ''}',
                      ),
                      _buildStatCard(
                        width: w,
                        icon: Icons.groups_rounded,
                        color: const Color(0xFF0284C7),
                        bg: const Color(0xFFE0F2FE),
                        val: '$totalStudents',
                        label: 'Apprenant${totalStudents > 1 ? 's' : ''} actif${totalStudents > 1 ? 's' : ''}',
                      ),
                      _buildStatCard(
                        width: w,
                        icon: Icons.star_rounded,
                        color: const Color(0xFFD97706),
                        bg: const Color(0xFFFEF3C7),
                        val: avgRatingStr,
                        label: 'Note moyenne',
                      ),
                      _buildStatCard(
                        width: w,
                        icon: Icons.sensors_rounded,
                        color: hasActiveLive ? Colors.redAccent : AppTheme.textMuted,
                        bg: hasActiveLive ? const Color(0xFFFFE4E6) : const Color(0xFFF1F5F9),
                        val: hasActiveLive ? 'En direct' : '0 en cours',
                        label: 'Sessions en direct',
                      ),
                    ],
                  );
                });
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard({required double width, required IconData icon, required Color color, required Color bg, required String val, required String label}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  val,
                  style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted, height: 1.2),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsChartSection(UserModel user) {
    return StreamBuilder<List<CourseModel>>(
      stream: _courseService.getTeacherCoursesStream(user.uid),
      builder: (context, snapshot) {
        final courses = snapshot.data ?? [];
        final totalStudents = courses.fold<int>(0, (acc, c) => acc + c.studentsCount);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.cardBorder)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Progression des inscriptions', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.ink)),
                  if (totalStudents > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppTheme.paleMint, borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        '$totalStudents inscrit${totalStudents > 1 ? 's' : ''}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.emeraldGreenDark),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
                child: totalStudents > 0
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.trending_up_rounded, color: AppTheme.emeraldGreenDark, size: 22),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '$totalStudents apprenant${totalStudents > 1 ? 's' : ''} suivent vos cours actuellement',
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.ink),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (totalStudents / (totalStudents + 10)).clamp(0.1, 1.0),
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.emeraldGreenDark),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.bar_chart_rounded, size: 32, color: AppTheme.textMuted),
                          const SizedBox(height: 6),
                          Text(
                            'Aucune inscription enregistrée pour le moment',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Vos statistiques d\'inscriptions s\'actualiseront automatiquement dès vos premières ventes.',
                            style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentReviewsSection(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.cardBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Derniers avis apprenants', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.ink)),
              const Icon(Icons.star_rounded, size: 18, color: Color(0xFFD97706)),
            ],
          ),
          const SizedBox(height: 14),
          StreamBuilder<List<TrainerReviewItem>>(
            stream: TrainerReviewService().getTeacherReviewsStream(user.uid),
            builder: (context, snapshot) {
              final reviews = snapshot.data ?? [];
              if (reviews.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.rate_review_outlined, size: 28, color: AppTheme.textMuted),
                      const SizedBox(height: 6),
                      Text(
                        'Aucun avis pour le moment',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.ink),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Les retours et avis laissés par vos apprenants apparaîtront ici.',
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: reviews.take(3).map((r) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.paleMint,
                          child: Text(
                            r.authorName.isNotEmpty ? r.authorName[0].toUpperCase() : 'A',
                            style: const TextStyle(color: AppTheme.emeraldGreenDark, fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    r.authorName,
                                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.ink),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded, size: 12, color: Color(0xFFD97706)),
                                      const SizedBox(width: 2),
                                      Text(r.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                r.comment,
                                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SESSIONS LIVE VIEW (LIVEKIT CLOUD - DYNAMIQUE)
  // ==========================================
  Widget _buildLiveSessionsView(UserModel user, bool isDesktop) {
    return StreamBuilder<List<LiveSessionModel>>(
      stream: _liveService.getLiveSessionsStream(),
      builder: (context, liveSnap) {
        final allLives = liveSnap.data ?? [];
        final teacherLives = allLives.where((l) =>
            l.teacherId == user.uid ||
            l.teacherName.toLowerCase() == user.displayName.toLowerCase() ||
            l.teacherId.isEmpty
        ).toList();

        final activeLive = teacherLives.where((l) => l.status == 'live').firstOrNull ?? _activeLive;
        final scheduledLives = teacherLives.where((l) => l.status == 'scheduled').toList()
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
        final endedLives = teacherLives.where((l) => l.status == 'ended' || l.hasReplay).toList();

        return StreamBuilder<List<CourseModel>>(
          stream: _courseService.getTeacherCoursesStream(user.uid),
          builder: (context, courseSnap) {
            final courses = courseSnap.data ?? [];
            final courseReplays = <Map<String, dynamic>>[];

            // Extraire les replays réels des cours du formateur
            for (final c in courses) {
              for (final r in c.replays) {
                courseReplays.add({
                  'title': r.title,
                  'course': c.title,
                  'duration': r.duration,
                  'date': DateFormat('d MMM yyyy', 'fr_FR').format(r.date),
                  'views': c.studentsCount,
                  'url': r.replayUrl,
                });
              }
            }

            // Ajouter les replays des sessions terminées
            for (final s in endedLives) {
              final alreadyAdded = courseReplays.any((cr) =>
                  cr['title'] == s.title ||
                  cr['title'] == 'Replay : ${s.title}'
              );
              if (!alreadyAdded) {
                courseReplays.add({
                  'title': s.title.startsWith('Replay') ? s.title : 'Replay : ${s.title}',
                  'course': s.courseName,
                  'duration': s.replayDuration ?? '1h 30min',
                  'date': s.endedAt != null
                      ? DateFormat('d MMM yyyy', 'fr_FR').format(s.endedAt!)
                      : DateFormat('d MMM yyyy', 'fr_FR').format(s.scheduledAt),
                  'views': s.participantCount > 0 ? s.participantCount : 1,
                  'url': s.replayUrl ?? '',
                });
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: MarketingSectionHeader(
                        badge: 'SESSIONS LIVE',
                        title: 'Animez vos sessions en direct',
                        subtitle: 'LiveKit Cloud — théorie interactive + exercices pratiques en temps réel.',
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.sensors_rounded, color: Colors.white, size: 18),
                      label: const Text('Démarrer un direct'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _showStartLiveModal(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // LiveKit Cloud Config Strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Serveur LiveKit Cloud : wss://anour-rv83fs3g.livekit.cloud (Opérationnel)',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('WebRTC / JWT HS256', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.white70)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Active Live Banner if any
                if (activeLive != null) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.sensors_rounded, color: Color(0xFFDC2626), size: 36),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDC2626),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('EN COURS', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      activeLive.title,
                                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.ink),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('Formation : ${activeLive.courseName} • ${activeLive.participantCount} participant(s)', style: TextStyle(fontSize: 12, color: Colors.red[900])),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
                          icon: const Icon(Icons.videocam_rounded, size: 16),
                          label: const Text('Rejoindre le Studio'),
                          onPressed: () => _openLiveStudio(activeLive, user),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red[800], side: BorderSide(color: Colors.red.shade400)),
                          onPressed: () => _showEndLiveModal(activeLive),
                          child: const Text('Terminer'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Upcoming Programmed Sessions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Prochaines sessions au programme', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.ink)),
                    if (scheduledLives.isNotEmpty)
                      TextButton.icon(
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                        label: const Text('Programmer un direct'),
                        onPressed: () => _showStartLiveModal(),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                if (scheduledLives.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: AppTheme.paleMint,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.event_available_rounded, size: 36, color: AppTheme.emeraldGreenDark),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Aucune session programmée',
                          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.ink),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Planifiez un webinaire ou atelier live pour réunir vos apprenants.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 18),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                          label: const Text('Programmer une session'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.emeraldGreenDark,
                            side: const BorderSide(color: AppTheme.emeraldGreenDark),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _showStartLiveModal(),
                        ),
                      ],
                    ),
                  )
                else
                  GridView.builder(
                    itemCount: scheduledLives.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isDesktop ? 2 : 1,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: isDesktop ? 2.4 : 2.0,
                    ),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final s = scheduledLives[index];
                      final dateFormatted = DateFormat("EEEE d MMMM 'à' HH'h'mm", 'fr_FR').format(s.scheduledAt);
                      return _buildLivePlanCard(
                        title: s.title,
                        course: s.courseName,
                        date: dateFormatted,
                        enrolled: s.participantCount,
                        onStart: () async {
                          await _liveService.startScheduledSession(s);
                          if (context.mounted) {
                            _openLiveStudio(s.copyWith(status: 'live'), user);
                          }
                        },
                        onDelete: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Annuler la session ?'),
                              content: Text('Voulez-vous vraiment annuler la session "${s.title}" ?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Non')),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Oui, annuler'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await _liveService.cancelLiveSession(s.id);
                          }
                        },
                      );
                    },
                  ),
                const SizedBox(height: 28),

                // Live Replays Section
                Text('Replays archivés des sessions passées', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.ink)),
                const SizedBox(height: 12),

                if (courseReplays.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.video_library_outlined, size: 36, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Aucun replay archivé',
                          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.ink),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Vos sessions en direct terminées seront automatiquement archivées et consultables ici.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: courseReplays.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final cr = courseReplays[index];
                        return _buildReplayRow(
                          title: cr['title'] as String,
                          course: cr['course'] as String,
                          duration: cr['duration'] as String,
                          date: cr['date'] as String,
                          views: (cr['views'] as num?)?.toInt() ?? 1,
                          onTap: () {
                            final url = cr['url'] as String?;
                            if (url != null && url.isNotEmpty) {
                              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                            }
                          },
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLivePlanCard({
    required String title,
    required String course,
    required String date,
    required int enrolled,
    required VoidCallback onStart,
    VoidCallback? onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppTheme.paleMint, borderRadius: BorderRadius.circular(6)),
                child: Text(date, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.emeraldGreenDark)),
              ),
              const Spacer(),
              Text('$enrolled inscrits', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
              if (onDelete != null) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(Icons.close_rounded, size: 16, color: Colors.grey.shade400),
                  ),
                ),
              ],
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.ink), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(course, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emeraldGreenDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('Lancer cette session en direct', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              onPressed: onStart,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplayRow({
    required String title,
    required String course,
    required String duration,
    required String date,
    required int views,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.play_circle_fill_rounded, color: Colors.redAccent, size: 26),
      ),
      title: Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.ink)),
      subtitle: Text('$course • Durée: $duration • $date', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
        child: Text('$views vues', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.ink)),
      ),
    );
  }

  // ==========================================
  // REVENUS & RETRAITS (API INTECH SN)
  // ==========================================
  String _formatCurrencyFCFA(num amount) {
    final int val = amount.round();
    return '${val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} FCFA';
  }

  Widget _buildEarningsAndWithdrawalsView(UserModel user, bool isDesktop) {
    return StreamBuilder<List<CourseModel>>(
      stream: _courseService.getTeacherCoursesStream(user.uid),
      builder: (context, snapshot) {
        final courses = snapshot.data ?? [];
        final totalStudents = courses.fold<int>(0, (s, c) => s + c.studentsCount);
        final totalRevenue = courses.fold<int>(0, (s, c) => s + (c.studentsCount * c.price));
        final netShare = (totalRevenue * 0.90).round();
        final completedWithdrawals = _withdrawalTransactions.where((t) => t.status == 'SUCCESS').toList();
        final totalWithdrawn = completedWithdrawals.fold<int>(0, (s, t) => s + t.amount);
        final availableBalance = (netShare - totalWithdrawn).clamp(0, 999999999);
        _teacherBalance = availableBalance;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            MarketingSectionHeader(
              badge: 'FINANCES',
              title: 'Revenus & retraits Wave / Orange',
              subtitle: 'Retraits automatiques via Wave SN et Orange Money SN.',
              actionLabel: 'Demander un retrait',
              actionIcon: Icons.send_rounded,
              onAction: () => _showWithdrawalModal(user),
            ),
            const SizedBox(height: 20),

            // Financial Stat Cards
            LayoutBuilder(builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 700;
              final w = isCompact ? (constraints.maxWidth - 16) / 2 : (constraints.maxWidth - 48) / 4;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildFinanceCard(
                    width: w,
                    title: 'Solde disponible',
                    amount: _formatCurrencyFCFA(availableBalance),
                    subtitle: 'Prêt pour retrait instantané',
                    icon: Icons.account_balance_wallet_rounded,
                    color: AppTheme.emeraldGreenDark,
                    bgColor: AppTheme.paleMint,
                  ),
                  _buildFinanceCard(
                    width: w,
                    title: 'Total généré',
                    amount: _formatCurrencyFCFA(totalRevenue),
                    subtitle: '$totalStudents inscription${totalStudents > 1 ? 's' : ''} payante${totalStudents > 1 ? 's' : ''}',
                    icon: Icons.trending_up_rounded,
                    color: const Color(0xFF0284C7),
                    bgColor: const Color(0xFFE0F2FE),
                  ),
                  _buildFinanceCard(
                    width: w,
                    title: 'Total retiré',
                    amount: _formatCurrencyFCFA(totalWithdrawn),
                    subtitle: '${completedWithdrawals.length} virement${completedWithdrawals.length > 1 ? 's' : ''} complété${completedWithdrawals.length > 1 ? 's' : ''}',
                    icon: Icons.check_circle_rounded,
                    color: const Color(0xFF16A34A),
                    bgColor: const Color(0xFFDCFCE7),
                  ),
                  _buildFinanceCard(
                    width: w,
                    title: 'Commission plateforme',
                    amount: '10%',
                    subtitle: '90% reversés au formateur',
                    icon: Icons.pie_chart_rounded,
                    color: const Color(0xFFD97706),
                    bgColor: const Color(0xFFFEF3C7),
                  ),
                ],
              );
            }),
            const SizedBox(height: 28),

        // Intech API Configuration Badge
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_user_rounded, color: AppTheme.emeraldGreenDark, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Intégration Intech API SN Activée', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.ink)),
                    const SizedBox(height: 2),
                    Text(
                      'Services connectés : WAVE_SN_API_CASH_OUT • ORANGE_SN_API_CASH_OUT (Virements mobiles directs)',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('En ligne', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Transactions History
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Historique des demandes de retrait', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.ink)),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 20, color: AppTheme.emeraldGreenDark),
              tooltip: 'Actualiser',
              onPressed: _loadWithdrawals,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: _withdrawalTransactions.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('Aucun retrait pour le moment.')),
                )
              : Column(
                  children: _withdrawalTransactions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final tx = entry.value;
                    final isWave = tx.providerName.contains('Wave');

                    return Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: isWave ? const Color(0xFF1E40AF).withValues(alpha: 0.1) : const Color(0xFFEA580C).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.phone_android_rounded,
                              color: isWave ? const Color(0xFF1E40AF) : const Color(0xFFEA580C),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(tx.providerName, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.ink)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: tx.status == 'SUCCESS' ? Colors.green[100] : Colors.amber[100],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  tx.status == 'SUCCESS' ? 'SUCCÈS' : 'EN COURS',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: tx.status == 'SUCCESS' ? Colors.green[800] : Colors.amber[900],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            'Numéro : +${tx.phone} • Réf : ${tx.externalTransactionId}',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '- ${tx.amount} FCFA',
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.ink),
                              ),
                              Text(
                                '${tx.createdAt.day.toString().padLeft(2, '0')}/${tx.createdAt.month.toString().padLeft(2, '0')}/${tx.createdAt.year}',
                                style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                        if (index < _withdrawalTransactions.length - 1) const Divider(height: 1),
                      ],
                    );
                  }).toList(),
                ),
        ),
      ],
    );
      },
    );
  }

  Widget _buildFinanceCard({
    required double width,
    required String title,
    required String amount,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(amount, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.ink)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  void _showWithdrawalModal(UserModel user) {
    WithdrawalMethod selectedMethod = WithdrawalMethod.wave;
    final phoneCtrl = TextEditingController(text: '77 123 45 67');
    final amountCtrl = TextEditingController(text: '50000');
    bool isProcessing = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.emeraldGreenDark),
              const SizedBox(width: 8),
              Text('Demande de retrait d\'argent', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16)),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.paleMint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Solde disponible actuel :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        Text('$_teacherBalance FCFA', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.emeraldGreenDark)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Sélectionnez votre opérateur mobile :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(() => selectedMethod = WithdrawalMethod.wave),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selectedMethod == WithdrawalMethod.wave ? const Color(0xFF1E40AF).withValues(alpha: 0.1) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedMethod == WithdrawalMethod.wave ? const Color(0xFF1E40AF) : AppTheme.cardBorder,
                                width: selectedMethod == WithdrawalMethod.wave ? 2 : 1,
                              ),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.waves_rounded, color: Color(0xFF1E40AF)),
                                SizedBox(height: 4),
                                Text('Wave Sénégal', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF1E40AF))),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(() => selectedMethod = WithdrawalMethod.orangeMoney),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selectedMethod == WithdrawalMethod.orangeMoney ? const Color(0xFFEA580C).withValues(alpha: 0.1) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedMethod == WithdrawalMethod.orangeMoney ? const Color(0xFFEA580C) : AppTheme.cardBorder,
                                width: selectedMethod == WithdrawalMethod.orangeMoney ? 2 : 1,
                              ),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.phone_android_rounded, color: Color(0xFFEA580C)),
                                SizedBox(height: 4),
                                Text('Orange Money', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFFEA580C))),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Numéro de téléphone du compte *',
                      prefixText: '+221 ',
                      hintText: '77 123 45 67',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Montant à retirer (FCFA) *',
                      hintText: '50000',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [25000, 50000, 100000].map((amt) {
                      return ActionChip(
                        label: Text('$amt FCFA', style: const TextStyle(fontSize: 11)),
                        onPressed: () => setModalState(() => amountCtrl.text = '$amt'),
                      );
                    }).toList(),
                  ),
                  if (isProcessing) ...[
                    const SizedBox(height: 16),
                    const Center(child: CircularProgressIndicator(color: AppTheme.emeraldGreen)),
                  ],
                ],
              ),
            ),
          ),
        ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emeraldGreenDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isProcessing ? null : () async {
                final amt = int.tryParse(amountCtrl.text.trim()) ?? 0;
                if (amt <= 0 || amt > _teacherBalance) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez saisir un montant valide inférieur ou égal à votre solde.'), backgroundColor: Colors.red),
                  );
                  return;
                }

                setModalState(() => isProcessing = true);
                final tx = await _intechService.requestWithdrawal(
                  teacherId: user.uid,
                  teacherName: user.displayName,
                  amount: amt,
                  phone: phoneCtrl.text.trim(),
                  method: selectedMethod,
                );

                setState(() {
                  _teacherBalance = (_teacherBalance - amt).clamp(0, 999999999);
                  _withdrawalTransactions.insert(0, tx);
                });

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Virement de $amt FCFA initié avec succès via ${tx.providerName} ! Réf: ${tx.externalTransactionId}'),
                      backgroundColor: AppTheme.emeraldGreen,
                    ),
                  );
                }
              },
              child: const Text('Confirmer le retrait'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar({bool isMobileDrawer = false}) {
    final menuItems = [
      {'title': 'Tableau de bord', 'icon': Icons.dashboard_rounded},
      {'title': 'Mes formations', 'icon': Icons.auto_stories_rounded},
      {'title': 'Étudiants Inscrits', 'icon': Icons.how_to_reg_rounded},
      {'title': 'Classes (100 Étudiants)', 'icon': Icons.groups_rounded},
      {'title': 'Emploi du temps', 'icon': Icons.calendar_month_rounded},
      {'title': 'Devoirs envoyés', 'icon': Icons.assignment_turned_in_rounded},
      {'title': 'Sessions Live', 'icon': Icons.sensors_rounded},
      {'title': 'Revenus & Retraits', 'icon': Icons.account_balance_wallet_rounded},
      {'title': 'Messages', 'icon': Icons.chat_bubble_outline_rounded},
      {'title': 'Règlement & Documents', 'icon': Icons.menu_book_rounded},
      {'title': 'Paramètres', 'icon': Icons.settings_outlined},
    ];

    return Container(
      color: const Color(0xFF07251F),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => Navigator.pushNamed(context, '/'),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 38,
                    height: 38,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Club des Formateurs', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('ESPACE FORMATEUR', style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.mintAccent, letterSpacing: 0.8)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Expanded(
            child: ListView(
              children: menuItems.map((item) {
                final isSelected = _activeMenu == item['title'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: InkWell(
                    onTap: () {
                      setState(() => _activeMenu = item['title'] as String);
                      if (isMobileDrawer) Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(item['icon'] as IconData, size: 18, color: isSelected ? AppTheme.mintAccent : const Color(0xFF94B5AD)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item['title'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? Colors.white : const Color(0xFFC7DFD9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // User Profile Pill & Logout
          // Bouton bascule vers l'Espace Apprenant
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () async {
                final cur = _authService.currentUser;
                if (cur != null) {
                  await _authService.updateUserProfile(role: 'student');
                }
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/dashboard/apprenant');
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: AppTheme.emeraldGreenDark.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.mintAccent.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.swap_horiz_rounded, color: AppTheme.mintAccent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Passer à l\'Espace Apprenant',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.mintAccent, size: 10),
                  ],
                ),
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppTheme.paleMint,
                  radius: 16,
                  child: Icon(Icons.person, size: 18, color: AppTheme.emeraldGreenDark),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _authService.currentUser?.displayName ?? 'Cheikh Diop',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text('Formateur', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.mintAccent)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.white60, size: 18),
                  onPressed: () {
                    _authService.signOut();
                    Navigator.pushReplacementNamed(context, '/');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 11. TEACHER LIVE STUDIO DIALOG (LIVEKIT CLOUD)
// ==========================================
class TeacherLiveStudioDialog extends StatefulWidget {
  final LiveSessionModel live;
  final UserModel currentUser;
  final VoidCallback onEndLive;

  const TeacherLiveStudioDialog({
    super.key,
    required this.live,
    required this.currentUser,
    required this.onEndLive,
  });

  @override
  State<TeacherLiveStudioDialog> createState() => _TeacherLiveStudioDialogState();
}

class _TeacherLiveStudioDialogState extends State<TeacherLiveStudioDialog> {
  final ChatService _chatService = ChatService();
  final LiveKitService _liveKitService = LiveKitService();
  final TextEditingController _msgCtrl = TextEditingController();

  bool _isMicMuted = false;
  bool _isCamOff = false;
  bool _isScreenSharing = false;
  String _currentPhase = 'interactive'; // 'interactive' (1h) | 'exercises' (30min)
  int _secondsRemaining = 3600; // 60 min countdown
  Timer? _countdownTimer;
  int _tabIndex = 0; // 0: Chat, 1: Participants
  final List<String> _raisedHands = ['Moussa Ndiaye (Demande de parole)', 'Aminata Diallo'];
  String _liveKitToken = '';

  @override
  void initState() {
    super.initState();
    _loadLiveKitToken();
    _startTimer();
  }

  Future<void> _loadLiveKitToken() async {
    final res = await _liveKitService.fetchLiveKitToken(widget.live.roomName);
    if (mounted && res != null && res['token'] != null) {
      setState(() {
        _liveKitToken = res['token'].toString();
      });
    }
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        if (_currentPhase == 'interactive') {
          _switchPhase('exercises');
        } else {
          timer.cancel();
        }
      }
    });
  }

  void _switchPhase(String nextPhase) {
    setState(() {
      _currentPhase = nextPhase;
      _secondsRemaining = nextPhase == 'exercises' ? 1800 : 3600;
    });
    LiveSessionService().switchToExercisesPhase(widget.live.id);
  }

  String _formatTimer(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _msgCtrl.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    await _chatService.sendMessage(
      conversationId: widget.live.id,
      senderId: widget.currentUser.uid,
      senderName: '${widget.currentUser.displayName} (Formateur)',
      senderRole: 'formateur',
      content: text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 1000,
        height: 680,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(
          children: [
            // Top Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: const Color(0xFF0F172A),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('STUDIO LIVE', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.0)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.live.title,
                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Row(
                      children: [
                        Icon(Icons.cloud_done_rounded, color: Color(0xFF10B981), size: 14),
                        SizedBox(width: 6),
                        Text('LiveKit Cloud: wss://anour-rv83fs3g.livekit.cloud', style: TextStyle(color: Colors.white70, fontSize: 10)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    tooltip: 'Fermer la vue (le direct reste actif)',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content Area
            Expanded(
              child: Row(
                children: [
                  // Left: Video Broadcaster Canvas & Stream controls
                  Expanded(
                    flex: 65,
                    child: Container(
                      color: const Color(0xFF020617),
                      child: Column(
                        children: [
                          // Phase Switcher & Countdown Bar
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: const BoxDecoration(
                              color: Color(0xFF1E293B),
                              border: Border(bottom: BorderSide(color: Color(0xFF334155))),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _currentPhase == 'interactive' ? Icons.record_voice_over_rounded : Icons.code_rounded,
                                  color: _currentPhase == 'interactive' ? AppTheme.emeraldGreen : const Color(0xFF38BDF8),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _currentPhase == 'interactive' ? 'Phase 1 : Cours interactif (Théorie & Échanges)' : 'Phase 2 : Pratique & Exercices guidés',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                                      ),
                                      Text(
                                        'Temps restant : ${_formatTimer(_secondsRemaining)} (sur ${_currentPhase == 'interactive' ? '60min' : '30min'})',
                                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _currentPhase == 'interactive' ? const Color(0xFF0284C7) : AppTheme.emeraldGreenDark,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () => _switchPhase(_currentPhase == 'interactive' ? 'exercises' : 'interactive'),
                                  child: Text(
                                    _currentPhase == 'interactive' ? 'Passer aux exercices (30min) ➔' : 'Revenir au cours interactif ➔',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Live Screen Canvas (WebRTC Camera / Screen Share + LiveKit Cloud)
                          Expanded(
                            child: LiveKitWebRtcView(
                              isCamOn: !_isCamOff,
                              isMicOn: !_isMicMuted,
                              isScreenSharing: _isScreenSharing,
                              roomName: widget.live.roomName,
                              jwtToken: _liveKitToken,
                              fallback: Stack(
                                alignment: Alignment.center,
                                children: [
                                  if (_isScreenSharing)
                                    Container(
                                      margin: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E293B),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: const Color(0xFF38BDF8), width: 2),
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.screen_share_rounded, color: Color(0xFF38BDF8), size: 54),
                                            const SizedBox(height: 12),
                                            const Text('Écran partagé avec les apprenants', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                                            const SizedBox(height: 6),
                                            Text('Diapositives / IDE en direct • LiveKit Cloud Screen Track', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    )
                                  else if (_isCamOff)
                                    Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          CircleAvatar(
                                            radius: 46,
                                            backgroundColor: const Color(0xFF334155),
                                            child: Text(
                                              widget.currentUser.displayName.isNotEmpty ? widget.currentUser.displayName[0].toUpperCase() : 'F',
                                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white),
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          const Text('Caméra désactivée', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    )
                                  else
                                    Container(
                                      width: double.infinity,
                                      height: double.infinity,
                                      color: const Color(0xFF0F172A),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              CircleAvatar(
                                                radius: 48,
                                                backgroundImage: widget.currentUser.photoUrl != null && widget.currentUser.photoUrl!.isNotEmpty
                                                    ? NetworkImage(widget.currentUser.photoUrl!) as ImageProvider
                                                    : const AssetImage('assets/images/student-man.jpeg'),
                                              ),
                                              const SizedBox(height: 14),
                                              Text(
                                                widget.currentUser.displayName,
                                                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                                              ),
                                              const SizedBox(height: 6),
                                              const Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.mic, color: AppTheme.emeraldGreen, size: 16),
                                                  SizedBox(width: 4),
                                                  Text('Micro actif • Diffusion HD 1080p', style: TextStyle(color: AppTheme.emeraldGreen, fontSize: 11, fontWeight: FontWeight.w700)),
                                                ],
                                              ),
                                            ],
                                          ),
                                          Positioned(
                                            top: 16,
                                            left: 16,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                                              child: Text('Room: ${widget.live.roomName}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),

                          // Controls Toolbar
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            color: const Color(0xFF0F172A),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Mic
                                IconButton.filledTonal(
                                  style: IconButton.styleFrom(
                                    backgroundColor: _isMicMuted ? Colors.red[800] : const Color(0xFF1E293B),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.all(12),
                                  ),
                                  icon: Icon(_isMicMuted ? Icons.mic_off_rounded : Icons.mic_rounded),
                                  tooltip: _isMicMuted ? 'Activer le micro' : 'Couper le micro',
                                  onPressed: () => setState(() => _isMicMuted = !_isMicMuted),
                                ),
                                const SizedBox(width: 14),

                                // Cam
                                IconButton.filledTonal(
                                  style: IconButton.styleFrom(
                                    backgroundColor: _isCamOff ? Colors.red[800] : const Color(0xFF1E293B),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.all(12),
                                  ),
                                  icon: Icon(_isCamOff ? Icons.videocam_off_rounded : Icons.videocam_rounded),
                                  tooltip: _isCamOff ? 'Activer la caméra' : 'Couper la caméra',
                                  onPressed: () => setState(() => _isCamOff = !_isCamOff),
                                ),
                                const SizedBox(width: 14),

                                // Screen Share
                                IconButton.filledTonal(
                                  style: IconButton.styleFrom(
                                    backgroundColor: _isScreenSharing ? const Color(0xFF0284C7) : const Color(0xFF1E293B),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.all(12),
                                  ),
                                  icon: Icon(_isScreenSharing ? Icons.stop_screen_share_rounded : Icons.screen_share_rounded),
                                  tooltip: _isScreenSharing ? 'Arrêter le partage' : 'Partager l\'écran',
                                  onPressed: () => setState(() => _isScreenSharing = !_isScreenSharing),
                                ),
                                const SizedBox(width: 24),

                                // End session button
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFDC2626),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.call_end_rounded, size: 18),
                                  label: const Text('Terminer le direct & Replay', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                                  onPressed: widget.onEndLive,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Right: Live Chat & Participants tabs
                  Expanded(
                    flex: 35,
                    child: Container(
                      color: const Color(0xFFF8FAFC),
                      child: Column(
                        children: [
                          // Tab selector
                          Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              border: Border(bottom: BorderSide(color: AppTheme.cardBorder)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => setState(() => _tabIndex = 0),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: _tabIndex == 0 ? AppTheme.emeraldGreenDark : Colors.transparent,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Chat en direct',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: _tabIndex == 0 ? FontWeight.w800 : FontWeight.w600,
                                            color: _tabIndex == 0 ? AppTheme.emeraldGreenDark : AppTheme.textMuted,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => setState(() => _tabIndex = 1),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: _tabIndex == 1 ? AppTheme.emeraldGreenDark : Colors.transparent,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Participants (${_raisedHands.length + 3})',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: _tabIndex == 1 ? FontWeight.w800 : FontWeight.w600,
                                            color: _tabIndex == 1 ? AppTheme.emeraldGreenDark : AppTheme.textMuted,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Tab Content
                          Expanded(
                            child: _tabIndex == 0
                                ? Column(
                                    children: [
                                      Expanded(
                                        child: StreamBuilder<List<MessageModel>>(
                                          stream: _chatService.getMessagesStream(widget.live.id),
                                          builder: (context, snapshot) {
                                            final msgs = snapshot.data ?? [];
                                            if (msgs.isEmpty) {
                                              return Center(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.textLight, size: 36),
                                                    const SizedBox(height: 8),
                                                    Text('Le chat est ouvert !', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
                                                    const Text('Vos messages apparaîtront en direct.', style: TextStyle(fontSize: 11, color: AppTheme.textLight)),
                                                  ],
                                                ),
                                              );
                                            }

                                            return ListView.builder(
                                              padding: const EdgeInsets.all(12),
                                              itemCount: msgs.length,
                                              itemBuilder: (context, index) {
                                                final m = msgs[index];
                                                final isMe = m.senderId == widget.currentUser.uid;
                                                return Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                    decoration: BoxDecoration(
                                                      color: isMe ? AppTheme.paleMint : Colors.white,
                                                      borderRadius: BorderRadius.circular(10),
                                                      border: Border.all(color: AppTheme.cardBorder),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(m.senderName, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: isMe ? AppTheme.emeraldGreenDark : AppTheme.ink)),
                                                        const SizedBox(height: 2),
                                                        Text(m.content, style: const TextStyle(fontSize: 12, color: AppTheme.ink)),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        color: Colors.white,
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                controller: _msgCtrl,
                                                decoration: const InputDecoration(
                                                  hintText: 'Envoyer aux apprenants...',
                                                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                                ),
                                                onSubmitted: (_) => _sendMessage(),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(Icons.send_rounded, color: AppTheme.emeraldGreenDark),
                                              onPressed: _sendMessage,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                : ListView(
                                    padding: const EdgeInsets.all(16),
                                    children: [
                                      Text('Mains levées (${_raisedHands.length})', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.ink)),
                                      const SizedBox(height: 8),
                                      ..._raisedHands.map((student) => Container(
                                            margin: const EdgeInsets.only(bottom: 8),
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.amber[50],
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: Colors.amber.shade200),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.front_hand_rounded, color: Color(0xFFD97706), size: 18),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(student, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                                                ),
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldGreenDark, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                                                  onPressed: () {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text('Parole accordée à $student ! Son micro est actif.'), backgroundColor: AppTheme.emeraldGreen),
                                                    );
                                                  },
                                                  child: const Text('Accorder', style: TextStyle(fontSize: 10)),
                                                ),
                                              ],
                                            ),
                                          )),
                                      const SizedBox(height: 16),
                                      Text('Autres apprenants connectés', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.ink)),
                                      const SizedBox(height: 8),
                                      ...['Ousmane Ba', 'Fatou Diop', 'Cheikh Fall'].map((s) => ListTile(
                                            dense: true,
                                            contentPadding: EdgeInsets.zero,
                                            leading: CircleAvatar(
                                              radius: 14,
                                              backgroundColor: AppTheme.paleMint,
                                              child: Text(s[0], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.emeraldGreenDark)),
                                            ),
                                            title: Text(s, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                            trailing: const Icon(Icons.circle, size: 8, color: Colors.green),
                                          )),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

