import 'package:flutter/foundation.dart';
import 'laravel_api_service.dart';

class LiveKitService {
  static final LiveKitService _instance = LiveKitService._internal();
  factory LiveKitService() => _instance;
  LiveKitService._internal();

  static const String serverUrl = String.fromEnvironment(
    'LIVEKIT_SERVER_URL',
    defaultValue: 'wss://anour-rv83fs3g.livekit.cloud',
  );

  final LaravelApiService _api = LaravelApiService();

  /// Récupère un jeton d'accès LiveKit généré et signé par le backend Laravel (POST /api/v1/livekit/token).
  /// Les secrets et les autorisations de publication (canPublish) sont strictement contrôlés côté serveur.
  Future<Map<String, dynamic>?> fetchLiveKitToken(String roomName) async {
    try {
      final res = await _api.post('/livekit/token', {'roomName': roomName});
      if (res != null && res['token'] != null) {
        debugPrint('LiveKitService: Jeton sécurisé récupéré depuis l\'API pour le salon $roomName');
        return res;
      }
    } catch (e) {
      debugPrint('LiveKitService: Erreur lors de la récupération du jeton via l\'API: $e');
    }
    return null;
  }

  /// Récupère la configuration de connexion complète de manière asynchrone via l'API.
  Future<Map<String, dynamic>> fetchConnectionConfig({
    required String roomName,
    required String participantIdentity,
    required String participantName,
    bool isTeacher = false,
  }) async {
    final serverData = await fetchLiveKitToken(roomName);
    final token = serverData?['token']?.toString() ?? '';
    final url = serverData?['serverUrl']?.toString() ?? serverUrl;

    return {
      'serverUrl': url,
      'token': token,
      'roomName': roomName,
      'participantIdentity': participantIdentity,
      'participantName': participantName,
      'isTeacher': isTeacher,
    };
  }

  /// Fournit une configuration par défaut sans exposer de secret.
  Map<String, dynamic> getConnectionConfig({
    required String roomName,
    required String participantIdentity,
    required String participantName,
    bool isTeacher = false,
  }) {
    return {
      'serverUrl': serverUrl,
      'token': '',
      'roomName': roomName,
      'participantIdentity': participantIdentity,
      'participantName': participantName,
      'isTeacher': isTeacher,
    };
  }

  /// Méthode conservée pour compatibilité d'interface sans secret en dur.
  String createAccessToken({
    required String roomName,
    required String participantIdentity,
    required String participantName,
    bool isTeacher = false,
    Duration validFor = const Duration(hours: 4),
  }) {
    debugPrint(
      'LiveKitService: La signature locale avec secret a été supprimée pour des raisons de sécurité. '
      'Utilisez fetchLiveKitToken().',
    );
    return '';
  }
}
