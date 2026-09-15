/// Every stat the tracking screen can show. Each is independently
/// toggleable in Settings; [defaultEnabled] seeds a sensible first-run set.
enum StatId {
  altitudeGps('Altitude (GPS)', defaultEnabled: true),
  altitudeBaro('Altitude (Barometric)', defaultEnabled: false),
  groundSpeed('Ground Speed', defaultEnabled: true),
  heading('Heading', defaultEnabled: true),
  verticalSpeed('Vertical Speed', defaultEnabled: false),
  distanceRemaining('Distance Remaining', defaultEnabled: true),
  distanceTraveled('Distance Traveled', defaultEnabled: false),
  progressPercent('Route Progress', defaultEnabled: false),
  eta('Time to Destination', defaultEnabled: true),
  elapsedTime('Elapsed Time', defaultEnabled: true),
  localTimeDestination('Local Time at Destination', defaultEnabled: false),
  timeZonesCrossed('Time Zones Crossed', defaultEnabled: false),
  coordinates('Coordinates', defaultEnabled: false);

  final String label;
  final bool defaultEnabled;

  const StatId(this.label, {required this.defaultEnabled});
}
