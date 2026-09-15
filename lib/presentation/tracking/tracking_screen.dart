import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/settings/app_settings.dart';
import '../../domain/flight_route.dart';
import '../../domain/geo_utils.dart';
import '../../state/flight_session_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/gps_status_pill.dart';
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
    final topInset = MediaQuery.paddingOf(context).top;

    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        backgroundColor: AppColors.background,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            Positioned.fill(
              bottom: 0,
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

            // back button
            Positioned(
              top: topInset + 10,
              left: 20,
              child: _HudButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ),

            // flight label
            Positioned(
              top: topInset + 10,
              left: 70,
              right: 104,
              child: Container(
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xB30F141A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: route.departure.displayCode, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const TextSpan(text: '  →  ', style: TextStyle(color: AppColors.textFaint)),
                    TextSpan(text: route.arrival.displayCode, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ]),
                  style: const TextStyle(fontSize: 14.5, color: AppColors.textPrimary),
                ),
              ),
            ),

            // GPS status
            Positioned(
              top: topInset + 10,
              right: 20,
              child: Consumer<FlightSessionController>(
                builder: (context, controller, _) => GpsStatusPill(
                  accuracyMeters: controller.stats?.gpsAccuracyM,
                  barometerAvailable: controller.barometerAvailability == BarometerAvailability.available,
                  hasError: controller.locationError != null,
                ),
              ),
            ),

            // route progress
            Positioned(
              top: topInset + 60,
              left: 20,
              right: 20,
              child: Consumer<FlightSessionController>(
                builder: (context, controller, _) {
                  final progress = controller.stats?.progressPercent;
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress != null ? (progress / 100).clamp(0.0, 1.0) : 0,
                      minHeight: 3,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                    ),
                  );
                },
              ),
            ),

            // stats sheet — height-capped with its own scroll, so turning
            // on every stat scrolls the sheet instead of overflowing it.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.52,
                ),
                child: Material(
                  color: AppColors.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 36,
                          height: 4,
                          margin: const EdgeInsets.only(top: 14, bottom: 16),
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HudButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HudButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xB30F141A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, size: 17, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
