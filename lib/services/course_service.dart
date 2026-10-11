import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course_model.dart';
import 'firebase_config.dart';
import 'laravel_api_service.dart';

class CourseService {
  static final CourseService _instance = CourseService._internal();
  factory CourseService() => _instance;
  CourseService._internal() {
    _initLocalCache();
  }

  static const String _coursesCacheKey = 'olivia_courses_cache_v5_prod';
  static const String _lessonsCachePrefix = 'olivia_course_lessons_v5_';

  final LaravelApiService _api = LaravelApiService();
  final StreamController<List<CourseModel>> _coursesController =
      StreamController<List<CourseModel>>.broadcast();
  final Map<String, StreamController<List<CourseLesson>>> _lessonControllers = {};

  static const Set<String> _demoCourseIds = {
    'react',
    'marketing',
    'gestion',
    'figma',
    'confiance',
    'anglais',
    'excel',
    'cyber',
  };

  static bool _isLegacyDummy(String id) {
    final lower = id.toLowerCase();
    return lower.startsWith('course-arabe') ||
        lower.startsWith('course-fiqh') ||
        lower.startsWith('course-tajweed') ||
        lower.startsWith('demo_') ||
        _demoCourseIds.contains(lower);
  }

  List<CourseModel> _cachedCourses = [];
  final Map<String, List<CourseLesson>> _cachedLessons = {};
  bool _initialized = false;

  FirebaseFirestore? get _firestore => FirebaseConfig.firestore;

  Future<void> _initLocalCache() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      // Purge old mock cache versions
      unawaited(prefs.remove('olivia_courses_cache_v1'));
      unawaited(prefs.remove('olivia_courses_cache_v2'));
      unawaited(prefs.remove('olivia_courses_cache_v3'));
      unawaited(prefs.remove('olivia_courses_cache_v4'));

      final raw = prefs.getString(_coursesCacheKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        final loaded = decoded
            .map((item) {
              final map = Map<String, dynamic>.from(item as Map);
              return CourseModel.fromMap(map, map['id']?.toString() ?? '');
            })
            .where((c) => !_isLegacyDummy(c.id))
            .toList();
        if (loaded.isNotEmpty) {
          _cachedCourses = loaded;
          _coursesController.add(_cachedCourses);
        }
      }
    } catch (e) {
      debugPrint('CourseService local cache init error: $e');
    }

    // Background sync with Firestore & Laravel API
    _syncFromRemote();
  }

  Future<void> _syncFromRemote() async {
    // 1. Try Firestore (Real-time cloud database canonical source of truth)
    try {
      final db = _firestore;
      if (db != null) {
        final snapshot = await db
            .collection('courses')
            .limit(50)
            .get()
            .timeout(const Duration(seconds: 4));
        if (snapshot.docs.isNotEmpty) {
          final List<CourseModel> fsList = [];
          for (final doc in snapshot.docs) {
            try {
              final c = CourseModel.fromMap(doc.data(), doc.id);
              if (!_isLegacyDummy(c.id)) {
                fsList.add(c);
              }
            } catch (courseErr) {
              debugPrint('Error parsing course ${doc.id}: $courseErr');
            }
          }
          _cachedCourses = fsList;
          await _saveLocalCache();
          _coursesController.add(_cachedCourses);
        } else {
          // If Firestore is empty (no real courses created yet), platform must display 0 courses!
          _cachedCourses = [];
          await _saveLocalCache();
          _coursesController.add(_cachedCourses);
        }
      }
    } catch (e) {
      debugPrint('Firestore sync courses fallback: $e');
    }

    // 2. Try Laravel API (/api/v1/courses)
    try {
      final res = await _api.get('/courses');
      if (res != null && res['courses'] is List) {
        final apiList = (res['courses'] as List)
            .map((item) {
              final map = Map<String, dynamic>.from(item as Map);
              return CourseModel.fromMap(map, map['id']?.toString() ?? '');
            })
            .where((c) => !_isLegacyDummy(c.id))
            .toList();
        if (apiList.isNotEmpty) {
          _cachedCourses = _mergeCourses(apiList, _cachedCourses);
          await _saveLocalCache();
          _coursesController.add(_cachedCourses);
        }
      }
    } catch (_) {}
  }

  List<CourseModel> _mergeCourses(List<CourseModel> primary, List<CourseModel> secondary) {
    final map = <String, CourseModel>{};
    for (final c in secondary) {
      if (!_isLegacyDummy(c.id)) map[c.id] = c;
    }
    for (final c in primary) {
      if (!_isLegacyDummy(c.id)) map[c.id] = c;
    }
    return map.values.toList();
  }

  Future<void> _saveLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_cachedCourses.map((c) {
        final m = c.toMap();
        m['id'] = c.id;
        return m;
      }).toList());
      await prefs.setString(_coursesCacheKey, encoded);
    } catch (e) {
      debugPrint('CourseService saveLocalCache error: $e');
    }
  }

  /// Get popular / published courses
  Future<List<CourseModel>> getPopularCourses() async {
    await _initLocalCache();
    final published = _cachedCourses.where((c) => c.isPublished).toList();
    return published.isNotEmpty ? published : _cachedCourses;
  }

  /// Stream of all courses (Reactive across local cache, Laravel API & Firestore)
  Stream<List<CourseModel>> getAllCoursesStream() async* {
    await _initLocalCache();
    yield _cachedCourses;
    await for (final updated in _coursesController.stream) {
      yield updated;
    }
  }

  /// Get teacher courses stream (Reactive across local cache, Laravel API & Firestore)
  Stream<List<CourseModel>> getTeacherCoursesStream(String teacherId) async* {
    await _initLocalCache();

    List<CourseModel> filterForTeacher(List<CourseModel> all) {
      return all.where((c) => c.teacherId == teacherId).toList();
    }

    yield filterForTeacher(_cachedCourses);

    await for (final updated in _coursesController.stream) {
      yield filterForTeacher(updated);
    }
  }

  /// Get teacher courses as a Future
  Future<List<CourseModel>> getTeacherCourses(String teacherId) async {
    await _initLocalCache();
    return _cachedCourses.where((c) => c.teacherId == teacherId).toList();
  }

  /// Create a new course (Saves to Local Cache, Laravel API, and Firestore)
  Future<String> createCourse(CourseModel course) async {
    await _initLocalCache();

    final newId = course.id.isNotEmpty && !course.id.startsWith('temp_')
        ? course.id
        : 'course_${DateTime.now().millisecondsSinceEpoch}';
    final effectiveTeacherId =
        course.teacherId.isNotEmpty ? course.teacherId : 'teacher_${DateTime.now().millisecondsSinceEpoch}';

    final newCourse = CourseModel(
      id: newId,
      title: course.title,
      category: course.category,
      rating: course.rating,
      duration: course.duration,
      lessonsCount: course.lessonsCount,
      trainerName: course.trainerName,
      trainerAvatar: course.trainerAvatar,
      trainerRole: course.trainerRole,
      price: course.price,
      originalPrice: course.originalPrice,
      discountPercent: course.discountPercent,
      image: course.image,
      thumbnailUrl: course.thumbnailUrl ?? course.image,
      presentationVideoUrl: course.presentationVideoUrl,
      badge: course.badge,
      description: course.description,
      studentsCount: course.studentsCount,
      publicationStatus: course.publicationStatus,
      isPublished: course.isPublished,
      teacherId: effectiveTeacherId,
      modules: course.modules,
      replays: course.replays,
      flatLessons: course.flatLessons,
    );

    // 1. Update local cache & broadcast immediately
    _cachedCourses = [
      newCourse,
      ..._cachedCourses.where((c) => c.id != newId),
    ];
    await _saveLocalCache();
    _coursesController.add(_cachedCourses);

    // 2. Sync with Laravel API (/api/v1/courses)
    final payload = newCourse.toMap()..['id'] = newId;
    try {
      await _api.post('/courses', payload);
    } catch (e) {
      debugPrint('Sync createCourse to Laravel API: $e');
    }

    // 3. Sync with Firestore
    try {
      final db = _firestore;
      if (db != null) {
        await db
            .collection('courses')
            .doc(newId)
            .set(newCourse.toMap())
            .timeout(const Duration(seconds: 4));
      }
    } catch (e) {
      debugPrint('Firestore createCourse fallback (persisted locally & via API): $e');
    }

    return newId;
  }

  /// Update existing course
  Future<void> updateCourse(CourseModel course) async {
    await _initLocalCache();

    _cachedCourses = _cachedCourses.map((c) => c.id == course.id ? course : c).toList();
    if (!_cachedCourses.any((c) => c.id == course.id)) {
      _cachedCourses.insert(0, course);
    }
    await _saveLocalCache();
    _coursesController.add(_cachedCourses);

    // Sync with Laravel API
    final payload = course.toMap()..['id'] = course.id;
    try {
      await _api.put('/courses/${course.id}', payload);
    } catch (e) {
      debugPrint('Sync updateCourse to Laravel API: $e');
    }

    // Sync with Firestore
    try {
      final db = _firestore;
      if (db != null) {
        await db
            .collection('courses')
            .doc(course.id)
            .set(course.toMap(), SetOptions(merge: true))
            .timeout(const Duration(seconds: 4));
      }
    } catch (e) {
      debugPrint('Firestore updateCourse fallback: $e');
    }
  }

  /// Increment student enrollment count for a course dynamically
  Future<void> incrementStudentCount(String courseId) async {
    await _initLocalCache();
    _cachedCourses = _cachedCourses.map((c) {
      if (c.id == courseId) {
        return c.copyWith(studentsCount: c.studentsCount + 1);
      }
      return c;
    }).toList();
    await _saveLocalCache();
    _coursesController.add(_cachedCourses);
  }

  /// Toggle publish status
  Future<void> togglePublishStatus(String courseId, bool currentStatus) async {
    await _initLocalCache();
    final newStatus = !currentStatus;

    _cachedCourses = _cachedCourses.map<CourseModel>((c) {
      if (c.id == courseId) {
        return c.copyWith(
          isPublished: newStatus,
          publicationStatus: newStatus ? 'published' : 'draft',
        );
      }
      return c;
    }).toList();

    await _saveLocalCache();
    _coursesController.add(_cachedCourses);

    unawaited(_api.patch('/courses/$courseId/toggle-publish'));

    try {
      final db = _firestore;
      if (db != null) {
        await db.collection('courses').doc(courseId).update({
          'isPublished': newStatus,
          'status': newStatus ? 'Publiée' : 'Brouillon',
        }).timeout(const Duration(seconds: 4));
      }
    } catch (e) {
      debugPrint('Firestore togglePublishStatus fallback: $e');
    }
  }

  /// Delete a course
  Future<void> deleteCourse(String courseId) async {
    await _initLocalCache();

    _cachedCourses = _cachedCourses.where((c) => c.id != courseId).toList();
    await _saveLocalCache();
    _coursesController.add(_cachedCourses);

    unawaited(_api.delete('/courses/$courseId'));

    try {
      final db = _firestore;
      if (db != null) {
        await db
            .collection('courses')
            .doc(courseId)
            .delete()
            .timeout(const Duration(seconds: 4));
      }
    } catch (e) {
      debugPrint('Firestore deleteCourse fallback: $e');
    }
  }

  /// Add a video lesson to course
  Future<void> addLessonToCourse({
    required String courseId,
    required CourseLesson lesson,
  }) async {
    await _initLocalCache();

    final currentLessons = await _getLocalLessons(courseId);
    final updatedLessons = [...currentLessons, lesson];
    _cachedLessons[courseId] = updatedLessons;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_lessonsCachePrefix$courseId',
        jsonEncode(updatedLessons.map((l) => l.toMap()..['id'] = l.id).toList()),
      );
    } catch (_) {}

    _lessonControllers[courseId]?.add(updatedLessons);

    // Update lesson count on course
    _cachedCourses = _cachedCourses.map<CourseModel>((c) {
      if (c.id == courseId) {
        return c.copyWith(lessonsCount: updatedLessons.length);
      }
      return c;
    }).toList();
    await _saveLocalCache();
    _coursesController.add(_cachedCourses);

    // Sync with Laravel API
    unawaited(_api.post('/courses/$courseId/lessons', lesson.toMap()..['id'] = lesson.id));

    // Sync with Firestore
    try {
      final db = _firestore;
      if (db != null) {
        await db
            .collection('courses')
            .doc(courseId)
            .collection('lessons')
            .doc(lesson.id)
            .set(lesson.toMap())
            .timeout(const Duration(seconds: 4));
        await db.collection('courses').doc(courseId).set({
          'lessonsCount': updatedLessons.length,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Firestore addLessonToCourse fallback: $e');
    }
  }

  Future<List<CourseLesson>> _getLocalLessons(String courseId) async {
    if (_cachedLessons.containsKey(courseId)) {
      return _cachedLessons[courseId]!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_lessonsCachePrefix$courseId');
      if (raw != null && raw.isNotEmpty) {
        final list = (jsonDecode(raw) as List)
            .map((item) {
              final map = Map<String, dynamic>.from(item as Map);
              return CourseLesson.fromMap(map, map['id']?.toString() ?? '');
            })
            .toList();
        if (list.isNotEmpty) {
          _cachedLessons[courseId] = list;
          return list;
        }
      }
    } catch (_) {}

    final matches = _cachedCourses.where((c) => c.id == courseId);
    if (matches.isNotEmpty) {
      final course = matches.first;
      final lessons = course.modules.expand((m) => m.lessons).toList();
      if (lessons.isNotEmpty) return lessons;
      if (course.flatLessons.isNotEmpty) return course.flatLessons;
    }
    return <CourseLesson>[];
  }

  /// Get real-time stream of lessons for a course
  Stream<List<CourseLesson>> getCourseLessonsStream(String courseId) async* {
    _lessonControllers.putIfAbsent(
      courseId,
      () => StreamController<List<CourseLesson>>.broadcast(),
    );

    final initial = await _getLocalLessons(courseId);
    yield initial;

    await for (final updated in _lessonControllers[courseId]!.stream) {
      yield updated;
    }
  }

  /// Add live replay to course
  Future<void> addLiveReplayToCourse({
    required String courseId,
    required CourseLiveReplay replay,
  }) async {
    await _initLocalCache();

    _cachedCourses = _cachedCourses.map((c) {
      if (c.id == courseId) {
        return c.copyWith(replays: [...c.replays, replay]);
      }
      return c;
    }).toList();
    await _saveLocalCache();
    _coursesController.add(_cachedCourses);

    unawaited(_api.post('/courses/$courseId/replays', replay.toMap()));

    try {
      final db = _firestore;
      if (db != null) {
        await db.collection('courses').doc(courseId).set({
          'replays': FieldValue.arrayUnion([replay.toMap()]),
        }, SetOptions(merge: true)).timeout(const Duration(seconds: 4));
      }
    } catch (e) {
      debugPrint('Firestore addLiveReplayToCourse fallback: $e');
    }
  }

  /// Search courses
  Future<List<CourseModel>> searchCourses({String query = '', String category = ''}) async {
    final all = await getPopularCourses();
    return all.where((c) {
      final matchesQuery = query.isEmpty ||
          c.title.toLowerCase().contains(query.toLowerCase()) ||
          c.trainerName.toLowerCase().contains(query.toLowerCase());
      final matchesCategory = category.isEmpty ||
          category == 'Toutes les catégories' ||
          c.category.toLowerCase() == category.toLowerCase();
      return matchesQuery && matchesCategory;
    }).toList();
  }

  Future<List<CourseModel>> getAllCourses() async {
    return getPopularCourses();
  }
}
