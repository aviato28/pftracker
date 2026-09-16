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
    update/       Checks GitHub Releases for a newer build and downloads
                  it — see "In-app updates" below.
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
  from [Natural Earth](https://www.naturalearthdata.com/) 1:50m data
  (public domain, no attribution required).
- **Fonts** (`assets/fonts/`): Manrope and JetBrains Mono, bundled as
  variable-font files rather than fetched from Google Fonts at runtime —
  this app has to render correctly with zero connectivity, so nothing can
  depend on a font CDN.
- **App icon / splash** (`assets/icon/`): a plain filled chevron (the same
  mark used as the map's aircraft marker) on the app's dark background,
  generated at 1024×1024 with Pillow — no external design tool. Wired up
  via `flutter_launcher_icons` and `flutter_native_splash` (dev
  dependencies; see the `flutter_launcher_icons:`/`flutter_native_splash:`
  blocks at the bottom of `pubspec.yaml`). Re-run `dart run
  flutter_launcher_icons` / `dart run flutter_native_splash:create` after
  changing either source image.
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
otherwise.

Speed/distance/altitude render in one of three unit presets (Settings →
Units, see `domain/unit_system.dart`): Metric (km/h, km, m), Imperial
(mph, mi, ft), or Aviation (kt, nm, ft). Vertical speed stays ft/min in
every preset, matching real aircraft instruments even in metric-unit
countries. `FlightStatsEngine` itself always computes in one canonical
set of units (feet, km/h, km) — the chosen preset only affects display.

The tracking screen's GPS status pill shows signal strength as ascending
bars (from the fix's horizontal accuracy) and distinguishes three states —
see "GPS reliability" below.

## GPS reliability

Two changes address "GPS works fine on the ground but stops capturing
in flight":

- **`forceLocationManager: true`** (`data/location/location_service.dart`,
  Android only). By default geolocator uses Google Play Services'
  `FusedLocationProviderClient`, a hybrid provider that leans on wifi/cell
  signal confidence and can simply stop reporting fixes when those are
  absent and GPS reception is weak — exactly the in-flight, airplane-mode,
  metal-fuselage-attenuated scenario this app lives in. Forcing the legacy
  `LocationManager` instead talks to the raw GPS chip directly. Also
  enabled `useMSLAltitude: true`, which reads mean-sea-level altitude from
  the chip's own NMEA sentences (only available via the raw provider) —
  closer to an aviation altimeter reference than the default WGS84
  ellipsoid altitude.
- **Explicit signal states** instead of silently showing stale numbers
  forever: `FlightSessionController.gpsSignalState` is `acquiring` (no fix
  yet — a raw-GPS cold start without assisted-GPS data can take longer
  than FLP's, especially in airplane mode), `active`, or `lost` (had a fix,
  nothing for 20+ seconds — e.g. weak reception away from a window). The
  status pill reflects this instead of just going quiet.

**What no code can fix**: physically, a metal fuselage and (especially)
UV/heat-reflective window coatings on many aircraft attenuate GPS signal
significantly — some seats/aircraft may simply never get a fix mid-flight,
same as any GPS-based flight tracker. And **neither Android nor iOS lets a
normal app survive an explicit swipe-away kill in the task switcher** —
that's deliberate OS policy, not something this app can override. What
this app does instead: the foreground service (with its persistent
notification) makes an *accidental* background kill (Doze/App Standby,
memory pressure) much less likely while merely backgrounded/screen-locked,
and the session-resume feature (above) makes recovery from a kill, when it
does happen, as painless as possible. If reliability is still an issue on
a specific device, check that device's battery-optimization settings for
this app — Samsung/OnePlus/Xiaomi etc. layer their own aggressive app-sleep
policies on top of stock Android's, and "unmonitored"/"never sleep" for
this app is worth setting manually.

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
  Not yet re-confirmed on-device: map rebuild/jank fix, app-kill resume,
  in-flight GPS capture via `forceLocationManager` (see "GPS reliability"
  above) — that last one in particular needs a real flight to know for
  sure.
- The AeroDataBox response parsing is best-effort; confirm against a real
  API response.

## In-app updates

There's no Play Store distribution, so the app checks GitHub Releases on
this (private) repo itself and can download + launch the installer for a
newer build — see `data/update/app_update_service.dart` and
`presentation/widgets/update_prompt.dart`. Checked once on Setup-screen
launch (silently, best-effort — never blocks or errors visibly) and
on-demand from Settings → About → "Check for updates".

Because the repo is private, this needs a GitHub token to call the API and
download release assets. **Never commit a real token** — it's baked in at
build time only:

```
flutter build apk --release --split-per-abi \
  --dart-define=GITHUB_UPDATE_TOKEN=<a fine-grained, read-only, single-repo token>
```

Without that define, `AppUpdateService.checkForUpdate()` always returns
null — update checks are simply disabled, not broken.

**Creating the token** (one-time, at
[github.com/settings/personal-access-tokens/new](https://github.com/settings/personal-access-tokens/new)):
repository access → only `aviato28/pftracker`; repository permissions →
Contents: Read-only. That's the minimum needed to read release metadata
and download release assets.

**Releasing an update** — the app finds it via `GET
/repos/aviato28/pftracker/releases/latest` and compares build numbers, so:

1. Bump `version:` in `pubspec.yaml` (`X.Y.Z+N` — `N`, the part after
   `+`, is what actually gets compared; it must increase every release).
2. Build with the `--dart-define` above.
3. Tag the commit `vX.Y.Z+N` — **matching pubspec.yaml exactly** — and
   create a GitHub Release from that tag with the built APK(s) attached as
   release assets and the changelog in the release body (shown to the
   user before they download). `AppUpdateService._buildNumberFromTag`
   parses the `+N` suffix; a tag without one is invisible to the app.
4. Any `.apk` among the release's assets is picked up — attaching just
   the arm64 build is enough for essentially any real device from the
   last ~8 years.

## Running

```
flutter pub get
flutter run
```
