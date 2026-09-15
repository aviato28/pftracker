import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/airport.dart';
import '../../domain/flight_route.dart';
import '../airports/airport_repository.dart';

class FlightRouteLookupException implements Exception {
  final String message;
  FlightRouteLookupException(this.message);
  @override
  String toString() => message;
}

/// Resolves a flight number (e.g. "UA123") to a [FlightRoute] using an
/// online schedule API. Must be run before departure, while there's still
/// connectivity — the whole point of the app is that nothing after this
/// needs the network.
abstract class FlightRouteLookupService {
  Future<FlightRoute> lookupByFlightNumber(String flightNumber, {DateTime? date});
}

/// AeroDataBox (via RapidAPI) implementation. Requires an API key —
/// https://rapidapi.com/aedbx-aedbx/api/aerodatabox — pass it in via
/// `--dart-define=AERODATABOX_API_KEY=...` or wire your own key storage.
///
/// NOTE: the response parsing below follows AeroDataBox's documented
/// flight-number-search schema as of this writing; verify field names
/// against the live API before shipping, since third-party schemas do
/// drift. This class intentionally throws a clear, catchable exception
/// rather than failing silently if the key is missing or a field is
/// absent, so the UI can fall back to manual airport entry.
class AeroDataBoxRouteLookupService implements FlightRouteLookupService {
  final String apiKey;
  final AirportRepository airportRepository;
  final http.Client _client;

  AeroDataBoxRouteLookupService({
    required this.apiKey,
    required this.airportRepository,
    http.Client? client,
  }) : _client = client ?? http.Client();

  @override
  Future<FlightRoute> lookupByFlightNumber(
    String flightNumber, {
    DateTime? date,
  }) async {
    if (apiKey.isEmpty) {
      throw FlightRouteLookupException(
        'No flight-lookup API key configured. Enter departure/arrival '
        'airports manually instead.',
      );
    }

    final day = (date ?? DateTime.now()).toUtc();
    final dateStr =
        '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    final uri = Uri.https(
      'aerodatabox.p.rapidapi.com',
      '/flights/number/${flightNumber.trim()}/$dateStr',
    );

    final response = await _client.get(uri, headers: {
      'X-RapidAPI-Key': apiKey,
      'X-RapidAPI-Host': 'aerodatabox.p.rapidapi.com',
    });

    if (response.statusCode != 200) {
      throw FlightRouteLookupException(
        'Flight lookup failed (${response.statusCode}). '
        'Enter departure/arrival airports manually instead.',
      );
    }

    final body = jsonDecode(response.body);
    final flights = body is List ? body : [body];
    if (flights.isEmpty) {
      throw FlightRouteLookupException('No flight found for "$flightNumber" on $dateStr.');
    }

    final flight = flights.first as Map<String, dynamic>;
    final departureIcao = flight['departure']?['airport']?['icao'] as String?;
    final arrivalIcao = flight['arrival']?['airport']?['icao'] as String?;
    if (departureIcao == null || arrivalIcao == null) {
      throw FlightRouteLookupException(
        'Flight lookup response was missing airport codes. '
        'Enter departure/arrival airports manually instead.',
      );
    }

    final departure = await airportRepository.byIataOrIcao(departureIcao);
    final arrival = await airportRepository.byIataOrIcao(arrivalIcao);
    if (departure == null || arrival == null) {
      throw FlightRouteLookupException(
        'Flight lookup returned an airport not in the local database.',
      );
    }

    return FlightRoute(
      departure: departure,
      arrival: arrival,
      flightNumber: flightNumber.trim().toUpperCase(),
      scheduledDepartureUtc: _parseDate(flight['departure']?['scheduledTimeUtc']),
      scheduledArrivalUtc: _parseDate(flight['arrival']?['scheduledTimeUtc']),
    );
  }

  DateTime? _parseDate(dynamic value) {
    if (value is! String) return null;
    return DateTime.tryParse(value);
  }

  void dispose() => _client.close();
}

/// Builds a [FlightRoute] directly from two chosen airports — the fully
/// offline-friendly path that needs no API key at all.
FlightRoute manualRoute({required Airport departure, required Airport arrival}) {
  return FlightRoute(departure: departure, arrival: arrival);
}
