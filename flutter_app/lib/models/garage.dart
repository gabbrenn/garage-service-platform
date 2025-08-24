import 'garage_service.dart';

class Garage {
  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? description;
  final String? workingHours;
  final DateTime createdAt;
  final List<GarageService>? services;

  Garage({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.description,
    this.workingHours,
    required this.createdAt,
    this.services,
  });

  factory Garage.fromJson(Map<String, dynamic> json) {
    return Garage(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      description: json['description'],
      workingHours: json['workingHours'],
      createdAt: DateTime.parse(json['createdAt']),
      services: json['services'] != null
          ? (json['services'] as List)
              .map((service) => GarageService.fromJson(service))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'workingHours': workingHours,
      'createdAt': createdAt.toIso8601String(),
      'services': services?.map((service) => service.toJson()).toList(),
    };
  }

  double distanceFrom(double lat, double lng) {
    // Simple distance calculation (Haversine formula would be more accurate)
    double deltaLat = latitude - lat;
    double deltaLng = longitude - lng;
    return (deltaLat * deltaLat + deltaLng * deltaLng) * 111; // Rough km conversion
  }
}