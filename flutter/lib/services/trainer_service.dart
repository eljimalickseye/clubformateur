import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/course_model.dart';
import '../models/trainer_model.dart';
import 'auth_service.dart';
import 'course_service.dart';
import 'firebase_config.dart';

class TrainerWithCourses {
  final TrainerModel trainer;
  final List<CourseModel> courses;

  TrainerWithCourses({
    required this.trainer,
    required this.courses,
  });

  int get coursesCount => courses.length;
}

class TrainerService {
  static final TrainerService _instance = TrainerService._internal();
  factory TrainerService() => _instance;
  TrainerService._internal();

  FirebaseFirestore? get _firestore => FirebaseConfig.firestore;

  /// Récupère la liste des formateurs réellement inscrits
  Future<List<TrainerModel>> getExpertTrainers() async {
    final list = await getRealTrainersWithCourses(onlyWithCourses: false);
    return list.map((e) => e.trainer).toList();
  }

  /// Récupère les professeurs réellement inscrits et leurs cours réels créés
  Future<List<TrainerWithCourses>> getRealTrainersWithCourses({bool onlyWithCourses = false}) async {
    final Map<String, TrainerModel> teachersMap = {};

    // 1. Utilisateur connecté si rôle professeur
    final currentUser = AuthService().currentUser;
    if (currentUser != null && (currentUser.role == 'teacher' || currentUser.role == 'formateur')) {
      final spec = (currentUser.speciality != null && currentUser.speciality!.isNotEmpty)
          ? (currentUser.speciality ?? 'Professeur & Formateur')
          : (currentUser.expertises.isNotEmpty ? currentUser.expertises.join(', ') : 'Professeur & Formateur');
      teachersMap[currentUser.uid] = TrainerModel(
        id: currentUser.uid,
        name: currentUser.displayName,
        role: spec,
        rating: 5.0,
        coursesCount: 0,
        image: currentUser.photoUrl ?? '',
        bio: currentUser.bio ?? 'Professeur inscrit sur Club des Formateurs',
        quote: currentUser.quote ?? 'Transmettre le savoir et former l\'excellence.',
        headline: spec,
        presentation: currentUser.bio ?? '',
        experienceYears: currentUser.experienceYears ?? '',
        skills: currentUser.skills.isNotEmpty ? currentUser.skills : currentUser.expertises,
        weeklySchedule: currentUser.weeklySchedule,
      );
    }

    // 2. Professeurs enregistrés dans Firestore
    try {
      final db = _firestore;
      if (db != null) {
        final snapshot = await db
            .collection('users')
            .where('role', whereIn: ['teacher', 'formateur'])
            .limit(50)
            .get()
            .timeout(const Duration(seconds: 4));

        for (final doc in snapshot.docs) {
          try {
            final data = doc.data();
            teachersMap[doc.id] = TrainerModel.fromMap(data, doc.id);
          } catch (docErr) {
            debugPrint('Error parsing doc ${doc.id}: $docErr');
          }
        }
      }
    } catch (e) {
      debugPrint('Firestore fetch real teachers error: $e');
    }

    // 3. Récupération des cours créés dynamiquement
    final allCourses = await CourseService().getPopularCourses();

    // Si des cours ont été créés avec un teacherId ou trainerName qui n'est pas encore dans teachersMap, on l'ajoute
    for (final course in allCourses) {
      final tid = course.teacherId.isNotEmpty ? course.teacherId : course.trainerName;
      if (tid.isNotEmpty && !teachersMap.containsKey(tid)) {
        teachersMap[tid] = TrainerModel(
          id: tid,
          name: course.trainerName.isNotEmpty ? course.trainerName : 'Professeur',
          role: course.trainerRole.isNotEmpty ? course.trainerRole : 'Enseignant certifié',
          rating: course.rating > 0 ? course.rating : 5.0,
          coursesCount: 1,
          image: course.trainerAvatar ?? '',
          bio: 'Professeur sur Club des Formateurs',
        );
      }
    }

    // 4. Association de chaque professeur avec ses cours réels
    final List<TrainerWithCourses> result = [];
    for (final entry in teachersMap.entries) {
      final teacherId = entry.key;
      final teacher = entry.value;

      final teacherCourses = allCourses.where((c) {
        if (c.teacherId.isNotEmpty && c.teacherId == teacherId) return true;
        if (c.teacherId.isEmpty &&
            c.trainerName.trim().isNotEmpty &&
            teacher.name.trim().isNotEmpty &&
            c.trainerName.trim().toLowerCase() == teacher.name.trim().toLowerCase()) {
          return true;
        }
        return false;
      }).toList();

      if (onlyWithCourses && teacherCourses.isEmpty) {
        continue;
      }

      String? effectiveVideo = teacher.presentationVideoUrl;
      if (effectiveVideo == null || effectiveVideo.isEmpty) {
        for (final c in teacherCourses) {
          if (c.presentationVideoUrl != null && c.presentationVideoUrl!.isNotEmpty) {
            effectiveVideo = c.presentationVideoUrl;
            break;
          }
        }
      }

      final updatedTrainer = TrainerModel(
        id: teacher.id,
        name: teacher.name,
        role: teacher.role,
        rating: teacher.rating,
        reviewsCount: teacher.reviewsCount,
        coursesCount: teacherCourses.length,
        studentsCount: teacherCourses.fold<int>(0, (acc, c) => acc + c.studentsCount),
        image: teacher.image,
        isVerified: teacher.isVerified,
        tags: teacher.tags,
        bio: teacher.bio,
        quote: teacher.quote,
        headline: teacher.headline,
        presentation: teacher.presentation,
        experienceYears: teacher.experienceYears,
        satisfactionRate: teacher.satisfactionRate,
        skills: teacher.skills,
        experiences: teacher.experiences,
        certifications: teacher.certifications,
        availableFor: teacher.availableFor,
        reviews: teacher.reviews,
        weeklySchedule: teacher.weeklySchedule,
        presentationVideoUrl: effectiveVideo,
      );

      result.add(TrainerWithCourses(
        trainer: updatedTrainer,
        courses: teacherCourses,
      ));
    }

    final deduplicated = _deduplicateTrainers(result);
    deduplicated.sort((a, b) => b.courses.length.compareTo(a.courses.length));
    return deduplicated;
  }

  /// Retourne un stream des professeurs inscrits avec leurs cours (mise à jour temps réel)
  Stream<List<TrainerWithCourses>> getExpertTrainersStream() {
    final db = _firestore;
    if (db == null) return Stream.value([]);

    try {
      return db
          .collection('users')
          .where('role', whereIn: ['teacher', 'formateur'])
          .snapshots()
          .handleError((err) {
            debugPrint('Trainer snapshots stream notice (safe fallback): $err');
          })
          .asyncMap((snapshot) async {
            final Map<String, TrainerModel> teachersMap = {};
            for (final doc in snapshot.docs) {
              try {
                final data = doc.data();
                teachersMap[doc.id] = TrainerModel.fromMap(data, doc.id);
              } catch (docErr) {
                debugPrint('Error parsing stream teacher ${doc.id}: $docErr');
              }
            }

            // Fetch current courses to match with teachers
            final allCourses = await CourseService().getPopularCourses();
            final List<TrainerWithCourses> result = [];

            for (final entry in teachersMap.entries) {
              final teacherId = entry.key;
              final teacher = entry.value;

              final teacherCourses = allCourses.where((c) {
                if (c.teacherId.isNotEmpty && c.teacherId == teacherId) return true;
                if (c.teacherId.isEmpty &&
                    c.trainerName.trim().isNotEmpty &&
                    teacher.name.trim().isNotEmpty &&
                    c.trainerName.trim().toLowerCase() == teacher.name.trim().toLowerCase()) {
                  return true;
                }
                return false;
              }).toList();

              String? effectiveVideo = teacher.presentationVideoUrl;
              if (effectiveVideo == null || effectiveVideo.isEmpty) {
                for (final c in teacherCourses) {
                  if (c.presentationVideoUrl != null && c.presentationVideoUrl!.isNotEmpty) {
                    effectiveVideo = c.presentationVideoUrl;
                    break;
                  }
                }
              }

              final updatedTrainer = TrainerModel(
                id: teacher.id,
                name: teacher.name,
                role: teacher.role,
                rating: teacher.rating,
                reviewsCount: teacher.reviewsCount,
                coursesCount: teacherCourses.length,
                studentsCount: teacherCourses.fold<int>(0, (acc, c) => acc + c.studentsCount),
                image: teacher.image,
                isVerified: teacher.isVerified,
                tags: teacher.tags,
                bio: teacher.bio,
                quote: teacher.quote,
                headline: teacher.headline,
                presentation: teacher.presentation,
                experienceYears: teacher.experienceYears,
                satisfactionRate: teacher.satisfactionRate,
                skills: teacher.skills,
                experiences: teacher.experiences,
                certifications: teacher.certifications,
                availableFor: teacher.availableFor,
                reviews: teacher.reviews,
                weeklySchedule: teacher.weeklySchedule,
                presentationVideoUrl: effectiveVideo,
              );

              result.add(TrainerWithCourses(
                trainer: updatedTrainer,
                courses: teacherCourses,
              ));
            }

            final deduplicated = _deduplicateTrainers(result);
            deduplicated.sort((a, b) => b.courses.length.compareTo(a.courses.length));
            return deduplicated;
          })
          .handleError((err) {
            debugPrint('Trainer asyncMap error (graceful fallback): $err');
            return <TrainerWithCourses>[];
          });
    } catch (e) {
      debugPrint('getExpertTrainersStream initialization error: $e');
      return Stream.value([]);
    }
  }

  /// Évite les doublons d'affichage pour les professeurs enregistrés sous le même nom
  static List<TrainerWithCourses> _deduplicateTrainers(List<TrainerWithCourses> list) {
    final Map<String, TrainerWithCourses> uniqueByName = {};
    for (final item in list) {
      final key = item.trainer.name.trim().toLowerCase();
      if (key.isEmpty) continue;
      if (!uniqueByName.containsKey(key)) {
        uniqueByName[key] = item;
      } else {
        final existing = uniqueByName[key];
        if (existing != null) {
          // Préférer l'entrée avec des cours réels créés, ou avec une vidéo/spécialité
          if (item.courses.length > existing.courses.length ||
              (item.courses.isNotEmpty && existing.courses.isEmpty) ||
              (item.trainer.presentationVideoUrl != null && existing.trainer.presentationVideoUrl == null) ||
              (existing.trainer.role == 'teacher' && item.trainer.role != 'teacher' && item.trainer.role.isNotEmpty)) {
            uniqueByName[key] = item;
          }
        }
      }
    }
    return uniqueByName.values.toList();
  }
}
