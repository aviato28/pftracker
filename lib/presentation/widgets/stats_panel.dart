import 'package:flutter/material.dart';

import '../../domain/flight_stats.dart';
import '../../domain/stat_id.dart';
import 'stat_formatting.dart';
import 'stat_tile.dart';

/// Wrapping row of stat tiles for every [StatId] the user has enabled in
/// Settings. Shows an em dash for a stat that's enabled but not yet
/// computable (e.g. no GPS fix yet).
class StatsPanel extends StatelessWidget {
  final FlightStats? stats;
  final Set<StatId> enabledStats;

  const StatsPanel({super.key, required this.stats, required this.enabledStats});

  @override
  Widget build(BuildContext context) {
    final orderedEnabled =
        StatId.values.where((id) => enabledStats.contains(id)).toList();

    if (orderedEnabled.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No stats enabled — turn some on in Settings.'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final id in orderedEnabled) _buildTile(id),
        ],
      ),
    );
  }

  Widget _buildTile(StatId id) {
    final formatted = stats != null ? formatStat(id, stats!) : null;
    return StatTile(
      label: id.label,
      value: formatted?.$1,
      unit: formatted?.$2 ?? '',
    );
  }
}
