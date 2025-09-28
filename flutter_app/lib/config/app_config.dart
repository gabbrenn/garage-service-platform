import '../main.dart';
import 'package:flutter/foundation.dart';

/// Central configuration access; precedence: --dart-define > .env > built-in fallback.
class AppConfig {
  static String get apiBaseUrl {
    final initial = Env.get('API_BASE_URL')?.trim();
    if (initial == null || initial.isEmpty) {
      return 'https://garage-service-platform.onrender.com/api';
    }
    var cleaned = initial;
    while (cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    return cleaned;
  }

  /// Platform specific Maps keys (web, android, ios). Falls back to legacy GOOGLE_MAPS_API_KEY or directions key.
  static String? get mapsKeyWeb =>
      Env.get('GOOGLE_MAPS_API_KEY_WEB') ?? Env.get('GOOGLE_MAPS_API_KEY');
  static String? get mapsKeyAndroid =>
      Env.get('GOOGLE_MAPS_API_KEY_ANDROID') ?? Env.get('GOOGLE_MAPS_API_KEY');
  static String? get mapsKeyIOS =>
      Env.get('GOOGLE_MAPS_API_KEY_IOS') ?? Env.get('GOOGLE_MAPS_API_KEY');

  /// Generic key selection based on current platform (non-web assumes native manifest/method channel may still override).
  static String? get effectiveMapsKey {
    if (kIsWeb) return mapsKeyWeb;
    // We could refine by Platform.isAndroid/ios but avoid dart:io on web.
    return mapsKeyAndroid ?? mapsKeyIOS ?? Env.get('GOOGLE_DIRECTIONS_API_KEY');
  }
}
