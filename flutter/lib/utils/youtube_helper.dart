class YouTubeHelper {
  /// Check if a given URL is a YouTube link
  static bool isYouTubeUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    final lower = url.trim().toLowerCase();
    return lower.contains('youtube.com') ||
        lower.contains('youtu.be') ||
        lower.contains('youtube-nocookie.com');
  }

  /// Extract the 11-character YouTube video ID
  static String? extractVideoId(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final trimmed = url.trim();

    // Format 1: youtu.be/<id>
    if (trimmed.contains('youtu.be/')) {
      final parts = trimmed.split('youtu.be/');
      if (parts.length > 1) {
        var id = parts[1];
        final q = id.indexOf('?');
        final s = id.indexOf('/');
        if (q != -1) id = id.substring(0, q);
        if (s != -1) id = id.substring(0, s);
        id = id.trim();
        if (id.length == 11) return id;
      }
    }

    // Format 2: youtube.com/watch?v=<id> or embed/<id> or shorts/<id>
    final regExp = RegExp(
      r'(?:youtube(?:-nocookie)?\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?|shorts)\/|\S*?[?&]v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(trimmed);
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }

    return null;
  }

  /// Generate a clean responsive YouTube embed URL
  static String getEmbedUrl(String? url, {bool autoplay = true}) {
    final videoId = extractVideoId(url);
    if (videoId == null) return url ?? '';
    final auto = autoplay ? 1 : 0;
    return 'https://www.youtube.com/embed/$videoId?autoplay=$auto&rel=0&enablejsapi=1&modestbranding=1&playsinline=1';
  }

  /// Get maximum resolution thumbnail for a YouTube video
  static String getThumbnailUrl(String? url) {
    final videoId = extractVideoId(url);
    if (videoId == null) return '';
    return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
  }

  /// Get high-quality fallback thumbnail
  static String getHqThumbnailUrl(String? url) {
    final videoId = extractVideoId(url);
    if (videoId == null) return '';
    return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
  }
}
