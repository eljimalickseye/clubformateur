// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/youtube_helper.dart';

class YouTubeWebPlayer extends StatefulWidget {
  final String videoUrl;
  final String? title;
  final bool autoPlay;

  const YouTubeWebPlayer({
    super.key,
    required this.videoUrl,
    this.title,
    this.autoPlay = true,
  });

  @override
  State<YouTubeWebPlayer> createState() => _YouTubeWebPlayerState();
}

class _YouTubeWebPlayerState extends State<YouTubeWebPlayer> {
  late final String _viewType;
  html.IFrameElement? _iframeElement;
  String? _videoId;

  @override
  void initState() {
    super.initState();
    _videoId = YouTubeHelper.extractVideoId(widget.videoUrl);
    _setupIframe();
  }

  void _setupIframe() {
    if (!kIsWeb) return;
    final embedUrl = YouTubeHelper.getEmbedUrl(widget.videoUrl, autoplay: widget.autoPlay);
    _viewType = 'youtube-iframe-${_videoId ?? "video"}-${DateTime.now().microsecondsSinceEpoch}';

    _iframeElement = html.IFrameElement()
      ..src = embedUrl
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.backgroundColor = '#000000'
      ..allow = 'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share'
      ..setAttribute('allowfullscreen', 'true');

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => _iframeElement!,
    );
  }

  @override
  void didUpdateWidget(covariant YouTubeWebPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _videoId = YouTubeHelper.extractVideoId(widget.videoUrl);
      if (kIsWeb && _iframeElement != null) {
        _iframeElement!.src = YouTubeHelper.getEmbedUrl(widget.videoUrl, autoplay: widget.autoPlay);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      final thumbUrl = YouTubeHelper.getHqThumbnailUrl(widget.videoUrl);
      return Container(
        color: Colors.black,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (thumbUrl.isNotEmpty)
                Image.network(thumbUrl, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
              Container(color: Colors.black.withValues(alpha: 0.4)),
              IconButton(
                icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.red, size: 64),
                onPressed: () async {
                  final uri = Uri.parse(widget.videoUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.black,
      width: double.infinity,
      height: double.infinity,
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
