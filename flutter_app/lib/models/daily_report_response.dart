import 'daily_report_entry.dart';

class DailyReportResponse {
  final int garageId;
  final DateTime from;
  final DateTime to;
  final List<DailyReportEntry> entries;
  final double? overallAverageEta;
  final int totalRequests;

  DailyReportResponse({
    required this.garageId,
    required this.from,
    required this.to,
    required this.entries,
    required this.overallAverageEta,
    required this.totalRequests,
  });

  factory DailyReportResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawEntries = json['entries'] ?? [];
    return DailyReportResponse(
      garageId: json['garageId'] ?? 0,
      from: DateTime.tryParse(json['from']?.toString() ?? '') ?? DateTime.now(),
      to: DateTime.tryParse(json['to']?.toString() ?? '') ?? DateTime.now(),
      entries: rawEntries.map((e) => DailyReportEntry.fromJson(e)).toList(),
      overallAverageEta: json['overallAverageEta'] == null ? null : (json['overallAverageEta'] as num).toDouble(),
      totalRequests: (json['totalRequests'] ?? 0) is num ? (json['totalRequests'] as num).toInt() : int.tryParse(json['totalRequests'].toString()) ?? 0,
    );
  }

  double get averagePerDay => entries.isEmpty ? 0 : totalRequests / entries.length;
}
