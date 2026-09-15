/// Which units to display speed/distance/altitude in. Everything computed
/// by [FlightStatsEngine] stays in one canonical set of units (feet, km/h,
/// km) — conversion for display happens here, at the edge.
enum UnitSystem {
  metric('Metric', altitudeUnit: 'm', speedUnit: 'km/h', distanceUnit: 'km'),
  imperial('Imperial', altitudeUnit: 'ft', speedUnit: 'mph', distanceUnit: 'mi'),
  aviation('Aviation', altitudeUnit: 'ft', speedUnit: 'kt', distanceUnit: 'nm');

  final String label;
  final String altitudeUnit;
  final String speedUnit;
  final String distanceUnit;

  const UnitSystem(
    this.label, {
    required this.altitudeUnit,
    required this.speedUnit,
    required this.distanceUnit,
  });

  double altitudeFromFeet(double feet) => this == UnitSystem.metric ? feet / 3.28084 : feet;

  double speedFromKmh(double kmh) {
    switch (this) {
      case UnitSystem.metric:
        return kmh;
      case UnitSystem.imperial:
        return kmh / 1.609344;
      case UnitSystem.aviation:
        return kmh / 1.852;
    }
  }

  double distanceFromKm(double km) {
    switch (this) {
      case UnitSystem.metric:
        return km;
      case UnitSystem.imperial:
        return km / 1.609344;
      case UnitSystem.aviation:
        return km / 1.852;
    }
  }
}
