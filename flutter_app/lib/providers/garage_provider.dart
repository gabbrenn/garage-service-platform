import 'package:flutter/material.dart';
import '../models/garage.dart';
import '../models/garage_service.dart';
import '../services/api_service.dart';

class GarageProvider with ChangeNotifier {
  List<Garage> _nearbyGarages = [];
  Garage? _myGarage;
  List<GarageService> _myServices = [];
  List<GarageService> _garageServices = [];
  bool _isLoading = false;
  String? _error;

  List<Garage> get nearbyGarages => _nearbyGarages;
  Garage? get myGarage => _myGarage;
  List<GarageService> get myServices => _myServices;
  List<GarageService> get garageServices => _garageServices;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Future<void> loadNearbyGarages(double latitude, double longitude) async {
    try {
      setLoading(true);
      setError(null);

      _nearbyGarages = await ApiService.getNearbyGarages(latitude, longitude);
      
      setLoading(false);
    } catch (e) {
      setError(e.toString());
      setLoading(false);
    }
  }

  Future<void> loadGarageServices(int garageId) async {
    try {
      setLoading(true);
      setError(null);

      _garageServices = await ApiService.getGarageServices(garageId);
      
      setLoading(false);
    } catch (e) {
      setError(e.toString());
      setLoading(false);
    }
  }

  Future<bool> createGarage({
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    String? description,
    String? workingHours,
  }) async {
    try {
      setLoading(true);
      setError(null);

      _myGarage = await ApiService.createGarage(
        name: name,
        address: address,
        latitude: latitude,
        longitude: longitude,
        description: description,
        workingHours: workingHours,
      );

      setLoading(false);
      return true;
    } catch (e) {
      setError(e.toString());
      setLoading(false);
      return false;
    }
  }

  Future<void> loadMyGarage() async {
    try {
      setLoading(true);
      setError(null);

      _myGarage = await ApiService.getMyGarage();
      
      setLoading(false);
    } catch (e) {
      setError(e.toString());
      setLoading(false);
    }
  }

  Future<bool> createService({
    required String name,
    String? description,
    required double price,
    int? estimatedDurationMinutes,
  }) async {
    try {
      setLoading(true);
      setError(null);

      final service = await ApiService.createService(
        name: name,
        description: description,
        price: price,
        estimatedDurationMinutes: estimatedDurationMinutes,
      );

      _myServices.add(service);
      
      setLoading(false);
      return true;
    } catch (e) {
      setError(e.toString());
      setLoading(false);
      return false;
    }
  }

  Future<void> loadMyServices() async {
    try {
      setLoading(true);
      setError(null);

      _myServices = await ApiService.getMyServices();
      
      setLoading(false);
    } catch (e) {
      setError(e.toString());
      setLoading(false);
    }
  }

  Future<bool> updateMyGarage({
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    String? description,
    String? workingHours,
  }) async {
    try {
      setLoading(true);
      setError(null);

      final updated = await ApiService.updateMyGarage(
        name: name,
        address: address,
        latitude: latitude,
        longitude: longitude,
        description: description,
        workingHours: workingHours,
      );
      _myGarage = updated;

      setLoading(false);
      return true;
    } catch (e) {
      setError(e.toString());
      setLoading(false);
      return false;
    }
  }

  Future<bool> updateService({
    required int serviceId,
    String? name,
    String? description,
    double? price,
    int? estimatedDurationMinutes,
  }) async {
    try {
      setLoading(true);
      setError(null);

      final updated = await ApiService.updateService(
        serviceId: serviceId,
        name: name,
        description: description,
        price: price,
        estimatedDurationMinutes: estimatedDurationMinutes,
      );

      final idx = _myServices.indexWhere((s) => s.id == serviceId);
      if (idx != -1) {
        _myServices[idx] = updated;
      }

      setLoading(false);
      return true;
    } catch (e) {
      setError(e.toString());
      setLoading(false);
      return false;
    }
  }

  Future<bool> deleteService(int serviceId) async {
    try {
      setLoading(true);
      setError(null);

      final ok = await ApiService.deleteService(serviceId);
      if (ok) {
        _myServices.removeWhere((s) => s.id == serviceId);
      }

      setLoading(false);
      return ok;
    } catch (e) {
      setError(e.toString());
      setLoading(false);
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}