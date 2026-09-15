import 'package:flutter/material.dart';

import '../../state/flight_session_controller.dart';
import '../theme/app_theme.dart';

/// Floating HUD pill showing GPS signal strength (as ascending bars, like
/// a phone's signal indicator) plus whether barometric altitude is also
/// fused in. Distinguishes "never had a fix yet" (acquiring), "fixes
/// arriving normally," and "had a fix, nothing for a while now" (lost) —
/// showing the last known numbers forever with no indication they've gone
/// stale would be misleading mid-flight.
class GpsStatusPill extends StatelessWidget {
  final GpsSignalState signalState;
  final Duration? timeSinceLastFix;
  final double? accuracyMeters;
  final bool barometerAvailable;
  final bool hasError;

  const GpsStatusPill({
    super.key,
    required this.signalState,
    required this.timeSinceLastFix,
    required this.accuracyMeters,
    required this.barometerAvailable,
    required this.hasError,
  });

  int get _bars {
    final acc = accuracyMeters;
    if (hasError || acc == null || signalState != GpsSignalState.active) return 0;
    if (acc <= 5) return 4;
    if (acc <= 15) return 3;
    if (acc <= 30) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    if (hasError) {
      color = AppColors.error;
      label = 'GPS ERROR';
    } else {
      switch (signalState) {
        case GpsSignalState.acquiring:
          color = AppColors.textMuted;
          label = 'ACQUIRING…';
        case GpsSignalState.lost:
          color = AppColors.error;
          final seconds = timeSinceLastFix?.inSeconds ?? 0;
          label = 'NO FIX ${seconds}s';
        case GpsSignalState.active:
          color = AppColors.accent;
          label = barometerAvailable ? 'GPS+BARO' : 'GPS';
      }
    }

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xB30F141A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SignalBars(activeBars: _bars, color: color),
          const SizedBox(width: 8),
          Container(width: 1, height: 14, color: color.withValues(alpha: 0.25)),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalBars extends StatelessWidget {
  final int activeBars;
  final Color color;
  const _SignalBars({required this.activeBars, required this.color});

  static const _heights = [4.0, 6.0, 9.0, 12.0];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 12,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 4; i++) ...[
            if (i > 0) const SizedBox(width: 1.5),
            Container(
              width: 2.6,
              height: _heights[i],
              decoration: BoxDecoration(
                color: i < activeBars ? color : color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
