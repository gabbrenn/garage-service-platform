import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:garage_service_app/providers/theme_provider.dart';
import 'package:garage_service_app/widgets/theme_toggle_button.dart';
import 'package:garage_service_app/l10n/gen/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Widget _wrap() {
  return ChangeNotifierProvider(
    create: (_) => ThemeProvider()..setMode(ThemeMode.system),
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: const Scaffold(body: Center(child: ThemeToggleButton())),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() { SharedPreferences.setMockInitialValues({}); });

  testWidgets('ThemeToggleButton cycles tooltips in expected order', (tester) async {
    await tester.pumpWidget(_wrap());
    Finder button = find.byKey(const Key('themeToggleButton'));
    expect(button, findsOneWidget);

    Tooltip tooltipWidget() => tester.widget<Tooltip>(find.byType(Tooltip));

    String tooltipText() {
      final tooltipFinder = find.byType(Tooltip);
      expect(tooltipFinder, findsOneWidget);
      final t = tester.widget<Tooltip>(tooltipFinder);
      return t.message!;
    }

    // System -> should offer switch to Light
    expect(tooltipText(), 'Switch to Light Theme');

    await tester.tap(button);
    await tester.pump();
    expect(tooltipText(), 'Switch to Dark Theme'); // now light active

    await tester.tap(button);
    await tester.pump();
    expect(tooltipText(), 'Switch to System Theme'); // dark active

    await tester.tap(button);
    await tester.pump();
    expect(tooltipText(), 'Switch to Light Theme'); // back to system
  });
}
