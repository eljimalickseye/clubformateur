import 'package:flutter/material.dart';
import 'livekit_webrtc_stub.dart'
    if (dart.library.html) 'livekit_webrtc_web.dart';

class LiveKitWebRtcView extends StatelessWidget {
  final bool isCamOn;
  final bool isMicOn;
  final bool isScreenSharing;
  final String roomName;
  final String jwtToken;
  final Widget fallback;

  const LiveKitWebRtcView({
    super.key,
    required this.isCamOn,
    required this.isMicOn,
    required this.isScreenSharing,
    required this.roomName,
    required this.jwtToken,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return LiveKitWebRtcPlatformView(
      isCamOn: isCamOn,
      isMicOn: isMicOn,
      isScreenSharing: isScreenSharing,
      roomName: roomName,
      jwtToken: jwtToken,
      fallback: fallback,
    );
  }
}
