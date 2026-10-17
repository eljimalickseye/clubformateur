import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    if (kIsWeb) return const ClampingScrollPhysics();
    return const BouncingScrollPhysics();
  }
}

mixin AutoCarouselMixin<T extends StatefulWidget> on State<T> {
  final ScrollController carouselController = ScrollController();
  Timer? _autoScrollTimer;
  Timer? _resumeTimer;
  bool userHoldingCarousel = false;
  bool _autoEnabled = true;

  double get carouselStep;
  Duration get autoScrollInterval => const Duration(seconds: 7);

  void syncAutoScroll({required bool enabled}) {
    if (_autoEnabled == enabled && _autoScrollTimer != null) return;
    _autoEnabled = enabled;
    _autoScrollTimer?.cancel();
    if (enabled) _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(autoScrollInterval, (_) {
      if (!mounted ||
          !_autoEnabled ||
          userHoldingCarousel ||
          !carouselController.hasClients) {
        return;
      }
      final maxScroll = carouselController.position.maxScrollExtent;
      if (maxScroll <= 0) return;
      final current = carouselController.offset;
      final atEnd = current + carouselStep >= maxScroll + 40;
      carouselController.animateTo(
        atEnd ? 0 : current + carouselStep,
        duration: Duration(milliseconds: atEnd ? 700 : 480),
        curve: Curves.easeOutCubic,
      );
    });
  }

  bool onCarouselNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification && notification.dragDetails != null) {
      pauseCarousel();
    }
    return false;
  }

  void pauseCarousel() {
    userHoldingCarousel = true;
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) userHoldingCarousel = false;
    });
  }

  void scrollCarouselBy(double delta) {
    if (!carouselController.hasClients) return;
    pauseCarousel();
    final target = (carouselController.offset + delta).clamp(
      0.0,
      carouselController.position.maxScrollExtent,
    );
    carouselController.animateTo(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _resumeTimer?.cancel();
    carouselController.dispose();
    super.dispose();
  }
}
