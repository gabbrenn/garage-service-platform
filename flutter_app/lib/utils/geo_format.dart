String formatCoordinate(double value, {int decimals = 4}) => value.toStringAsFixed(decimals);

String formatLat(double lat) => '${lat.toStringAsFixed(4)}°${lat >= 0 ? 'N' : 'S'}';
String formatLng(double lng) => '${lng.toStringAsFixed(4)}°${lng >= 0 ? 'E' : 'W'}';
