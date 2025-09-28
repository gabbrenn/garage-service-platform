import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:garage_service_app/providers/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeProvider', () {
    test('load() sets default light when no pref', () async {
      SharedPreferences.setMockInitialValues({});
      final prov = ThemeProvider();
      await prov.load();
      expect(prov.loaded, isTrue);
      expect(prov.mode, ThemeMode.light);
    });

    test('setMode persists and load retrieves', () async {
      SharedPreferences.setMockInitialValues({});
      final prov = ThemeProvider();
      await prov.setMode(ThemeMode.dark);
      // simulate new instance
      final prov2 = ThemeProvider();
      await prov2.load();
      expect(prov2.mode, ThemeMode.dark);
    });

    test('cycleMode sequence system -> light -> dark -> system', () async {
      SharedPreferences.setMockInitialValues({});
      final prov = ThemeProvider();
      // start from system explicitly
      await prov.setMode(ThemeMode.system);
      await prov.cycleMode();
      expect(prov.mode, ThemeMode.light);
      await prov.cycleMode();
      expect(prov.mode, ThemeMode.dark);
      await prov.cycleMode();
      expect(prov.mode, ThemeMode.system);
    });
  });
}
