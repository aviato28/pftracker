import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../data/basemap/land_basemap_repository.dart';
import '../../domain/flight_route.dart';
import '../../domain/geo_utils.dart';
import '../../state/flight_session_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/nav_chevron.dart';

const _oceanColor = Color(0xFF0A1B21);
const _oceanColorDeep = Color(0xFF071319);
const _graticuleColor = Color(0x14BFE0F0);

List<List<LatLng>> _toLatLngSegments(List<List<double>> latLon) {
  return GeoUtils.splitAtAntimeridian(latLon)
      .map((segment) => segment.map((p) => LatLng(p[0], p[1])).toList())
      .toList();
}

/// Lat/lon reference grid — purely decorative, but it's what stops a
/// zoomed-in view over open ocean or a single landmass' interior from
/// reading as an empty rectangle. Meridians/parallels are straight lines
/// under Web Mercator, so two endpoints per line are enough.
List<Polyline> _graticule() {
  final lines = <Polyline>[];
  for (var lon = -180; lon <= 180; lon += 30) {
    lines.add(Polyline(
      points: [LatLng(-80, lon.toDouble()), LatLng(80, lon.toDouble())],
      color: _graticuleColor,
      strokeWidth: 1,
    ));
  }
  for (var lat = -60; lat <= 60; lat += 20) {
    lines.add(Polyline(
      points: [LatLng(lat.toDouble(), -180), LatLng(lat.toDouble(), 180)],
      color: _graticuleColor,
      strokeWidth: 1,
    ));
  }
  return lines;
}

/// A basic, fully offline world map: a bundled land/ocean vector outline
/// (no tiles, no network, ever) with the planned route, flown track, and
/// the aircraft's own position drawn on top. Built on `flutter_map`'s own
/// pan/zoom/camera-fit handling — plain, well-tested gesture behavior
/// rather than a hand-rolled one.
///
/// Only the traveled-track/marker layers listen to [FlightSessionController]
/// — everything else (the map itself, the ~60k-point land outline, the
/// graticule, the static route line) is built once from [route] and never
/// rebuilt on a GPS tick. Rebuilding the whole map (and re-simplifying that
/// much geometry) every few seconds was the source of visible jank.
class WorldMapView extends StatefulWidget {
  final FlightRoute route;

  const WorldMapView({super.key, required this.route});

  @override
  State<WorldMapView> createState() => _WorldMapViewState();
}

class _WorldMapViewState extends State<WorldMapView> {
  final _repository = LandBasemapRepository();
  List<Polygon>? _land;

  late final List<LatLng> _routePoints;
  late final LatLngBounds _bounds;
  late final List<List<LatLng>> _routeSegments;

  @override
  void initState() {
    super.initState();
    final routeLatLon = GeoUtils.greatCirclePath(
      widget.route.departure.lat,
      widget.route.departure.lon,
      widget.route.arrival.lat,
      widget.route.arrival.lon,
    );
    _routePoints = routeLatLon.map((p) => LatLng(p[0], p[1])).toList();
    _bounds = LatLngBounds.fromPoints(_routePoints);
    _routeSegments = _toLatLngSegments(routeLatLon);

    _repository.load().then((polygons) {
      if (mounted) setState(() => _land = polygons);
    });
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

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.2),
          radius: 1.1,
          colors: [_oceanColor, _oceanColorDeep],
        ),
      ),
      child: FlutterMap(
        options: MapOptions(
          initialCameraFit: CameraFit.bounds(
            bounds: _bounds,
            padding: const EdgeInsets.all(48),
          ),
          minZoom: 1,
          maxZoom: 13,
          backgroundColor: Colors.transparent,
        ),
        children: [
          PolylineLayer(polylines: _graticule()),
          PolygonLayer(polygons: land),
          PolylineLayer(polylines: [
            for (final segment in _routeSegments)
              Polyline(
                points: segment,
                color: const Color(0xFF3A4B57),
                strokeWidth: 2,
                pattern: StrokePattern.dashed(segments: const [1, 9]),
              ),
          ]),
          Consumer<FlightSessionController>(
            builder: (context, controller, _) {
              final traveledSegments = _toLatLngSegments(
                controller.samples.map((s) => [s.lat, s.lon]).toList(),
              );
              return PolylineLayer(polylines: [
                // Glow: a soft wide line underneath the crisp traveled track.
                for (final segment in traveledSegments)
                  Polyline(points: segment, color: AppColors.accent.withValues(alpha: 0.25), strokeWidth: 9),
                for (final segment in traveledSegments)
                  Polyline(points: segment, color: AppColors.accent, strokeWidth: 3),
              ]);
            },
          ),
          Consumer<FlightSessionController>(
            builder: (context, controller, _) {
              final stats = controller.stats;
              if (stats == null) return const SizedBox.shrink();
              return MarkerLayer(markers: [
                Marker(
                  point: LatLng(stats.lat, stats.lon),
                  width: 44,
                  height: 44,
                  child: _AircraftMarker(headingDegrees: stats.headingDegrees ?? 0),
                ),
              ]);
            },
          ),
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
