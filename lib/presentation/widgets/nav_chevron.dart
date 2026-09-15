import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The app's mark: a simple filled chevron/beacon shape, reused as the
/// logo, the route-preview arrow, and the aircraft position marker on the
/// map — one consistent glyph instead of a literal plane icon.
class NavChevron extends StatelessWidget {
  final double size;
  final Color color;

  const NavChevron({super.key, this.size = 24, this.color = AppColors.accent});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _ChevronPainter(color));
  }
}

class _ChevronPainter extends CustomPainter {
  final Color color;
  const _ChevronPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width / 2, size.height * 0.62)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _ChevronPainter oldDelegate) => oldDelegate.color != color;
}
