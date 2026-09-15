import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../domain/airport.dart';

/// In-memory lookup over the bundled airport dataset (OpenFlights/
/// OurAirports, ~7.7k airports with ICAO codes). Loaded once and kept in
/// memory — small enough that a database would be overkill.
class AirportRepository {
  List<Airport>? _airports;

  Future<List<Airport>> _load() async {
    if (_airports != null) return _airports!;
    final raw = await rootBundle.loadString('assets/data/airports.json');
    final list = jsonDecode(raw) as List<dynamic>;
    _airports = list
        .map((e) => Airport.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return _airports!;
  }

  /// Case-insensitive search over ICAO/IATA code, name, and city.
  /// Prioritizes exact code matches, then prefix matches, then substrings.
  Future<List<Airport>> search(String query, {int limit = 25}) async {
    final airports = await _load();
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];

    final exact = <Airport>[];
    final prefix = <Airport>[];
    final contains = <Airport>[];

    for (final airport in airports) {
      final iata = airport.iata?.toLowerCase();
      final icao = airport.icao.toLowerCase();
      final name = airport.name.toLowerCase();
      final city = airport.city.toLowerCase();

      if (iata == q || icao == q) {
        exact.add(airport);
      } else if (iata?.startsWith(q) == true ||
          icao.startsWith(q) ||
          name.startsWith(q) ||
          city.startsWith(q)) {
        prefix.add(airport);
      } else if (name.contains(q) || city.contains(q)) {
        contains.add(airport);
      }
    }

    return [...exact, ...prefix, ...contains].take(limit).toList();
  }

  Future<Airport?> byIataOrIcao(String code) async {
    final airports = await _load();
    final q = code.trim().toUpperCase();
    for (final airport in airports) {
      if (airport.iata == q || airport.icao == q) return airport;
    }
    return null;
  }
}
