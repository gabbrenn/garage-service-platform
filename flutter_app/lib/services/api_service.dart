import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/maps_api_key.dart';
import '../config/app_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../models/garage.dart';
import '../models/garage_service.dart';
import '../models/service_request.dart';
import '../models/daily_report_response.dart';
import '../models/notification.dart';

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException([this.message = 'Unauthorized']);
  @override
  String toString() => 'UnauthorizedException: $message';
}

class ApiService {
  // Base URL resolved dynamically (dart-define > .env > fallback) via AppConfig.
  static String get baseUrl => AppConfig.apiBaseUrl;

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static String? _cachedToken;
  static String? _cachedRefreshToken;
  static Timer? _refreshTimer; // proactive refresh timer

  // Optional client-side Google Directions. Provide via:
  // flutter run --dart-define=GOOGLE_DIRECTIONS_API_KEY=YOUR_KEY
  static Future<String> _getGoogleDirectionsApiKey() => MapsApiKeyProvider.getKey();

  static Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    final t = await _storage.read(key: 'auth_token');
    _cachedToken = t;
    return t;
  }

  static Future<void> saveToken(String token) async {
    _cachedToken = token;
    await _storage.write(key: 'auth_token', value: token);
    _scheduleProactiveRefresh(token); // (re)schedule
  }

  // Schedule a refresh about 60s before expiry (if exp claim present)
  static void _scheduleProactiveRefresh(String? jwt) {
    _refreshTimer?.cancel();
    if (jwt == null) return;
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return;
      final payload = jsonDecode(utf8.decode(base64Url.decode(_padBase64(parts[1]))));
      final exp = payload['exp'];
      if (exp is int) {
        final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
        final now = DateTime.now().toUtc();
        final diff = expiry.difference(now) - const Duration(seconds: 60);
        if (diff.isNegative) {
          // If already near/expired, attempt immediate refresh async
          _triggerImmediateRefresh();
        } else {
            _refreshTimer = Timer(diff, _triggerImmediateRefresh);
        }
      }
    } catch (_) {
      // ignore decoding errors
    }
  }

  static Future<void> _triggerImmediateRefresh() async {
    final ok = await _refreshAccessToken();
    if (!ok) {
      // Could notify listeners via a stream/callback in future
    }
  }

  static String _padBase64(String input) {
    // Add missing padding if needed
    final pad = input.length % 4;
  if (pad == 2) return input + '==';
  if (pad == 3) return input + '=';
  if (pad == 1) return input + '==='; // uncommon
    return input;
  }

  static Future<void> saveRefreshToken(String token) async {
    _cachedRefreshToken = token;
    await _storage.write(key: 'refresh_token', value: token);
  }

  static Future<String?> getRefreshToken() async {
    if(_cachedRefreshToken != null) return _cachedRefreshToken;
    _cachedRefreshToken = await _storage.read(key: 'refresh_token');
    return _cachedRefreshToken;
  }

  static Future<void> removeToken() async {
    _cachedToken = null;
    await _storage.delete(key: 'auth_token');
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  static Future<void> fullLogout() async {
    _cachedToken = null;
    _cachedRefreshToken = null;
    _refreshTimer?.cancel();
    _refreshTimer = null;
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'refresh_token');
  }

  static Future<Map<String, String>> getHeaders() async {
    var token = await getToken();
    if (token == null) {
      // Retry once after slight delay in case write not flushed yet (web)
      await Future.delayed(const Duration(milliseconds: 50));
      token = await getToken();
      if (token == null) {
        // debug print (can later guard with kDebugMode)
        // ignore: avoid_print
        print('[ApiService] Warning: auth token is null when building headers');
      }
    }
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Auth endpoints
  static Future<Map<String, dynamic>> login(String email, String password) async {
    // Do NOT include existing auth header on login; build minimal headers.
    final response = await http.post(
      Uri.parse('$baseUrl/auth/signin'),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await saveToken(data['token']);
      if(data['refreshToken'] != null){
        await saveRefreshToken(data['refreshToken']);
      }
      try {
        // If FCM is present, send token to backend (best-effort)
        // This call is also done in AuthProvider after login with fresh token.
        // await registerDeviceTokenIfAvailable();
      } catch (_) {}
      return data;
    } else {
      // Throw a clear exception with backend message
      final errorData = jsonDecode(response.body);
      throw Exception('Login failed: ${errorData['message'] ?? response.body}');
    }
  }

  static Future<void> registerDeviceToken(String token) async {
    final headers = await getHeaders();
    final resp = await http.post(
      Uri.parse('$baseUrl/notifications/register-token'),
      headers: headers,
      body: jsonEncode({ 'deviceToken': token, 'platform': 'flutter' }),
    );
    if (resp.statusCode != 200) {
      // Log and ignore for now; app should continue
      // ignore: avoid_print
      print('[ApiService] registerDeviceToken failed: ${resp.statusCode} ${resp.body}');
    }
  }

  static Future<void> removeDeviceToken(String token) async {
    final headers = await getHeaders();
    final uri = Uri.parse('$baseUrl/notifications/remove-token').replace(queryParameters: {'deviceToken': token});
    final resp = await http.delete(uri, headers: headers);
    if (resp.statusCode != 200) {
      // ignore: avoid_print
      print('[ApiService] removeDeviceToken failed: ${resp.statusCode} ${resp.body}');
    }
  }

  // Routing / distance
  static Future<Map<String, dynamic>?> getRoadDistance({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    try {
      // Prefer client-side Google Directions if an API key is supplied
      final googleRes = await _getGoogleDirectionsDistance(
        originLat: originLat,
        originLng: originLng,
        destLat: destLat,
        destLng: destLng,
      );
      if (googleRes != null) return googleRes;

      // Fallback to backend routing endpoint
      final headers = await getHeaders();
      final uri = Uri.parse('$baseUrl/routing/distance').replace(queryParameters: {
        'originLat': originLat.toString(),
        'originLng': originLng.toString(),
        'destLat': destLat.toString(),
        'destLng': destLng.toString(),
      });
      final resp = await http.get(uri, headers: headers);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return {
          'distanceKm': (data['distanceMeters'] as num).toDouble() / 1000.0,
          'durationMinutes': (data['durationSeconds'] as num).toDouble() / 60.0,
          'polyline': data['polyline'],
          'precision': data['precision'],
        };
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // Google Directions API (client-side) best-effort helper.
  // Returns null if no API key or request fails.
  static Future<Map<String, dynamic>?> _getGoogleDirectionsDistance({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    final key = await _getGoogleDirectionsApiKey();
    if (key.isEmpty) return null;
    try {
      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/directions/json',
        {
          'origin': '$originLat,$originLng',
          'destination': '$destLat,$destLng',
          'mode': 'driving',
          'alternatives': 'false',
          'units': 'metric',
          'key': key,
        },
      );
      final resp = await http.get(uri);
      if (resp.statusCode != 200) return null;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') return null;
      final routes = (data['routes'] as List?) ?? const [];
      if (routes.isEmpty) return null;
      final route = routes.first as Map<String, dynamic>;
      final legs = (route['legs'] as List?) ?? const [];
      if (legs.isEmpty) return null;
      final leg = legs.first as Map<String, dynamic>;
      final distanceMeters = ((leg['distance'] as Map?)?['value'] as num?)?.toDouble();
      final durationSeconds = ((leg['duration'] as Map?)?['value'] as num?)?.toDouble();
      final polyline = ((route['overview_polyline'] as Map?)?['points'] as String?) ?? '';
      if (distanceMeters == null || durationSeconds == null) return null;
      return {
        'distanceKm': distanceMeters / 1000.0,
        'durationMinutes': durationSeconds / 60.0,
        'polyline': polyline,
        'precision': 5, // Google Directions uses polyline5
      };
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
    required UserType userType,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/signup'),
      // No auth header needed when registering.
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'email': email.trim(),
        'phoneNumber': phoneNumber.trim(),
        'password': password,
        'userType': userType.toString().split('.').last,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Registration failed: ${response.body}');
    }
  }

  // Password reset endpoints
  static Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    final resp = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'email': email.trim()}),
    );
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      throw Exception('Failed to request password reset: ${resp.body}');
    }
  }

  static Future<Map<String, dynamic>> resetPassword({required String token, required String newPassword}) async {
    final resp = await http.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'token': token, 'newPassword': newPassword}),
    );
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      throw Exception('Failed to reset password: ${resp.body}');
    }
  }

  // Garage endpoints
  static Future<List<Garage>> getNearbyGarages(double latitude, double longitude, {double radiusKm = 10.0}) async {
    final response = await _httpGet(Uri.parse('$baseUrl/garages/nearby?latitude=$latitude&longitude=$longitude&radiusKm=$radiusKm'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Garage.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load nearby garages: ${response.body}');
    }
  }

  static Future<List<GarageService>> getGarageServices(int garageId) async {
    final response = await _httpGet(Uri.parse('$baseUrl/garages/$garageId/services'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => GarageService.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load garage services: ${response.body}');
    }
  }

  static Future<Garage> createGarage({
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    String? description,
    String? workingHours,
  }) async {
    final response = await _httpPost(
      Uri.parse('$baseUrl/garages'),
      body: jsonEncode({
        'name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'description': description,
        'workingHours': workingHours,
      }),
    );

    if (response.statusCode == 200) {
      return Garage.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create garage: ${response.body}');
    }
  }

  static Future<Garage?> getMyGarage() async {
    final response = await _httpGet(Uri.parse('$baseUrl/garages/my-garage'));

    if (response.statusCode == 200) {
      return Garage.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to load garage: ${response.body}');
    }
  }

  static Future<Garage> updateMyGarage({
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    String? description,
    String? workingHours,
  }) async {
    final response = await _httpPut(
      Uri.parse('$baseUrl/garages/my-garage'),
      body: jsonEncode({
        'name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'description': description,
        'workingHours': workingHours,
      }),
    );

    if (response.statusCode == 200) {
      return Garage.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update garage: ${response.body}');
    }
  }

  // Service endpoints
  static Future<GarageService> createService({
    required String name,
    String? description,
    required double price,
    int? estimatedDurationMinutes,
  }) async {
    final response = await _httpPost(
      Uri.parse('$baseUrl/services'),
      body: jsonEncode({
        'name': name,
        'description': description,
        'price': price,
        'estimatedDurationMinutes': estimatedDurationMinutes,
      }),
    );

    if (response.statusCode == 200) {
      return GarageService.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create service: ${response.body}');
    }
  }

  static Future<List<GarageService>> getMyServices() async {
    final response = await _httpGet(Uri.parse('$baseUrl/services/my-services'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => GarageService.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load services: ${response.body}');
    }
  }

  static Future<GarageService> updateService({
    required int serviceId,
    String? name,
    String? description,
    double? price,
    int? estimatedDurationMinutes,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'description': description,
      'price': price,
      'estimatedDurationMinutes': estimatedDurationMinutes,
    }..removeWhere((key, value) => value == null);

    final response = await _httpPut(Uri.parse('$baseUrl/services/$serviceId'), body: jsonEncode(body));

    if (response.statusCode == 200) {
      return GarageService.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update service: ${response.body}');
    }
  }

  static Future<bool> deleteService(int serviceId) async {
    final response = await _httpDelete(Uri.parse('$baseUrl/services/$serviceId'));

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to delete service: ${response.body}');
    }
  }

  // Service Request endpoints
  static Future<ServiceRequest> createServiceRequest({
    required int garageId,
    required int serviceId,
    required double customerLatitude,
    required double customerLongitude,
    String? customerAddress,
    String? description,
  }) async {
    final response = await _httpPost(
      Uri.parse('$baseUrl/service-requests'),
      body: jsonEncode({
        'garageId': garageId,
        'serviceId': serviceId,
        'customerLatitude': customerLatitude,
        'customerLongitude': customerLongitude,
        'customerAddress': customerAddress,
        'description': description,
      }),
    );

    if (response.statusCode == 200) {
      return ServiceRequest.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create service request: ${response.body}');
    }
  }

  static Future<List<ServiceRequest>> getMyRequests() async {
    final response = await _httpGet(Uri.parse('$baseUrl/service-requests/my-requests'));
  
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ServiceRequest.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load requests: ${response.body}');
    }
  }

  static Future<List<ServiceRequest>> getGarageRequests() async {
    final response = await _httpGet(Uri.parse('$baseUrl/service-requests/garage-requests'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ServiceRequest.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load garage requests: ${response.body}');
    }
  }

  static Future<ServiceRequest> respondToRequest({
    required int requestId,
    required RequestStatus status,
    String? response,
    int? estimatedArrivalMinutes,
  }) async {
    final httpResponse = await _httpPut(
      Uri.parse('$baseUrl/service-requests/$requestId/respond'),
      body: jsonEncode({
        'status': status.toString().split('.').last,
        'response': response,
        'estimatedArrivalMinutes': estimatedArrivalMinutes,
      }),
    );

    if (httpResponse.statusCode == 200) {
      return ServiceRequest.fromJson(jsonDecode(httpResponse.body));
    } else {
      throw Exception('Failed to respond to request: ${httpResponse.body}');
    }
  }

  static Future<DailyReportResponse> fetchDailyReport({DateTime? from, DateTime? to}) async {
    final params = <String, String>{};
    if (from != null) params['from'] = from.toIso8601String().split('T').first;
    if (to != null) params['to'] = to.toIso8601String().split('T').first;
    final uri = Uri.parse('$baseUrl/reports/daily').replace(queryParameters: params.isEmpty ? null : params);

    final response = await _httpGet(uri);
    return DailyReportResponse.fromJson(jsonDecode(response.body));
  }

  // ---------------- Notification endpoints ----------------
  static Future<List<AppNotification>> getNotifications() async {
    final resp = await _httpGet(Uri.parse('$baseUrl/notifications/my'));
    if(resp.statusCode == 200){
      final data = jsonDecode(resp.body) as List<dynamic>;
      return data.map((e) => AppNotification.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load notifications: ${resp.body}');
    }
  }

  static Future<AppNotification> markNotificationRead(int id) async {
    final resp = await _httpPut(Uri.parse('$baseUrl/notifications/$id/read'));
    if(resp.statusCode == 200){
      return AppNotification.fromJson(jsonDecode(resp.body));
    } else if(resp.statusCode == 404){
      throw Exception('Notification not found');
    } else {
      throw Exception('Failed to mark notification read: ${resp.body}');
    }
  }

  static Future<void> markAllNotificationsRead() async {
    final resp = await _httpPut(Uri.parse('$baseUrl/notifications/mark-all-read'));
    if(resp.statusCode != 200){
      throw Exception('Failed to mark all notifications read: ${resp.body}');
    }
  }

  // ---------------- Dev/Test utilities ----------------
  static Future<Map<String, dynamic>> sendTestPushCustom({
    String? title,
    String? message,
    String? channelId,
    String? sound,
    bool urgent = false,
  }) async {
    final headers = await getHeaders();
    final body = {
      if (title != null) 'title': title,
      if (message != null) 'message': message,
      if (channelId != null) 'channelId': channelId,
      if (sound != null) 'sound': sound,
      'urgent': urgent.toString(),
    };
    final resp = await http.post(
      Uri.parse('$baseUrl/notifications/test-push-custom'),
      headers: headers,
      body: jsonEncode(body),
    );
    if (resp.statusCode == 200) return jsonDecode(resp.body);
    throw Exception('Failed to send test push: ${resp.body}');
  }

  // ------------------ Auto refresh core ------------------
  static Future<http.Response> _httpGet(Uri uri) async {
    final headers = await getHeaders();
    final resp = await http.get(uri, headers: headers);
    if(resp.statusCode == 401){
      _debugAuthState('GET', uri, headers);
      final retried = await _attemptRefreshAndRetry(() async => await http.get(uri, headers: await getHeaders()));
      return retried;
    }
    return resp;
  }

  static Future<http.Response> _httpPost(Uri uri, {Object? body}) async {
    final headers = await getHeaders();
    final resp = await http.post(uri, headers: headers, body: body);
    if(resp.statusCode == 401){
      _debugAuthState('POST', uri, headers);
      final retried = await _attemptRefreshAndRetry(() async => await http.post(uri, headers: await getHeaders(), body: body));
      return retried;
    }
    return resp;
  }

  static Future<http.Response> _httpPut(Uri uri, {Object? body}) async {
    final headers = await getHeaders();
    final resp = await http.put(uri, headers: headers, body: body);
    if(resp.statusCode == 401){
      _debugAuthState('PUT', uri, headers);
      final retried = await _attemptRefreshAndRetry(() async => await http.put(uri, headers: await getHeaders(), body: body));
      return retried;
    }
    return resp;
  }

  static Future<http.Response> _httpDelete(Uri uri) async {
    final headers = await getHeaders();
    final resp = await http.delete(uri, headers: headers);
    if(resp.statusCode == 401){
      _debugAuthState('DELETE', uri, headers);
      final retried = await _attemptRefreshAndRetry(() async => await http.delete(uri, headers: await getHeaders()));
      return retried;
    }
    return resp;
  }

  // ---------------- Account endpoints ----------------
  static Future<bool> deleteAccount() async {
    final resp = await _httpDelete(Uri.parse('$baseUrl/account'));
    if (resp.statusCode == 200 || resp.statusCode == 204) {
      return true;
    }
    throw Exception('Failed to delete account: ${resp.statusCode} ${resp.body}');
  }

  static Future<http.Response> _attemptRefreshAndRetry(Future<http.Response> Function() retryFn) async {
    final ok = await _refreshAccessToken();
    if(!ok){
      throw UnauthorizedException('Session expired');
    }
    return await retryFn();
  }

  static Future<bool> _refreshAccessToken() async {
    final refresh = await getRefreshToken();
    if (refresh == null) return false;
    try {
      final resp = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'refreshToken': refresh}),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final newAccess = data['accessToken'];
        if (newAccess != null) {
          await saveToken(newAccess); // schedules next proactive refresh
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static void _debugAuthState(String method, Uri uri, Map<String,String> headers){
    final auth = headers['Authorization'];
    if(auth == null){
      // ignore: avoid_print
      print('[ApiService][401] No Authorization header for $method $uri');
    } else {
      // Attempt to parse expiry
      try {
        final parts = auth.substring(7).split('.');
        if(parts.length==3){
          final payload = jsonDecode(utf8.decode(base64Url.decode(_padBase64(parts[1]))));
          final exp = payload['exp'];
          if(exp is int){
            final expiry = DateTime.fromMillisecondsSinceEpoch(exp*1000, isUtc: true);
            final now = DateTime.now().toUtc();
            final secs = expiry.difference(now).inSeconds;
            // ignore: avoid_print
            print('[ApiService][401] Authorization present; expires in ${secs}s (at $expiry UTC) for $method $uri');
          }
        }
      } catch(_) {
        // ignore
      }
    }
  }

}