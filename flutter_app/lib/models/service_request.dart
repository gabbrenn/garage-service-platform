import 'garage.dart';
import 'garage_service.dart';
import 'user.dart';

class ServiceRequest {
  final int id;

  // Flattened customer info
  final String? customerEmail;
  final String? customerName;
  final String? customerPhone;

  // Flattened garage info
  final String? garageName;
  final String? garageAddress;
  final String? garagePhone;

  // Flattened service info
  final String? serviceName;
  final String? serviceDescription;
  final double? servicePrice;

  final User? customer;
  final Garage? garage;
  final GarageService service;

  final double customerLatitude;
  final double customerLongitude;
  final String? customerAddress;
  final String? description;
  final String? garageResponse;
  final int? estimatedArrivalMinutes;
  final RequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceRequest({
    required this.id,
    this.customerEmail,
    this.customerName,
    this.customerPhone,
    this.garageName,
    this.garageAddress,
    this.garagePhone,
    this.serviceName,
    this.serviceDescription,
    this.servicePrice,
    this.customer,
    this.garage,
    required this.service,
    required this.customerLatitude,
    required this.customerLongitude,
    this.customerAddress,
    this.description,
    this.garageResponse,
    this.estimatedArrivalMinutes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    // Extract flattened fields
    final String? flatCustomerEmail = json['customerEmail'] as String?;
    final String? flatCustomerName = json['customerName'] as String?;
    final String? flatCustomerPhone = json['customerPhone'] as String?;
    final String? flatGarageName = json['garageName'] as String?;
    final String? flatGarageAddress = json['garageAddress'] as String?;
    final String? flatGaragePhone = json['garagePhone'] as String?;

    // Split customer name into first/last
    String firstName = 'Unknown';
    String lastName = '';
    if (flatCustomerName != null && flatCustomerName.trim().isNotEmpty) {
      final parts = flatCustomerName.trim().split(' ');
      firstName = parts.first;
      if (parts.length > 1) {
        lastName = parts.sublist(1).join(' ');
      }
    }

    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    final double flatLat = parseDouble(json['customerLatitude']);
    final double flatLng = parseDouble(json['customerLongitude']);

    final created = DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now();
    final updated = DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? created;

    return ServiceRequest(
      id: json['id'] ?? 0,
      customerEmail: flatCustomerEmail,
      customerName: flatCustomerName,
      customerPhone: flatCustomerPhone,
      garageName: flatGarageName,
      garageAddress: flatGarageAddress,
      garagePhone: flatGaragePhone,
      serviceName: json['serviceName'] as String?,
      serviceDescription: json['serviceDescription'] as String?,
      servicePrice: json['servicePrice'] != null ? (json['servicePrice'] as num).toDouble() : 0.0,
      // Build lightweight nested objects from flattened fields so UI can render names/phones
      customer: User(
        id: 0,
        firstName: firstName,
        lastName: lastName,
        email: flatCustomerEmail ?? '',
        phoneNumber: flatCustomerPhone ?? '',
        userType: UserType.CUSTOMER,
        createdAt: created,
      ),
      garage: Garage(
        id: 0,
        name: flatGarageName ?? 'Unknown Garage',
        address: flatGarageAddress ?? '',
        latitude: 0.0,
        longitude: 0.0,
        description: null,
        workingHours: null,
        createdAt: created,
      ),
      service: GarageService(
        id: 0,
        name: json['serviceName'] ?? 'Unknown Service',
        description: json['serviceDescription'],
        price: json['servicePrice'] != null ? (json['servicePrice'] as num).toDouble() : 0.0,
        createdAt: created,
      ),
      customerLatitude: flatLat,
      customerLongitude: flatLng,
      customerAddress: json['customerAddress'],
      description: json['description'],
      garageResponse: json['garageResponse'],
      estimatedArrivalMinutes: json['estimatedArrivalMinutes'] != null ? (json['estimatedArrivalMinutes'] as num).toInt() : null,
      status: RequestStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (json['status'] ?? 'PENDING'),
        orElse: () => RequestStatus.PENDING,
      ),
      createdAt: created,
      updatedAt: updated,
    );
  }

  String get statusText {
    switch (status) {
      case RequestStatus.PENDING:
        return 'Pending';
      case RequestStatus.ACCEPTED:
        return 'Accepted';
      case RequestStatus.REJECTED:
        return 'Rejected';
      case RequestStatus.IN_PROGRESS:
        return 'In Progress';
      case RequestStatus.COMPLETED:
        return 'Completed';
      case RequestStatus.CANCELLED:
        return 'Cancelled';
    }
  }

  String get formattedEstimatedArrival {
    if (estimatedArrivalMinutes == null) return 'Not specified';
    if (estimatedArrivalMinutes! < 60) return '${estimatedArrivalMinutes}min';
    int hours = estimatedArrivalMinutes! ~/ 60;
    int minutes = estimatedArrivalMinutes! % 60;
    return minutes > 0 ? '${hours}h ${minutes}min' : '${hours}h';
  }
}

enum RequestStatus {
  PENDING,
  ACCEPTED,
  REJECTED,
  IN_PROGRESS,
  COMPLETED,
  CANCELLED
}
