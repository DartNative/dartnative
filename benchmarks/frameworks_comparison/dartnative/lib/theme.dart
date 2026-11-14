import 'dart:math' as math;

import 'package:dartnative/dartnative.dart';

abstract final class AppColors {
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF4F1EC);
  static const Color skeleton = Color(0xFFEDE9E3);
  static const Color border = Color(0xFFE6E1D9);
  static const Color text = Color(0xFF1C1B19);
  static const Color textMuted = Color(0xFF6E6A63);
  static const Color sale = Color(0xFFB4361E);
  static const Color body = Color(0xFF3D3A35);
  static const Color overlay = Color(0xB81C1B19); // rgba(28,27,25,0.72)
  static const Color dotInactive = Color(0x401C1B19); // rgba(28,27,25,0.25)
}

/// Text style with the platform system font. [lineHeight] is in points.
TextStyle ts(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color color = AppColors.text,
  double? lineHeight,
  double letterSpacing = 0,
  TextDecoration? decoration,
}) {
  return TextStyle(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: lineHeight == null ? null : lineHeight / size,
    letterSpacing: letterSpacing,
    decoration: decoration,
    decorationColor: color,
  );
}

enum AppIcon { home, search, cart, back, minus, plus, alert }

/// The vector icons drawn in the design (24×24 viewBox, round stroke), painted
/// by the native CustomPaint (Core Graphics / android.graphics.Canvas).
class VectorIcon extends StatelessWidget {
  const VectorIcon(this.icon,
      {super.key, this.size = 24, this.color = AppColors.text, this.strokeWidth = 1.75});

  final AppIcon icon;
  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _IconPainter(icon, color, strokeWidth),
    );
  }
}

class _IconPainter extends CustomPainter {
  _IconPainter(this.icon, this.color, this.strokeWidth);

  final AppIcon icon;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final Paint paint = Paint(
      color: color,
      style: PaintingStyle.stroke,
      strokeWidth: strokeWidth,
      strokeCap: StrokeCap.round,
      strokeJoin: StrokeJoin.round,
    );
    final Path path = Path();
    switch (icon) {
      case AppIcon.home:
        // M3 10.5 12 3l9 7.5V20a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z
        path
          ..moveTo(3, 10.5)
          ..lineTo(12, 3)
          ..lineTo(21, 10.5)
          ..lineTo(21, 20)
          ..arcTo(Rect.fromCircle(center: const Offset(20, 20), radius: 1), 0, math.pi / 2, false)
          ..lineTo(15, 21)
          ..lineTo(15, 15)
          ..lineTo(9, 15)
          ..lineTo(9, 21)
          ..lineTo(4, 21)
          ..arcTo(Rect.fromCircle(center: const Offset(4, 20), radius: 1), math.pi / 2, math.pi / 2, false)
          ..close();
      case AppIcon.search:
        // circle cx=11 cy=11 r=7; m20 20-3.5-3.5
        path
          ..addOval(Rect.fromCircle(center: const Offset(11, 11), radius: 7))
          ..moveTo(20, 20)
          ..lineTo(16.5, 16.5);
      case AppIcon.cart:
        // M6 7h12l-1 13H7z; M9 7a3 3 0 0 1 6 0
        path
          ..moveTo(6, 7)
          ..lineTo(18, 7)
          ..lineTo(17, 20)
          ..lineTo(7, 20)
          ..close()
          ..moveTo(9, 7)
          ..arcTo(Rect.fromCircle(center: const Offset(12, 7), radius: 3), math.pi, math.pi, false);
      case AppIcon.back:
        // m15 5-7 7 7 7
        path
          ..moveTo(15, 5)
          ..lineTo(8, 12)
          ..lineTo(15, 19);
      case AppIcon.minus:
        // M5 12h14
        path
          ..moveTo(5, 12)
          ..lineTo(19, 12);
      case AppIcon.plus:
        // M12 5v14M5 12h14
        path
          ..moveTo(12, 5)
          ..lineTo(12, 19)
          ..moveTo(5, 12)
          ..lineTo(19, 12);
      case AppIcon.alert:
        // circle cx=12 cy=12 r=9; M12 7.5v5.5; M12 16.5h.01
        path
          ..addOval(Rect.fromCircle(center: const Offset(12, 12), radius: 9))
          ..moveTo(12, 7.5)
          ..lineTo(12, 13)
          ..moveTo(12, 16.5)
          ..lineTo(12.01, 16.5);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_IconPainter old) =>
      old.icon != icon || old.color != color || old.strokeWidth != strokeWidth;
}
