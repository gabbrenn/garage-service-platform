/// Decodes an encoded polyline string into a list of [LatLng]-like points.
/// This implementation supports Google polyline precision 5 and OSRM polyline6.
class DecodedPoint {
  final double latitude;
  final double longitude;
  const DecodedPoint(this.latitude, this.longitude);
}

List<DecodedPoint> decodePolyline(String encoded, {int precision = 5}) {
  final List<DecodedPoint> points = [];
  int index = 0;
  int lat = 0;
  int lng = 0;
  final factor = MathPow.pow10(precision);

  while (index < encoded.length) {
    int b;
    int shift = 0;
    int result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20 && index < encoded.length);
    int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    lat += dlat;

    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20 && index < encoded.length);
    int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    lng += dlng;

    points.add(DecodedPoint(lat / factor, lng / factor));
  }
  return points;
}

class MathPow {
  static double pow10(int p) {
    double v = 1.0;
    for (int i = 0; i < p; i++) {
      v *= 10.0;
    }
    return v;
  }
}
