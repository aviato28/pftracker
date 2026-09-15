import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import 'data/settings/app_settings.dart';
import 'presentation/setup/setup_screen.dart';
import 'presentation/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz_data.initializeTimeZones();
  final settings = await AppSettings.load();
  runApp(PftrackerApp(settings: settings));
}

class PftrackerApp extends StatelessWidget {
  final AppSettings settings;
  const PftrackerApp({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: settings,
      child: MaterialApp(
        title: 'pftracker',
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: const SetupScreen(),
      ),
    );
  }
}
