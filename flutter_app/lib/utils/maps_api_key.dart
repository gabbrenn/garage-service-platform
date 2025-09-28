import 'dart:async';
import 'package:flutter/services.dart';
import '../config/app_config.dart';

// Conditional import for web to read index.html script tag key
import 'maps_api_key_stub.dart'
  if (dart.library.html) 'maps_api_key_web.dart' as impl;

class MapsApiKeyProvider {
  static const MethodChannel _channel = MethodChannel('com.garageservice/native_config');
  static String? _cached;

  static Future<String> getKey() async {
    if (_cached != null) return _cached!;
    // 0) Try explicit env/platform key (dart-define > .env) for quick override without native channel.
    final envKey = AppConfig.effectiveMapsKey;
    if (envKey != null && envKey.isNotEmpty) {
      _cached = envKey;
      return envKey;
    }

    // 1) Try native (Android/iOS) via method channel
    try {
      final key = await _channel.invokeMethod<String>('getMapsApiKey');
      if (key != null && key.isNotEmpty) {
        _cached = key;
        return key;
      }
    } catch (_) {}

    // 2) Try platform-specific implementation (web reads script tag; others read dart-define)
    final key = impl.getGoogleDirectionsApiKey();
    _cached = key;
    return key;
  }
}
