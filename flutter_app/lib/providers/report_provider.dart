import 'package:flutter/material.dart';
import '../models/daily_report_response.dart';
import '../services/api_service.dart';

class ReportProvider with ChangeNotifier {
  DailyReportResponse? _report;
  bool _isLoading = false;
  String? _error;
  DateTime? _from;
  DateTime? _to;

  DailyReportResponse? get report => _report;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get from => _from;
  DateTime? get to => _to;

  void _setState({DailyReportResponse? report, bool? loading, String? error, DateTime? from, DateTime? to}) {
    if (report != null) _report = report;
    if (loading != null) _isLoading = loading;
    if (error != null) _error = error;
    if (from != null) _from = from;
    if (to != null) _to = to;
    notifyListeners();
  }

  Future<void> loadReport({DateTime? from, DateTime? to}) async {
    try {
      _setState(loading: true, error: null);
      final resp = await ApiService.fetchDailyReport(from: from, to: to);
      _setState(report: resp, loading: false, from: from, to: to);
    } catch (e) {
      _setState(error: e.toString(), loading: false);
    }
  }

  void clear() {
    _report = null;
    _error = null;
    _from = null;
    _to = null;
    notifyListeners();
  }
}
