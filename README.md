# pftracker

An offline flight tracker for Android and iOS. Set up your route once, on
the ground, while you still have wifi/cell — then track your own flight's
position, altitude, speed, and time to destination on a map for the whole
flight with **zero connectivity**, using only the device's GPS (receive-only,
so it works in airplane mode) and, optionally, its barometer.

The map is a basic bundled world outline, not detailed street tiles — it
ships inside the app itself, so there is nothing to download and no network
dependency at any point, ever.

## How it works

1. **Before boarding** (needs internet, briefly): pick a route, either by
   choosing departure/arrival airports manually or by looking up a flight
   number. That's the only step that touches the network.
2. **In the air** (needs nothing): the app streams GPS fixes, derives
   altitude/speed/heading/ETA/etc. locally, and draws your position on the
   bundled offline map.

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
    basemap/      Loads the bundled world land/ocean outline into a single
                  cached `Path`, ready to paint — see below.
    settings/     Persisted user preferences (shared_preferences).
  state/          FlightSessionController: owns the live session, merges
                  GPS + barometer readings, exposes computed stats.
  presentation/   Setup, Tracking (map + stats), and Settings screens.
```

## The map

`presentation/tracking/world_map_view.dart` is a deliberately basic offline
map: an equirectangular (plate carrée) projection of a bundled land/ocean
outline (`assets/data/world_land.json`, ~75KB, simplified from Natural
Earth 1:110m — see `domain/map_projection.dart`), drawn once as a static
`Path` and reused every frame. Pan/zoom come from a plain `InteractiveViewer`
around that canvas — no tile pyramid, no tile server, no download step, and
nothing that can get stuck waiting on a network request. The route line,
flown track, and aircraft marker are drawn/positioned in the same
coordinate space on top.

## Data sources

- **Airports** (`assets/data/airports.json`): ~7.7k airports with ICAO/IATA
  codes, coordinates, elevation, and IANA timezone, derived from the
  [OpenFlights](https://openflights.org/data.html) dataset (itself sourced
  from OurAirports), licensed under ODbL. Attribution is shown in Settings.
- **Map** (`assets/data/world_land.json`): land polygon outlines derived
  from [Natural Earth](https://www.naturalearthdata.com/) 1:110m data
  (public domain, no attribution required — see "The map" above).
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

## Build status

- **Android**: `flutter build apk --release --split-per-abi` succeeds
  (verified in this sandbox with a manually installed Android SDK —
  Gradle/AGP/Kotlin versions are current as of the last build).
- An earlier version used `flutter_map` + live/pre-downloaded OpenStreetMap
  tiles for the map and an overlay-based autocomplete for airport search.
  Both were reported broken on a real device (map not loading, UI feeling
  stuck/unscrollable) and have been replaced outright: the map is now the
  bundled offline outline described above, and airport search is a plain
  full-screen list (`presentation/setup/airport_search_page.dart`) instead
  of an inline overlay. Rebuilding/analyzing confirms it compiles, but
  **this specific fix has not yet been re-tested on the device that hit the
  original bug** — that's the next thing to confirm.
- **iOS**: unverified — this sandbox has no macOS/Xcode. The Xcode project
  was regenerated from a current `flutter create` (scene-based lifecycle),
  and `AppDelegate.swift`'s barometer channel setup follows Flutter's own
  `FlutterImplicitEngineDelegate` example, but neither has been compiled.
- Either way, **run on a real device before trusting it in flight**: GPS
  and barometer behavior can't be trusted on an emulator/simulator, and
  the whole point of the app is airplane-mode GPS tracking.
- The AeroDataBox response parsing is best-effort; confirm against a real
  API response.

## Running

```
flutter pub get
flutter run
```
