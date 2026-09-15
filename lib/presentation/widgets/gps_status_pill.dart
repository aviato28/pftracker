import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Floating HUD pill showing GPS signal strength (as ascending bars, like
/// a phone's signal indicator) plus whether barometric altitude is also
/// fused in. Bar count is derived from the GPS fix's horizontal accuracy.
class GpsStatusPill extends StatelessWidget {
  final double? accuracyMeters;
  final bool barometerAvailable;
  final bool hasError;

  const GpsStatusPill({
    super.key,
    required this.accuracyMeters,
    required this.barometerAvailable,
    required this.hasError,
  });

  int get _bars {
    final acc = accuracyMeters;
    if (hasError || acc == null) return 0;
    if (acc <= 5) return 4;
    if (acc <= 15) return 3;
    if (acc <= 30) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final bars = _bars;
    final color = hasError ? AppColors.error : AppColors.accent;
    final label = hasError ? 'GPS ERROR' : (barometerAvailable ? 'GPS+BARO' : 'GPS');

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
          _SignalBars(activeBars: bars, color: color),
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
