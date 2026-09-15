import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/flight_route.dart';
import '../airports/airport_repository.dart';

const _departureKey = 'active_session_departure_icao';
const _arrivalKey = 'active_session_arrival_icao';
const _flightNumberKey = 'active_session_flight_number';
const _startUtcKey = 'active_session_start_utc';

class ActiveSession {
  final FlightRoute route;
  final DateTime sessionStartUtc;
  const ActiveSession({required this.route, required this.sessionStartUtc});
}

/// Persists just enough about the in-progress tracking session — the
/// route and when it started — to offer resuming it if the app process
/// gets killed mid-flight (an accidental swipe-away, Android reclaiming
/// memory, a battery-optimization kill) and relaunched. Deliberately
/// doesn't persist GPS samples: on resume, GPS reacquires the real
/// current position immediately, which is simpler and always accurate:
/// only the flown-track breadcrumb starts fresh from the resume point,
/// while elapsed time and route stay correct.
class ActiveSessionRepository {
  final AirportRepository _airportRepository;

  ActiveSessionRepository({AirportRepository? airportRepository})
      : _airportRepository = airportRepository ?? AirportRepository();

  Future<void> save({required FlightRoute route, required DateTime sessionStartUtc}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_departureKey, route.departure.icao);
    await prefs.setString(_arrivalKey, route.arrival.icao);
    final flightNumber = route.flightNumber;
    if (flightNumber != null) {
      await prefs.setString(_flightNumberKey, flightNumber);
    } else {
      await prefs.remove(_flightNumberKey);
    }
    await prefs.setString(_startUtcKey, sessionStartUtc.toIso8601String());
  }

  Future<ActiveSession?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final departureIcao = prefs.getString(_departureKey);
    final arrivalIcao = prefs.getString(_arrivalKey);
    final startUtcRaw = prefs.getString(_startUtcKey);
    if (departureIcao == null || arrivalIcao == null || startUtcRaw == null) {
      return null;
    }

    final startUtc = DateTime.tryParse(startUtcRaw);
    if (startUtc == null) return null;

    final departure = await _airportRepository.byIataOrIcao(departureIcao);
    final arrival = await _airportRepository.byIataOrIcao(arrivalIcao);
    if (departure == null || arrival == null) return null;

    return ActiveSession(
      route: FlightRoute(
        departure: departure,
        arrival: arrival,
        flightNumber: prefs.getString(_flightNumberKey),
      ),
      sessionStartUtc: startUtc,
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_departureKey);
    await prefs.remove(_arrivalKey);
    await prefs.remove(_flightNumberKey);
    await prefs.remove(_startUtcKey);
  }
}
