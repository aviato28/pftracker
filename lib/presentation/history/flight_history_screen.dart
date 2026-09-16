import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/history/flight_history_repository.dart';
import '../../data/settings/app_settings.dart';
import '../../domain/flight_history_entry.dart';
import '../../domain/unit_system.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_tile.dart';

final _dateFormat = DateFormat('MMM d, yyyy');

class FlightHistoryScreen extends StatefulWidget {
  const FlightHistoryScreen({super.key});

  @override
  State<FlightHistoryScreen> createState() => _FlightHistoryScreenState();
}

class _FlightHistoryScreenState extends State<FlightHistoryScreen> {
  final _repository = FlightHistoryRepository();
  List<FlightHistoryEntry>? _entries;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await _repository.loadAll();
    if (mounted) setState(() => _entries = entries);
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Clear flight history?'),
        content: const Text('This removes every past flight from this log. It can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Clear')),
        ],
      ),
    );
    if (confirmed == true) {
      await _repository.clear();
      if (mounted) setState(() => _entries = const []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entries;
    final unitSystem = context.watch<AppSettings>().unitSystem;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flight History'),
        actions: [
          if (entries != null && entries.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Clear history',
              onPressed: _confirmClear,
            ),
        ],
      ),
      body: switch (entries) {
        null => const Center(child: CircularProgressIndicator()),
        [] => const _EmptyState(),
        final list => ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
            itemCount: list.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _HistoryCard(entry: list[i], unitSystem: unitSystem),
            ),
          ),
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          'No flights recorded yet — completed flights show up here.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.5),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final FlightHistoryEntry entry;
  final UnitSystem unitSystem;
  const _HistoryCard({required this.entry, required this.unitSystem});

  @override
  Widget build(BuildContext context) {
    final maxAltitude = entry.maxAltitudeFt;
    final maxSpeed = entry.maxGroundSpeedKmh;
    final distance = entry.distanceTraveledKm;
    final hours = entry.duration.inHours;
    final minutes = entry.duration.inMinutes.remainder(60);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.routeLabel,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                _dateFormat.format(entry.sessionStartUtc.toLocal()),
                style: const TextStyle(fontSize: 12.5, color: AppColors.textFaint, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${entry.departureCity} → ${entry.arrivalCity}',
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: CompactStatTile(
                  label: 'Duration',
                  icon: Icons.schedule_rounded,
                  value: '${hours}h ${minutes.toString().padLeft(2, '0')}m',
                  unit: '',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CompactStatTile(
                  label: 'Max altitude',
                  icon: Icons.height_rounded,
                  value: maxAltitude != null
                      ? unitSystem.altitudeFromFeet(maxAltitude).round().toString()
                      : null,
                  unit: unitSystem.altitudeUnit,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CompactStatTile(
                  label: 'Max speed',
                  icon: Icons.speed_rounded,
                  value: maxSpeed != null
                      ? unitSystem.speedFromKmh(maxSpeed).round().toString()
                      : null,
                  unit: unitSystem.speedUnit,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CompactStatTile(
                  label: 'Distance',
                  icon: Icons.straighten_rounded,
                  value: distance != null
                      ? unitSystem.distanceFromKm(distance).round().toString()
                      : null,
                  unit: unitSystem.distanceUnit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
