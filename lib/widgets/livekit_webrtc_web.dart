// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

class LiveKitWebRtcPlatformView extends StatefulWidget {
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
  State<LiveKitWebRtcPlatformView> createState() =>
      _LiveKitWebRtcPlatformViewState();
}

class _LiveKitWebRtcPlatformViewState extends State<LiveKitWebRtcPlatformView> {
  late final String _viewType;
  html.VideoElement? _videoElement;
  html.MediaStream? _mediaStream;
  bool _hasActiveStream = false;

  @override
  void initState() {
    super.initState();
    _viewType =
        'livekit-webrtc-${widget.roomName}-${DateTime.now().microsecondsSinceEpoch}';

    _videoElement = html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..controls = false
      ..setAttribute('playsinline', 'true')
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover'
      ..style.backgroundColor = '#0F172A';

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => _videoElement!,
    );

    _updateMediaStream();
  }

  @override
  void didUpdateWidget(covariant LiveKitWebRtcPlatformView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isCamOn != widget.isCamOn ||
        oldWidget.isScreenSharing != widget.isScreenSharing ||
        oldWidget.isMicOn != widget.isMicOn) {
      _updateMediaStream();
    }
  }

  Future<void> _stopCurrentStream() async {
    try {
      _mediaStream?.getTracks().forEach((track) => track.stop());
      _videoElement?.srcObject = null;
    } catch (_) {}
    _mediaStream = null;
  }

  Future<void> _updateMediaStream() async {
    if (!widget.isCamOn && !widget.isScreenSharing) {
      await _stopCurrentStream();
      if (mounted) setState(() => _hasActiveStream = false);
      return;
    }

    try {
      await _stopCurrentStream();
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) {
        if (mounted) setState(() => _hasActiveStream = false);
        return;
      }

      html.MediaStream? stream;
      if (widget.isScreenSharing) {
        stream = await (mediaDevices as dynamic).getDisplayMedia({
          'video': true,
          'audio': widget.isMicOn,
        }) as html.MediaStream?;
      } else if (widget.isCamOn) {
        stream = await mediaDevices.getUserMedia({
          'video': {
            'width': {'ideal': 1280},
            'height': {'ideal': 720},
          },
          'audio': widget.isMicOn,
        });
      }

      if (stream != null && mounted) {
        _mediaStream = stream;
        _videoElement?.srcObject = stream;
        await _videoElement?.play();
        setState(() => _hasActiveStream = true);
      }
    } catch (e) {
      debugPrint('WebRTC MediaStream fallback (permission or device): $e');
      if (mounted) setState(() => _hasActiveStream = false);
    }
  }

  @override
  void dispose() {
    _stopCurrentStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasActiveStream) {
      return widget.fallback;
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        HtmlElementView(viewType: _viewType),
        Positioned(
          bottom: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.6)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.videocam, color: Color(0xFF10B981), size: 14),
                const SizedBox(width: 6),
                Text(
                  widget.isScreenSharing ? 'Partage d\'écran WebRTC actif' : 'Caméra WebRTC HD active',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
