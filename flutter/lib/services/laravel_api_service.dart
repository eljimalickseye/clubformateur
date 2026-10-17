import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service centralisant toutes les communications avec le Backend Laravel (/api/v1)
class LaravelApiService {
  static final LaravelApiService _instance = LaravelApiService._internal();
  factory LaravelApiService() => _instance;
  LaravelApiService._internal();

  static String baseUrl = const String.fromEnvironment(
    'LARAVEL_API_URL',
    defaultValue: 'http://180.149.199.233:8095/api/v1',
  );

  String? _authToken;
  final Map<String, String> _etagCache = {};
  final Map<String, Map<String, dynamic>> _responseCache = {};

  void setAuthToken(String? token) {
    if (_authToken != token) {
      clearCache();
    }
    _authToken = token;
  }

  void clearCache() {
    _etagCache.clear();
    _responseCache.clear();
  }

  void _invalidateCacheFor(String endpoint) {
    if (endpoint.startsWith('/courses')) {
      _etagCache.removeWhere((k, _) => k.startsWith('/courses'));
      _responseCache.removeWhere((k, _) => k.startsWith('/courses'));
    } else {
      _etagCache.remove(endpoint);
      _responseCache.remove(endpoint);
    }
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  bool get _isMixedContentBlocked {
    if (kIsWeb) {
      final originScheme = Uri.base.scheme.toLowerCase();
      if (originScheme == 'https' && baseUrl.toLowerCase().startsWith('http://')) {
        return true;
      }
    }
    return false;
  }

  /// Exécute une requête GET avec support des en-têtes ETag et révalidation conditionnelle HTTP 304
  Future<Map<String, dynamic>?> get(String endpoint) async {
    if (_isMixedContentBlocked) return null;
    try {
      final headers = Map<String, String>.from(_headers);
      final cachedEtag = _etagCache[endpoint];
      if (cachedEtag != null) {
        headers['If-None-Match'] = cachedEtag;
      }

      final response = await http
          .get(Uri.parse('$baseUrl$endpoint'), headers: headers)
          .timeout(const Duration(seconds: 3));

      // Contenu inchangé validé par le serveur
      if (response.statusCode == 304) {
        return _responseCache[endpoint];
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final etag = response.headers['etag'];
        if (etag != null) {
          _etagCache[endpoint] = etag;
          _responseCache[endpoint] = decoded;
        }
        return decoded;
      }
    } catch (e) {
      debugPrint('Laravel API GET $endpoint offline/fallback: $e');
    }
    return _responseCache[endpoint];
  }

  Future<Map<String, dynamic>?> post(String endpoint, Map<String, dynamic> body) async {
    if (_isMixedContentBlocked) return null;
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 3));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _invalidateCacheFor(endpoint);
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Laravel API POST $endpoint offline/fallback: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> put(String endpoint, Map<String, dynamic> body) async {
    if (_isMixedContentBlocked) return null;
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl$endpoint'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 3));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _invalidateCacheFor(endpoint);
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Laravel API PUT $endpoint offline/fallback: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> patch(String endpoint, [Map<String, dynamic>? body]) async {
    if (_isMixedContentBlocked) return null;
    try {
      final response = await http
          .patch(
            Uri.parse('$baseUrl$endpoint'),
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 3));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _invalidateCacheFor(endpoint);
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Laravel API PATCH $endpoint offline/fallback: $e');
    }
    return null;
  }

  Future<bool> delete(String endpoint) async {
    if (_isMixedContentBlocked) return false;
    try {
      final response = await http
          .delete(Uri.parse('$baseUrl$endpoint'), headers: _headers)
          .timeout(const Duration(seconds: 3));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _invalidateCacheFor(endpoint);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Laravel API DELETE $endpoint offline/fallback: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> deleteJson(String endpoint, [Map<String, dynamic>? body]) async {
    if (_isMixedContentBlocked) return null;
    try {
      final request = http.Request('DELETE', Uri.parse('$baseUrl$endpoint'));
      request.headers.addAll(_headers);
      if (body != null) {
        request.body = jsonEncode(body);
      }
      final streamed = await request.send().timeout(const Duration(seconds: 4));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _invalidateCacheFor(endpoint);
        if (response.body.isNotEmpty) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('Laravel API DELETE $endpoint offline/fallback: $e');
    }
    return null;
  }

  /// Upload d'un fichier binaire (image, vidéo, audio, PDF) vers POST /api/v1/courses/upload-media
  Future<String?> uploadMedia({
    required Uint8List bytes,
    required String fileName,
    String folder = 'uploads',
  }) async {
    if (_isMixedContentBlocked) return null;
    try {
      final uri = Uri.parse('$baseUrl/courses/upload-media');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Accept'] = 'application/json';
      if (_authToken != null) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }
      request.fields['folder'] = folder;
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
        ),
      );

      final streamed = await request.send().timeout(const Duration(seconds: 8));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final url = data['url']?.toString() ??
            (data['data'] is Map ? data['data']['url']?.toString() : null);
        if (url != null && url.isNotEmpty) return url;
      }
    } catch (e) {
      debugPrint('Laravel API uploadMedia fallback: $e');
    }
    return null;
  }
}
