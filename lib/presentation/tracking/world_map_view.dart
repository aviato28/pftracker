import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/basemap/land_basemap_repository.dart';
import '../../domain/geo_utils.dart';
import '../theme/app_theme.dart';
import '../widgets/nav_chevron.dart';

const _oceanColor = Color(0xFF0A1B21);

/// A basic, fully offline world map: a bundled land/ocean vector outline
/// (no tiles, no network, ever) with the planned route, flown track, and
/// the aircraft's own position drawn on top. Built on `flutter_map`'s own
/// pan/zoom/camera-fit handling — plain, well-tested gesture behavior
/// rather than a hand-rolled one.
class WorldMapView extends StatefulWidget {
  final List<List<double>> routeLatLon;
  final List<List<double>> traveledLatLon;
  final double? currentLat;
  final double? currentLon;
  final double? headingDegrees;

  const WorldMapView({
    super.key,
    required this.routeLatLon,
    required this.traveledLatLon,
    this.currentLat,
    this.currentLon,
    this.headingDegrees,
  });

  @override
  State<WorldMapView> createState() => _WorldMapViewState();
}

class _WorldMapViewState extends State<WorldMapView> {
  final _repository = LandBasemapRepository();
  List<Polygon>? _land;

  @override
  void initState() {
    super.initState();
    _repository.load().then((polygons) {
      if (mounted) setState(() => _land = polygons);
    });
  }

  List<List<LatLng>> _toLatLngSegments(List<List<double>> latLon) {
    return GeoUtils.splitAtAntimeridian(latLon)
        .map((segment) => segment.map((p) => LatLng(p[0], p[1])).toList())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final land = _land;
    if (land == null) {
      return const ColoredBox(
        color: AppColors.background,
        child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    final routePoints = widget.routeLatLon.map((p) => LatLng(p[0], p[1])).toList();
    final bounds = LatLngBounds.fromPoints(routePoints);
    final routeSegments = _toLatLngSegments(widget.routeLatLon);
    final traveledSegments = _toLatLngSegments(widget.traveledLatLon);

    return ColoredBox(
      color: _oceanColor,
      child: FlutterMap(
        options: MapOptions(
          initialCameraFit: CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(48),
          ),
          minZoom: 1,
          maxZoom: 13,
        ),
        children: [
          PolygonLayer(polygons: land),
          PolylineLayer(polylines: [
            for (final segment in routeSegments)
              Polyline(
                points: segment,
                color: const Color(0xFF3A4B57),
                strokeWidth: 2,
                pattern: StrokePattern.dashed(segments: const [1, 9]),
              ),
          ]),
          // Glow: a soft wide line underneath the crisp traveled track.
          PolylineLayer(polylines: [
            for (final segment in traveledSegments)
              Polyline(points: segment, color: AppColors.accent.withValues(alpha: 0.25), strokeWidth: 9),
          ]),
          PolylineLayer(polylines: [
            for (final segment in traveledSegments)
              Polyline(points: segment, color: AppColors.accent, strokeWidth: 3),
          ]),
          if (widget.currentLat != null && widget.currentLon != null)
            MarkerLayer(markers: [
              Marker(
                point: LatLng(widget.currentLat!, widget.currentLon!),
                width: 44,
                height: 44,
                child: _AircraftMarker(headingDegrees: widget.headingDegrees ?? 0),
              ),
            ]),
        ],
      ),
    );
  }
}

class _AircraftMarker extends StatelessWidget {
  final double headingDegrees;
  const _AircraftMarker({required this.headingDegrees});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accent.withValues(alpha: 0.18),
          ),
        ),
        Transform.rotate(
          angle: headingDegrees * math.pi / 180,
          child: const NavChevron(size: 18),
        ),
      ],
    );
  }
}
