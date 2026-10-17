import 'package:flutter/material.dart';

/// Network image decoded at display size so scrolling stays smooth on mobile web.
class AppNetworkImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final int? cacheWidth;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.cacheWidth,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 2.0;
    int? decodedWidth = cacheWidth;
    if (decodedWidth == null && width != null && width!.isFinite && width! > 0) {
      decodedWidth = (width! * dpr).round().clamp(48, 960);
    }
    decodedWidth ??= (320 * dpr).round().clamp(160, 960);

    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      cacheWidth: decodedWidth,
      filterQuality: FilterQuality.low,
      gaplessPlayback: true,
      errorBuilder: errorBuilder,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return ColoredBox(
          color: const Color(0xFFF1F5F4),
          child: SizedBox(width: width, height: height),
        );
      },
    );
  }
}
