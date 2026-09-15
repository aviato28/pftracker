import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/settings/app_settings.dart';
import '../../domain/flight_route.dart';
import '../../domain/geo_utils.dart';
import '../../state/flight_session_controller.dart';
import '../widgets/stats_panel.dart';
import 'world_map_view.dart';

class TrackingScreen extends StatefulWidget {
  final FlightRoute route;
  const TrackingScreen({super.key, required this.route});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  late final FlightSessionController _controller;
  bool _startAttempted = false;

  @override
  void initState() {
    super.initState();
    _controller = FlightSessionController(settings: context.read<AppSettings>());
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
    );

    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        appBar: AppBar(
          title: Text(route.label),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Consumer<FlightSessionController>(
                  builder: (context, controller, _) => _StatusChip(controller: controller),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Consumer<FlightSessionController>(
                builder: (context, controller, _) {
                  final stats = controller.stats;
                  return WorldMapView(
                    routeLatLon: routePath,
                    traveledLatLon: controller.samples.map((s) => [s.lat, s.lon]).toList(),
                    currentLat: stats?.lat,
                    currentLon: stats?.lon,
                    headingDegrees: stats?.headingDegrees,
                  );
                },
              ),
            ),
            Material(
              elevation: 8,
              color: Theme.of(context).colorScheme.surface,
              child: SafeArea(
                top: false,
                child: Consumer<FlightSessionController>(
                  builder: (context, controller, _) => StatsPanel(
                    stats: controller.stats,
                    enabledStats: settings.enabledStats,
                  ),
                ),
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
        label: const Text('GPS error', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red.shade700,
        visualDensity: VisualDensity.compact,
      );
    }
    if (!controller.isTracking) {
      return const Chip(
        label: Text('Starting GPS…'),
        visualDensity: VisualDensity.compact,
      );
    }
    return Chip(
      avatar: Icon(
        Icons.gps_fixed,
        size: 16,
        color: Theme.of(context).colorScheme.primary,
      ),
      label: Text(
        controller.barometerAvailability == BarometerAvailability.available
            ? 'GPS + baro'
            : 'GPS',
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}
