import 'dart:math' as math;

class TileCoord {
  final int z;
  final int x;
  final int y;
  const TileCoord(this.z, this.x, this.y);

  @override
  bool operator ==(Object other) =>
      other is TileCoord && other.z == z && other.x == x && other.y == y;
  @override
  int get hashCode => Object.hash(z, x, y);

  String get cacheKey => '$z/$x/$y';
}

class LatLngBoundsSimple {
  final double minLat;
  final double maxLat;
  final double minLon;
  final double maxLon;
  const LatLngBoundsSimple({
    required this.minLat,
    required this.maxLat,
    required this.minLon,
    required this.maxLon,
  });

  /// Bounding box around a route, padded by [paddingDegrees] on each side
  /// so the downloaded area covers a reasonable margin either side of the
  /// great-circle track, not just the two endpoints.
  factory LatLngBoundsSimple.fromPoints(
    List<List<double>> points, {
    double paddingDegrees = 2.0,
  }) {
    var minLat = double.infinity;
    var maxLat = -double.infinity;
    var minLon = double.infinity;
    var maxLon = -double.infinity;
    for (final p in points) {
      minLat = math.min(minLat, p[0]);
      maxLat = math.max(maxLat, p[0]);
      minLon = math.min(minLon, p[1]);
      maxLon = math.max(maxLon, p[1]);
    }
    return LatLngBoundsSimple(
      minLat: (minLat - paddingDegrees).clamp(-85.0, 85.0),
      maxLat: (maxLat + paddingDegrees).clamp(-85.0, 85.0),
      minLon: minLon - paddingDegrees,
      maxLon: maxLon + paddingDegrees,
    );
  }
}

/// Slippy-map (OSM/Google) tile numbering math.
class TileMath {
  static int _lonToX(double lon, int z) {
    final n = math.pow(2, z).toDouble();
    return ((lon + 180.0) / 360.0 * n).floor();
  }

  static int _latToY(double lat, int z) {
    final n = math.pow(2, z).toDouble();
    final latRad = lat * math.pi / 180.0;
    return ((1.0 -
                math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) /
            2.0 *
            n)
        .floor();
  }

  /// All tiles covering [bounds] across [minZoom]..[maxZoom] inclusive.
  static List<TileCoord> tilesForBounds(
    LatLngBoundsSimple bounds, {
    required int minZoom,
    required int maxZoom,
  }) {
    final tiles = <TileCoord>[];
    for (var z = minZoom; z <= maxZoom; z++) {
      final xMin = _lonToX(bounds.minLon, z);
      final xMax = _lonToX(bounds.maxLon, z);
      // Latitude decreases as Y increases, so min/max lat map to max/min Y.
      final yMin = _latToY(bounds.maxLat, z);
      final yMax = _latToY(bounds.minLat, z);
      final maxTileIndex = math.pow(2, z).toInt() - 1;
      for (var x = xMin.clamp(0, maxTileIndex); x <= xMax.clamp(0, maxTileIndex); x++) {
        for (var y = yMin.clamp(0, maxTileIndex); y <= yMax.clamp(0, maxTileIndex); y++) {
          tiles.add(TileCoord(z, x, y));
        }
      }
    }
    return tiles;
  }
}
