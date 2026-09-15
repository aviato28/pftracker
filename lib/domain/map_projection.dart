import 'dart:ui';

/// Simple equirectangular (plate carrée) projection onto a fixed-size
/// canvas. Good enough for a "basic map, not a detailed one" — no tile
/// pyramid, no network, just a flat world laid out in one bundled asset.
class MapProjection {
  static const double mapWidth = 2048;
  static const double mapHeight = 1024;

  static Offset project(double lat, double lon) {
    final x = (lon + 180) / 360 * mapWidth;
    final y = (90 - lat) / 180 * mapHeight;
    return Offset(x, y);
  }

  /// Projects a lat/lon polyline (as `[lat, lon]` pairs) into one or more
  /// pixel-space segments, starting a new segment wherever the path
  /// crosses the antimeridian — otherwise a transpacific route would draw
  /// a spurious line all the way across the map.
  static List<List<Offset>> projectPolyline(List<List<double>> latLonPoints) {
    final segments = <List<Offset>>[];
    var current = <Offset>[];
    double? previousLon;
    for (final point in latLonPoints) {
      final lat = point[0];
      final lon = point[1];
      if (previousLon != null && (lon - previousLon).abs() > 180) {
        if (current.length > 1) segments.add(current);
        current = [];
      }
      current.add(project(lat, lon));
      previousLon = lon;
    }
    if (current.length > 1) segments.add(current);
    return segments;
  }
}
