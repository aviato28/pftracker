import 'dart:convert';

import 'package:flutter/material.dart' show Color;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

const _landColor = Color(0xFF263832);
const _landBorderColor = Color(0xFF3A4C44);

/// Loads the bundled world land silhouette
/// (`assets/data/world_land.json`, simplified from Natural Earth 1:110m,
/// public domain) as [Polygon]s for [PolygonLayer] — a basic, fully
/// offline vector basemap. Cached after the first load since the shapes
/// (and their styling — this app has one fixed dark theme) never change.
class LandBasemapRepository {
  List<Polygon>? _cached;

  Future<List<Polygon>> load() async {
    final cached = _cached;
    if (cached != null) return cached;

    final raw = await rootBundle.loadString('assets/data/world_land.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final rawPolygons = data['polygons'] as List<dynamic>;

    final polygons = <Polygon>[];
    for (final polygon in rawPolygons) {
      final rings = (polygon as List<dynamic>).map((ring) {
        return (ring as List<dynamic>).map((coord) {
          final c = coord as List<dynamic>;
          final lon = (c[0] as num).toDouble();
          final lat = (c[1] as num).toDouble();
          return LatLng(lat, lon);
        }).toList();
      }).toList();

      if (rings.isEmpty) continue;
      polygons.add(Polygon(
        points: rings.first,
        holePointsList: rings.length > 1 ? rings.sublist(1) : null,
        color: _landColor,
        borderColor: _landBorderColor,
        borderStrokeWidth: 0.7,
      ));
    }

    _cached = polygons;
    return polygons;
  }
}
