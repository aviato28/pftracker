import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart' show rootBundle;

import '../../domain/map_projection.dart';

/// Loads the bundled world land silhouette (`assets/data/world_land.json`,
/// simplified from Natural Earth 1:110m, public domain) and turns it into
/// one pre-projected [Path], cached after the first load. Rendering a
/// static path is far cheaper than re-projecting ~127 polygons every
/// frame, and needs no network — the whole point of shipping the map
/// inside the app instead of downloading tiles.
class LandBasemapRepository {
  Path? _cached;

  Future<Path> load() async {
    final cached = _cached;
    if (cached != null) return cached;

    final raw = await rootBundle.loadString('assets/data/world_land.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final polygons = data['polygons'] as List<dynamic>;

    final path = Path()..fillType = PathFillType.evenOdd;
    for (final polygon in polygons) {
      for (final ring in polygon as List<dynamic>) {
        final points = (ring as List<dynamic>).map((coord) {
          final c = coord as List<dynamic>;
          final lon = (c[0] as num).toDouble();
          final lat = (c[1] as num).toDouble();
          return MapProjection.project(lat, lon);
        }).toList();
        if (points.isEmpty) continue;
        path.moveTo(points.first.dx, points.first.dy);
        for (final point in points.skip(1)) {
          path.lineTo(point.dx, point.dy);
        }
        path.close();
      }
    }

    _cached = path;
    return path;
  }
}
