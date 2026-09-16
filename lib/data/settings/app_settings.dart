import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/stat_id.dart';
import '../../domain/unit_system.dart';

const _enabledStatsKey = 'enabled_stats';
const _qnhHpaKey = 'qnh_hpa';
const _flightApiKeyKey = 'flight_api_key';
const _unitSystemKey = 'unit_system';
const _dismissedUpdateBuildKey = 'dismissed_update_build';

/// Persisted user preferences: which stats are shown, the QNH reference
/// pressure for barometric altitude, and the optional flight-lookup API
/// key. Backed by shared_preferences and exposed as a ChangeNotifier so
/// the UI updates live when a toggle flips.
class AppSettings extends ChangeNotifier {
  final SharedPreferences _prefs;
  late Set<StatId> _enabledStats;

  AppSettings._(this._prefs) {
    final stored = _prefs.getStringList(_enabledStatsKey);
    if (stored == null) {
      _enabledStats = {
        for (final s in StatId.values)
          if (s.defaultEnabled) s
      };
    } else {
      _enabledStats = stored
          .map(_statByName)
          .whereType<StatId>()
          .toSet();
    }
  }

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings._(prefs);
  }

  bool isEnabled(StatId id) => _enabledStats.contains(id);

  Set<StatId> get enabledStats => Set.unmodifiable(_enabledStats);

  void setEnabled(StatId id, bool enabled) {
    if (enabled) {
      _enabledStats.add(id);
    } else {
      _enabledStats.remove(id);
    }
    _prefs.setStringList(
      _enabledStatsKey,
      _enabledStats.map((s) => s.name).toList(),
    );
    notifyListeners();
  }

  double get qnhHpa => _prefs.getDouble(_qnhHpaKey) ?? 1013.25;

  set qnhHpa(double value) {
    _prefs.setDouble(_qnhHpaKey, value);
    notifyListeners();
  }

  String get flightApiKey => _prefs.getString(_flightApiKeyKey) ?? '';

  set flightApiKey(String value) {
    _prefs.setString(_flightApiKeyKey, value);
    notifyListeners();
  }

  UnitSystem get unitSystem {
    final stored = _prefs.getString(_unitSystemKey);
    for (final u in UnitSystem.values) {
      if (u.name == stored) return u;
    }
    return UnitSystem.metric;
  }

  set unitSystem(UnitSystem value) {
    _prefs.setString(_unitSystemKey, value.name);
    notifyListeners();
  }

  /// The build number of an available update the user has already said
  /// "later" to, so the setup screen doesn't nag about the same release
  /// on every launch. A newer release still prompts again.
  int get dismissedUpdateBuild => _prefs.getInt(_dismissedUpdateBuildKey) ?? 0;

  set dismissedUpdateBuild(int value) {
    _prefs.setInt(_dismissedUpdateBuildKey, value);
    notifyListeners();
  }
}

StatId? _statByName(String name) {
  for (final s in StatId.values) {
    if (s.name == name) return s;
  }
  return null;
}
