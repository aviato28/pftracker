import 'package:flutter/material.dart';

class WorldMapPainter extends CustomPainter {
  final Path land;
  final List<List<Offset>> routeSegments;
  final List<List<Offset>> traveledSegments;
  final Color oceanColor;
  final Color landColor;
  final Color landBorderColor;

  WorldMapPainter({
    required this.land,
    required this.routeSegments,
    required this.traveledSegments,
    required this.oceanColor,
    required this.landColor,
    required this.landBorderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = oceanColor);
    canvas.drawPath(land, Paint()..color = landColor);
    canvas.drawPath(
      land,
      Paint()
        ..color = landBorderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.75,
    );

    final routePaint = Paint()
      ..color = Colors.blueGrey.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final segment in routeSegments) {
      _drawPolyline(canvas, segment, routePaint);
    }

    final traveledPaint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final segment in traveledSegments) {
      _drawPolyline(canvas, segment, traveledPaint);
    }
  }

  void _drawPolyline(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WorldMapPainter oldDelegate) {
    return oldDelegate.land != land ||
        oldDelegate.routeSegments != routeSegments ||
        oldDelegate.traveledSegments != traveledSegments;
  }
}
