// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as jsu;
import '../config/app_config.dart';

/// Ensures the Google Maps JS API script is present before the map widget tries to access
/// the global `google.maps` namespace. Returns when loaded or immediately if already there.
Future<void> ensureMapsScriptLoaded() async {
  // Already loaded?
  if (_hasGoogleObject()) return;

  final key = AppConfig.mapsKeyWeb;
  if (key == null || key.isEmpty) {
    // Nothing we can do; map will likely fail later.
    return;
  }

  // Check if a script with this key already exists
  final existing = html.document.querySelectorAll('script').where((s) {
    final src = s.getAttribute('src');
    return src != null && src.contains('maps.googleapis.com/maps/api/js') && src.contains(key);
  });
  if (existing.isNotEmpty) {
    // Wait a short time to allow it to finish loading
    await _waitForGoogle();
    return;
  }

  final script = html.ScriptElement()
    ..type = 'text/javascript'
    ..src = 'https://maps.googleapis.com/maps/api/js?key=' + key
    ..async = true;
  final completer = Completer<void>();
  script.onError.first.then((_) {
    if (!completer.isCompleted) completer.complete();
  });
  script.onLoad.first.then((_) {
    if (!completer.isCompleted) completer.complete();
  });
  html.document.head!.append(script);
  await completer.future;
  // Poll briefly for the global object.
  await _waitForGoogle();
}

bool _hasGoogleObject() {
  final win = html.window;
  if (!jsu.hasProperty(win, 'google')) return false;
  final g = jsu.getProperty(win, 'google');
  if (g == null) return false;
  return jsu.hasProperty(g, 'maps');
}

Future<void> _waitForGoogle({Duration timeout = const Duration(seconds: 5)}) async {
  final start = DateTime.now();
  while (DateTime.now().difference(start) < timeout) {
    if (_hasGoogleObject()) return;
    await Future.delayed(const Duration(milliseconds: 100));
  }
}
