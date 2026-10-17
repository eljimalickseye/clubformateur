import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/course_model.dart';
import '../models/trainer_model.dart';
import '../models/user_model.dart';
import '../services/appointment_service.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/course_service.dart';
import '../services/corrector_service.dart';
import '../services/live_session_service.dart';
import '../services/trainer_review_service.dart';
import '../services/trainer_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_flow_dialog.dart';
import '../widgets/footer_section.dart';
import '../widgets/navbar.dart';
import 'package:intl/intl.dart';
import '../models/live_session_model.dart';
import '../widgets/teacher_registration_flow_dialog.dart';

class TrainerProfileScreen extends StatefulWidget {
  final TrainerModel? trainer;

  const TrainerProfileScreen({super.key, this.trainer});

  @override
  State<TrainerProfileScreen> createState() => _TrainerProfileScreenState();
}

class _TrainerProfileScreenState extends State<TrainerProfileScreen> {
  late TrainerModel _trainer;
  int _activeTabIndex = 0;
  bool _isFavorite = false;
  List<CourseModel> _trainerCourses = [];
  bool _isLoadingCourses = true;
  List<TrainerReviewItem> _reviewsList = [];
  StreamSubscription? _reviewsSub;

  @override
  void initState() {
    super.initState();
    _trainer = widget.trainer ?? TrainerModel(
      id: '',
      name: 'Formateur',
      role: 'Formateur Expert',
      rating: 5.0,
      coursesCount: 0,
      studentsCount: 0,
      image: '',
      bio: 'Formateur sur Club des Formateurs',
      quote: 'Transmettre le savoir et former l\'excellence.',
      headline: 'Formateur Expert',
      presentation: 'Formateur sur Club des Formateurs',
      experienceYears: '5+ ans',
      skills: const ['Pédagogie', 'Accompagnement'],
      availableFor: const ['Formations en direct', 'Mentorat individuel'],
    );
    _initTrainer();
  }

  Future<void> _initTrainer() async {
    if (widget.trainer != null) {
      _trainer = widget.trainer!;
      await _fetchTrainerFromFirestore();
    } else {
      final realTrainers = await TrainerService().getExpertTrainers();
      if (realTrainers.isNotEmpty && mounted) {
        setState(() {
          _trainer = realTrainers.first;
        });
        await _fetchTrainerFromFirestore();
      }
    }
    _checkIfCurrentTeacher();
    _loadTrainerCourses();
    _listenToReviews();
  }

  Future<void> _fetchTrainerFromFirestore() async {
    if (_trainer.id.isNotEmpty) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(_trainer.id).get();
        if (doc.exists && doc.data() != null && mounted) {
          final t = TrainerModel.fromMap(doc.data()!, doc.id);
          setState(() {
            _trainer = t;
          });
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _reviewsSub?.cancel();
    super.dispose();
  }

  void _checkIfCurrentTeacher() {
    final user = AuthService().currentUser;
    if (user != null &&
        (user.uid == _trainer.id ||
            user.displayName.trim().toLowerCase() == _trainer.name.trim().toLowerCase())) {
      final spec = (user.speciality != null && user.speciality!.isNotEmpty)
          ? user.speciality!
          : (user.expertises.isNotEmpty ? user.expertises.join(', ') : _trainer.role);
      setState(() {
        _trainer = TrainerModel(
          id: user.uid,
          name: user.displayName,
          role: spec,
          rating: _trainer.rating,
          reviewsCount: _trainer.reviewsCount,
          coursesCount: _trainerCourses.length,
          studentsCount: _realStudentsCount,
          image: (user.photoUrl != null && user.photoUrl!.isNotEmpty)
              ? user.photoUrl!
              : _trainer.image,
          isVerified: true,
          tags: user.skills.isNotEmpty
              ? user.skills
              : (user.expertises.isNotEmpty ? user.expertises : _trainer.tags),
          bio: (user.bio != null && user.bio!.isNotEmpty) ? user.bio! : _trainer.bio,
          quote: (user.quote != null && user.quote!.isNotEmpty)
              ? user.quote!
              : _trainer.quote,
          headline: spec,
          presentation: (user.bio != null && user.bio!.isNotEmpty)
              ? user.bio!
              : _trainer.presentation,
          experienceYears: (user.experienceYears != null && user.experienceYears!.isNotEmpty)
              ? user.experienceYears!
              : _trainer.experienceYears,
          satisfactionRate: _trainer.satisfactionRate,
          skills: user.skills.isNotEmpty ? user.skills : _trainer.skills,
          experiences: _trainer.experiences,
          certifications: _trainer.certifications,
          availableFor: _trainer.availableFor,
          reviews: _trainer.reviews,
          weeklySchedule: user.weeklySchedule,
        );
      });
    }
  }

  void _listenToReviews() {
    _reviewsSub = TrainerReviewService()
        .getTeacherReviewsStream(_trainer.id)
        .listen((reviews) {
      if (mounted) {
        setState(() {
          _reviewsList = reviews;
        });
      }
    });
  }

  int get _reviewsCount =>
      _reviewsList.isNotEmpty ? _reviewsList.length : _trainer.reviewsCount;

  double get _averageRating {
    if (_reviewsList.isEmpty) return _trainer.rating;
    final sum = _reviewsList.fold<double>(0.0, (acc, r) => acc + r.rating);
    return sum / _reviewsList.length;
  }

  String get _satisfactionRateDisplay {
    if (_reviewsList.isEmpty) return _trainer.satisfactionRate;
    final pct = ((_averageRating / 5.0) * 100).round();
    return '$pct%';
  }

  int get _realStudentsCount =>
      _trainerCourses.fold<int>(0, (acc, c) => acc + c.studentsCount);

  Future<void> _loadTrainerCourses() async {
    final allCourses = await CourseService().getAllCourses();
    final filtered = allCourses.where((c) {
      final matchesId = c.teacherId == _trainer.id;
      final matchesName = c.trainerName.trim().isNotEmpty &&
          _trainer.name.trim().isNotEmpty &&
          c.trainerName.toLowerCase().contains(_trainer.name.toLowerCase().split(' ').first);
      return matchesId || matchesName;
    }).toList();

    if (mounted) {
      setState(() {
        _trainerCourses = filtered;
        _isLoadingCourses = false;
      });
    }
  }

  void _showContactModal() {
    final messageCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.email_outlined, color: AppTheme.emeraldGreenDark),
            const SizedBox(width: 8),
            Text(
              'Contacter ${_trainer.name}',
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: subjectCtrl,
              decoration: const InputDecoration(
                labelText: 'Objet de votre demande',
                hintText: 'Mentorat, question sur une formation...',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Votre message',
                hintText: 'Expliquez vos besoins au formateur...',
              ),
            ),
          ],
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
            ),
            onPressed: () async {
              final text = messageCtrl.text.trim();
              if (text.isEmpty) return;
              final user = AuthService().currentUser ?? UserModel.demoStudent;
              final targetId = 'teacher_${_trainer.name.toLowerCase().replaceAll(' ', '_')}';
              final convId = await ChatService().getOrCreateConversation(
                currentUserId: user.uid,
                currentUserName: user.displayName,
                currentUserPhoto: user.photoUrl ?? '',
                targetUserId: targetId,
                targetUserName: _trainer.name,
                targetUserPhoto: _trainer.image,
                courseName: _trainer.role,
              );
              final content = subjectCtrl.text.trim().isNotEmpty
                  ? '[${subjectCtrl.text.trim()}] $text'
                  : text;
              await ChatService().sendMessage(
                conversationId: convId,
                senderId: user.uid,
                senderName: user.displayName,
                senderRole: user.role,
                content: content,
              );
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Message envoyé à ${_trainer.name} ! La discussion est ouverte dans votre messagerie.')),
                      ],
                    ),
                    backgroundColor: AppTheme.emeraldGreenDark,
                    behavior: SnackBarBehavior.floating,
                    action: SnackBarAction(
                      label: 'Voir discussion',
                      textColor: Colors.white,
                      onPressed: () {
                        Navigator.pushNamed(context, '/dashboard/apprenant');
                      },
                    ),
                  ),
                );
              }
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  void _showAppointmentModal({String? initialSlot, String? initialDay}) {
    final user = AuthService().currentUser ?? UserModel.demoStudent;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String selectedSlot = initialSlot ?? '14:00 - 15:00';
    String selectedType = 'Mentorat individuel (45 min)';
    final notesCtrl = TextEditingController();
    bool isBooking = false;

    final availableSlots = [
      '09:00 - 10:00',
      '10:30 - 11:30',
      '14:00 - 15:00',
      '15:30 - 16:30',
      '17:00 - 18:00',
      '18:30 - 19:30',
    ];

    final sessionTypes = [
      'Mentorat individuel (45 min)',
      'Questions / Réponses cours (30 min)',
      'Revue de code & projet (60 min)',
      'Orientation & Insertion (45 min)',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.paleMint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calendar_month_rounded, color: AppTheme.emeraldGreenDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prendre un rendez-vous',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.ink,
                      ),
                    ),
                    Text(
                      'Avec ${_trainer.name} • ${_trainer.role}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Choix de la date
                  Text(
                    '1. Date du rendez-vous :',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                          label: Text(
                            '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.emeraldGreenDark,
                            side: const BorderSide(color: AppTheme.emeraldGreen),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 90)),
                            );
                            if (picked != null) {
                              setModalState(() => selectedDate = picked);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => setModalState(
                            () => selectedDate = DateTime.now().add(const Duration(days: 1))),
                        child: Chip(
                          label: const Text('Demain', style: TextStyle(fontSize: 11)),
                          backgroundColor:
                              selectedDate.difference(DateTime.now()).inDays == 1
                                  ? AppTheme.paleMint
                                  : Colors.grey.shade100,
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => setModalState(
                            () => selectedDate = DateTime.now().add(const Duration(days: 2))),
                        child: Chip(
                          label: const Text('Dans 2 j', style: TextStyle(fontSize: 11)),
                          backgroundColor:
                              selectedDate.difference(DateTime.now()).inDays == 2
                                  ? AppTheme.paleMint
                                  : Colors.grey.shade100,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 2. Créneau horaire
                  Text(
                    '2. Créneaux horaires disponibles :',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableSlots.map((slot) {
                      final isSelected = selectedSlot == slot;
                      return ChoiceChip(
                        label: Text(
                          slot,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) setModalState(() => selectedSlot = slot);
                        },
                        selectedColor: AppTheme.emeraldGreen,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.ink,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // 3. Type de session
                  Text(
                    '3. Format de la séance :',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: sessionTypes
                        .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12))))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedType = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // 4. Notes / Sujet
                  Text(
                    '4. Vos attentes ou questions (optionnel) :',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Expliquez brièvement le sujet pour préparer la session...',
                      hintStyle: const TextStyle(fontSize: 11),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Info apprenant
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.textMuted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Réservation au nom de ${user.displayName} (${user.email})',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.ink),
                          ),
                        ),
                      ],
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
              child: const Text('Annuler'),
            ),
            ElevatedButton.icon(
              icon: isBooking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_rounded, size: 16),
              label: const Text('Confirmer le rendez-vous'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emeraldGreenDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isBooking
                  ? null
                  : () async {
                      setModalState(() => isBooking = true);
                      await AppointmentService().bookAppointment(
                        teacherId: _trainer.id,
                        teacherName: _trainer.name,
                        teacherPhoto: _trainer.image,
                        studentId: user.uid,
                        studentName: user.displayName,
                        studentEmail: user.email,
                        studentPhone: user.phoneNumber,
                        date: selectedDate,
                        timeSlot: selectedSlot,
                        sessionType: selectedType,
                        notes: notesCtrl.text.trim(),
                      );

                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        _showAppointmentSuccessDialog(
                          date: selectedDate,
                          slot: selectedSlot,
                          type: selectedType,
                        );
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  void _showAppointmentSuccessDialog({
    required DateTime date,
    required String slot,
    required String type,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppTheme.paleMint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppTheme.emeraldGreenDark, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                'Rendez-vous confirmé !',
                style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.ink),
              ),
              const SizedBox(height: 8),
              Text(
                'Votre session avec ${_trainer.name} a été enregistrée avec succès.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• Date : ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Créneau : $slot',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Format : $type',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Fermer'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emeraldGreenDark,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pushNamed(context, '/dashboard/apprenant');
                      },
                      child: const Text('Mes RDV'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddReviewDialog() {
    final user = AuthService().currentUser;
    if (user == null) {
      AuthFlowDialog.show(context, initialStep: AuthFlowStep.login);
      return;
    }

    double selectedRating = 5.0;
    final commentCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFFBBF24)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Laisser un avis sur ${_trainer.name}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Attribuez une note globale :',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.ink),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starVal = index + 1.0;
                  final isFilled = starVal <= selectedRating;
                  return IconButton(
                    iconSize: 32,
                    icon: Icon(
                      isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                      color: const Color(0xFFFBBF24),
                    ),
                    onPressed: () {
                      setModalState(() => selectedRating = starVal);
                    },
                  );
                }),
              ),
              Center(
                child: Text(
                  selectedRating == 5.0
                      ? 'Excellente expérience (5/5)'
                      : (selectedRating >= 4.0 ? 'Très satisfaisant (4/5)' : 'Correct (3/5)'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.emeraldGreenDark,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Votre commentaire d\'évaluation',
                  hintText: 'Partagez votre avis sur la pédagogie, le suivi et la clarté des explications...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
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
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final comment = commentCtrl.text.trim();
                      if (comment.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Veuillez écrire un commentaire.')),
                        );
                        return;
                      }

                      setModalState(() => isSubmitting = true);
                      await TrainerReviewService().addReview(
                        teacherId: _trainer.id,
                        authorId: user.uid,
                        authorName: user.displayName,
                        authorAvatar: user.photoUrl ?? '',
                        rating: selectedRating,
                        comment: comment,
                      );

                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Merci ! Votre avis a été publié et le taux de satisfaction a été mis à jour.'),
                            backgroundColor: AppTheme.emeraldGreen,
                          ),
                        );
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Publier mon avis'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 992;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Navbar(
              activeRoute: '/formateurs',
              onLoginTap: () => AuthFlowDialog.show(context, initialStep: AuthFlowStep.login),
              onRegisterTap: () => AuthFlowDialog.show(context, initialStep: AuthFlowStep.roleChoice),
            ),

            // Top Hero Banner (Forest Green #0A2B24)
            _buildHeroBanner(context, isDesktop),

            // Tabs Bar
            _buildTabsBar(isDesktop),

            // Main Content Body (Left column + Right Sidebar)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 48 : 16,
                vertical: 28,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1240),
                  child: isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 7, child: _buildMainColumnContent()),
                            const SizedBox(width: 28),
                            Expanded(flex: 3, child: _buildSidebarContent()),
                          ],
                        )
                      : Column(
                          children: [
                            _buildSidebarActionButtons(isDesktop),
                            const SizedBox(height: 20),
                            _buildMainColumnContent(),
                            const SizedBox(height: 28),
                            _buildSidebarContent(skipActionButtons: true),
                          ],
                        ),
                ),
              ),
            ),

            const SizedBox(height: 40),
            const FooterSection(),
          ],
        ),
      ),
    );
  }

  // --- Hero Banner (Maquette 1) ---
  Widget _buildHeroBanner(BuildContext context, bool isDesktop) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF092B24), Color(0xFF041C17)],
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : 20,
        vertical: isDesktop ? 36 : 24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            children: [
              // Top Actions: Partager & Ajouter aux favoris
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildBannerTopButton(
                    icon: Icons.share_rounded,
                    label: 'Partager',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lien du profil copié dans le presse-papier !'),
                          backgroundColor: AppTheme.emeraldGreen,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  _buildBannerTopButton(
                    icon: _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    label: 'Ajouter aux favoris',
                    iconColor: _isFavorite ? Colors.redAccent : Colors.white,
                    onTap: () {
                      setState(() => _isFavorite = !_isFavorite);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_isFavorite ? 'Ajouté à vos favoris' : 'Retiré des favoris'),
                          backgroundColor: AppTheme.emeraldGreen,
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Main Trainer Hero row
              isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildTrainerAvatar(),
                        const SizedBox(width: 24),
                        Expanded(child: _buildTrainerHeroDetails()),
                        const SizedBox(width: 24),
                        _buildHeroQuoteBox(),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildTrainerAvatar(size: 90),
                            const SizedBox(width: 16),
                            Expanded(child: _buildTrainerHeroDetails()),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildHeroQuoteBox(),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrainerAvatar({double size = 120}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            width: size,
            height: size * 1.15,
            child: _buildSafeTrainerImage(size, size * 1.15),
          ),
        ),
        // En ligne badge
        Positioned(
          bottom: -6,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'En ligne',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF065F46),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSafeTrainerImage(double width, double height) {
    final img = _trainer.image.trim();
    if (img.startsWith('http://') || img.startsWith('https://')) {
      return Image.network(
        img,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildInitialsAvatar(width, height),
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return Container(
            color: AppTheme.emeraldGreenDark,
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
            ),
          );
        },
      );
    } else if (img.startsWith('assets/') && !img.contains('dummy')) {
      return Image.asset(
        img,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildInitialsAvatar(width, height),
      );
    }
    return _buildInitialsAvatar(width, height);
  }

  Widget _buildInitialsAvatar(double width, double height) {
    final initials = _trainer.name.isNotEmpty
        ? _trainer.name
            .trim()
            .split(' ')
            .where((w) => w.isNotEmpty)
            .map((w) => w[0])
            .take(2)
            .join()
            .toUpperCase()
        : 'CF';

    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.emeraldGreenDark, Color(0xFF042F2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 6),
            Text(
              initials,
              style: GoogleFonts.plusJakartaSans(
                fontSize: width > 90 ? 22 : 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainerHeroDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                _trainer.name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            if (_trainer.isVerified) ...[
              const SizedBox(width: 6),
              const Icon(Icons.verified_rounded, color: Color(0xFF38BDF8), size: 20),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _trainer.role,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.mintAccent,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _trainer.headline,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: const Color(0xFFD1E8E2),
          ),
        ),
        const SizedBox(height: 8),

        // Niveau Enseigné (Licence 3)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.school_rounded, color: Color(0xFF34D399), size: 14),
              const SizedBox(width: 6),
              Text(
                'Niveau enseigné : ${_trainer.levels.isNotEmpty ? _trainer.levels.join(", ") : "Licence 3"}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Stats: Note, Apprenants, Formations (Dynamiques & Réelles)
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 16),
                const SizedBox(width: 4),
                Text(
                  '${_averageRating.toStringAsFixed(1)} ($_reviewsCount avis)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people_alt_rounded, color: AppTheme.mintAccent, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$_realStudentsCount apprenants',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_stories_rounded, color: AppTheme.mintAccent, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${_trainerCourses.length} formations',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Tags
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _trainer.tags.map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Text(
                tag,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildHeroQuoteBox() {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('“', style: TextStyle(fontSize: 28, color: AppTheme.mintAccent, height: 1)),
          Text(
            _trainer.quote,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.laptop_chromebook_rounded, color: AppTheme.mintAccent, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Former • Inspirer • Construire demain !',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.mintAccent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBannerTopButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Onglets / Tabs ---
  Widget _buildTabsBar(bool isDesktop) {
    final tabs = [
      'À propos',
      'Formations (${_trainerCourses.length})',
      'Sessions Live',
      'Avis ($_reviewsCount)',
      'Horaires & RDV',
      'Certifications',
    ];

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.cardBorder)),
      ),
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(tabs.length, (index) {
                final isActive = _activeTabIndex == index;
                return InkWell(
                  onTap: () => setState(() => _activeTabIndex = index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isActive ? AppTheme.emeraldGreen : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                    child: Text(
                      tabs[index],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive ? AppTheme.emeraldGreenDark : AppTheme.textMuted,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  // --- Left Main Column Content ---
  Widget _buildMainColumnContent() {
    if (_activeTabIndex == 1) {
      return _buildCoursesTabContent();
    }
    if (_activeTabIndex == 2) {
      return _buildSessionsLiveTabContent();
    }
    if (_activeTabIndex == 3) {
      return _buildReviewsTabContent();
    }
    if (_activeTabIndex == 4) {
      return _buildScheduleTabContent();
    }
    if (_activeTabIndex == 5) {
      return _buildCertificationsTabContent();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Présentation
        _buildSectionCard(
          icon: Icons.person_outline_rounded,
          title: 'Présentation',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _trainer.presentation,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.ink,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),

              // 4 Stat Cards (Dynamiques & Réelles - Pas de fausses valeurs)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildMetricBadge(
                    icon: Icons.workspace_premium_rounded,
                    value: _trainer.experienceYears.trim().isNotEmpty
                        ? (_trainer.experienceYears.contains('an')
                            ? _trainer.experienceYears
                            : '${_trainer.experienceYears} ans')
                        : 'Certifié',
                    label: _trainer.experienceYears.trim().isNotEmpty
                        ? "d'expérience"
                        : "Formateur certifié",
                  ),
                  _buildMetricBadge(
                    icon: Icons.groups_rounded,
                    value: '$_realStudentsCount',
                    label: 'apprenants formés',
                  ),
                  _buildMetricBadge(
                    icon: Icons.auto_stories_rounded,
                    value: '${_trainerCourses.length}',
                    label: 'formations en ligne',
                  ),
                  _buildMetricBadge(
                    icon: Icons.thumb_up_alt_rounded,
                    value: _satisfactionRateDisplay,
                    label: 'taux de satisfaction',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 2. Mes domaines d'expertise
        _buildSectionCard(
          icon: Icons.settings_suggest_rounded,
          title: "Mes domaines d'expertise",
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _trainer.skills.map((skill) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  skill,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.ink,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),

        // 3. Mon parcours
        _buildSectionCard(
          icon: Icons.school_outlined,
          title: 'Mon parcours',
          child: Column(
            children: _trainer.experiences.map((exp) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppTheme.emeraldGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exp.period,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.emeraldGreenDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            exp.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.ink,
                            ),
                          ),
                          Text(
                            exp.organization,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            exp.description,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),

        // 4. Certifications
        _buildCertificationsCard(),
        const SizedBox(height: 24),

        // 5. Horaires & Disponibilités (Demandé par l'utilisateur: "on doit voir ses horaires en bas")
        _buildScheduleSection(),
      ],
    );
  }

  Widget _buildCertificationsCard() {
    return _buildSectionCard(
      icon: Icons.military_tech_rounded,
      title: 'Certifications & Accréditations',
      child: Column(
        children: _trainer.certifications.isNotEmpty
            ? _trainer.certifications.map((cert) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.verified_user_rounded, color: AppTheme.emeraldGreen, size: 24),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cert.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.ink,
                              ),
                            ),
                            Text(
                              '${cert.issuer} • ${cert.year}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList()
            : [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded, color: AppTheme.emeraldGreen, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Formateur Officiel Vérifié - Club des Formateurs',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.ink,
                              ),
                            ),
                            Text(
                              'Identité et compétences pédagogiques validées par notre équipe.',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
      ),
    );
  }

  Widget _buildScheduleTabContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Horaires de disponibilité de ${_trainer.name}',
          style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.ink),
        ),
        const SizedBox(height: 8),
        Text(
          'Consultez les créneaux ouverts et réservez une session individuelle en direct avec le formateur.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 20),
        _buildScheduleSection(),
      ],
    );
  }

  Widget _buildCertificationsTabContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Certifications & Diplômes de ${_trainer.name}',
          style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.ink),
        ),
        const SizedBox(height: 16),
        _buildCertificationsCard(),
      ],
    );
  }

  // --- 5. Section Horaires en bas du profil (Demandé par l'utilisateur) ---
  Widget _buildScheduleSection() {
    return _buildSectionCard(
      icon: Icons.access_time_filled_rounded,
      title: 'Emploi du Temps Hebdomadaire & Horaires de Disponibilité',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Créneaux réguliers ouverts aux réservations directes',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.emeraldGreenDark,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAppointmentModal(),
                icon: const Icon(Icons.event_available_rounded, size: 16),
                label: const Text('Prendre RDV'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emeraldGreenDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  textStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildScheduleDaysGrid(),
        ],
      ),
    );
  }

  Widget _buildScheduleDaysGrid() {
    final days = [
      {
        'day': 'Lundi',
        'badge': 'Disponible',
        'slots': ['09h00 - 12h30', '14h00 - 18h00'],
        'desc': 'Cours en direct & Mentorat',
      },
      {
        'day': 'Mardi',
        'badge': 'Disponible',
        'slots': ['09h00 - 12h30', '14h00 - 18h00'],
        'desc': 'Sessions pratiques & Q/R',
      },
      {
        'day': 'Mercredi',
        'badge': 'Disponible',
        'slots': ['10h00 - 13h00', '15h00 - 19h00'],
        'desc': 'Suivi de projets & Correction',
      },
      {
        'day': 'Jeudi',
        'badge': 'Disponible',
        'slots': ['09h00 - 12h30', '14h00 - 18h00'],
        'desc': 'Mentorat individuel',
      },
      {
        'day': 'Vendredi',
        'badge': 'Disponible',
        'slots': ['09h00 - 12h30', '15h00 - 18h30'],
        'desc': 'Ateliers & Bilan hebdomadaire',
      },
      {
        'day': 'Samedi',
        'badge': 'Disponible',
        'slots': ['10h00 - 14h00'],
        'desc': 'Permanence & Conseils carrières',
      },
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth >= 600;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: days.map((d) {
          final dayName = d['day'] as String;
          final slots = d['slots'] as List<String>;
          final desc = d['desc'] as String;

          return Container(
            width: isWide ? (constraints.maxWidth - 24) / 2 : constraints.maxWidth,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dayName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.ink,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.paleMint,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Disponible',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.emeraldGreenDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(desc, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: slots.map((s) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.emeraldGreen.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time_rounded, size: 12, color: AppTheme.emeraldGreenDark),
                          const SizedBox(width: 4),
                          Text(
                            s,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.ink,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () => _showAppointmentModal(initialSlot: slots.first, initialDay: dayName),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Réserver ce créneau',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.emeraldGreenDark,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded, size: 12, color: AppTheme.emeraldGreenDark),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    });
  }

  // --- Right Sidebar Content ---
  Widget _buildSidebarContent({bool skipActionButtons = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!skipActionButtons) ...[
          _buildSidebarActionButtons(true),
          const SizedBox(height: 20),
        ],

        // Correcteur attitré
        FutureBuilder<UserModel?>(
          future: CorrectorService().getLinkedCorrector(_trainer.id),
          builder: (context, snapshot) {
            final corrector = snapshot.data;
            if (corrector == null) return const SizedBox.shrink();

            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Correcteur attitré', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.ink)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          corrector.photoUrl != null && corrector.photoUrl!.isNotEmpty ? corrector.photoUrl! : 'https://via.placeholder.com/50',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 50, height: 50, color: AppTheme.paleMint,
                            child: const Icon(Icons.person, color: AppTheme.emeraldGreenDark),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(corrector.displayName.isNotEmpty ? corrector.displayName : 'Correcteur', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.ink)),
                                const SizedBox(width: 4),
                                const Icon(Icons.verified_rounded, size: 16, color: AppTheme.emeraldGreen),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text('Correcteur Certifié', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.emeraldGreenDark)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),

        // Disponible pour
        Container(
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
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppTheme.emeraldGreen, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Disponible pour',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ..._trainer.availableFor.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_rounded, color: AppTheme.emeraldGreen, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item,
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.ink),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Statistiques
        Container(
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
                children: [
                  const Icon(Icons.bar_chart_rounded, color: AppTheme.emeraldGreenDark, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Statistiques',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildStatItem(Icons.auto_stories_rounded, '${_trainerCourses.length}', 'Formations')),
                      Expanded(child: _buildStatItem(Icons.people_alt_rounded, '$_realStudentsCount', 'Apprenants')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildStatItem(Icons.star_rounded, '$_reviewsCount', 'Avis')),
                      Expanded(child: _buildStatItem(Icons.verified_rounded, _satisfactionRateDisplay, 'Satisfaction')),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Avis des apprenants
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.rate_review_rounded, color: AppTheme.emeraldGreen, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Avis des apprenants',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => setState(() => _activeTabIndex = 2),
                    child: Text(
                      'Voir tous les avis →',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.emeraldGreenDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Single Review card
              if (_reviewsList.isNotEmpty)
                _buildRealReviewItem(_reviewsList.first)
              else if (_trainer.reviews.isNotEmpty)
                _buildReviewItem(_trainer.reviews.first)
              else
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Aucun avis pour l\'instant.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _showAddReviewDialog,
                        icon: const Icon(Icons.rate_review_outlined, size: 14),
                        label: const Text('Donner le 1er avis', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _showAddReviewDialog,
                  icon: const Icon(Icons.edit_note_rounded, size: 16),
                  label: const Text('Donner mon avis sur ce formateur'),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.emeraldGreenDark),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarActionButtons(bool isDesktop) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              TeacherRegistrationFlowDialog.show(context, teacher: _trainer);
            },
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
            label: Text(
              'S\'inscrire auprès de ce professeur',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emeraldGreenDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showContactModal,
            icon: const Icon(Icons.email_outlined, size: 16),
            label: const Text('Contacter le formateur'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.emeraldGreenDark,
              side: const BorderSide(color: AppTheme.emeraldGreen, width: 1.2),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showAppointmentModal,
            icon: const Icon(Icons.calendar_today_rounded, size: 16),
            label: const Text('Prendre un rendez-vous'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.emeraldGreenDark,
              side: const BorderSide(color: AppTheme.emeraldGreen, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Social icons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialIcon(Icons.link_rounded),
            const SizedBox(width: 8),
            _buildSocialIcon(Icons.alternate_email_rounded),
            const SizedBox(width: 8),
            _buildSocialIcon(Icons.video_library_rounded),
            const SizedBox(width: 8),
            _buildSocialIcon(Icons.camera_alt_rounded),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(icon, color: AppTheme.ink, size: 18),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.emeraldGreenDark, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppTheme.ink,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textMuted),
        ),
      ],
    );
  }

  Widget _buildReviewItem(TrainerReview review) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  width: 34,
                  height: 34,
                  child: review.avatar.startsWith('http')
                      ? Image.network(
                          review.avatar,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildAvatarInitials(review.author),
                        )
                      : (review.avatar.startsWith('assets/') && !review.avatar.contains('dummy')
                          ? Image.asset(
                              review.avatar,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildAvatarInitials(review.author),
                            )
                          : _buildAvatarInitials(review.author)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.author,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                          color: const Color(0xFFFBBF24),
                          size: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '“${review.comment}”',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: AppTheme.ink,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            review.date,
            style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildRealReviewItem(TrainerReviewItem review) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 38,
                  height: 38,
                  color: AppTheme.paleMint,
                  child: review.authorAvatar.startsWith('http')
                      ? Image.network(
                          review.authorAvatar,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildAvatarInitials(review.authorName),
                        )
                      : (review.authorAvatar.startsWith('assets/') && !review.authorAvatar.contains('dummy')
                          ? Image.asset(
                              review.authorAvatar,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildAvatarInitials(review.authorName),
                            )
                          : _buildAvatarInitials(review.authorName)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.authorName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                          color: const Color(0xFFFBBF24),
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${review.createdAt.day.toString().padLeft(2, '0')}/${review.createdAt.month.toString().padLeft(2, '0')}/${review.createdAt.year}',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '“${review.comment}”',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppTheme.ink,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarInitials(String name) {
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').where((w) => w.isNotEmpty).map((w) => w[0]).take(2).join().toUpperCase()
        : 'AP';
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppTheme.emeraldGreenDark,
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.paleMint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppTheme.emeraldGreenDark, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildMetricBadge({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.emeraldGreen, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesTabContent() {
    if (_isLoadingCourses) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_trainerCourses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.school_outlined, size: 48, color: AppTheme.textMuted),
              const SizedBox(height: 12),
              Text(
                'Aucune formation créée pour le moment',
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.ink),
              ),
              const SizedBox(height: 6),
              Text(
                'Ce formateur n\'a pas encore publié de cours. Revenez bientôt ou prenez rendez-vous directement.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _showAppointmentModal(),
                icon: const Icon(Icons.calendar_today_rounded, size: 16),
                label: const Text('Prendre un rendez-vous direct'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldGreenDark),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Formations dispensées par ${_trainer.name}',
          style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        ..._trainerCourses.map((course) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: course.image.startsWith('http')
                      ? Image.network(course.image, width: 80, height: 60, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.menu_book, size: 40))
                      : Image.asset(course.image, width: 80, height: 60, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.menu_book, size: 40)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${course.rating} ★ (${course.reviewsCount} avis) • ${course.duration}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/course', arguments: course);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldGreen),
                  child: const Text("S'inscrire"),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildReviewsTabContent() {
    final hasRealReviews = _reviewsList.isNotEmpty;
    final hasDefaultReviews = _trainer.reviews.isNotEmpty;

    return Column(
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
                    'Tous les avis pour ${_trainer.name}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.ink),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '${_averageRating.toStringAsFixed(1)} / 5',
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.ink),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• $_reviewsCount avis • Satisfaction : $_satisfactionRateDisplay',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _showAddReviewDialog,
              icon: const Icon(Icons.rate_review_rounded, size: 16),
              label: const Text('Donner mon avis'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emeraldGreenDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        if (hasRealReviews)
          ..._reviewsList.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildRealReviewItem(r),
              ))
        else if (hasDefaultReviews)
          ..._trainer.reviews.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildReviewItem(r),
              ))
        else
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.rate_review_outlined, size: 48, color: AppTheme.textMuted),
                  const SizedBox(height: 12),
                  Text(
                    'Aucun avis pour l\'instant',
                    style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.ink),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Avez-vous suivi une session avec ${_trainer.name} ? Soyez le premier à partager votre expérience !',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _showAddReviewDialog,
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldGreen),
                    child: const Text('Écrire le premier avis'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSessionsLiveTabContent() {
    return StreamBuilder<List<LiveSessionModel>>(
      stream: LiveSessionService().getLiveSessionsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allSessions = snapshot.data ?? [];
        final trainerSessions = allSessions.where((s) => s.teacherId == _trainer.id).toList();

        if (trainerSessions.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.videocam_outlined, size: 48, color: AppTheme.textMuted),
                  const SizedBox(height: 12),
                  Text(
                    'Aucune session live',
                    style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.ink),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ce formateur n\'a pas de sessions live prévues.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: trainerSessions.map((session) {
            final isLive = session.isLive;
            final dateStr = DateFormat('dd MMM yyyy à HH:mm', 'fr_FR').format(session.scheduledAt);

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isLive ? const Color(0xFFFEE2E2) : AppTheme.paleMint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.videocam_rounded,
                      color: isLive ? const Color(0xFFEF4444) : AppTheme.emeraldGreenDark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(session.title, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700)),
                            const SizedBox(width: 10),
                            if (isLive)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('EN DIRECT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isLive ? 'En cours...' : 'Prévu le : $dateStr',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (isLive && session.liveKitRoomUrl != null) {
                        // Normally you'd use url_launcher, but since we're in Flutter web maybe pushNamed
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLive ? const Color(0xFFEF4444) : AppTheme.emeraldGreenDark,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(isLive ? 'Rejoindre' : 'Rappel'),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
