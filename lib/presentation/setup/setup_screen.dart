import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/airports/airport_repository.dart';
import '../../data/routes/route_lookup_service.dart';
import '../../data/settings/app_settings.dart';
import '../../data/tiles/tile_cache_dir.dart';
import '../../data/tiles/tile_downloader.dart';
import '../../data/tiles/tile_math.dart';
import '../../domain/airport.dart';
import '../../domain/flight_route.dart';
import '../../domain/geo_utils.dart';
import '../settings/settings_screen.dart';
import '../tracking/tracking_screen.dart';
import 'airport_search_field.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _airportRepository = AirportRepository();
  final _flightNumberController = TextEditingController();

  bool _byFlightNumber = false;
  Airport? _departure;
  Airport? _arrival;
  FlightRoute? _route;
  bool _lookingUp = false;
  String? _lookupError;

  double? _downloadProgress;

  @override
  void dispose() {
    _flightNumberController.dispose();
    super.dispose();
  }

  void _tryBuildManualRoute() {
    if (_departure != null && _arrival != null) {
      setState(() {
        _route = manualRoute(departure: _departure!, arrival: _arrival!);
        _lookupError = null;
      });
    }
  }

  Future<void> _lookupFlightNumber() async {
    final settings = context.read<AppSettings>();
    final flightNumber = _flightNumberController.text.trim();
    if (flightNumber.isEmpty) return;

    setState(() {
      _lookingUp = true;
      _lookupError = null;
    });

    final service = AeroDataBoxRouteLookupService(
      apiKey: settings.flightApiKey,
      airportRepository: _airportRepository,
    );
    try {
      final route = await service.lookupByFlightNumber(flightNumber);
      setState(() {
        _route = route;
      });
    } on FlightRouteLookupException catch (e) {
      setState(() => _lookupError = e.message);
    } catch (e) {
      setState(() => _lookupError = 'Lookup failed: $e');
    } finally {
      service.dispose();
      if (mounted) setState(() => _lookingUp = false);
    }
  }

  Future<void> _downloadOfflineMaps() async {
    final route = _route;
    if (route == null) return;

    setState(() => _downloadProgress = 0);
    final cacheDir = await tileCacheDirectory();
    final downloader = TileDownloader(cacheDir: cacheDir);
    final path = GeoUtils.greatCirclePath(
      route.departure.lat,
      route.departure.lon,
      route.arrival.lat,
      route.arrival.lon,
    );
    final bounds = LatLngBoundsSimple.fromPoints(path);

    await downloader.downloadRoute(
      bounds: bounds,
      minZoom: 3,
      maxZoom: 8,
      onProgress: (done, total) {
        if (mounted) setState(() => _downloadProgress = total == 0 ? 1 : done / total);
      },
    );
    downloader.dispose();
    if (mounted) {
      setState(() => _downloadProgress = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offline map download complete.')),
      );
    }
  }

  void _startTracking() {
    final route = _route;
    if (route == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TrackingScreen(route: route)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('pftracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Set up your route before you lose connectivity — this is '
                'the only step that needs the internet. Tracking itself '
                'works fully offline via GPS.',
              ),
              const SizedBox(height: 16),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Departure / Arrival')),
                  ButtonSegment(value: true, label: Text('Flight Number')),
                ],
                selected: {_byFlightNumber},
                onSelectionChanged: (s) => setState(() {
                  _byFlightNumber = s.first;
                  _route = null;
                  _lookupError = null;
                }),
              ),
              const SizedBox(height: 16),
              if (!_byFlightNumber) ...[
                AirportSearchField(
                  label: 'Departure airport',
                  repository: _airportRepository,
                  onSelected: (a) {
                    _departure = a;
                    _tryBuildManualRoute();
                  },
                ),
                const SizedBox(height: 12),
                AirportSearchField(
                  label: 'Arrival airport',
                  repository: _airportRepository,
                  onSelected: (a) {
                    _arrival = a;
                    _tryBuildManualRoute();
                  },
                ),
              ] else ...[
                TextField(
                  controller: _flightNumberController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Flight number',
                    hintText: 'e.g. UA123',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _lookingUp ? null : _lookupFlightNumber,
                  child: _lookingUp
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Look up route'),
                ),
                if (_lookupError != null) ...[
                  const SizedBox(height: 8),
                  Text(_lookupError!, style: const TextStyle(color: Colors.red)),
                ],
              ],
              if (_route != null) ...[
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_route!.label, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        if (_downloadProgress != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              LinearProgressIndicator(value: _downloadProgress),
                              const SizedBox(height: 8),
                              const Text('Downloading offline map tiles...'),
                            ],
                          )
                        else
                          OutlinedButton.icon(
                            onPressed: _downloadOfflineMaps,
                            icon: const Icon(Icons.download_for_offline),
                            label: const Text('Download offline maps for this route'),
                          ),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: _startTracking,
                          icon: const Icon(Icons.flight_takeoff),
                          label: const Text('Start tracking'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
