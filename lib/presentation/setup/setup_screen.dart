import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/airports/airport_repository.dart';
import '../../data/routes/route_lookup_service.dart';
import '../../data/settings/app_settings.dart';
import '../../domain/airport.dart';
import '../../domain/flight_route.dart';
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
      setState(() => _route = route);
    } on FlightRouteLookupException catch (e) {
      setState(() => _lookupError = e.message);
    } catch (e) {
      setState(() => _lookupError = 'Lookup failed: $e');
    } finally {
      service.dispose();
      if (mounted) setState(() => _lookingUp = false);
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('pftracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.wifi_off_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Set up your route now, while you still have wifi. '
                    'Tracking itself needs no connectivity — just GPS.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.flight_takeoff),
                  label: Text('Airports'),
                ),
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.confirmation_number_outlined),
                  label: Text('Flight number'),
                ),
              ],
              selected: {_byFlightNumber},
              onSelectionChanged: (s) => setState(() {
                _byFlightNumber = s.first;
                _route = null;
                _lookupError = null;
              }),
            ),
            const SizedBox(height: 20),
            if (!_byFlightNumber) ...[
              AirportSearchField(
                label: 'Departure airport',
                icon: Icons.flight_takeoff,
                repository: _airportRepository,
                value: _departure,
                onSelected: (a) {
                  _departure = a;
                  _tryBuildManualRoute();
                },
              ),
              const SizedBox(height: 12),
              AirportSearchField(
                label: 'Arrival airport',
                icon: Icons.flight_land,
                repository: _airportRepository,
                value: _arrival,
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
                  prefixIcon: Icon(Icons.confirmation_number_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _lookingUp ? null : _lookupFlightNumber,
                icon: _lookingUp
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: Text(_lookingUp ? 'Looking up…' : 'Look up route'),
              ),
              if (_lookupError != null) ...[
                const SizedBox(height: 12),
                Text(_lookupError!, style: TextStyle(color: theme.colorScheme.error)),
              ],
            ],
            if (_route != null) ...[
              const SizedBox(height: 24),
              Card(
                elevation: 0,
                color: theme.colorScheme.primaryContainer,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _route!.label,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _startTracking,
                          icon: const Icon(Icons.flight_takeoff),
                          label: const Text('Start tracking'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
