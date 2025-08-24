import 'garage.dart';
import 'garage_service.dart';
import 'user.dart';

class ServiceRequest {
  final int id;
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
    return ServiceRequest(
      id: json['id'],
      customer: json['customer'] != null ? User.fromJson(json['customer']) : null,
      garage: json['garage'] != null ? Garage.fromJson(json['garage']) : null,
      service: GarageService.fromJson(json['service']),
      customerLatitude: json['customerLatitude'].toDouble(),
      customerLongitude: json['customerLongitude'].toDouble(),
      customerAddress: json['customerAddress'],
      description: json['description'],
      garageResponse: json['garageResponse'],
      estimatedArrivalMinutes: json['estimatedArrivalMinutes'],
      status: RequestStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer': customer?.toJson(),
      'garage': garage?.toJson(),
      'service': service.toJson(),
      'customerLatitude': customerLatitude,
      'customerLongitude': customerLongitude,
      'customerAddress': customerAddress,
      'description': description,
      'garageResponse': garageResponse,
      'estimatedArrivalMinutes': estimatedArrivalMinutes,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
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