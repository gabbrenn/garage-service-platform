import 'package:flutter/material.dart';
import '../models/service_request.dart';
import '../services/api_service.dart';

class ServiceRequestProvider with ChangeNotifier {
  List<ServiceRequest> _myRequests = [];
  List<ServiceRequest> _garageRequests = [];
  bool _isLoading = false;
  String? _error;

  List<ServiceRequest> get myRequests => _myRequests;
  List<ServiceRequest> get garageRequests => _garageRequests;
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

  Future<bool> createServiceRequest({
    required int garageId,
    required int serviceId,
    required double customerLatitude,
    required double customerLongitude,
    String? customerAddress,
    String? description,
  }) async {
    try {
      setLoading(true);
      setError(null);

      final request = await ApiService.createServiceRequest(
        garageId: garageId,
        serviceId: serviceId,
        customerLatitude: customerLatitude,
        customerLongitude: customerLongitude,
        customerAddress: customerAddress,
        description: description,
      );

      _myRequests.insert(0, request);
      
      setLoading(false);
      return true;
    } catch (e) {
      setError(e.toString());
      setLoading(false);
      return false;
    }
  }

  Future<void> loadMyRequests() async {
    try {
      setLoading(true);
      setError(null);

      _myRequests = await ApiService.getMyRequests();
      
      setLoading(false);
    } catch (e) {
      setError(e.toString());
      setLoading(false);
    }
  }

  Future<void> loadGarageRequests() async {
    try {
      setLoading(true);
      setError(null);

      _garageRequests = await ApiService.getGarageRequests();

      setLoading(false);
    } catch (e) {
      setError(e.toString());
      setLoading(false);
    }
  }


  Future<bool> respondToRequest({
    required int requestId,
    required RequestStatus status,
    String? response,
    int? estimatedArrivalMinutes,
  }) async {
    try {
      setLoading(true);
      setError(null);

      final updatedRequest = await ApiService.respondToRequest(
        requestId: requestId,
        status: status,
        response: response,
        estimatedArrivalMinutes: estimatedArrivalMinutes,
      );

      // Update the request in the list
      final index = _garageRequests.indexWhere((req) => req.id == requestId);
      if (index != -1) {
        _garageRequests[index] = updatedRequest;
      }
      
      setLoading(false);
      return true;
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