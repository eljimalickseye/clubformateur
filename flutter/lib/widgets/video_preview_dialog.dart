import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../utils/youtube_helper.dart';
import 'youtube_web_player.dart';

class VideoPreviewDialog extends StatelessWidget {
  final String videoUrl;
  final String title;
  final String duration;
  final bool isFreePreview;

  const VideoPreviewDialog({
    super.key,
    required this.videoUrl,
    required this.title,
    this.duration = '',
    this.isFreePreview = false,
  });

  static void show(
    BuildContext context, {
    required String videoUrl,
    required String title,
    String duration = '',
    bool isFreePreview = false,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => VideoPreviewDialog(
        videoUrl: videoUrl,
        title: title,
        duration: duration,
        isFreePreview: isFreePreview,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isYouTube = YouTubeHelper.isYouTubeUrl(videoUrl);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 780,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 30,
                offset: Offset(0, 10),
              ),
            ],
            border: Border.all(color: Colors.white.withAlpha(25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.emeraldGreenDark.withAlpha(50),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.smart_display_rounded,
                        color: AppTheme.mintAccent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  title,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isFreePreview) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Aperçu Gratuit',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (duration.isNotEmpty)
                            Text(
                              'Durée : $duration',
                              style: const TextStyle(fontSize: 12, color: Colors.white54),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Player View
              ClipRRect(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    color: Colors.black,
                    child: isYouTube
                        ? YouTubeWebPlayer(videoUrl: videoUrl, autoPlay: true)
                        : _buildDirectVideoFallback(context),
                  ),
                ),
              ),

              // Bottom bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        videoUrl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withAlpha(50)),
                      ),
                      icon: const Icon(Icons.open_in_new_rounded, size: 14),
                      label: const Text('Ouvrir lien externe', style: TextStyle(fontSize: 12)),
                      onPressed: () async {
                        final uri = Uri.parse(videoUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDirectVideoFallback(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_library_rounded, color: AppTheme.mintAccent, size: 48),
            const SizedBox(height: 12),
            Text(
              'Lien direct vidéo (MP4 / Flux distant)',
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              videoUrl,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emeraldGreenDark,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Lire la vidéo dans un nouvel onglet'),
              onPressed: () async {
                final uri = Uri.parse(videoUrl);
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
}
