import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/settings/app_settings.dart';
import '../../domain/stat_id.dart';
import '../theme/app_theme.dart';
import '../widgets/pill_switch.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _qnhController;
  late final TextEditingController _apiKeyController;

  @override
  void initState() {
    super.initState();
    final settings = context.read<AppSettings>();
    _qnhController = TextEditingController(text: settings.qnhHpa.toStringAsFixed(2));
    _apiKeyController = TextEditingController(text: settings.flightApiKey);
  }

  @override
  void dispose() {
    _qnhController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
        children: [
          const _SectionLabel('Displayed stats'),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                for (var i = 0; i < StatId.values.length; i++)
                  _StatToggleRow(
                    id: StatId.values[i],
                    value: settings.isEnabled(StatId.values[i]),
                    onChanged: (v) => settings.setEnabled(StatId.values[i], v),
                    showDivider: i < StatId.values.length - 1,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const _SectionLabel('Barometric calibration'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('QNH reference pressure', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                const SizedBox(height: 8),
                TextField(
                  controller: _qnhController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: dataTextStyle(size: 20),
                  decoration: const InputDecoration(
                    isDense: true,
                    suffixText: 'hPa',
                    suffixStyle: TextStyle(color: AppColors.textFaint, fontWeight: FontWeight.w600),
                    border: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (value) {
                    final parsed = double.tryParse(value);
                    if (parsed != null) settings.qnhHpa = parsed;
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  'Set from departure ATIS/METAR for best accuracy.',
                  style: TextStyle(fontSize: 12, color: AppColors.textFaint, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const _SectionLabel('Flight lookup'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AeroDataBox API key', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                const SizedBox(height: 8),
                TextField(
                  controller: _apiKeyController,
                  obscureText: true,
                  style: dataTextStyle(size: 17),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (value) => settings.flightApiKey = value,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Optional — manual airport entry always works without one.',
                  style: TextStyle(fontSize: 12, color: AppColors.textFaint, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Map & airport data are bundled offline.\nNothing ever leaves your device.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: AppColors.textDisabled, height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: AppColors.textFaint,
        ),
      ),
    );
  }
}

class _StatToggleRow extends StatelessWidget {
  final StatId id;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;

  const _StatToggleRow({
    required this.id,
    required this.value,
    required this.onChanged,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Icon(id.icon, size: 17, color: AppColors.textMuted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(id.label, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
              ),
              PillSwitch(value: value, onChanged: onChanged),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}
