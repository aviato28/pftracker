import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';

import '../../data/settings/app_settings.dart';
import '../../data/tiles/offline_tile_provider.dart';
import '../../data/tiles/tile_cache_dir.dart';
import '../../domain/flight_route.dart';
import '../../domain/geo_utils.dart';
import '../../state/flight_session_controller.dart';
import '../widgets/stats_panel.dart';

class TrackingScreen extends StatefulWidget {
  final FlightRoute route;
  const TrackingScreen({super.key, required this.route});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  late final FlightSessionController _controller;
  final _mapController = MapController();
  Directory? _tileCacheDir;
  bool _startAttempted = false;

  @override
  void initState() {
    super.initState();
    _controller = FlightSessionController(settings: context.read<AppSettings>());
    tileCacheDirectory().then((dir) {
      if (mounted) setState(() => _tileCacheDir = dir);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    if (_startAttempted) return;
    _startAttempted = true;
    final ok = await _controller.start(widget.route);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_controller.locationError ?? 'Could not start tracking.')),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.route;
    final settings = context.watch<AppSettings>();
    final routePath = GeoUtils.greatCirclePath(
      route.departure.lat,
      route.departure.lon,
      route.arrival.lat,
      route.arrival.lon,
    ).map((p) => ll.LatLng(p[0], p[1])).toList();

    final bounds = LatLngBounds.fromPoints(routePath);

    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        appBar: AppBar(title: Text(route.label)),
        body: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCameraFit: CameraFit.bounds(
                        bounds: bounds,
                        padding: const EdgeInsets.all(40),
                      ),
                    ),
                    children: [
                      if (_tileCacheDir != null)
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.pftracker.pftracker',
                          tileProvider: OfflineFirstTileProvider(cacheDir: _tileCacheDir!),
                        ),
                      PolylineLayer(polylines: [
                        Polyline(points: routePath, color: Colors.blue.withValues(alpha: 0.5), strokeWidth: 2),
                      ]),
                      Consumer<FlightSessionController>(
                        builder: (context, controller, _) {
                          final traveled = controller.samples
                              .map((s) => ll.LatLng(s.lat, s.lon))
                              .toList();
                          return PolylineLayer(polylines: [
                            if (traveled.length > 1)
                              Polyline(points: traveled, color: Colors.red, strokeWidth: 3),
                          ]);
                        },
                      ),
                      Consumer<FlightSessionController>(
                        builder: (context, controller, _) {
                          final stats = controller.stats;
                          if (stats == null) return const SizedBox.shrink();
                          final heading = stats.headingDegrees ?? 0;
                          return MarkerLayer(markers: [
                            Marker(
                              point: ll.LatLng(stats.lat, stats.lon),
                              width: 36,
                              height: 36,
                              child: Transform.rotate(
                                angle: heading * math.pi / 180,
                                child: const Icon(Icons.navigation, color: Colors.red, size: 32),
                              ),
                            ),
                          ]);
                        },
                      ),
                    ],
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Consumer<FlightSessionController>(
                      builder: (context, controller, _) => _StatusChip(controller: controller),
                    ),
                  ),
                ],
              ),
            ),
            Consumer<FlightSessionController>(
              builder: (context, controller, _) => StatsPanel(
                stats: controller.stats,
                enabledStats: settings.enabledStats,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final FlightSessionController controller;
  const _StatusChip({required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.locationError != null) {
      return Chip(
        avatar: const Icon(Icons.gps_off, size: 16, color: Colors.white),
        label: Text(controller.locationError!, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red.shade700,
      );
    }
    if (!controller.isTracking) {
      return const Chip(label: Text('Starting GPS...'));
    }
    return Chip(
      avatar: const Icon(Icons.gps_fixed, size: 16),
      label: Text(
        controller.barometerAvailability == BarometerAvailability.available
            ? 'GPS + barometer'
            : 'GPS',
      ),
    );
  }
}
