class DailyReportEntry {
  final DateTime day;
  final Map<String, int> statusCounts; // status -> count
  final double? averageEstimatedArrivalMinutes;

  DailyReportEntry({
    required this.day,
    required this.statusCounts,
    required this.averageEstimatedArrivalMinutes,
  });

  factory DailyReportEntry.fromJson(Map<String, dynamic> json) {
    final rawCounts = (json['statusCounts'] as Map<String, dynamic>? ) ?? {};
    final map = <String, int>{};
    rawCounts.forEach((k, v) {
      if (v == null) return;
      if (v is int) {
        map[k] = v;
      } else if (v is num) {
        map[k] = v.toInt();
      } else {
        final parsed = int.tryParse(v.toString());
        if (parsed != null) map[k] = parsed;
      }
    });

    return DailyReportEntry(
      day: DateTime.tryParse(json['day']?.toString() ?? '') ?? DateTime.now(),
      statusCounts: map,
      averageEstimatedArrivalMinutes: json['averageEstimatedArrivalMinutes'] == null
          ? null
          : (json['averageEstimatedArrivalMinutes'] as num).toDouble(),
    );
  }
}
