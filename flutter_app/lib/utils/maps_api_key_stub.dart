// Default (non-web) implementation: read from --dart-define
// Usage: flutter run --dart-define=GOOGLE_DIRECTIONS_API_KEY=YOUR_KEY

String getGoogleDirectionsApiKey() {
  const key = String.fromEnvironment('GOOGLE_DIRECTIONS_API_KEY', defaultValue: '');
  return key;
}
