import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

class LiveKitService {
  static final LiveKitService _instance = LiveKitService._internal();
  factory LiveKitService() => _instance;
  LiveKitService._internal();

  static const String serverUrl = 'wss://anour-rv83fs3g.livekit.cloud';
  static const String apiKey = 'APIsCo9dSx9D6VC';
  static const String apiSecret = 'uOfP2sDQQjFe3dREQazqQq3fLWkv5JPfMVnikLAoCPAB';

  /// Generates a valid HS256 LiveKit JWT Access Token
  String createAccessToken({
    required String roomName,
    required String participantIdentity,
    required String participantName,
    bool isTeacher = false,
    Duration validFor = const Duration(hours: 4),
  }) {
    final now = DateTime.now();
    final exp = now.add(validFor);

    // 1. JWT Header
    final header = {
      'alg': 'HS256',
      'typ': 'JWT',
    };

    // 2. JWT Payload compliant with LiveKit specifications
    final payload = {
      'iss': apiKey,
      'sub': participantIdentity,
      'name': participantName,
      'nbf': (now.millisecondsSinceEpoch ~/ 1000) - 10,
      'exp': exp.millisecondsSinceEpoch ~/ 1000,
      'metadata': isTeacher ? 'teacher' : 'student',
      'video': {
        'room': roomName,
        'roomJoin': true,
        'canPublish': isTeacher,
        'canSubscribe': true,
        'canPublishData': true,
        'canPublishSources': isTeacher ? ['camera', 'microphone', 'screen_share', 'screen_share_audio'] : [],
      },
    };

    final headerB64 = _base64UrlEncode(utf8.encode(jsonEncode(header)));
    final payloadB64 = _base64UrlEncode(utf8.encode(jsonEncode(payload)));
    final dataToSign = '$headerB64.$payloadB64';

    // 3. HMAC-SHA256 signature using API Secret
    final hmac = Hmac(sha256, utf8.encode(apiSecret));
    final signature = hmac.convert(utf8.encode(dataToSign));
    final signatureB64 = _base64UrlEncode(signature.bytes);

    final jwt = '$dataToSign.$signatureB64';
    debugPrint('LiveKit Token generated for room: $roomName (role: ${isTeacher ? 'teacher' : 'student'})');
    return jwt;
  }

  String _base64UrlEncode(List<int> bytes) {
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  /// Builds connection configuration for a session
  Map<String, dynamic> getConnectionConfig({
    required String roomName,
    required String participantIdentity,
    required String participantName,
    bool isTeacher = false,
  }) {
    final token = createAccessToken(
      roomName: roomName,
      participantIdentity: participantIdentity,
      participantName: participantName,
      isTeacher: isTeacher,
    );

    return {
      'serverUrl': serverUrl,
      'token': token,
      'roomName': roomName,
      'participantIdentity': participantIdentity,
      'participantName': participantName,
      'isTeacher': isTeacher,
    };
  }
}
