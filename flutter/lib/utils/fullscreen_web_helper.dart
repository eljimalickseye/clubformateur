// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

class FullscreenWebHelper {
  static void toggleFullscreen(bool enter) {
    if (!kIsWeb) return;
    try {
      if (enter) {
        if (html.document.fullscreenElement == null) {
          html.document.documentElement?.requestFullscreen();
        }
      } else {
        if (html.document.fullscreenElement != null) {
          html.document.exitFullscreen();
        }
      }
    } catch (e) {
      debugPrint('Fullscreen error: $e');
    }
  }

  static bool get isFullscreen {
    if (!kIsWeb) return false;
    try {
      return html.document.fullscreenElement != null;
    } catch (_) {
      return false;
    }
  }

  static StreamSubscription? addFullscreenListener(void Function(bool isFs) callback) {
    if (!kIsWeb) return null;
    try {
      return html.document.onFullscreenChange.listen((_) {
        callback(isFullscreen);
      });
    } catch (_) {
      return null;
    }
  }
}
