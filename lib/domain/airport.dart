class Airport {
  final String icao;
  final String? iata;
  final String name;
  final String city;
  final String country;
  final double lat;
  final double lon;
  final int elevationFt;

  /// IANA timezone name (e.g. "Pacific/Port_Moresby"), when known. Used for
  /// DST-aware local time / timezone-crossing stats; falls back to a
  /// longitude-based approximation when null.
  final String? ianaTimezone;

  const Airport({
    required this.icao,
    required this.iata,
    required this.name,
    required this.city,
    required this.country,
    required this.lat,
    required this.lon,
    required this.elevationFt,
    this.ianaTimezone,
  });

  String get displayCode => iata ?? icao;

  factory Airport.fromJson(Map<String, dynamic> json) {
    return Airport(
      icao: json['icao'] as String,
      iata: json['iata'] as String?,
      name: json['name'] as String,
      city: json['city'] as String? ?? '',
      country: json['country'] as String,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      elevationFt: (json['elevationFt'] as num?)?.toInt() ?? 0,
      ianaTimezone: json['tz'] as String?,
    );
  }

  @override
  String toString() => '$displayCode - $name';
}
