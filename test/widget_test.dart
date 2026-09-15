import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pftracker/data/settings/app_settings.dart';
import 'package:pftracker/main.dart';

void main() {
  testWidgets('Setup screen loads', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = await AppSettings.load();

    await tester.pumpWidget(PftrackerApp(settings: settings));
    await tester.pumpAndSettle();

    expect(find.text('pftracker'), findsOneWidget);
    expect(find.text('DEPARTURE'), findsOneWidget);
    expect(find.text('ARRIVAL'), findsOneWidget);
  });
}
