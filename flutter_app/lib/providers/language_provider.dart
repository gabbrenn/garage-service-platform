import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  static const _prefKey = 'app_locale_code';
  Locale _locale = const Locale('en');
  bool _initialized = false;

  Locale get locale => _locale;
  bool get isInitialized => _initialized;

  Future<void> loadSavedLocale() async {
    if(_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefKey);
    if(code != null && code.isNotEmpty){
      _locale = Locale(code);
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, locale.languageCode);
    notifyListeners();
  }

  Future<void> resetToSystem() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
    // Not auto-detecting system locale now; default to en
    _locale = const Locale('en');
    notifyListeners();
  }
}