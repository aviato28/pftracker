/// One point-in-time reading of the aircraft's own position/motion,
/// merged from GPS and (optionally) the barometric sensor.
class FlightSample {
  final DateTime timestamp;
  final double lat;
  final double lon;
  final double? gpsAltitudeM;
  final double? baroAltitudeM;
  final double? speedMps;
  final double? headingDegrees;
  final double? gpsAccuracyM;

  const FlightSample({
    required this.timestamp,
    required this.lat,
    required this.lon,
    this.gpsAltitudeM,
    this.baroAltitudeM,
    this.speedMps,
    this.headingDegrees,
    this.gpsAccuracyM,
  });

  FlightSample copyWith({double? baroAltitudeM}) {
    return FlightSample(
      timestamp: timestamp,
      lat: lat,
      lon: lon,
      gpsAltitudeM: gpsAltitudeM,
      baroAltitudeM: baroAltitudeM ?? this.baroAltitudeM,
      speedMps: speedMps,
      headingDegrees: headingDegrees,
      gpsAccuracyM: gpsAccuracyM,
    );
  }
}
