import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

class DynamicImageHelper {
  static final ImagePicker _picker = ImagePicker();
  static const _uuid = Uuid();

  static Future<DynamicPhoto?> pickFromGallery() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (file != null) {
        final Uint8List bytes = await file.readAsBytes();
        return DynamicPhoto(
          id: _uuid.v4(),
          bytes: bytes,
          fileName: file.name,
          createdAt: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
    return null;
  }

  static Future<DynamicPhoto?> pickFromCamera() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (file != null) {
        final Uint8List bytes = await file.readAsBytes();
        return DynamicPhoto(
          id: _uuid.v4(),
          bytes: bytes,
          fileName: file.name,
          createdAt: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('Error capturing photo: $e');
    }
    return null;
  }

  static Widget buildPhotoWidget(
    DynamicPhoto photo, {
    double width = 80,
    double height = 80,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    final radius = borderRadius ?? BorderRadius.circular(12);

    Widget imageContent;
    if (photo.isBytes) {
      imageContent = Image.memory(
        photo.bytes!,
        width: width,
        height: height,
        fit: fit,
      );
    } else if (photo.assetPath != null && photo.assetPath!.isNotEmpty) {
      imageContent = Image.asset(
        photo.assetPath!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _errorPlaceholder(width, height),
      );
    } else {
      imageContent = _errorPlaceholder(width, height);
    }

    return ClipRRect(
      borderRadius: radius,
      child: imageContent,
    );
  }

  static Widget _errorPlaceholder(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
    );
  }

  static void showImageZoomDialog(BuildContext context, DynamicPhoto photo) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              constraints: const BoxConstraints(maxHeight: 550, maxWidth: 500),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: photo.isBytes
                      ? Image.memory(photo.bytes!, fit: BoxFit.contain)
                      : Image.asset(photo.assetPath ?? '', fit: BoxFit.contain),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
