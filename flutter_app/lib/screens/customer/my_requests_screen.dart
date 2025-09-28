import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../providers/service_request_provider.dart';
import '../../models/service_request.dart';
import '../../theme/app_colors.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  _MyRequestsScreenState createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  @override
  void initState() {
    super.initState();
    // Defer to next frame to avoid provider notify during build lifecycle
    WidgetsBinding.instance.addPostFrameCallback((_) { _loadRequests(); });
  }

  Future<void> _loadRequests() async {
    final serviceRequestProvider = Provider.of<ServiceRequestProvider>(context, listen: false);
    await serviceRequestProvider.loadMyRequests();
  }

  @override
  Widget build(BuildContext context) {
    final serviceRequestProvider = Provider.of<ServiceRequestProvider>(context);

    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(loc.myRequests),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadRequests,
          ),
        ],
      ),
      body: serviceRequestProvider.isLoading
          ? Center(child: CircularProgressIndicator())
          : serviceRequestProvider.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: AppColors.error),
                      SizedBox(height: 16),
                      Text(loc.errorLoadingRequests),
                      SizedBox(height: 8),
                      Text(serviceRequestProvider.error!),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadRequests,
                        child: Text(loc.retry),
                      ),
                    ],
                  ),
                )
              : serviceRequestProvider.myRequests.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: AppColors.textSecondary),
                          SizedBox(height: 16),
                          Text(
                            loc.noRequestsYet,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          SizedBox(height: 8),
                          Text(loc.noRequestsYetLong, style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: serviceRequestProvider.myRequests.length,
                      itemBuilder: (context, index) {
                        final request = serviceRequestProvider.myRequests[index];
                        return _buildRequestCard(request);
                      },
                    ),
    );
  }

  Widget _buildRequestCard(ServiceRequest request) {
    Color statusColor;
    IconData statusIcon;

    switch (request.status) {
      case RequestStatus.PENDING:
        statusColor = AppColors.pending;
        statusIcon = Icons.hourglass_empty;
        break;
      case RequestStatus.ACCEPTED:
        statusColor = AppColors.accepted;
        statusIcon = Icons.check_circle;
        break;
      case RequestStatus.REJECTED:
        statusColor = AppColors.rejected;
        statusIcon = Icons.cancel;
        break;
      case RequestStatus.IN_PROGRESS:
        statusColor = AppColors.inProgress;
        statusIcon = Icons.build;
        break;
      case RequestStatus.COMPLETED:
        statusColor = AppColors.completed;
        statusIcon = Icons.check_circle_outline;
        break;
      case RequestStatus.CANCELLED:
        statusColor = AppColors.cancelled;
        statusIcon = Icons.cancel_outlined;
        break;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    request.statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Spacer(),
                Text(
                  '${request.createdAt.day}/${request.createdAt.month}/${request.createdAt.year}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              request.service.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              request.garage?.name ?? request.garageName ?? 'Unknown Garage',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            if (request.description != null) ...[
              SizedBox(height: 8),
              Text(
                'Description: ${request.description}',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
            if (request.garageResponse != null) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.navy.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Garage Response:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      request.garageResponse!,
                      style: TextStyle(color: AppColors.navy),
                    ),
                  ],
                ),
              ),
            ],
            if (request.estimatedArrivalMinutes != null) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, color: AppColors.success, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Estimated arrival: ${request.formattedEstimatedArrival}',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.attach_money, color: AppColors.success, size: 16),
                Text(
                  request.service.formattedPrice,
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                Text(
                  'Updated: ${request.updatedAt.day}/${request.updatedAt.month} ${request.updatedAt.hour}:${request.updatedAt.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}