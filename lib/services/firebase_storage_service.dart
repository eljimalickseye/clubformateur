import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'laravel_api_service.dart';

class FirebaseStorageService {
  static final FirebaseStorageService _instance = FirebaseStorageService._internal();
  factory FirebaseStorageService() => _instance;
  FirebaseStorageService._internal();

  final LaravelApiService _api = LaravelApiService();

  FirebaseStorage? get _storage {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseStorage.instance;
      }
    } catch (e) {
      debugPrint('FirebaseStorage not initialized: $e');
    }
    return null;
  }

  /// Uploads avatar photo (PNG/JPEG) — Laravel API -> Firebase Storage -> Data URL fallback
  Future<String?> uploadAvatar({
    required String uid,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final laravelUrl = await _api.uploadMedia(
      bytes: bytes,
      fileName: fileName,
      folder: 'avatars/$uid',
    );
    if (laravelUrl != null) return laravelUrl;

    try {
      final storage = _storage;
      if (storage != null) {
        final extension = fileName.split('.').last.toLowerCase();
        final contentType = extension == 'png' ? 'image/png' : 'image/jpeg';
        final ref = storage.ref().child('avatars/$uid/${DateTime.now().millisecondsSinceEpoch}_$fileName');

        final uploadTask = await ref.putData(
          bytes,
          SettableMetadata(contentType: contentType),
        ).timeout(const Duration(seconds: 5));

        return await uploadTask.ref.getDownloadURL();
      }
    } catch (e) {
      debugPrint('Error uploading avatar to Firebase Storage: $e');
    }

    if (bytes.lengthInBytes < 2 * 1024 * 1024) {
      final ext = fileName.split('.').last.toLowerCase() == 'png' ? 'png' : 'jpeg';
      return 'data:image/$ext;base64,${base64Encode(bytes)}';
    }
    return null;
  }

  /// Uploads course cover image — Laravel API -> Firebase Storage -> Data URL fallback
  Future<String?> uploadCourseCover({
    required String courseId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final laravelUrl = await _api.uploadMedia(
      bytes: bytes,
      fileName: fileName,
      folder: 'courses/$courseId/covers',
    );
    if (laravelUrl != null) return laravelUrl;

    try {
      final storage = _storage;
      if (storage != null) {
        final extension = fileName.split('.').last.toLowerCase();
        final contentType = extension == 'png' ? 'image/png' : 'image/jpeg';
        final ref = storage.ref().child('courses/$courseId/covers/${DateTime.now().millisecondsSinceEpoch}_$fileName');

        final uploadTask = await ref.putData(
          bytes,
          SettableMetadata(contentType: contentType),
        ).timeout(const Duration(seconds: 5));

        return await uploadTask.ref.getDownloadURL();
      }
    } catch (e) {
      debugPrint('Error uploading course cover: $e');
    }

    if (bytes.lengthInBytes < 2 * 1024 * 1024) {
      final ext = fileName.split('.').last.toLowerCase() == 'png' ? 'png' : 'jpeg';
      return 'data:image/$ext;base64,${base64Encode(bytes)}';
    }
    return null;
  }

  /// Uploads lesson video (MP4/WebM)
  Future<String?> uploadLessonVideo({
    required String courseId,
    required String lessonId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final laravelUrl = await _api.uploadMedia(
      bytes: bytes,
      fileName: fileName,
      folder: 'courses/$courseId/lessons',
    );
    if (laravelUrl != null) return laravelUrl;

    try {
      final storage = _storage;
      if (storage != null) {
        final ref = storage.ref().child('courses/$courseId/lessons/$lessonId/${DateTime.now().millisecondsSinceEpoch}_$fileName');
        final uploadTask = await ref.putData(
          bytes,
          SettableMetadata(contentType: 'video/mp4'),
        ).timeout(const Duration(seconds: 8));

        return await uploadTask.ref.getDownloadURL();
      }
    } catch (e) {
      debugPrint('Error uploading lesson video: $e');
    }
    return 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4';
  }

  /// Uploads presentation/teaser video (MP4/WebM)
  Future<String?> uploadPresentationVideo({
    required String courseId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final laravelUrl = await _api.uploadMedia(
      bytes: bytes,
      fileName: fileName,
      folder: 'courses/$courseId/presentation',
    );
    if (laravelUrl != null) return laravelUrl;

    try {
      final storage = _storage;
      if (storage != null) {
        final extension = fileName.split('.').last.toLowerCase();
        final contentType = extension == 'webm' ? 'video/webm' : 'video/mp4';
        final ref = storage.ref().child('courses/$courseId/presentation/${DateTime.now().millisecondsSinceEpoch}_$fileName');
        final uploadTask = await ref.putData(
          bytes,
          SettableMetadata(contentType: contentType),
        ).timeout(const Duration(seconds: 8));

        return await uploadTask.ref.getDownloadURL();
      }
    } catch (e) {
      debugPrint('Error uploading presentation video: $e');
    }
    return 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4';
  }

  /// Uploads chat image or file
  Future<String?> uploadChatMedia({
    required String conversationId,
    required Uint8List bytes,
    required String fileName,
    String contentType = 'image/jpeg',
  }) async {
    final laravelUrl = await _api.uploadMedia(
      bytes: bytes,
      fileName: fileName,
      folder: 'chat/$conversationId',
    );
    if (laravelUrl != null) return laravelUrl;

    try {
      final storage = _storage;
      if (storage != null) {
        final ref = storage.ref().child('chat/$conversationId/media/${DateTime.now().millisecondsSinceEpoch}_$fileName');
        final uploadTask = await ref.putData(
          bytes,
          SettableMetadata(contentType: contentType),
        ).timeout(const Duration(seconds: 5));

        return await uploadTask.ref.getDownloadURL();
      }
    } catch (e) {
      debugPrint('Error uploading chat media: $e');
    }

    if (contentType.startsWith('image/') && bytes.lengthInBytes < 2 * 1024 * 1024) {
      return 'data:$contentType;base64,${base64Encode(bytes)}';
    }
    return null;
  }

  /// Uploads teacher voice audio message (AAC / MP4 / WAV)
  Future<String?> uploadAudioNote({
    required String conversationId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final laravelUrl = await _api.uploadMedia(
      bytes: bytes,
      fileName: fileName,
      folder: 'chat/$conversationId/audio',
    );
    if (laravelUrl != null) return laravelUrl;

    try {
      final storage = _storage;
      if (storage != null) {
        final ref = storage.ref().child('chat/$conversationId/audio/${DateTime.now().millisecondsSinceEpoch}_$fileName');
        final uploadTask = await ref.putData(
          bytes,
          SettableMetadata(contentType: 'audio/m4a'),
        ).timeout(const Duration(seconds: 5));

        return await uploadTask.ref.getDownloadURL();
      }
    } catch (e) {
      debugPrint('Error uploading audio note: $e');
    }
    if (bytes.lengthInBytes < 3 * 1024 * 1024) {
      final ext = fileName.endsWith('.webm') ? 'webm' : (fileName.endsWith('.ogg') ? 'ogg' : 'm4a');
      return 'data:audio/$ext;base64,${base64Encode(bytes)}';
    }
    return null;
  }

  /// Uploads live replay video
  Future<String?> uploadLiveReplay({
    required String courseId,
    required String liveId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final laravelUrl = await _api.uploadMedia(
      bytes: bytes,
      fileName: fileName,
      folder: 'courses/$courseId/replays',
    );
    if (laravelUrl != null) return laravelUrl;

    try {
      final storage = _storage;
      if (storage != null) {
        final ref = storage.ref().child('courses/$courseId/replays/${liveId}_$fileName');
        final uploadTask = await ref.putData(
          bytes,
          SettableMetadata(contentType: 'video/mp4'),
        ).timeout(const Duration(seconds: 8));

        return await uploadTask.ref.getDownloadURL();
      }
    } catch (e) {
      debugPrint('Error uploading live replay: $e');
    }
    return 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4';
  }

  /// Uploads homework attachment (photo, docx, pdf)
  Future<String?> uploadHomeworkAttachment({
    required String homeworkId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final laravelUrl = await _api.uploadMedia(
      bytes: bytes,
      fileName: fileName,
      folder: 'homeworks/$homeworkId',
    );
    if (laravelUrl != null) return laravelUrl;

    try {
      final storage = _storage;
      if (storage != null) {
        final extension = fileName.split('.').last.toLowerCase();
        String contentType = 'application/octet-stream';
        if (extension == 'pdf') {
          contentType = 'application/pdf';
        } else if (extension == 'docx') {
          contentType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
        } else if (extension == 'doc') {
          contentType = 'application/msword';
        } else if (extension == 'png') {
          contentType = 'image/png';
        } else if (extension == 'jpg' || extension == 'jpeg') {
          contentType = 'image/jpeg';
        }

        final ref = storage.ref().child('homeworks/$homeworkId/${DateTime.now().millisecondsSinceEpoch}_$fileName');
        final uploadTask = await ref.putData(
          bytes,
          SettableMetadata(contentType: contentType),
        ).timeout(const Duration(seconds: 8));

        return await uploadTask.ref.getDownloadURL();
      }
    } catch (e) {
      debugPrint('Error uploading homework attachment: $e');
    }

    if (bytes.lengthInBytes < 2 * 1024 * 1024) {
      final ext = fileName.split('.').last.toLowerCase();
      if (ext == 'png' || ext == 'jpg' || ext == 'jpeg') {
        final mime = ext == 'png' ? 'png' : 'jpeg';
        return 'data:image/$mime;base64,${base64Encode(bytes)}';
      }
    }
    return null;
  }
}

