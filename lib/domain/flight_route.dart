import 'airport.dart';

/// A planned route for the current tracking session. Built either from a
/// manually chosen departure/arrival airport pair, or from a flight-number
/// lookup that resolves to the same shape.
class FlightRoute {
  final Airport departure;
  final Airport arrival;
  final String? flightNumber;
  final DateTime? scheduledDepartureUtc;
  final DateTime? scheduledArrivalUtc;

  const FlightRoute({
    required this.departure,
    required this.arrival,
    this.flightNumber,
    this.scheduledDepartureUtc,
    this.scheduledArrivalUtc,
  });

  String get label => flightNumber != null
      ? '$flightNumber (${departure.displayCode} → ${arrival.displayCode})'
      : '${departure.displayCode} → ${arrival.displayCode}';
}
