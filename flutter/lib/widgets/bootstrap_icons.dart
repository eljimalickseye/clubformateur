import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BootstrapIcon extends StatelessWidget {
  final String iconKey;
  final double size;
  final Color color;

  const BootstrapIcon({
    super.key,
    required this.iconKey,
    this.size = 22.0,
    required this.color,
  });

  static const String display = r'''<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16"><path d="M0 4s0-2 2-2h12s2 0 2 2v6s0 2-2 2h-4c0 .667.083 1.167.25 1.5H11a.5.5 0 0 1 0 1H5a.5.5 0 0 1 0-1h.75c.167-.333.25-.833.25-1.5H2s-2 0-2-2zm1.398-.855a.76.76 0 0 0-.254.302A1.5 1.5 0 0 0 1 4.01V10c0 .325.078.502.145.602.07.105.17.188.302.254a1.5 1.5 0 0 0 .553.144H14c.325 0 .502-.078.602-.145a.76.76 0 0 0 .254-.302 1.5 1.5 0 0 0 .144-.553V4.01c0-.325-.078-.502-.145-.602a.76.76 0 0 0-.302-.254A1.5 1.5 0 0 0 14 3.01H2c-.325 0-.502.078-.602.145"/></svg>''';

  static const String megaphone = r'''<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16"><path d="M13 2.5a1.5 1.5 0 0 1 3 0v11a1.5 1.5 0 0 1-3 0v-.214c-2.162-1.241-4.49-1.843-6.912-2.083l.405 2.712A1 1 0 0 1 5.51 15.1h-.548a1 1 0 0 1-.916-.599l-1.85-3.49a68 68 0 0 1-.202-.049A1.5 1.5 0 0 1 0 9.5v-3a1.5 1.5 0 0 1 1.994-1.423c.373.11.8.225 1.28.344l1.62-3.056A1 1 0 0 1 5.79 1.8h.548a1 1 0 0 1 .99.858l.413 2.766c2.42-.24 4.748-.842 6.91-2.083zm1.139 1.111v9.778c.628-.15 1-.613 1-1.139V3.611c0-.526-.372-.989-1-1.139M13 3.652c-2.196 1.258-4.57 1.868-7.03 2.115l-.462-3.097H5.21l-1.5 2.827c-.42-.108-.8-.21-1.136-.307a.5.5 0 0 0-.574.477v3a.5.5 0 0 0 .574.477c.337-.097.717-.2 1.136-.307l1.5 2.827h.3l.462-3.097c2.46.247 4.834.857 7.03 2.115z"/></svg>''';

  static const String barChart = r'''<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16"><path d="M11 2a1 1 0 0 1 1-1h2a1 1 0 0 1 1 1v12h.5a.5.5 0 0 1 0 1H.5a.5.5 0 0 1 0-1H1v-3a1 1 0 0 1 1-1h2a1 1 0 0 1 1 1v3h1V7a1 1 0 0 1 1-1h2a1 1 0 0 1 1 1v7h1zm1 12h2V2h-2zm-3 0V7H7v7zm-5 0v-3H2v3z"/></svg>''';

  static const String palette = r'''<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16"><path d="M8 5a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3m4 3a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3M5.5 7a1.5 1.5 0 1 1-3 0 1.5 1.5 0 0 1 3 0m.5 6a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3"/><path d="M16 8c0 3.15-1.866 2.583-3.667 2.583-.404 0-.827.02-1.253.064-.99.103-1.638.65-1.802 1.597-.105.61-.43 1.13-.888 1.488C7.94 14.07 7.37 14.25 6.75 14.25A6.75 6.75 0 0 1 0 7.5 7.5 7.5 0 0 1 15 7.5q0 .25-.015.5H16zm-1.522 1.417C14.773 9.07 15 8.563 15 8a6 6 0 1 0-6 6c.383 0 .73-.086 1.036-.245.314-.163.535-.41.618-.737.33-1.306 1.432-2.14 2.827-2.285.508-.052 1.012-.075 1.5-.075.76 0 1.522.045 1.522.259z"/></svg>''';

  static const String people = r'''<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16"><path d="M15 14s1 0 1-1-1-4-5-4-5 3-5 4 1 1 1 1zm-7.978-1L7 12.996c.001-.264.167-1.03.76-1.72C8.312 10.629 9.282 10 11 10c1.717 0 2.687.63 3.24 1.276.593.69.758 1.457.76 1.72zm-2.943-.035q-.18-.04-.353-.087a7 7 0 0 1-3.23-1.604c-.604-.576-.906-1.258-.906-1.942 0-.258.077-.492.215-.705.158-.246.394-.44.69-.572.63-.284 1.472-.44 2.506-.44.42 0 .828.026 1.217.076.082.35.24.69.476 1.002.39.516.93 1.004 1.635 1.435-.444.62-.79 1.34-1.026 2.052zM10 8a3 3 0 1 0 0-6 3 3 0 0 0 0 6m-5 0a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5m0-1a1.5 1.5 0 1 1 0-3 1.5 1.5 0 0 1 0 3m5 0a2 2 0 1 1 0-4 2 2 0 0 1 0 4"/></svg>''';

  static const String threeDots = r'''<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16"><path d="M3 9.5a1.5 1.5 0 1 1 0-3 1.5 1.5 0 0 1 0 3m5 0a1.5 1.5 0 1 1 0-3 1.5 1.5 0 0 1 0 3m5 0a1.5 1.5 0 1 1 0-3 1.5 1.5 0 0 1 0 3"/></svg>''';

  static String _getSvg(String key) {
    switch (key) {
      case 'display':
      case 'informatique':
        return display;
      case 'megaphone':
      case 'marketing':
        return megaphone;
      case 'barChart':
      case 'business':
        return barChart;
      case 'palette':
      case 'design':
        return palette;
      case 'people':
      case 'dev_perso':
        return people;
      case 'threeDots':
      case 'autres':
      default:
        return threeDots;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      _getSvg(iconKey),
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
