import 'package:flutter/material.dart' show IconData, Icons;

/// Every stat the tracking screen can show. Each is independently
/// toggleable in Settings; [defaultEnabled] seeds a sensible first-run set.
enum StatId {
  altitudeGps('Altitude (GPS)', Icons.height, defaultEnabled: true),
  altitudeBaro('Altitude (Barometric)', Icons.speed, defaultEnabled: false),
  groundSpeed('Ground Speed', Icons.air, defaultEnabled: true),
  heading('Heading', Icons.explore_outlined, defaultEnabled: true),
  verticalSpeed('Vertical Speed', Icons.trending_up, defaultEnabled: false),
  distanceRemaining('Distance Remaining', Icons.flag_outlined, defaultEnabled: true),
  distanceTraveled('Distance Traveled', Icons.route_outlined, defaultEnabled: false),
  progressPercent('Route Progress', Icons.percent, defaultEnabled: false),
  eta('Time to Destination', Icons.schedule, defaultEnabled: true),
  elapsedTime('Elapsed Time', Icons.timer_outlined, defaultEnabled: true),
  localTimeDestination('Local Time at Destination', Icons.public, defaultEnabled: false),
  timeZonesCrossed('Time Zones Crossed', Icons.language, defaultEnabled: false),
  coordinates('Coordinates', Icons.my_location, defaultEnabled: false);

  final String label;
  final IconData icon;
  final bool defaultEnabled;

  const StatId(this.label, this.icon, {required this.defaultEnabled});
}
