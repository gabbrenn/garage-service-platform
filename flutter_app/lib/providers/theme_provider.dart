import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const _key = 'app_theme_mode';
  ThemeMode _mode = ThemeMode.light;
  bool _loaded = false;

  ThemeMode get mode => _mode;
  bool get loaded => _loaded;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getString(_key);
      switch (v) {
        case 'dark': _mode = ThemeMode.dark; break;
        case 'system': _mode = ThemeMode.system; break;
        default: _mode = ThemeMode.light; break;
      }
    } catch (_) {
      _mode = ThemeMode.light;
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = switch(mode){
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system'
      };
      await prefs.setString(_key, str);
    } catch (_) {}
  }

  // Legacy binary toggle kept for backward compatibility.
  Future<void> toggle() async {
    if (_mode == ThemeMode.light) {
      await setMode(ThemeMode.dark);
    } else if (_mode == ThemeMode.dark) {
      await setMode(ThemeMode.light);
    } else { // system -> light
      await setMode(ThemeMode.light);
    }
  }

  // New: cycle through system -> light -> dark -> system
  Future<void> cycleMode() async {
    switch (_mode) {
      case ThemeMode.system:
        await setMode(ThemeMode.light);
        break;
      case ThemeMode.light:
        await setMode(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        await setMode(ThemeMode.system);
        break;
    }
  }

  IconData currentIcon() {
    switch (_mode) {
      case ThemeMode.system: return Icons.auto_mode;
      case ThemeMode.light: return Icons.light_mode;
      case ThemeMode.dark: return Icons.dark_mode;
    }
  }

  String currentTooltip() {
    switch (_mode) {
      case ThemeMode.system: return 'System Theme';
      case ThemeMode.light: return 'Light Theme';
      case ThemeMode.dark: return 'Dark Theme';
    }
  }

  String nextTooltip() {
    switch (_mode) {
      case ThemeMode.system: return 'Switch to Light Theme';
      case ThemeMode.light: return 'Switch to Dark Theme';
      case ThemeMode.dark: return 'Switch to System Theme';
    }
  }
}
