import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class FileDownloadHelper {
  /// Ouvre ou télécharge un fichier (URL http/https ou data URL base64)
  static Future<void> downloadOrOpenFile(String url, {String? fileName}) async {
    if (url.isEmpty) return;

    final name = fileName ?? 'document';

    // 1. Si c'est une data URL (base64) sur Web
    if (kIsWeb && url.startsWith('data:')) {
      try {
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', name)
          ..style.display = 'none';
        html.document.body?.children.add(anchor);
        anchor.click();
        anchor.remove();
        return;
      } catch (e) {
        debugPrint('Web data URL download fallback error: $e');
      }
    }

    // 2. Si c'est une URL HTTP / HTTPS standard
    try {
      final uri = Uri.parse(url);
      if (kIsWeb) {
        // Sur le web, créer un anchor avec download pour forcer le téléchargement si possible
        try {
          final anchor = html.AnchorElement(href: url)
            ..target = '_blank'
            ..setAttribute('download', name)
            ..style.display = 'none';
          html.document.body?.children.add(anchor);
          anchor.click();
          anchor.remove();
          return;
        } catch (_) {}
      }

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('downloadOrOpenFile error: $e');
    }
  }

  /// Détermine l'icône correspondante à l'extension
  static IconData getFileIcon(String nameOrUrl) {
    final ext = getFileExtension(nameOrUrl).toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
      case 'csv':
        return Icons.table_chart_rounded;
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
        return Icons.folder_zip_rounded;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'webp':
      case 'gif':
        return Icons.image_rounded;
      case 'dart':
      case 'js':
      case 'ts':
      case 'html':
      case 'css':
      case 'py':
      case 'json':
        return Icons.code_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  /// Détermine la couleur correspondante à l'extension
  static Color getFileColor(String nameOrUrl) {
    final ext = getFileExtension(nameOrUrl).toLowerCase();
    switch (ext) {
      case 'pdf':
        return const Color(0xFFEF4444);
      case 'doc':
      case 'docx':
        return const Color(0xFF2563EB);
      case 'xls':
      case 'xlsx':
      case 'csv':
        return const Color(0xFF10B981);
      case 'zip':
      case 'rar':
      case '7z':
        return const Color(0xFFF59E0B);
      case 'png':
      case 'jpg':
      case 'jpeg':
        return const Color(0xFF8B5CF6);
      case 'dart':
      case 'js':
      case 'ts':
      case 'py':
        return const Color(0xFF06B6D4);
      default:
        return const Color(0xFF64748B);
    }
  }

  /// Extrait l'extension
  static String getFileExtension(String nameOrUrl) {
    if (nameOrUrl.contains('?')) {
      nameOrUrl = nameOrUrl.split('?').first;
    }
    if (nameOrUrl.contains('/')) {
      nameOrUrl = nameOrUrl.split('/').last;
    }
    if (nameOrUrl.contains('.')) {
      return nameOrUrl.split('.').last;
    }
    return '';
  }

  /// Formate la taille en Ko ou Mo
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes octets';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} Ko';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }
}
