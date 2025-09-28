import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:garage_service_app/providers/theme_provider.dart';
import 'package:garage_service_app/screens/settings/settings_screen.dart';
import 'package:garage_service_app/l10n/gen/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child) {
  return ChangeNotifierProvider(
    create: (_) => ThemeProvider()..setMode(ThemeMode.light),
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() { SharedPreferences.setMockInitialValues({}); });
  testWidgets('SettingsScreen shows theme radio options and apply initially disabled', (tester) async {
    await tester.pumpWidget(_wrap(const SettingsScreen()));
    expect(find.text('Theme Mode'), findsOneWidget);
    expect(find.byType(Radio<ThemeMode>), findsNWidgets(3));
  final applyBtn = find.byKey(const Key('applyThemeButton'));
    expect(applyBtn, findsOneWidget);
    final ElevatedButton btnWidget = tester.widget(applyBtn);
    expect(btnWidget.onPressed, isNull);
  });

  testWidgets('Selecting Dark then Apply changes provider mode', (tester) async {
    final themeProv = ThemeProvider();
    // Start as light
    await themeProv.setMode(ThemeMode.light);
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: themeProv,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const SettingsScreen(),
      ),
    ));
  // No pumpAndSettle to avoid waiting on unrelated async tasks
    // Tap Dark radio label text (choose the third radio list row)
    await tester.tap(find.text('Dark'));
    await tester.pump();
    final applyFinder = find.byKey(const Key('applyThemeButton'));
    ElevatedButton btn = tester.widget(applyFinder);
    expect(btn.onPressed, isNotNull, reason: 'Apply button should enable after selecting different mode');
    await tester.tap(applyFinder);
    await tester.pump();
    expect(themeProv.mode, ThemeMode.dark);
  });
}
