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

  void setAuthToken(String? token) {
    _authToken = token;
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

  Future<Map<String, dynamic>?> get(String endpoint) async {
    if (_isMixedContentBlocked) return null;
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$endpoint'), headers: _headers)
          .timeout(const Duration(seconds: 3));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Laravel API GET $endpoint offline/fallback: $e');
    }
    return null;
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
      return response.statusCode >= 200 && response.statusCode < 300;
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
      if (response.body.isNotEmpty) {
        return jsonDecode(response.body) as Map<String, dynamic>;
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
