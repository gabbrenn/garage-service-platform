import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/service_request_provider.dart';
import '../../models/service_request.dart';

class ServiceRequestsScreen extends StatefulWidget {
  @override
  _ServiceRequestsScreenState createState() => _ServiceRequestsScreenState();
}

class _ServiceRequestsScreenState extends State<ServiceRequestsScreen> {
  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    final serviceRequestProvider = Provider.of<ServiceRequestProvider>(context, listen: false);
    await serviceRequestProvider.loadGarageRequests();
  }

  @override
  Widget build(BuildContext context) {
    final serviceRequestProvider = Provider.of<ServiceRequestProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Service Requests'),
        backgroundColor: Colors.blue,
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
                      Icon(Icons.error, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text('Error loading requests'),
                      SizedBox(height: 8),
                      Text(serviceRequestProvider.error!),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadRequests,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : serviceRequestProvider.garageRequests.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No requests yet',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text('Service requests from customers will appear here'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: serviceRequestProvider.garageRequests.length,
                      itemBuilder: (context, index) {
                        final request = serviceRequestProvider.garageRequests[index];
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
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case RequestStatus.ACCEPTED:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case RequestStatus.REJECTED:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case RequestStatus.IN_PROGRESS:
        statusColor = Colors.blue;
        statusIcon = Icons.build;
        break;
      case RequestStatus.COMPLETED:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case RequestStatus.CANCELLED:
        statusColor = Colors.grey;
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
                CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Icon(Icons.person, color: Colors.blue),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.customer?.fullName ?? 'Unknown Customer',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        request.customer?.phoneNumber ?? 'No phone',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 16),
                      SizedBox(width: 4),
                      Text(
                        request.statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.build, color: Colors.blue, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Service: ${request.service.name}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Spacer(),
                      Text(
                        request.service.formattedPrice,
                        style: TextStyle(
                          color: Colors.green[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (request.description != null) ...[
                    SizedBox(height: 8),
                    Text(
                      'Description: ${request.description}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 12),
            
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.red, size: 16),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    request.customerAddress ?? 
                    'Lat: ${request.customerLatitude.toStringAsFixed(4)}, Lng: ${request.customerLongitude.toStringAsFixed(4)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.grey[600], size: 16),
                SizedBox(width: 4),
                Text(
                  'Requested: ${request.createdAt.day}/${request.createdAt.month}/${request.createdAt.year} ${request.createdAt.hour}:${request.createdAt.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            
            if (request.garageResponse != null) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Response:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      request.garageResponse!,
                      style: TextStyle(color: Colors.blue[700]),
                    ),
                    if (request.estimatedArrivalMinutes != null) ...[
                      SizedBox(height: 4),
                      Text(
                        'ETA: ${request.formattedEstimatedArrival}',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            
            if (request.status == RequestStatus.PENDING) ...[
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showResponseDialog(request, RequestStatus.ACCEPTED),
                      icon: Icon(Icons.check, color: Colors.white),
                      label: Text('Accept', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showResponseDialog(request, RequestStatus.REJECTED),
                      icon: Icon(Icons.close, color: Colors.white),
                      label: Text('Reject', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (request.status == RequestStatus.ACCEPTED) ...[
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateStatus(request, RequestStatus.IN_PROGRESS),
                      icon: Icon(Icons.build, color: Colors.white),
                      label: Text('Start Work', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (request.status == RequestStatus.IN_PROGRESS) ...[
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateStatus(request, RequestStatus.COMPLETED),
                      icon: Icon(Icons.check_circle, color: Colors.white),
                      label: Text('Mark Complete', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showResponseDialog(ServiceRequest request, RequestStatus status) {
    final responseController = TextEditingController();
    final etaController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(status == RequestStatus.ACCEPTED ? 'Accept Request' : 'Reject Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: responseController,
              decoration: InputDecoration(
                labelText: 'Response Message',
                hintText: status == RequestStatus.ACCEPTED 
                    ? 'We\'ll be there soon!'
                    : 'Sorry, we cannot fulfill this request.',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            if (status == RequestStatus.ACCEPTED) ...[
              SizedBox(height: 16),
              TextField(
                controller: etaController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Estimated Arrival (minutes)',
                  hintText: 'e.g., 30',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _respondToRequest(
                request,
                status,
                responseController.text.trim().isEmpty ? null : responseController.text.trim(),
                etaController.text.trim().isEmpty ? null : int.tryParse(etaController.text.trim()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: status == RequestStatus.ACCEPTED ? Colors.green : Colors.red,
            ),
            child: Text(
              status == RequestStatus.ACCEPTED ? 'Accept' : 'Reject',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _respondToRequest(ServiceRequest request, RequestStatus status, String? response, int? eta) async {
    final serviceRequestProvider = Provider.of<ServiceRequestProvider>(context, listen: false);
    
    final success = await serviceRequestProvider.respondToRequest(
      requestId: request.id,
      status: status,
      response: response,
      estimatedArrivalMinutes: eta,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request ${status.toString().split('.').last.toLowerCase()} successfully!'),
          backgroundColor: status == RequestStatus.ACCEPTED ? Colors.green : Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(serviceRequestProvider.error ?? 'Failed to respond to request'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateStatus(ServiceRequest request, RequestStatus status) async {
    final serviceRequestProvider = Provider.of<ServiceRequestProvider>(context, listen: false);
    
    final success = await serviceRequestProvider.respondToRequest(
      requestId: request.id,
      status: status,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request status updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(serviceRequestProvider.error ?? 'Failed to update request'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}