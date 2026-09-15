import 'dart:math' as math;

/// Great-circle math on a spherical Earth. Good enough for in-flight
/// distance/ETA/heading display — not for navigation-grade precision.
class GeoUtils {
  static const double earthRadiusMeters = 6371000;

  static double _degToRad(double deg) => deg * math.pi / 180;
  static double _radToDeg(double rad) => rad * 180 / math.pi;

  /// Haversine distance between two points, in meters.
  static double distanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final phi1 = _degToRad(lat1);
    final phi2 = _degToRad(lat2);
    final dPhi = _degToRad(lat2 - lat1);
    final dLambda = _degToRad(lon2 - lon1);

    final a = math.sin(dPhi / 2) * math.sin(dPhi / 2) +
        math.cos(phi1) *
            math.cos(phi2) *
            math.sin(dLambda / 2) *
            math.sin(dLambda / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  /// Initial bearing (degrees, 0-360, 0 = true north) from point 1 to point 2.
  static double initialBearingDegrees(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final phi1 = _degToRad(lat1);
    final phi2 = _degToRad(lat2);
    final dLambda = _degToRad(lon2 - lon1);

    final y = math.sin(dLambda) * math.cos(phi2);
    final x = math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(dLambda);
    final theta = math.atan2(y, x);
    return (_radToDeg(theta) + 360) % 360;
  }

  /// Points along the great-circle path between two coordinates, for
  /// drawing a route line on the map. [segments] controls resolution.
  static List<List<double>> greatCirclePath(
    double lat1,
    double lon1,
    double lat2,
    double lon2, {
    int segments = 64,
  }) {
    final phi1 = _degToRad(lat1);
    final lambda1 = _degToRad(lon1);
    final phi2 = _degToRad(lat2);
    final lambda2 = _degToRad(lon2);

    final delta = 2 *
        math.asin(
          math.sqrt(
            math.pow(math.sin((phi2 - phi1) / 2), 2) +
                math.cos(phi1) *
                    math.cos(phi2) *
                    math.pow(math.sin((lambda2 - lambda1) / 2), 2),
          ),
        );

    if (delta == 0) {
      return [
        [lat1, lon1]
      ];
    }

    final points = <List<double>>[];
    for (var i = 0; i <= segments; i++) {
      final f = i / segments;
      final a = math.sin((1 - f) * delta) / math.sin(delta);
      final b = math.sin(f * delta) / math.sin(delta);
      final x = a * math.cos(phi1) * math.cos(lambda1) +
          b * math.cos(phi2) * math.cos(lambda2);
      final y = a * math.cos(phi1) * math.sin(lambda1) +
          b * math.cos(phi2) * math.sin(lambda2);
      final z = a * math.sin(phi1) + b * math.sin(phi2);
      final lat = math.atan2(z, math.sqrt(x * x + y * y));
      final lon = math.atan2(y, x);
      points.add([_radToDeg(lat), _radToDeg(lon)]);
    }
    return points;
  }

  /// Barometric altitude (meters, above the reference pressure level) from
  /// a station pressure reading, using the ISA formula. [seaLevelHpa] is
  /// the QNH reference pressure; 1013.25 is the standard atmosphere default.
  static double altitudeFromPressure(
    double pressureHpa, {
    double seaLevelHpa = 1013.25,
  }) {
    return 44330 * (1 - math.pow(pressureHpa / seaLevelHpa, 0.1903)).toDouble();
  }
}
