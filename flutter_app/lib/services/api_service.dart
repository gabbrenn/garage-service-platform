import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../models/garage.dart';
import '../models/garage_service.dart';
import '../models/service_request.dart';

class ApiService {
  // Configure via: flutter run --dart-define=API_BASE_URL=http://10.0.2.2/api (Android emulator)
  // or: flutter run -d windows --dart-define=API_BASE_URL=http://localhost/api
  // static const String baseUrl = String.fromEnvironment(
  //   'API_BASE_URL',
  //   defaultValue: 'http://localhost/api',
  // );
  static const String baseUrl = 'https://0770836a8b7a.ngrok-free.app/api';

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  static Future<void> removeToken() async {
    await _storage.delete(key: 'auth_token');
  }

  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Auth endpoints
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/signin'),
      // headers: await getHeaders(),
      headers: await getHeaders(),
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await saveToken(data['token']);
      return data;
    } else {
      // Throw a clear exception with backend message
      final errorData = jsonDecode(response.body);
      throw Exception('Login failed: ${errorData['message'] ?? response.body}');
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
      headers: await getHeaders(),
      body: jsonEncode({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phoneNumber': phoneNumber,
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

  // Garage endpoints
  static Future<List<Garage>> getNearbyGarages(double latitude, double longitude, {double radiusKm = 10.0}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/garages/nearby?latitude=$latitude&longitude=$longitude&radiusKm=$radiusKm'),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Garage.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load nearby garages: ${response.body}');
    }
  }

  static Future<List<GarageService>> getGarageServices(int garageId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/garages/$garageId/services'),
      headers: await getHeaders(),
    );

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
    final response = await http.post(
      Uri.parse('$baseUrl/garages'),
      headers: await getHeaders(),
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
    final response = await http.get(
      Uri.parse('$baseUrl/garages/my-garage'),
      headers: await getHeaders(),
    );

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
    final response = await http.put(
      Uri.parse('$baseUrl/garages/my-garage'),
      headers: await getHeaders(),
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
    final response = await http.post(
      Uri.parse('$baseUrl/services'),
      headers: await getHeaders(),
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
    final response = await http.get(
      Uri.parse('$baseUrl/services/my-services'),
      headers: await getHeaders(),
    );

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

    final response = await http.put(
      Uri.parse('$baseUrl/services/$serviceId'),
      headers: await getHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return GarageService.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update service: ${response.body}');
    }
  }

  static Future<bool> deleteService(int serviceId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/services/$serviceId'),
      headers: await getHeaders(),
    );

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
    final response = await http.post(
      Uri.parse('$baseUrl/service-requests'),
      headers: await getHeaders(),
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
    final response = await http.get(
      Uri.parse('$baseUrl/service-requests/my-requests'),
      headers: await getHeaders(),
    );
  
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ServiceRequest.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load requests: ${response.body}');
    }
  }

  static Future<List<ServiceRequest>> getGarageRequests() async {
    print("Calling: $baseUrl/service-requests/garage-requests");
    print("Headers: ${await getHeaders()}");
    final response = await http.get(
      Uri.parse('$baseUrl/service-requests/garage-requests'),
      headers: await getHeaders(),
    );

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
    final httpResponse = await http.put(
      Uri.parse('$baseUrl/service-requests/$requestId/respond'),
      headers: await getHeaders(),
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
}