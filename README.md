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
3. **If the app gets killed mid-flight** (an accidental swipe-away, Android
   reclaiming memory, a battery-optimization kill) — relaunching offers to
   resume the same session: elapsed time keeps counting from the original
   start, GPS reacquires the real position immediately, and only the
   flown-track breadcrumb restarts from that point rather than from
   departure. See `data/session/active_session_repository.dart`.

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
    session/      Persists the in-progress route + start time so a killed
                  app can offer to resume tracking on relaunch.
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
(`assets/data/world_land.json`, ~1MB, simplified from Natural Earth
1:50m — ~60k coastline points) as `flutter_map` `Polygon`s, plus a lat/lon
graticule for texture at any zoom — a basic vector map, not raster tiles,
so there's no tile server, no download step, and nothing that can fail to
load. Pan/zoom/fit-to-route use `flutter_map`'s own camera and gesture
handling rather than a hand-rolled one — an earlier version drove a plain
`InteractiveViewer` with a manually-computed transform, which is what
caused the map to render but not be pannable ("stuck in a random
position"): setting `TransformationController.value` directly fights that
widget's internal pan/zoom clamping. `flutter_map`'s `CameraFit.bounds` and
default interaction handling do the same job correctly.

`WorldMapView` only takes the (static) `FlightRoute`, not a stream of
position updates — the land outline, graticule, and static route line are
built once. Only two small `Consumer<FlightSessionController>`-scoped
layers (the flown-track polyline and the aircraft marker) rebuild on each
GPS tick. Earlier, the whole map (including re-simplifying ~60k points of
land geometry) rebuilt on every GPS sample because an ancestor `Consumer`
wrapped the entire widget — the periodic jank that caused is a good example
of why `Consumer`/`Selector` scope should be as narrow as possible.

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
  of the app is airplane-mode GPS tracking. Confirmed fixed on-device so
  far: map pan/zoom, the stats sheet scrolling with everything toggled on.
  Reported but not yet re-confirmed on-device: general map smoothness
  (addressed by no longer rebuilding the whole map on each GPS tick — see
  "The map" above) and app-kill resume (new — see "How it works" above).
- The AeroDataBox response parsing is best-effort; confirm against a real
  API response.

## Running

```
flutter pub get
flutter run
```
