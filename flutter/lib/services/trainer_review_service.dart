import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrainerReviewItem {
  final String id;
  final String teacherId;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final double rating;
  final String comment;
  final DateTime createdAt;

  TrainerReviewItem({
    required this.id,
    required this.teacherId,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory TrainerReviewItem.fromMap(Map<String, dynamic> data, String id) {
    return TrainerReviewItem(
      id: id.isNotEmpty ? id : (data['id']?.toString() ?? ''),
      teacherId: data['teacherId']?.toString() ?? '',
      authorId: data['authorId']?.toString() ?? '',
      authorName: data['authorName']?.toString() ?? 'Apprenant vérifié',
      authorAvatar: data['authorAvatar']?.toString() ?? '',
      rating: (data['rating'] is num) ? (data['rating'] as num).toDouble() : 5.0,
      comment: data['comment']?.toString() ?? '',
      createdAt: DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'teacherId': teacherId,
    'authorId': authorId,
    'authorName': authorName,
    'authorAvatar': authorAvatar,
    'rating': rating,
    'comment': comment,
    'createdAt': createdAt.toIso8601String(),
  };
}

class TrainerReviewService {
  static final TrainerReviewService _instance = TrainerReviewService._internal();
  factory TrainerReviewService() => _instance;
  TrainerReviewService._internal() {
    _initCache();
  }

  static const String _cacheKey = 'olivia_trainer_reviews_v1';
  final StreamController<List<TrainerReviewItem>> _reviewsController =
      StreamController<List<TrainerReviewItem>>.broadcast();

  List<TrainerReviewItem> _cachedReviews = [];
  bool _initialized = false;

  FirebaseFirestore? get _firestore {
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('Firestore not ready in TrainerReviewService: $e');
    }
    return null;
  }

  Future<void> _initCache() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _cachedReviews = decoded
            .map((item) => TrainerReviewItem.fromMap(
                Map<String, dynamic>.from(item as Map), item['id']?.toString() ?? ''))
            .toList();
        _reviewsController.add(_cachedReviews);
      }
    } catch (e) {
      debugPrint('TrainerReviewService cache error: $e');
    }

    _syncRemote();
  }

  Future<void> _saveCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_cachedReviews.map((r) => r.toMap()).toList());
      await prefs.setString(_cacheKey, encoded);
    } catch (e) {
      debugPrint('TrainerReviewService saveCache error: $e');
    }
  }

  Future<void> _syncRemote() async {
    try {
      final db = _firestore;
      if (db != null) {
        final snap = await db
            .collection('teacher_reviews')
            .orderBy('createdAt', descending: true)
            .limit(100)
            .get()
            .timeout(const Duration(seconds: 4));

        if (snap.docs.isNotEmpty) {
          final list = snap.docs
              .map((d) => TrainerReviewItem.fromMap(d.data(), d.id))
              .toList();
          _cachedReviews = list;
          await _saveCache();
          _reviewsController.add(_cachedReviews);
        }
      }
    } catch (e) {
      debugPrint('Firestore sync teacher_reviews fallback: $e');
    }
  }

  /// Get real-time stream of reviews for a specific teacher
  Stream<List<TrainerReviewItem>> getTeacherReviewsStream(String teacherId) async* {
    await _initCache();
    yield _cachedReviews.where((r) => r.teacherId == teacherId).toList();
    yield* _reviewsController.stream.map(
      (list) => list.where((r) => r.teacherId == teacherId).toList(),
    );
  }

  /// Add a real review and update satisfaction metrics
  Future<String> addReview({
    required String teacherId,
    required String authorId,
    required String authorName,
    String authorAvatar = '',
    required double rating,
    required String comment,
  }) async {
    await _initCache();
    final reviewId = 'rev_${DateTime.now().millisecondsSinceEpoch}';

    final review = TrainerReviewItem(
      id: reviewId,
      teacherId: teacherId,
      authorId: authorId,
      authorName: authorName,
      authorAvatar: authorAvatar,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );

    _cachedReviews = [review, ..._cachedReviews];
    await _saveCache();
    _reviewsController.add(_cachedReviews);

    try {
      final db = _firestore;
      if (db != null) {
        await db
            .collection('teacher_reviews')
            .doc(reviewId)
            .set(review.toMap())
            .timeout(const Duration(seconds: 4));
      }
    } catch (e) {
      debugPrint('Firestore save review fallback: $e');
    }

    return reviewId;
  }
}
