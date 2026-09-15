import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/settings/app_settings.dart';
import '../../domain/stat_id.dart';

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
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('Displayed stats', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          for (final id in StatId.values)
            SwitchListTile(
              title: Text(id.label),
              value: settings.isEnabled(id),
              onChanged: (v) => settings.setEnabled(id, v),
            ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('Barometric altitude', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _qnhController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'QNH reference pressure (hPa)',
                helperText: 'Set from departure-airport ATIS/METAR for accurate '
                    'barometric altitude; 1013.25 (standard atmosphere) is used '
                    'otherwise.',
                helperMaxLines: 3,
              ),
              onSubmitted: (value) {
                final parsed = double.tryParse(value);
                if (parsed != null) settings.qnhHpa = parsed;
              },
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('Automatic flight lookup', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _apiKeyController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'AeroDataBox API key (RapidAPI)',
                helperText: 'Optional — only needed for "look up by flight number". '
                    'Manual departure/arrival entry always works with no key.',
                helperMaxLines: 3,
              ),
              onSubmitted: (value) => settings.flightApiKey = value,
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Map tiles © OpenStreetMap contributors. Airport data from '
              'OpenFlights/OurAirports (ODbL).',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
