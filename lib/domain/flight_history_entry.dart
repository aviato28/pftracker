/// A summary of one completed flight, saved once tracking ends. Stores
/// already-resolved display strings rather than airport codes to look up
/// later — this is read-only history, so there's no need to reconstruct a
/// trackable [FlightRoute] from it, and it stays valid even if the bundled
/// airport dataset changes in a future release.
class FlightHistoryEntry {
  final String departureCode;
  final String departureCity;
  final String arrivalCode;
  final String arrivalCity;
  final String? flightNumber;
  final DateTime sessionStartUtc;
  final DateTime sessionEndUtc;
  final double? maxAltitudeFt;
  final double? maxGroundSpeedKmh;
  final double? distanceTraveledKm;

  const FlightHistoryEntry({
    required this.departureCode,
    required this.departureCity,
    required this.arrivalCode,
    required this.arrivalCity,
    this.flightNumber,
    required this.sessionStartUtc,
    required this.sessionEndUtc,
    this.maxAltitudeFt,
    this.maxGroundSpeedKmh,
    this.distanceTraveledKm,
  });

  Duration get duration => sessionEndUtc.difference(sessionStartUtc);

  String get routeLabel => flightNumber != null
      ? '$flightNumber ($departureCode → $arrivalCode)'
      : '$departureCode → $arrivalCode';

  Map<String, dynamic> toJson() => {
        'departureCode': departureCode,
        'departureCity': departureCity,
        'arrivalCode': arrivalCode,
        'arrivalCity': arrivalCity,
        'flightNumber': flightNumber,
        'sessionStartUtc': sessionStartUtc.toIso8601String(),
        'sessionEndUtc': sessionEndUtc.toIso8601String(),
        'maxAltitudeFt': maxAltitudeFt,
        'maxGroundSpeedKmh': maxGroundSpeedKmh,
        'distanceTraveledKm': distanceTraveledKm,
      };

  factory FlightHistoryEntry.fromJson(Map<String, dynamic> json) => FlightHistoryEntry(
        departureCode: json['departureCode'] as String,
        departureCity: json['departureCity'] as String,
        arrivalCode: json['arrivalCode'] as String,
        arrivalCity: json['arrivalCity'] as String,
        flightNumber: json['flightNumber'] as String?,
        sessionStartUtc: DateTime.parse(json['sessionStartUtc'] as String),
        sessionEndUtc: DateTime.parse(json['sessionEndUtc'] as String),
        maxAltitudeFt: (json['maxAltitudeFt'] as num?)?.toDouble(),
        maxGroundSpeedKmh: (json['maxGroundSpeedKmh'] as num?)?.toDouble(),
        distanceTraveledKm: (json['distanceTraveledKm'] as num?)?.toDouble(),
      );
}
