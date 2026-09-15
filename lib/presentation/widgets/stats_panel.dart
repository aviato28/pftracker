import 'package:flutter/material.dart';

import '../../domain/flight_stats.dart';
import '../../domain/stat_id.dart';
import '../../domain/unit_system.dart';
import 'stat_formatting.dart';
import 'stat_tile.dart';

/// Which two enabled stats get the big "hero" treatment, in priority
/// order — altitude and speed are the classic instrument pairing pilots
/// glance at first. Whatever doesn't make the top two falls into the
/// secondary grid, in the catalog's normal order.
const _heroPriority = [
  StatId.altitudeGps,
  StatId.groundSpeed,
  StatId.altitudeBaro,
];

/// Renders every [StatId] the user has enabled in Settings: up to two as
/// large hero tiles, the rest in a compact 2-column grid. Shows an em
/// dash for a stat that's enabled but not yet computable (e.g. no GPS
/// fix yet).
class StatsPanel extends StatelessWidget {
  final FlightStats? stats;
  final Set<StatId> enabledStats;
  final UnitSystem unitSystem;

  const StatsPanel({
    super.key,
    required this.stats,
    required this.enabledStats,
    required this.unitSystem,
  });

  @override
  Widget build(BuildContext context) {
    final enabledOrdered = StatId.values.where(enabledStats.contains).toList();

    if (enabledOrdered.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          'No stats enabled — turn some on in Settings.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final heroes = <StatId>[
      for (final id in _heroPriority)
        if (enabledOrdered.contains(id)) id,
    ].take(2).toList();
    final secondary = enabledOrdered.where((id) => !heroes.contains(id)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (heroes.isNotEmpty)
          Row(
            children: [
              for (var i = 0; i < heroes.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: _heroTile(heroes[i])),
              ],
            ],
          ),
        if (heroes.isNotEmpty && secondary.isNotEmpty) const SizedBox(height: 12),
        if (secondary.isNotEmpty)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.4,
            children: [for (final id in secondary) _compactTile(id)],
          ),
      ],
    );
  }

  Widget _heroTile(StatId id) {
    final formatted = stats != null ? formatStat(id, stats!, unitSystem) : null;
    return HeroStatTile(label: id.label, icon: id.icon, value: formatted?.$1, unit: formatted?.$2 ?? '');
  }

  Widget _compactTile(StatId id) {
    final formatted = stats != null ? formatStat(id, stats!, unitSystem) : null;
    return CompactStatTile(label: id.label, icon: id.icon, value: formatted?.$1, unit: formatted?.$2 ?? '');
  }
}
