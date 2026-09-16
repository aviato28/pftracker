import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/flight_history_entry.dart';

const _historyKey = 'flight_history';

/// Caps how many past flights get kept — plenty for a personal log without
/// the stored JSON blob growing unbounded over years of use.
const _maxEntries = 200;

/// Persists a summary of each completed flight so past trips show up in a
/// log. Deliberately doesn't store GPS samples, only the final numbers —
/// keeping this cheap regardless of how long a flight was tracked.
class FlightHistoryRepository {
  Future<List<FlightHistoryEntry>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null) return const [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => FlightHistoryEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> add(FlightHistoryEntry entry) async {
    final entries = await loadAll();
    entries.insert(0, entry);
    if (entries.length > _maxEntries) {
      entries.removeRange(_maxEntries, entries.length);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_historyKey, jsonEncode(entries.map((e) => e.toJson()).toList()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}
