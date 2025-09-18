// ignore_for_file: avoid_web_libraries_in_flutter
// Web implementation: try to extract key from the Google Maps script tag in index.html
import 'dart:html' as html;

String getGoogleDirectionsApiKey() {
  // Try explicit dart-define first to allow override
  const define = String.fromEnvironment('GOOGLE_DIRECTIONS_API_KEY', defaultValue: '');
  if (define.isNotEmpty) return define;

  // Try meta tag used by google_maps_flutter_web: <meta name="google_maps_api_key" content="...">
  final metas = html.document.getElementsByTagName('meta').cast<html.MetaElement?>();
  for (final m in metas) {
    if (m == null) continue;
    if (m.name.toLowerCase() == 'google_maps_api_key') {
      final key = m.content.trim();
      if (key.isNotEmpty) return key;
    }
  }

  // Look for <script src="https://maps.googleapis.com/maps/api/js?key=...">
  for (final script in html.document.getElementsByTagName('script').cast<html.Element>()) {
    final src = script.getAttribute('src');
    if (src != null && src.contains('maps.googleapis.com/maps/api/js')) {
      final uri = Uri.tryParse(src);
      if (uri != null) {
        final key = uri.queryParameters['key'];
        if (key != null && key.isNotEmpty) return key;
      } else {
        // Fallback simple parse
        final idx = src.indexOf('key=');
        if (idx != -1) {
          final tail = src.substring(idx + 4);
          final end = tail.indexOf('&');
          final key = end == -1 ? tail : tail.substring(0, end);
          if (key.isNotEmpty) return key;
        }
      }
    }
  }
  return '';
}
