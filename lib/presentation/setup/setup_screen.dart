import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/airports/airport_repository.dart';
import '../../data/routes/route_lookup_service.dart';
import '../../data/session/active_session_repository.dart';
import '../../data/settings/app_settings.dart';
import '../../data/update/app_update_service.dart';
import '../../data/update/update_info.dart';
import '../../domain/airport.dart';
import '../../domain/flight_route.dart';
import '../../domain/geo_utils.dart';
import '../guide/guide_screen.dart';
import '../settings/settings_screen.dart';
import '../theme/app_theme.dart';
import '../tracking/tracking_screen.dart';
import '../widgets/nav_chevron.dart';
import '../widgets/update_prompt.dart';
import 'airport_search_field.dart';

/// Purely for the route-preview card's rough time estimate — we don't
/// know the aircraft's actual speed until tracking starts, so this uses a
/// typical commercial cruise speed and is labelled "est." accordingly.
const _typicalCruiseKmh = 850.0;

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _airportRepository = AirportRepository();
  final _flightNumberController = TextEditingController();

  bool _byFlightNumber = false;
  Airport? _departure;
  Airport? _arrival;
  FlightRoute? _route;
  bool _lookingUp = false;
  String? _lookupError;
  UpdateInfo? _availableUpdate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForActiveSession();
      _checkForUpdate();
    });
  }

  Future<void> _checkForUpdate() async {
    final service = AppUpdateService();
    final update = await service.checkForUpdate();
    service.dispose();
    if (!mounted || update == null) return;
    final settings = context.read<AppSettings>();
    if (update.buildNumber <= settings.dismissedUpdateBuild) return;
    setState(() => _availableUpdate = update);
  }

  @override
  void dispose() {
    _flightNumberController.dispose();
    super.dispose();
  }

  Future<void> _checkForActiveSession() async {
    final repository = ActiveSessionRepository(airportRepository: _airportRepository);
    final session = await repository.load();
    if (session == null || !mounted) return;

    final elapsed = DateTime.now().toUtc().difference(session.sessionStartUtc);
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes.remainder(60);

    final resume = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Resume tracking?'),
        content: Text(
          '${session.route.label} was still tracking '
          '(started ${hours}h ${minutes}m ago) when the app closed.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Discard')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Resume')),
        ],
      ),
    );

    if (!mounted) return;
    if (resume == true) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TrackingScreen(route: session.route, resumeStartUtc: session.sessionStartUtc),
        ),
      );
    } else {
      await repository.clear();
    }
  }

  void _tryBuildManualRoute() {
    if (_departure != null && _arrival != null) {
      setState(() {
        _route = manualRoute(departure: _departure!, arrival: _arrival!);
        _lookupError = null;
      });
    }
  }

  void _swap() {
    setState(() {
      final d = _departure;
      _departure = _arrival;
      _arrival = d;
    });
    _tryBuildManualRoute();
  }

  Future<void> _lookupFlightNumber() async {
    final settings = context.read<AppSettings>();
    final flightNumber = _flightNumberController.text.trim();
    if (flightNumber.isEmpty) return;

    setState(() {
      _lookingUp = true;
      _lookupError = null;
    });

    final service = AeroDataBoxRouteLookupService(
      apiKey: settings.flightApiKey,
      airportRepository: _airportRepository,
    );
    try {
      final route = await service.lookupByFlightNumber(flightNumber);
      setState(() => _route = route);
    } on FlightRouteLookupException catch (e) {
      setState(() => _lookupError = e.message);
    } catch (e) {
      setState(() => _lookupError = 'Lookup failed: $e');
    } finally {
      service.dispose();
      if (mounted) setState(() => _lookingUp = false);
    }
  }

  void _startTracking() {
    final route = _route;
    if (route == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TrackingScreen(route: route)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // faint decorative radar rings, purely atmospheric
          const Positioned.fill(child: _RadarBackdrop()),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
              children: [
                if (_availableUpdate != null)
                  UpdateBanner(
                    info: _availableUpdate!,
                    onDismiss: () {
                      context.read<AppSettings>().dismissedUpdateBuild = _availableUpdate!.buildNumber;
                      setState(() => _availableUpdate = null);
                    },
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const NavChevron(size: 26),
                        const SizedBox(width: 10),
                        const Text(
                          'pftracker',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19, letterSpacing: -0.2),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _IconSquareButton(
                          icon: Icons.help_outline_rounded,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const GuideScreen()),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _IconSquareButton(
                          icon: Icons.tune_rounded,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Set your route now — tracking itself needs no signal.',
                  style: TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.4),
                ),
                const SizedBox(height: 28),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, icon: Icon(Icons.flight_takeoff), label: Text('Airports')),
                    ButtonSegment(value: true, icon: Icon(Icons.confirmation_number_outlined), label: Text('Flight number')),
                  ],
                  selected: {_byFlightNumber},
                  onSelectionChanged: (s) => setState(() {
                    _byFlightNumber = s.first;
                    _route = null;
                    _lookupError = null;
                  }),
                ),
                const SizedBox(height: 26),
                if (!_byFlightNumber)
                  _AirportPickerCards(
                    repository: _airportRepository,
                    departure: _departure,
                    arrival: _arrival,
                    onDeparture: (a) {
                      _departure = a;
                      _tryBuildManualRoute();
                    },
                    onArrival: (a) {
                      _arrival = a;
                      _tryBuildManualRoute();
                    },
                    onSwap: _swap,
                  )
                else
                  _FlightNumberEntry(
                    controller: _flightNumberController,
                    loading: _lookingUp,
                    error: _lookupError,
                    onSubmit: _lookupFlightNumber,
                  ),
                if (_route != null) ...[
                  const SizedBox(height: 22),
                  _RoutePreviewCard(route: _route!),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _route != null ? _startTracking : null,
                  icon: const Icon(Icons.flight_takeoff, size: 19),
                  label: const Text('Start Tracking'),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Uses GPS only — works fully offline, even in airplane mode.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: AppColors.textFaint, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AirportPickerCards extends StatelessWidget {
  final AirportRepository repository;
  final Airport? departure;
  final Airport? arrival;
  final ValueChanged<Airport> onDeparture;
  final ValueChanged<Airport> onArrival;
  final VoidCallback onSwap;

  const _AirportPickerCards({
    required this.repository,
    required this.departure,
    required this.arrival,
    required this.onDeparture,
    required this.onArrival,
    required this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16), bottom: Radius.circular(4)),
              ),
              child: AirportSearchField(
                label: 'Departure',
                icon: Icons.flight_takeoff,
                repository: repository,
                value: departure,
                onSelected: onDeparture,
              ),
            ),
            const SizedBox(height: 1),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4), bottom: Radius.circular(16)),
              ),
              child: AirportSearchField(
                label: 'Arrival',
                icon: Icons.flight_land,
                repository: repository,
                value: arrival,
                onSelected: onArrival,
              ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          top: 0,
          bottom: 0,
          child: Center(
            child: Material(
              color: const Color(0xFF1B2530),
              shape: const CircleBorder(side: BorderSide(color: Color(0xFF2A3743))),
              elevation: 4,
              shadowColor: Colors.black54,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onSwap,
                child: const SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(Icons.swap_vert_rounded, size: 18, color: AppColors.accent),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FlightNumberEntry extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final String? error;
  final VoidCallback onSubmit;

  const _FlightNumberEntry({
    required this.controller,
    required this.loading,
    required this.error,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Flight number',
            hintText: 'e.g. UA123',
            prefixIcon: Icon(Icons.confirmation_number_outlined),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: loading ? null : onSubmit,
          icon: loading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onAccent),
                )
              : const Icon(Icons.search, size: 19),
          label: Text(loading ? 'Looking up…' : 'Look up route'),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(error!, style: const TextStyle(color: AppColors.error)),
        ],
      ],
    );
  }
}

class _RoutePreviewCard extends StatelessWidget {
  final FlightRoute route;
  const _RoutePreviewCard({required this.route});

  @override
  Widget build(BuildContext context) {
    final units = context.watch<AppSettings>().unitSystem;
    final distanceKm = GeoUtils.distanceMeters(
          route.departure.lat,
          route.departure.lon,
          route.arrival.lat,
          route.arrival.lon,
        ) /
        1000.0;
    final displayDistance = units.distanceFromKm(distanceKm).round();
    final hours = distanceKm / _typicalCruiseKmh;
    final h = hours.floor();
    final m = ((hours - h) * 60).round();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(route.departure.displayCode, style: dataTextStyle(size: 20, weight: FontWeight.w800)),
              Text(route.arrival.displayCode, style: dataTextStyle(size: 20, weight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _DashedLine()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Transform.rotate(angle: 1.5708, child: const NavChevron(size: 20)),
              ),
              Expanded(child: _DashedLine()),
            ],
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              children: [
                TextSpan(text: '$displayDistance ${units.distanceUnit} · est. '),
                TextSpan(
                  text: '${h}h ${m.toString().padLeft(2, '0')}m',
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 1),
      painter: _DashPainter(),
    );
  }
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    const dashWidth = 5.0;
    const gap = 4.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _IconSquareButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconSquareButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(width: 40, height: 40, child: Icon(icon, size: 19, color: AppColors.textMuted)),
      ),
    );
  }
}

class _RadarBackdrop extends StatelessWidget {
  const _RadarBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: const Alignment(0, 0.05),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 520,
              height: 520,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.05)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
