import 'package:home_widget/home_widget.dart';

import '../../domain/flight_route.dart';
import '../../domain/flight_stats.dart';
import '../../domain/unit_system.dart';

const _androidWidgetName = 'FlightWidgetProvider';

/// Pushes the current flight's headline numbers to the Android home screen
/// widget (see android/.../FlightWidgetProvider.kt) so altitude and speed
/// are visible without opening the app. iOS has no equivalent yet — a Live
/// Activity would need a Widget Extension target built and signed in
/// Xcode, which isn't possible from this project's toolchain.
///
/// Every call is best-effort: no widget added, or a platform that doesn't
/// support this at all, must never affect tracking itself.
class FlightWidgetService {
  Future<void> update({
    required FlightRoute route,
    required FlightStats? stats,
    required UnitSystem unitSystem,
  }) async {
    try {
      final altitudeFt = stats?.altitudeBaroFt ?? stats?.altitudeGpsFt;
      final speedKmh = stats?.groundSpeedKmh;

      await HomeWidget.saveWidgetData<String>(
        'widget_route',
        '${route.departure.displayCode} → ${route.arrival.displayCode}',
      );
      await HomeWidget.saveWidgetData<String>(
        'widget_altitude',
        altitudeFt != null
            ? '${unitSystem.altitudeFromFeet(altitudeFt).round()} ${unitSystem.altitudeUnit}'
            : '—',
      );
      await HomeWidget.saveWidgetData<String>(
        'widget_speed',
        speedKmh != null
            ? '${unitSystem.speedFromKmh(speedKmh).round()} ${unitSystem.speedUnit}'
            : '—',
      );
      await HomeWidget.updateWidget(androidName: _androidWidgetName);
    } catch (_) {
      // Best-effort — see class doc.
    }
  }

  Future<void> clear() async {
    try {
      await HomeWidget.saveWidgetData<String>('widget_route', 'No active flight');
      await HomeWidget.saveWidgetData<String>('widget_altitude', '—');
      await HomeWidget.saveWidgetData<String>('widget_speed', '—');
      await HomeWidget.updateWidget(androidName: _androidWidgetName);
    } catch (_) {
      // Best-effort — see class doc.
    }
  }
}
