import 'package:timezone/timezone.dart' as tz;

import 'flight_route.dart';
import 'flight_sample.dart';
import 'geo_utils.dart';

const double _metersToFeet = 3.28084;
const double _mpsToKmh = 3.6;

/// A computed snapshot of everything the UI might display, derived from
/// the route plan and the sample history collected so far. Every field is
/// nullable — either because it isn't computable yet (no fix, no prior
/// sample to diff against) or because the underlying sensor is disabled.
class FlightStats {
  final double? altitudeGpsFt;
  final double? altitudeBaroFt;
  final double? groundSpeedKmh;
  final double? headingDegrees;
  final double? verticalSpeedFtPerMin;
  final double? distanceRemainingKm;
  final double? distanceTraveledKm;
  final double? progressPercent;
  final Duration? eta;
  final Duration elapsedTime;
  final DateTime? localTimeAtDestination;
  final int? timeZonesCrossed;
  final double? gpsAccuracyM;
  final double lat;
  final double lon;

  const FlightStats({
    this.altitudeGpsFt,
    this.altitudeBaroFt,
    this.groundSpeedKmh,
    this.headingDegrees,
    this.verticalSpeedFtPerMin,
    this.distanceRemainingKm,
    this.distanceTraveledKm,
    this.progressPercent,
    this.eta,
    required this.elapsedTime,
    this.localTimeAtDestination,
    this.timeZonesCrossed,
    this.gpsAccuracyM,
    required this.lat,
    required this.lon,
  });
}

class FlightStatsEngine {
  /// Computes the current stats from the full sample history collected so
  /// far. [samples] must be non-empty and chronologically ordered.
  static FlightStats compute({
    required FlightRoute route,
    required DateTime sessionStartUtc,
    required List<FlightSample> samples,
  }) {
    final current = samples.last;
    final previous = samples.length > 1 ? samples[samples.length - 2] : null;

    final altitudeGpsFt =
        current.gpsAltitudeM != null ? current.gpsAltitudeM! * _metersToFeet : null;
    final altitudeBaroFt =
        current.baroAltitudeM != null ? current.baroAltitudeM! * _metersToFeet : null;

    final groundSpeedKmh =
        current.speedMps != null ? current.speedMps! * _mpsToKmh : null;

    double? verticalSpeedFtPerMin;
    if (previous != null) {
      final dtSeconds =
          current.timestamp.difference(previous.timestamp).inMilliseconds / 1000.0;
      final currentAlt = current.baroAltitudeM ?? current.gpsAltitudeM;
      final previousAlt = previous.baroAltitudeM ?? previous.gpsAltitudeM;
      if (dtSeconds > 0 && currentAlt != null && previousAlt != null) {
        final deltaFt = (currentAlt - previousAlt) * _metersToFeet;
        verticalSpeedFtPerMin = deltaFt / (dtSeconds / 60.0);
      }
    }

    final distanceRemainingKm = GeoUtils.distanceMeters(
          current.lat,
          current.lon,
          route.arrival.lat,
          route.arrival.lon,
        ) /
        1000.0;

    var distanceTraveledKm = 0.0;
    for (var i = 1; i < samples.length; i++) {
      distanceTraveledKm += GeoUtils.distanceMeters(
            samples[i - 1].lat,
            samples[i - 1].lon,
            samples[i].lat,
            samples[i].lon,
          ) /
          1000.0;
    }

    final totalRouteKm = GeoUtils.distanceMeters(
          route.departure.lat,
          route.departure.lon,
          route.arrival.lat,
          route.arrival.lon,
        ) /
        1000.0;
    final straightLineFromDepartureKm = GeoUtils.distanceMeters(
          route.departure.lat,
          route.departure.lon,
          current.lat,
          current.lon,
        ) /
        1000.0;
    final progressPercent = totalRouteKm > 0
        ? (straightLineFromDepartureKm / totalRouteKm * 100).clamp(0, 100)
        : null;

    Duration? eta;
    if (groundSpeedKmh != null && groundSpeedKmh > 5) {
      final hours = distanceRemainingKm / groundSpeedKmh;
      eta = Duration(seconds: (hours * 3600).round());
    }

    final elapsedTime = current.timestamp.difference(sessionStartUtc);

    final nowUtc = current.timestamp.toUtc();
    final DateTime localTimeAtDestination;
    final int timeZonesCrossed;
    final destinationOffset = _tzOffset(route.arrival.ianaTimezone, nowUtc);
    final departureOffset = _tzOffset(route.departure.ianaTimezone, nowUtc);
    if (destinationOffset != null) {
      localTimeAtDestination = nowUtc.add(destinationOffset);
    } else {
      // Longitude-based approximation when the airport's IANA zone is
      // unknown: real timezone boundaries don't follow meridians exactly,
      // but this needs no timezone database lookup.
      final approxOffsetHours = (route.arrival.lon / 15.0).round();
      localTimeAtDestination = nowUtc.add(Duration(hours: approxOffsetHours));
    }
    if (destinationOffset != null && departureOffset != null) {
      timeZonesCrossed =
          ((destinationOffset - departureOffset).inMinutes / 60.0).round().abs();
    } else {
      timeZonesCrossed =
          ((route.arrival.lon - route.departure.lon) / 15.0).round().abs();
    }

    return FlightStats(
      altitudeGpsFt: altitudeGpsFt,
      altitudeBaroFt: altitudeBaroFt,
      groundSpeedKmh: groundSpeedKmh,
      headingDegrees: current.headingDegrees,
      verticalSpeedFtPerMin: verticalSpeedFtPerMin,
      distanceRemainingKm: distanceRemainingKm,
      distanceTraveledKm: distanceTraveledKm,
      progressPercent: progressPercent?.toDouble(),
      eta: eta,
      elapsedTime: elapsedTime,
      localTimeAtDestination: localTimeAtDestination,
      timeZonesCrossed: timeZonesCrossed,
      gpsAccuracyM: current.gpsAccuracyM,
      lat: current.lat,
      lon: current.lon,
    );
  }
}

extension SpeedConversions on double {
  double get kmhToKnots => this / 1.852;
}

/// UTC offset (DST-aware, for the given instant) of an IANA zone name, or
/// null if the name is missing/unrecognized — callers fall back to the
/// longitude approximation in that case. Requires
/// `tz.initializeTimeZones()` to have been called at app startup.
Duration? _tzOffset(String? ianaName, DateTime instantUtc) {
  if (ianaName == null) return null;
  try {
    final location = tz.getLocation(ianaName);
    return tz.TZDateTime.from(instantUtc, location).timeZoneOffset;
  } catch (_) {
    return null;
  }
}
