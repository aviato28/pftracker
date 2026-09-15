import 'dart:io' show Platform;

import 'package:geolocator/geolocator.dart';

import '../../domain/flight_sample.dart';

/// Thin wrapper around `geolocator`. GPS is receive-only, so all of this
/// works with the device in airplane mode as long as GPS/location is left
/// on — no cell or wifi connectivity required.
class LocationService {
  /// Ensures location services are on and permission is granted. Returns
  /// false if the user needs to be sent to settings.
  Future<bool> ensurePermission({bool requestBackground = true}) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    if (requestBackground && permission != LocationPermission.always) {
      // Best-effort: lets tracking continue if the screen locks mid-flight.
      // Falls back silently to whileInUse if the user declines.
      permission = await Geolocator.requestPermission();
    }
    return true;
  }

  /// Streams position updates suited to aircraft speeds/altitudes. Emits
  /// roughly every [intervalSeconds] or every [distanceFilterMeters],
  /// whichever comes first.
  Stream<FlightSample> positionStream({
    int intervalSeconds = 3,
    int distanceFilterMeters = 50,
  }) {
    late final LocationSettings settings;
    if (Platform.isAndroid) {
      settings = AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: distanceFilterMeters,
        intervalDuration: Duration(seconds: intervalSeconds),
        // Google Play Services' FusedLocationProviderClient (the default)
        // is a hybrid provider that leans on wifi/cell signal confidence
        // and can simply stop reporting fixes when those are absent and
        // GPS reception is weak — exactly the in-flight, airplane-mode,
        // metal-fuselage scenario this app lives in. Forcing the legacy
        // LocationManager talks to the raw GPS chip directly instead.
        forceLocationManager: true,
        // Mean-sea-level altitude from the GPS chip's own NMEA sentences,
        // only available via the raw LocationManager — closer to an
        // aviation altimeter reference than the default WGS84 ellipsoid
        // altitude, which can be off by tens of meters.
        useMSLAltitude: true,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'pftracker is tracking your flight',
          notificationText: 'Position, altitude and speed are updating live.',
          enableWakeLock: true,
        ),
      );
    } else if (Platform.isIOS) {
      settings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        activityType: ActivityType.airborne,
        distanceFilter: distanceFilterMeters,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
      );
    } else {
      settings = LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: distanceFilterMeters,
      );
    }

    return Geolocator.getPositionStream(locationSettings: settings)
        .map(_toFlightSample);
  }

  FlightSample _toFlightSample(Position position) {
    return FlightSample(
      timestamp: position.timestamp,
      lat: position.latitude,
      lon: position.longitude,
      gpsAltitudeM: position.altitude,
      speedMps: position.speed >= 0 ? position.speed : null,
      headingDegrees: position.heading >= 0 ? position.heading : null,
      gpsAccuracyM: position.accuracy,
    );
  }
}
