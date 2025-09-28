import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../l10n/gen/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/service_request_provider.dart';
import '../../models/daily_report_entry.dart';
import '../../models/service_request.dart';
import '../../utils/csv_download_util.dart';
import '../../theme/app_colors.dart';

class GarageReportScreen extends StatefulWidget {
  const GarageReportScreen({super.key});

  @override
  State<GarageReportScreen> createState() => _GarageReportScreenState();
}

class _GarageReportScreenState extends State<GarageReportScreen> {
  DateTimeRange? _range;
  bool _showEta = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      // Load aggregated report
      await context.read<ReportProvider>().loadReport();
      // Also load detailed requests for the garage so we can build the detailed table
      try {
        await context.read<ServiceRequestProvider>().loadGarageRequests();
      } catch (_) {}
    });
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: _range ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 6)),
            end: now,
          ),
    );
    if (picked != null) {
      setState(() => _range = picked);
      await context.read<ReportProvider>().loadReport(
            from: picked.start,
            to: picked.end,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportProvider>();
    final report = provider.report;
    final requestProvider = context.watch<ServiceRequestProvider>();
    final allRequests = requestProvider.garageRequests;
    final from = _range?.start;
    final to = _range?.end;
    // Filter requests by selected date range (inclusive) if range chosen
    List<ServiceRequest> filteredRequests = allRequests;
    if (from != null && to != null) {
      filteredRequests = allRequests.where((r) {
        final d = DateTime(r.createdAt.year, r.createdAt.month, r.createdAt.day);
        final start = DateTime(from.year, from.month, from.day);
        final end = DateTime(to.year, to.month, to.day);
        return (d.isAtSameMomentAs(start) || d.isAfter(start)) && (d.isAtSameMomentAs(end) || d.isBefore(end));
      }).toList();
    }
    filteredRequests.sort((a,b) => b.createdAt.compareTo(a.createdAt));

    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.dailyReportTitle),
        actions: [
          IconButton(
            onPressed: report == null ? null : () => _exportCsv(report),
            tooltip: loc.exportCsvTooltip,
            icon: const Icon(Icons.download),
          ),
          // Detailed export button
          IconButton(
            onPressed: filteredRequests.isEmpty ? null : () => _exportDetailedCsv(filteredRequests, loc),
            tooltip: 'Export detailed CSV',
            icon: const Icon(Icons.table_view),
          ),
          IconButton(
            onPressed: report == null ? null : () => _shareReport(report),
            tooltip: loc.shareSaveTooltip,
            icon: const Icon(Icons.share),
          ),
          IconButton(
            onPressed: _pickRange,
            tooltip: loc.selectDateRangeTooltip,
            icon: const Icon(Icons.date_range),
          ),
            IconButton(
            onPressed: () => provider.loadReport(from: _range?.start, to: _range?.end),
            tooltip: loc.refreshTooltip,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () => setState(() => _showEta = !_showEta),
            tooltip: loc.toggleEtaChartTooltip,
            icon: Icon(_showEta ? Icons.visibility : Icons.visibility_off),
          ),
        ],
      ),
      body: provider.isLoading && report == null
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? _ErrorView(message: provider.error!, onRetry: () => provider.loadReport(from: _range?.start, to: _range?.end))
              : report == null
                  ? Center(child: Text(loc.noDataLabel))
                  : RefreshIndicator(
                      onRefresh: () => provider.loadReport(from: _range?.start, to: _range?.end),
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _SummaryHeader(report: report),
                          const SizedBox(height: 16),
                          if (report.entries.isNotEmpty) _StatusStackedBar(entries: report.entries),
                          if (_showEta && report.entries.any((e) => e.averageEstimatedArrivalMinutes != null)) ...[
                            const SizedBox(height: 24),
                            _EtaLineChart(entries: report.entries),
                          ],
                          const SizedBox(height: 24),
                          _DetailedRequestsSection(
                            requests: filteredRequests,
                            loading: requestProvider.isLoading && allRequests.isEmpty,
                          ),
                          const SizedBox(height: 24),
                          Text(loc.dailyBreakdownTitle, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          ...report.entries.map((e) => _DailyCard(entry: e)),
                        ],
                      ),
                    ),
    );
  }

  Future<void> _exportDetailedCsv(List<ServiceRequest> requests, AppLocalizations loc) async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('Detailed Service Requests');
      if (_range != null) {
        buffer.writeln('Period,${_range!.start.toIso8601String().split('T').first},${_range!.end.toIso8601String().split('T').first}');
      }
      buffer.writeln();
      buffer.writeln('Date,Client,Service,Amount,Status');
      for (final r in requests) {
        final date = r.createdAt.toIso8601String().split('T').first;
        final client = (r.customerName ?? '').replaceAll(',', ' ');
        final service = (r.serviceName ?? '').replaceAll(',', ' ');
        final amount = (r.servicePrice ?? 0).toStringAsFixed(2);
        final status = r.statusText.replaceAll(',', ' ');
        buffer.writeln([date, client, service, amount, status].join(','));
      }
      final csv = buffer.toString();
      await Clipboard.setData(ClipboardData(text: csv));
      final fileName = 'garage-detailed-${DateTime.now().millisecondsSinceEpoch}.csv';
      final result = await CsvDownloadUtil.downloadCsv(fileName, csv);
      if (!mounted) return;
      if (result.triggeredBrowserDownload) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Detailed CSV downloaded & copied')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Detailed CSV saved & copied: ${result.filePath ?? ''}')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Detailed export failed: $e')));
    }
  }

  Future<void> _exportCsv(dynamic report) async {
    try {
  final buffer = StringBuffer();
  final loc = AppLocalizations.of(context);
      // Header meta
  buffer.writeln(loc.dailyReportTitle);
  buffer.writeln('${loc.periodLabel},${report.from.toString().split(' ').first},${report.to.toString().split(' ').first}');
  buffer.writeln('${loc.totalRequestsLabel},${report.totalRequests}');
  buffer.writeln('${loc.avgPerDayLabel},${report.averagePerDay.toStringAsFixed(2)}');
  buffer.writeln('${loc.avgEtaLabel} (min),${report.overallAverageEta ?? ''}');
      buffer.writeln();
      // Columns
  buffer.writeln('Date,PENDING,ACCEPTED,IN_PROGRESS,COMPLETED,REJECTED,CANCELLED,${loc.avgEtaLabel} (min)');
      for (final e in report.entries) {
        final day = e.day.toString().split(' ').first;
        String fmtEta = e.averageEstimatedArrivalMinutes?.toStringAsFixed(2) ?? '';
        buffer.writeln([
          day,
          e.statusCounts['PENDING'] ?? 0,
            e.statusCounts['ACCEPTED'] ?? 0,
            e.statusCounts['IN_PROGRESS'] ?? 0,
            e.statusCounts['COMPLETED'] ?? 0,
            e.statusCounts['REJECTED'] ?? 0,
            e.statusCounts['CANCELLED'] ?? 0,
            fmtEta
        ].join(','));
      }
      final csv = buffer.toString();
      // Clipboard copy for quick paste
      await Clipboard.setData(ClipboardData(text: csv));

      final filename = 'garage-report-${report.from.toString().split(' ').first}-${report.to.toString().split(' ').first}.csv';
      final result = await CsvDownloadUtil.downloadCsv(filename, csv);

      if (!mounted) return;
      if (result.triggeredBrowserDownload) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.csvDownloadedAndCopied)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.csvSavedAndCopiedWithPath(result.filePath ?? ''))));
      }
    } catch (e) {
      if (!mounted) return;
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${loc.exportFailedGeneric}: $e')));
    }
  }

  Future<void> _shareReport(dynamic report) async {
    try {
      final loc = AppLocalizations.of(context);
      final csv = await _buildCsv(report);
      final dir = await getTemporaryDirectory();
      final file = await File('${dir.path}/garage-report-${report.from.toString().split(' ').first}-${report.to.toString().split(' ').first}.csv').create();
      await file.writeAsString(csv);
      await Share.shareXFiles([XFile(file.path)], text: loc.dailyReportTitle);
    } catch(e){
      if(!mounted) return;
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${loc.shareFailedGeneric}: $e')));
    }
  }

  Future<String> _buildCsv(dynamic report) async {
    final entries = List.of(report.entries);
    entries.sort((a,b) => a.day.compareTo(b.day)); // ascending
    final totalDays = entries.length;
    final avgPerDay = totalDays == 0 ? 0 : report.totalRequests / totalDays;
    final buffer = StringBuffer();
    final loc = AppLocalizations.of(context);
    buffer.writeln(loc.dailyReportTitle.toUpperCase());
    buffer.writeln('${loc.generatedAtLabel},${DateTime.now().toIso8601String()}');
    buffer.writeln('${loc.periodStartLabel},${report.from.toString().split(' ').first}');
    buffer.writeln('${loc.periodEndLabel},${report.to.toString().split(' ').first}');
    buffer.writeln('${loc.totalDaysLabel},$totalDays');
    buffer.writeln('${loc.totalRequestsLabel},${report.totalRequests}');
    buffer.writeln('${loc.avgRequestsPerDayLabel},${avgPerDay.toStringAsFixed(2)}');
    buffer.writeln('${loc.avgEtaLabel} (min),${report.overallAverageEta ?? ''}');
    buffer.writeln();
    buffer.writeln('Date,PENDING,ACCEPTED,IN_PROGRESS,COMPLETED,REJECTED,CANCELLED,TOTAL,${loc.avgEtaLabel} (min)');
    for (final e in entries) {
      final day = e.day.toString().split(' ').first;
      final pending = e.statusCounts['PENDING'] ?? 0;
      final accepted = e.statusCounts['ACCEPTED'] ?? 0;
      final inProgress = e.statusCounts['IN_PROGRESS'] ?? 0;
      final completed = e.statusCounts['COMPLETED'] ?? 0;
      final rejected = e.statusCounts['REJECTED'] ?? 0;
      final cancelled = e.statusCounts['CANCELLED'] ?? 0;
      final total = pending + accepted + inProgress + completed + rejected + cancelled;
      final fmtEta = e.averageEstimatedArrivalMinutes?.toStringAsFixed(2) ?? '';
      buffer.writeln([
        day,
        pending,
        accepted,
        inProgress,
        completed,
        rejected,
        cancelled,
        total,
        fmtEta
      ].join(','));
    }
    return buffer.toString();
  }
}

class _DetailedRequestsSection extends StatelessWidget {
  final List<ServiceRequest> requests;
  final bool loading;
  const _DetailedRequestsSection({required this.requests, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.table_chart, size: 18),
                const SizedBox(width: 6),
                Text('Detailed Requests', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text('${requests.length} items', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),
            if (requests.isEmpty)
              const Text('No requests found for this period', style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic))
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 40,
                  dataRowMinHeight: 40,
                  columns: const [
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Client')),
                    DataColumn(label: Text('Service')),
                    DataColumn(label: Text('Amount')),
                    DataColumn(label: Text('Status')),
                  ],
                  rows: requests.map((r) {
                    final date = '${r.createdAt.year}-${r.createdAt.month.toString().padLeft(2,'0')}-${r.createdAt.day.toString().padLeft(2,'0')}';
                    final amount = (r.servicePrice ?? 0).toStringAsFixed(2);
                    return DataRow(cells: [
                      DataCell(Text(date)),
                      DataCell(Text(r.customerName ?? '')),
                      DataCell(Text(r.serviceName ?? '')),
                      DataCell(Text(amount)),
                      DataCell(_StatusChip(status: r.statusText)),
                    ]);
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});
  Color _color(String s) {
    switch (s.toLowerCase()) {
      case 'pending': return AppColors.pending;
      case 'accepted': return AppColors.accepted;
      case 'in progress': return AppColors.inProgress;
      case 'completed': return AppColors.completed;
      case 'rejected': return AppColors.rejected;
      case 'cancelled': return AppColors.cancelled;
      default: return Colors.blueGrey;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color(status).withOpacity(.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(status, style: TextStyle(fontSize: 11, color: _color(status), fontWeight: FontWeight.w600)),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  final dynamic report; // DailyReportResponse
  const _SummaryHeader({required this.report});

  @override
  Widget build(BuildContext context) {
  final dateStyle = TextStyle(color: Colors.grey[700]);
  final loc = AppLocalizations.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.summaryTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 20,
              runSpacing: 8,
              children: [
                _metric(loc.periodLabel, '${report.from.toString().split(' ').first} → ${report.to.toString().split(' ').first}', dateStyle),
                _metric(loc.totalRequestsLabel, report.totalRequests.toString(), dateStyle),
                _metric(loc.avgPerDayLabel, report.averagePerDay.toStringAsFixed(2), dateStyle),
                _metric(loc.avgEtaLabel, report.overallAverageEta == null ? '—' : _fmtEta(report.overallAverageEta!), dateStyle),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value, TextStyle? style) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: style?.copyWith(fontWeight: FontWeight.w600, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _fmtEta(double minutes) {
    final m = minutes.round();
    if (m < 60) return '$m min';
    final h = m ~/ 60; final r = m % 60;
    return r > 0 ? '${h}h ${r}m' : '${h}h';
  }
}

class _StatusStackedBar extends StatelessWidget {
  final List<DailyReportEntry> entries;
  const _StatusStackedBar({required this.entries});

  static const _order = [
    'PENDING','ACCEPTED','IN_PROGRESS','COMPLETED','REJECTED','CANCELLED'
  ];
  static const _colors = {
    'PENDING': AppColors.pending,
    'ACCEPTED': AppColors.accepted,
    'IN_PROGRESS': AppColors.inProgress,
    'COMPLETED': AppColors.completed,
    'REJECTED': AppColors.rejected,
    'CANCELLED': AppColors.cancelled,
  };

  @override
  Widget build(BuildContext context) {
    final reversed = entries.reversed.toList(); // chronological left->right
    return SizedBox(
      height: 220,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context).requestsByStatusDaily, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Expanded(
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= reversed.length) return const SizedBox();
                            final d = reversed[idx].day;
                            return Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text('${d.month}/${d.day}', style: const TextStyle(fontSize: 11)),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: [
                      for (int i=0;i<reversed.length;i++) _buildGroup(i, reversed[i])
                    ],
                    barTouchData: BarTouchData(enabled: true),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _order.map((s) => _LegendDot(label: _localizedStatus(context, s), color: _colors[s]!)).toList(),
              )
            ],
          ),
        ),
      ),
    );
  }

  BarChartGroupData _buildGroup(int x, DailyReportEntry entry) {
    final total = entry.statusCounts.values.fold<int>(0, (p,c) => p+c).toDouble();
    double running = 0;
    final rods = <BarChartRodStackItem>[];
    for (final status in _order) {
      final v = entry.statusCounts[status] ?? 0;
      if (v == 0) continue;
      final start = running;
      final end = running + v.toDouble();
      rods.add(BarChartRodStackItem(start, end, _colors[status]!));
      running = end;
    }
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: total == 0 ? 0 : running,
          rodStackItems: rods,
          width: 18,
          borderRadius: BorderRadius.circular(2),
        )
      ],
    );
  }

  String _localizedStatus(BuildContext context, String raw) {
    final loc = AppLocalizations.of(context);
    switch(raw){
      case 'PENDING': return loc.statusPending;
      case 'ACCEPTED': return loc.statusAccepted;
      case 'REJECTED': return loc.statusRejected;
      case 'IN_PROGRESS': return loc.statusInProgress;
      case 'COMPLETED': return loc.statusCompleted;
      case 'CANCELLED': return loc.statusCancelled;
      default: return raw;
    }
  }
}

class _EtaLineChart extends StatelessWidget {
  final List<DailyReportEntry> entries;
  const _EtaLineChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    final chronological = entries.reversed.where((e) => e.averageEstimatedArrivalMinutes != null).toList();
    if (chronological.isEmpty) return const SizedBox();
    return SizedBox(
      height: 220,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context).averageEtaMinutes, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: true),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= chronological.length) return const SizedBox();
                            final d = chronological[idx].day;
                            return Text('${d.month}/${d.day}', style: const TextStyle(fontSize: 11));
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          for (int i=0;i<chronological.length;i++) FlSpot(i.toDouble(), chronological[i].averageEstimatedArrivalMinutes!.toDouble())
                        ],
                        isCurved: true,
                        barWidth: 3,
                        color: AppColors.chartLine,
                        dotData: const FlDotData(show: true),
                      )
                    ],
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyCard extends StatelessWidget {
  final DailyReportEntry entry;
  const _DailyCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final statuses = entry.statusCounts.entries.toList()
      ..sort((a,b) => b.value.compareTo(a.value));
    final loc = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${entry.day.year}-${entry.day.month.toString().padLeft(2,'0')}-${entry.day.day.toString().padLeft(2,'0')}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: statuses.map((kv) => Chip(label: Text('${_label(context, kv.key)}: ${kv.value}'))).toList(),
            ),
            const SizedBox(height: 4),
            Text('${loc.avgEtaLabel}: ${entry.averageEstimatedArrivalMinutes == null ? '—' : _fmtEta(entry.averageEstimatedArrivalMinutes!)}'),
          ],
        ),
      ),
    );
  }

  String _label(BuildContext context, String raw) {
    final loc = AppLocalizations.of(context);
    switch(raw){
      case 'PENDING': return loc.statusPending;
      case 'ACCEPTED': return loc.statusAccepted;
      case 'REJECTED': return loc.statusRejected;
      case 'IN_PROGRESS': return loc.statusInProgress;
      case 'COMPLETED': return loc.statusCompleted;
      case 'CANCELLED': return loc.statusCancelled;
      default: return raw;
    }
  }

  String _fmtEta(double minutes) {
    final m = minutes.round();
    if (m < 60) return '$m min';
    final h = m ~/ 60; final r = m % 60; return r>0? '${h}h ${r}m':'${h}h';
  }
}

class _LegendDot extends StatelessWidget {
  final String label; final Color color;
  const _LegendDot({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11))
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message; final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 46),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            )
          ],
        ),
      ),
    );
  }
}
