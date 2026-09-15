import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/barometer/barometer_service.dart';
import '../data/location/location_service.dart';
import '../data/settings/app_settings.dart';
import '../domain/flight_route.dart';
import '../domain/flight_sample.dart';
import '../domain/flight_stats.dart';
import '../domain/geo_utils.dart';

enum BarometerAvailability { unknown, available, unavailable }

/// How long without a new GPS fix before the UI should say so explicitly,
/// rather than silently keep showing the last known numbers.
const gpsSignalLostThreshold = Duration(seconds: 20);

enum GpsSignalState {
  /// Tracking hasn't produced a single fix yet (just started, or the GPS
  /// chip is still doing a cold start without assisted-GPS data — which
  /// takes longer in airplane mode).
  acquiring,

  /// Fixes are arriving normally.
  active,

  /// Had a fix before, but nothing for [gpsSignalLostThreshold] or more —
  /// e.g. weak reception away from a window, mid-turn antenna shadowing.
  lost,
}

/// Orchestrates a single tracking session: owns the GPS and barometer
/// streams, merges their readings into [FlightSample]s, and exposes the
/// derived [FlightStats] to the UI. This is the only place in the app that
/// touches the sensor services directly.
class FlightSessionController extends ChangeNotifier {
  final AppSettings settings;
  final LocationService _locationService;
  final BarometerService _barometerService;

  FlightRoute? route;
  DateTime? _sessionStartUtc;
  final List<FlightSample> _samples = [];
  StreamSubscription<FlightSample>? _positionSub;
  StreamSubscription<double>? _pressureSub;
  Timer? _watchdogTimer;
  double? _latestPressureHpa;
  DateTime? _lastSampleAtLocal;

  BarometerAvailability barometerAvailability = BarometerAvailability.unknown;
  String? locationError;
  bool get isTracking => _positionSub != null;
  DateTime? get sessionStartUtc => _sessionStartUtc;

  GpsSignalState get gpsSignalState {
    final lastSample = _lastSampleAtLocal;
    if (lastSample == null) return GpsSignalState.acquiring;
    final since = DateTime.now().difference(lastSample);
    return since > gpsSignalLostThreshold ? GpsSignalState.lost : GpsSignalState.active;
  }

  Duration? get timeSinceLastFix {
    final lastSample = _lastSampleAtLocal;
    return lastSample == null ? null : DateTime.now().difference(lastSample);
  }

  FlightSessionController({
    required this.settings,
    LocationService? locationService,
    BarometerService? barometerService,
  })  : _locationService = locationService ?? LocationService(),
        _barometerService = barometerService ?? BarometerService();

  List<FlightSample> get samples => List.unmodifiable(_samples);

  FlightStats? get stats {
    final currentRoute = route;
    final startUtc = _sessionStartUtc;
    if (currentRoute == null || startUtc == null || _samples.isEmpty) {
      return null;
    }
    return FlightStatsEngine.compute(
      route: currentRoute,
      sessionStartUtc: startUtc,
      samples: _samples,
    );
  }

  /// Starts (or resumes) tracking. Pass [resumeSessionStartUtc] — the
  /// original start time of a session that was persisted before the app
  /// got killed — so elapsed time keeps counting from departure rather
  /// than restarting at zero. GPS reacquires the current position
  /// immediately either way; only the flown-track breadcrumb is lost,
  /// starting fresh from wherever the aircraft is now.
  Future<bool> start(FlightRoute flightRoute, {DateTime? resumeSessionStartUtc}) async {
    bool granted;
    try {
      granted = await _locationService.ensurePermission();
    } catch (e) {
      locationError = 'Could not access location services: $e';
      notifyListeners();
      return false;
    }
    if (!granted) {
      locationError =
          'Location permission (and location services) are required to track your flight.';
      notifyListeners();
      return false;
    }

    route = flightRoute;
    _sessionStartUtc = resumeSessionStartUtc ?? DateTime.now().toUtc();
    _samples.clear();
    locationError = null;

    _positionSub = _locationService.positionStream().listen(
      _onPosition,
      onError: (Object e) {
        locationError = 'Location error: $e';
        notifyListeners();
      },
    );

    _pressureSub = _barometerService.pressureHpaStream().listen(
      (hpa) {
        _latestPressureHpa = hpa;
        if (barometerAvailability != BarometerAvailability.available) {
          barometerAvailability = BarometerAvailability.available;
          notifyListeners();
        }
      },
      onError: (Object e) {
        barometerAvailability = BarometerAvailability.unavailable;
        notifyListeners();
      },
    );

    // Ticks the UI independently of new fixes arriving, so "time since
    // last fix" (and the acquiring/active/lost state derived from it) is
    // live even while nothing new is coming in — that's the whole point.
    _watchdogTimer = Timer.periodic(const Duration(seconds: 3), (_) => notifyListeners());

    notifyListeners();
    return true;
  }

  void _onPosition(FlightSample sample) {
    final pressure = _latestPressureHpa;
    final merged = pressure != null
        ? sample.copyWith(
            baroAltitudeM: GeoUtils.altitudeFromPressure(
              pressure,
              seaLevelHpa: settings.qnhHpa,
            ),
          )
        : sample;
    _samples.add(merged);
    _lastSampleAtLocal = DateTime.now();
    notifyListeners();
  }

  void stop() {
    _positionSub?.cancel();
    _pressureSub?.cancel();
    _watchdogTimer?.cancel();
    _positionSub = null;
    _pressureSub = null;
    _watchdogTimer = null;
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
