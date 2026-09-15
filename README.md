# pftracker

An offline flight tracker for Android and iOS. Set up your route once, on
the ground, while you still have wifi/cell — then track your own flight's
position, altitude, speed, and time to destination on a map for the whole
flight with **zero connectivity**, using only the device's GPS (receive-only,
so it works in airplane mode) and, optionally, its barometer.

## How it works

1. **Before boarding** (needs internet): pick a route, either by choosing
   departure/arrival airports manually or by looking up a flight number.
   Optionally pre-download map tiles for the route corridor.
2. **In the air** (needs nothing): the app streams GPS fixes, derives
   altitude/speed/heading/ETA/etc. locally, and draws your position on the
   pre-cached map. No network calls happen during tracking itself.

## Architecture

```
lib/
  domain/        Pure Dart models and math — Airport, FlightRoute,
                  FlightSample, FlightStats (+ the engine that computes it),
                  StatId (the toggleable stat catalog), great-circle/
                  barometric-altitude math.
  data/
    location/     GPS via `geolocator` (airplane-mode friendly).
    barometer/    Platform channel to the native pressure sensor
                  (Android SensorManager / iOS CMAltimeter).
    airports/     In-memory search over the bundled airport dataset.
    routes/       Flight-number -> route lookup (pluggable; ships with an
                  AeroDataBox/RapidAPI implementation).
    tiles/        Offline-first map tile provider + bulk pre-downloader.
    settings/     Persisted user preferences (shared_preferences).
  state/          FlightSessionController: owns the live session, merges
                  GPS + barometer readings, exposes computed stats.
  presentation/   Setup, Tracking (map + stats), and Settings screens.
```

## Data sources

- **Airports** (`assets/data/airports.json`): ~7.7k airports with ICAO/IATA
  codes, coordinates, elevation, and IANA timezone, derived from the
  [OpenFlights](https://openflights.org/data.html) dataset (itself sourced
  from OurAirports), licensed under ODbL. Attribution is shown in Settings.
- **Map tiles**: OpenStreetMap by default. **OSM's tile usage policy
  prohibits sustained bulk downloading from third-party apps** — the
  pre-flight downloader in `data/tiles/tile_downloader.dart` is fine for
  development, but before shipping, point `TileDownloader.urlTemplate` at a
  provider meant for this (MapTiler, Stadia Maps, Thunderforest, etc.) with
  your own API key.
- **Flight-number lookup**: `AeroDataBoxRouteLookupService` calls AeroDataBox
  via RapidAPI. It needs an API key (enter it in Settings) — without one,
  manual airport entry still works fully. The response parsing follows
  AeroDataBox's documented schema but hasn't been verified against a live
  key; check field names against the current API docs before relying on it.

## Stats shown

Every stat is independently toggleable in Settings (see `domain/stat_id.dart`):
GPS altitude, barometric altitude, ground speed, heading, vertical speed,
distance remaining/traveled, route progress %, ETA, elapsed time, local time
at destination, timezones crossed, and raw coordinates. Local time / timezone
math uses each airport's real IANA timezone (DST-aware) when known, falling
back to a longitude-based approximation otherwise.

## Permissions

- **Location** (foreground + background): required for tracking to continue
  if the screen locks. Android runs a foreground service notification while
  tracking; iOS requests background location updates.
- **Barometer**: no permission prompt needed on either platform, but not
  every Android device has a pressure sensor (all recent iPhones do) — the
  app falls back to GPS-only altitude when it's absent.

## What's not yet verified

This was built in a sandbox with no Android SDK or Xcode available, so:
- `flutter analyze` and `flutter test` pass, but the app has **not been
  built or run on a device/emulator**.
- The native Kotlin (`android/.../MainActivity.kt`) and Swift
  (`ios/Runner/AppDelegate.swift`) barometer bridges are unverified —
  compile and test them on a real device (barometer behavior can't be
  trusted on an emulator anyway).
- The AeroDataBox response parsing is best-effort; confirm against a real
  API response.

## Running

```
flutter pub get
flutter run
```
