import 'package:intl/intl.dart';

import '../../domain/flight_stats.dart';
import '../../domain/stat_id.dart';

final _timeFormat = DateFormat('HH:mm');
final _numberFormat = NumberFormat.decimalPattern();

/// (value, unit) display pair for a stat, or null if it can't be shown yet
/// (e.g. no GPS fix, or the source sensor is unavailable/disabled).
(String, String)? formatStat(StatId id, FlightStats stats) {
  switch (id) {
    case StatId.altitudeGps:
      if (stats.altitudeGpsFt == null) return null;
      return (_numberFormat.format(stats.altitudeGpsFt!.round()), 'ft');
    case StatId.altitudeBaro:
      if (stats.altitudeBaroFt == null) return null;
      return (_numberFormat.format(stats.altitudeBaroFt!.round()), 'ft');
    case StatId.groundSpeed:
      if (stats.groundSpeedKmh == null) return null;
      return (stats.groundSpeedKmh!.round().toString(), 'km/h');
    case StatId.heading:
      if (stats.headingDegrees == null) return null;
      return (stats.headingDegrees!.round().toString(), '°');
    case StatId.verticalSpeed:
      if (stats.verticalSpeedFtPerMin == null) return null;
      final v = stats.verticalSpeedFtPerMin!.round();
      return ('${v > 0 ? '+' : ''}$v', 'ft/min');
    case StatId.distanceRemaining:
      if (stats.distanceRemainingKm == null) return null;
      return (stats.distanceRemainingKm!.round().toString(), 'km');
    case StatId.distanceTraveled:
      if (stats.distanceTraveledKm == null) return null;
      return (stats.distanceTraveledKm!.round().toString(), 'km');
    case StatId.progressPercent:
      if (stats.progressPercent == null) return null;
      return (stats.progressPercent!.round().toString(), '%');
    case StatId.eta:
      if (stats.eta == null) return null;
      return (_formatDuration(stats.eta!), '');
    case StatId.elapsedTime:
      return (_formatDuration(stats.elapsedTime), '');
    case StatId.localTimeDestination:
      if (stats.localTimeAtDestination == null) return null;
      return (_timeFormat.format(stats.localTimeAtDestination!), 'local');
    case StatId.timeZonesCrossed:
      if (stats.timeZonesCrossed == null) return null;
      return (stats.timeZonesCrossed.toString(), 'zones');
    case StatId.coordinates:
      return (
        '${stats.lat.toStringAsFixed(3)}, ${stats.lon.toStringAsFixed(3)}',
        ''
      );
  }
}

String _formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  return '${h}h ${m.toString().padLeft(2, '0')}m';
}
