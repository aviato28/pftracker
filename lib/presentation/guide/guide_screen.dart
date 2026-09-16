import 'package:flutter/material.dart';

import '../../state/flight_session_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/gps_status_pill.dart';

const _bodyStyle = TextStyle(fontSize: 13.5, color: AppColors.textMuted, height: 1.5);

/// A plain-language walkthrough for first-time users, reachable from the
/// setup screen's header. Each section is its own expansion tile rather
/// than one long scroll, so someone can jump straight to "what does that
/// GPS pill mean" mid-flight instead of re-reading everything.
class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guide')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
        children: [
          const Text(
            "New here? This is everything, in the order you'll need it.",
            style: TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.4),
          ),
          const SizedBox(height: 20),
          _GuideSection(
            number: '01',
            title: 'Set up your route',
            initiallyExpanded: true,
            child: const Text(
              'Before you board, add a route one of two ways: search departure '
              'and arrival airports manually, or look up your flight number '
              '(needs a connection and, optionally, a free API key in '
              'Settings — manual entry never needs one). This is the only '
              'step in the whole app that ever touches the network.',
              style: _bodyStyle,
            ),
          ),
          _GuideSection(
            number: '02',
            title: 'Read the tracking screen',
            child: const Text(
              'The two big numbers up top — altitude and speed — are your '
              '"hero" stats and are always shown. Everything else you\'ve '
              'turned on in Settings sits in the grid below. On the map, '
              'your flown path is a solid line and the rest of the route '
              'is dashed.',
              style: _bodyStyle,
            ),
          ),
          _GuideSection(
            number: '03',
            title: 'Understand the GPS pill',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "The pill on the tracking screen tells you exactly what "
                  "your GPS is doing right now:",
                  style: _bodyStyle,
                ),
                const SizedBox(height: 14),
                const Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    GpsStatusPill(
                      signalState: GpsSignalState.acquiring,
                      timeSinceLastFix: null,
                      accuracyMeters: null,
                      barometerAvailable: false,
                      hasError: false,
                    ),
                    GpsStatusPill(
                      signalState: GpsSignalState.active,
                      timeSinceLastFix: Duration.zero,
                      accuracyMeters: 4,
                      barometerAvailable: true,
                      hasError: false,
                    ),
                    GpsStatusPill(
                      signalState: GpsSignalState.lost,
                      timeSinceLastFix: Duration(seconds: 35),
                      accuracyMeters: null,
                      barometerAvailable: false,
                      hasError: false,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'ACQUIRING means no fix yet — normal for the first minute '
                  'or two, especially cold-starting in airplane mode. GPS / '
                  'GPS+BARO means fixes are arriving normally; more bars is '
                  'a tighter fix. NO FIX means it had a signal and lost it — '
                  "common away from a window, and nothing to worry about "
                  "unless it lasts the whole flight.",
                  style: _bodyStyle,
                ),
              ],
            ),
          ),
          _GuideSection(
            number: '04',
            title: 'Make it yours',
            child: const Text(
              'Settings lets you toggle exactly which stats show and switch '
              'between Metric, Imperial, or Aviation units at any time — '
              'even mid-flight.',
              style: _bodyStyle,
            ),
          ),
          _GuideSection(
            number: '05',
            title: 'If the app closes by accident',
            child: const Text(
              "A swipe-away or the OS killing the app mid-flight doesn't "
              'lose your track — reopening pftracker offers to resume the '
              'exact same session: same start time, same flown path, right '
              'where it left off.',
              style: _bodyStyle,
            ),
          ),
          _GuideSection(
            number: '06',
            title: 'Getting updates',
            child: const Text(
              "pftracker isn't on the Play Store, so it checks its own "
              'GitHub releases instead. It checks quietly on launch, or you '
              'can trigger it yourself from Settings → About → "Check for '
              'updates."',
              style: _bodyStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideSection extends StatelessWidget {
  final String number;
  final String title;
  final Widget child;
  final bool initiallyExpanded;

  const _GuideSection({
    required this.number,
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          iconColor: AppColors.accent,
          collapsedIconColor: AppColors.textFaint,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          title: Row(
            children: [
              Text(
                number,
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          children: [Align(alignment: Alignment.centerLeft, child: child)],
        ),
      ),
    );
  }
}
