# pftracker

An offline flight tracker for Android and iOS. Set up your route once, on
the ground, while you still have wifi/cell — then track your own flight's
position, altitude, speed, and time to destination on a map for the whole
flight with **zero connectivity**, using only the device's GPS (receive-only,
so it works in airplane mode) and, optionally, its barometer.

The UI is a dark, glass-cockpit-inspired design (see the approved mockups
this was built from) — deep charcoal background, one electric-cyan accent,
Manrope for text and JetBrains Mono for the big HUD-style numbers. The map
is a basic bundled world outline, not detailed street tiles — it ships
inside the app itself, so there is nothing to download and no network
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
                  antimeridian-split/barometric-altitude math.
  data/
    location/     GPS via `geolocator` (airplane-mode friendly).
    barometer/    Platform channel to the native pressure sensor
                  (Android SensorManager / iOS CMAltimeter).
    airports/     In-memory search over the bundled airport dataset.
    routes/       Flight-number -> route lookup (pluggable; ships with an
                  AeroDataBox/RapidAPI implementation).
    basemap/      Loads the bundled world land outline into `flutter_map`
                  `Polygon`s, ready to render — see "The map" below.
    settings/     Persisted user preferences (shared_preferences).
  state/          FlightSessionController: owns the live session, merges
                  GPS + barometer readings, exposes computed stats.
  presentation/
    theme/         AppColors + AppTheme — the whole app's dark palette and
                    type scale in one place.
    setup/         Route setup screen, airport search.
    tracking/       Live tracking screen + the map.
    settings/       Settings screen.
    widgets/        Shared pieces (stat tiles, the pill switch, the GPS
                    signal-strength pill, the nav-chevron mark).
```

## The map

`presentation/tracking/world_map_view.dart` renders a bundled land outline
(`assets/data/world_land.json`, ~75KB, simplified from Natural Earth 1:110m)
as `flutter_map` `Polygon`s — a basic vector map, not raster tiles, so
there's no tile server, no download step, and nothing that can fail to
load. Pan/zoom/fit-to-route use `flutter_map`'s own camera and gesture
handling rather than a hand-rolled one — an earlier version drove a plain
`InteractiveViewer` with a manually-computed transform, which is what
caused the map to render but not be pannable ("stuck in a random
position"): setting `TransformationController.value` directly fights that
widget's internal pan/zoom clamping. `flutter_map`'s `CameraFit.bounds` and
default interaction handling do the same job correctly.

## Data sources

- **Airports** (`assets/data/airports.json`, ~9.3k airports): derived from
  [OurAirports](https://ourairports.com/data/) (public domain, actively
  maintained — unlike the OpenFlights snapshot this originally shipped
  with, which was missing newer airports like Noida/Jewar (DXN) and Navi
  Mumbai (NMI)). IANA timezones are computed locally at build time from
  each airport's coordinates (via `timezonefinder`), not sourced from any
  API.
- **Map** (`assets/data/world_land.json`): land polygon outlines derived
  from [Natural Earth](https://www.naturalearthdata.com/) 1:110m data
  (public domain, no attribution required).
- **Fonts** (`assets/fonts/`): Manrope and JetBrains Mono, bundled as
  variable-font files rather than fetched from Google Fonts at runtime —
  this app has to render correctly with zero connectivity, so nothing can
  depend on a font CDN.
- **Flight-number lookup**: `AeroDataBoxRouteLookupService` calls AeroDataBox
  via RapidAPI. It needs an API key (enter it in Settings) — without one,
  manual airport entry still works fully. The response parsing follows
  AeroDataBox's documented schema but hasn't been verified against a live
  key; check field names against the current API docs before relying on it.

## Stats shown

Every stat is independently toggleable in Settings (see `domain/stat_id.dart`):
GPS altitude, barometric altitude, ground speed, heading, vertical speed,
distance remaining/traveled, route progress %, ETA, elapsed time, local time
at destination, timezones crossed, and raw coordinates. The two most-glanced
at (altitude and speed, by default) get the large "hero" tile treatment on
the tracking screen; everything else enabled sits in a compact grid below.
Local time / timezone math uses each airport's real IANA timezone
(DST-aware) when known, falling back to a longitude-based approximation
otherwise. The tracking screen's GPS status pill also shows signal strength
as ascending bars, derived from the GPS fix's horizontal accuracy.

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
  `flutter analyze` and `flutter test` are clean.
- **iOS**: unverified — this sandbox has no macOS/Xcode. The Xcode project
  was regenerated from a current `flutter create` (scene-based lifecycle),
  and `AppDelegate.swift`'s barometer channel setup follows Flutter's own
  `FlutterImplicitEngineDelegate` example, but neither has been compiled.
- **Run on a real device before trusting it in flight**: GPS and barometer
  behavior can't be trusted on an emulator/simulator, and the whole point
  of the app is airplane-mode GPS tracking. In particular, please confirm
  the map now pans/zooms normally — that was the one bug in the previous
  build that a from-a-distance rebuild (no device here) can't fully rule
  out on its own.
- The AeroDataBox response parsing is best-effort; confirm against a real
  API response.

## Running

```
flutter pub get
flutter run
```
