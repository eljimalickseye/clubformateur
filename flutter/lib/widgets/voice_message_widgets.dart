import 'dart:async';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../services/audio_recording_service.dart';
import '../services/firebase_storage_service.dart';
import '../theme/app_theme.dart';

enum RecordingState { idle, recording, preview }

class VoiceRecordingBar extends StatefulWidget {
  final String conversationId;
  final Function(String audioUrl, int durationSeconds) onAudioSent;
  final Widget child; // Regular text input widget when not recording

  const VoiceRecordingBar({
    super.key,
    required this.conversationId,
    required this.onAudioSent,
    required this.child,
  });

  @override
  State<VoiceRecordingBar> createState() => _VoiceRecordingBarState();
}

class _VoiceRecordingBarState extends State<VoiceRecordingBar> {
  final AudioRecordingService _audioService = AudioRecordingService();
  final FirebaseStorageService _storageService = FirebaseStorageService();

  RecordingState _state = RecordingState.idle;
  int _seconds = 0;
  Timer? _timer;
  String? _recordedPath;
  Uint8List? _recordedBytes;
  bool _isPlayingPreview = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _audioService.init();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _startRecording() async {
    try {
      final ok = await _audioService.startRecording();
      if (ok) {
        setState(() {
          _state = RecordingState.recording;
          _seconds = 0;
          _recordedPath = null;
          _recordedBytes = null;
          _isPlayingPreview = false;
        });
        _timer?.cancel();
        _timer = Timer.periodic(const Duration(seconds: 1), (t) {
          if (mounted) setState(() => _seconds++);
        });
      } else {
        _showError('Impossible d\'activer le microphone. Vérifiez les autorisations.');
      }
    } catch (e) {
      _showError('Erreur micro: $e');
    }
  }

  Future<void> _cancelRecording() async {
    _timer?.cancel();
    await _audioService.stopRecording();
    await _audioService.stopAudio();
    if (mounted) {
      setState(() {
        _state = RecordingState.idle;
        _seconds = 0;
        _recordedPath = null;
        _recordedBytes = null;
        _isPlayingPreview = false;
      });
    }
  }

  Future<void> _stopForPreview() async {
    _timer?.cancel();
    final path = await _audioService.stopRecording();
    if (path == null || path.isEmpty) {
      _cancelRecording();
      return;
    }

    _recordedPath = path;
    _fetchAudioBytes(path);

    if (mounted) {
      setState(() {
        _state = RecordingState.preview;
      });
    }
  }

  Future<Uint8List?> _fetchAudioBytes(String path) async {
    if (_recordedBytes != null) return _recordedBytes;
    try {
      if (path.startsWith('blob:') || path.startsWith('http')) {
        final res = await http.get(Uri.parse(path));
        if (res.statusCode == 200) {
          _recordedBytes = res.bodyBytes;
          return _recordedBytes;
        }
      }
      final xfile = XFile(path);
      _recordedBytes = await xfile.readAsBytes();
      return _recordedBytes;
    } catch (e) {
      debugPrint('Error reading audio bytes: $e');
    }
    return null;
  }

  Future<void> _togglePreviewPlay() async {
    if (_recordedPath == null) return;
    if (_isPlayingPreview) {
      await _audioService.pauseAudio();
      if (mounted) setState(() => _isPlayingPreview = false);
    } else {
      setState(() => _isPlayingPreview = true);
      await _audioService.playAudio(_recordedPath!);
      // Check for completion
      Timer.periodic(const Duration(milliseconds: 500), (t) {
        if (!mounted || _audioService.currentlyPlayingUrl != _recordedPath) {
          t.cancel();
          if (mounted) setState(() => _isPlayingPreview = false);
        }
      });
    }
  }

  Future<void> _sendRecording() async {
    if (_isSending) return;
    setState(() => _isSending = true);

    String? path = _recordedPath;
    if (path == null) {
      _timer?.cancel();
      path = await _audioService.stopRecording();
    }

    if (path == null || path.isEmpty) {
      _showError('Enregistrement audio vide');
      _cancelRecording();
      setState(() => _isSending = false);
      return;
    }

    final duration = _seconds > 0 ? _seconds : 1;
    final bytes = await _fetchAudioBytes(path);

    String finalAudioUrl = path;
    if (bytes != null && bytes.isNotEmpty) {
      final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.${kIsWeb ? 'webm' : 'm4a'}';
      final uploadedUrl = await _storageService.uploadAudioNote(
        conversationId: widget.conversationId,
        bytes: bytes,
        fileName: fileName,
      );
      if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
        finalAudioUrl = uploadedUrl;
      } else {
        // Fallback to Base64 Data URL so audio is self-contained and universally playable
        final ext = kIsWeb ? 'webm' : 'm4a';
        finalAudioUrl = 'data:audio/$ext;base64,${base64Encode(bytes)}';
      }
    }

    await widget.onAudioSent(finalAudioUrl, duration);

    if (mounted) {
      setState(() {
        _state = RecordingState.idle;
        _seconds = 0;
        _recordedPath = null;
        _recordedBytes = null;
        _isPlayingPreview = false;
        _isSending = false;
      });
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_state == RecordingState.idle) {
      return Row(
        children: [
          Expanded(child: widget.child),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Enregistrer une note vocale',
            child: InkWell(
              onTap: _startRecording,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppTheme.paleMint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mic_rounded,
                  color: AppTheme.emeraldGreenDark,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (_state == RecordingState.recording) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Row(
          children: [
            // Blinking red dot
            const _BlinkingRedDot(),
            const SizedBox(width: 8),
            Text(
              'Enregistrement... ${_formatTime(_seconds)}',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFFDC2626),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const Spacer(),

            // Cancel
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 22),
              tooltip: 'Annuler',
              onPressed: _cancelRecording,
            ),

            // Stop to preview
            IconButton(
              icon: const Icon(Icons.stop_circle_outlined, color: AppTheme.emeraldGreenDark, size: 24),
              tooltip: 'Écouter avant d\'envoyer',
              onPressed: _stopForPreview,
            ),

            // Send immediately
            IconButton.filled(
              style: IconButton.styleFrom(backgroundColor: AppTheme.emeraldGreenDark),
              icon: _isSending
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
              tooltip: 'Envoyer',
              onPressed: _isSending ? null : _sendRecording,
            ),
          ],
        ),
      );
    }

    // Preview state
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Row(
        children: [
          // Play / Pause preview
          IconButton(
            icon: Icon(
              _isPlayingPreview ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
              color: AppTheme.emeraldGreenDark,
              size: 28,
            ),
            tooltip: _isPlayingPreview ? 'Mettre en pause' : 'Écouter',
            onPressed: _togglePreviewPlay,
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Note vocale prête',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppTheme.emeraldGreenDark,
                ),
              ),
              Text(
                'Durée: ${_formatTime(_seconds)}',
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
          ),
          const Spacer(),

          // Discard
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
            tooltip: 'Supprimer',
            onPressed: _cancelRecording,
          ),

          // Send
          IconButton.filled(
            style: IconButton.styleFrom(backgroundColor: AppTheme.emeraldGreenDark),
            icon: _isSending
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            tooltip: 'Envoyer la note vocale',
            onPressed: _isSending ? null : _sendRecording,
          ),
        ],
      ),
    );
  }
}

class _BlinkingRedDot extends StatefulWidget {
  const _BlinkingRedDot();

  @override
  State<_BlinkingRedDot> createState() => _BlinkingRedDotState();
}

class _BlinkingRedDotState extends State<_BlinkingRedDot> with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          color: Color(0xFFDC2626),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// A playback bubble for voice messages in chat
class AudioMessageBubble extends StatefulWidget {
  final String audioUrl;
  final int durationSeconds;
  final bool isMe;

  const AudioMessageBubble({
    super.key,
    required this.audioUrl,
    required this.durationSeconds,
    required this.isMe,
  });

  @override
  State<AudioMessageBubble> createState() => _AudioMessageBubbleState();
}

class _AudioMessageBubbleState extends State<AudioMessageBubble> {
  final AudioRecordingService _audioService = AudioRecordingService();
  bool _isPlaying = false;
  Timer? _pollTimer;

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  String _formatTime(int sec) {
    final m = (sec ~/ 60).toString();
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _togglePlay() async {
    if (_isPlaying) {
      await _audioService.pauseAudio();
      setState(() => _isPlaying = false);
    } else {
      setState(() => _isPlaying = true);
      await _audioService.playAudio(widget.audioUrl);
      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(const Duration(milliseconds: 400), (t) {
        if (!mounted || _audioService.currentlyPlayingUrl != widget.audioUrl) {
          t.cancel();
          if (mounted) setState(() => _isPlaying = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMe = widget.isMe;
    final activeColor = isMe ? Colors.white : AppTheme.emeraldGreenDark;
    final textColor = isMe ? Colors.white.withValues(alpha: 0.85) : AppTheme.textMuted;
    final bubbleBg = isMe ? AppTheme.emeraldGreenDark : const Color(0xFFF1F5F9);
    final borderColor = isMe ? Colors.transparent : const Color(0xFFCBD5E1);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      constraints: const BoxConstraints(maxWidth: 320),
      decoration: BoxDecoration(
        color: bubbleBg,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isMe ? 0.08 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMe ? Colors.white.withValues(alpha: 0.22) : AppTheme.paleMint,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: isMe ? Colors.white : AppTheme.emeraldGreenDark,
                size: 26,
              ),
              onPressed: _togglePlay,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.graphic_eq_rounded, color: activeColor, size: 16),
                    const SizedBox(width: 5),
                    Text(
                      'Note vocale',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: isMe ? Colors.white : AppTheme.ink,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _formatTime(widget.durationSeconds),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 140,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _isPlaying ? null : 0.0,
                      minHeight: 4,
                      backgroundColor: isMe ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFCBD5E1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isMe ? Colors.white : AppTheme.emeraldGreenDark,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
