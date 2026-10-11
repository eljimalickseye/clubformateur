import 'package:flutter/material.dart';

class LiveKitWebRtcPlatformView extends StatelessWidget {
  final bool isCamOn;
  final bool isMicOn;
  final bool isScreenSharing;
  final String roomName;
  final String jwtToken;
  final Widget fallback;

  const LiveKitWebRtcPlatformView({
    super.key,
    required this.isCamOn,
    required this.isMicOn,
    required this.isScreenSharing,
    required this.roomName,
    required this.jwtToken,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) => fallback;
}
