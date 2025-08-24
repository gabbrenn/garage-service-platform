import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/garage_provider.dart';
import '../../providers/service_request_provider.dart';

class GarageHomeScreen extends StatefulWidget {
  @override
  _GarageHomeScreenState createState() => _GarageHomeScreenState();
}

class _GarageHomeScreenState extends State<GarageHomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final garageProvider = Provider.of<GarageProvider>(context, listen: false);
    final serviceRequestProvider = Provider.of<ServiceRequestProvider>(context, listen: false);
    
    await garageProvider.loadMyGarage();
    
    if (garageProvider.myGarage != null) {
      await Future.wait([
        garageProvider.loadMyServices(),
        serviceRequestProvider.loadGarageRequests(),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final garageProvider = Provider.of<GarageProvider>(context);
    final serviceRequestProvider = Provider.of<ServiceRequestProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Garage Dashboard'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                authProvider.logout();
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: garageProvider.isLoading
          ? Center(child: CircularProgressIndicator())
          : garageProvider.myGarage == null
              ? _buildNoGarageView()
              : _buildGarageView(),
      floatingActionButton: garageProvider.myGarage != null
          ? FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, '/add-service');
              },
              backgroundColor: Colors.blue,
              child: Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildNoGarageView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Set Up Your Garage',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Create your garage profile to start receiving service requests from customers.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/garage-setup');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Set Up Garage',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGarageView() {
    final garageProvider = Provider.of<GarageProvider>(context);
    final serviceRequestProvider = Provider.of<ServiceRequestProvider>(context);
    final garage = garageProvider.myGarage!;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Garage Info Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.store, color: Colors.blue, size: 24),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          garage.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.grey[600], size: 16),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          garage.address,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                  if (garage.description != null) ...[
                    SizedBox(height: 8),
                    Text(
                      garage.description!,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                  if (garage.workingHours != null) ...[
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.grey[600], size: 16),
                        SizedBox(width: 4),
                        Text(
                          garage.workingHours!,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          
          // Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Services',
                  garageProvider.myServices.length.toString(),
                  Icons.build,
                  Colors.blue,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Requests',
                  serviceRequestProvider.garageRequests.length.toString(),
                  Icons.inbox,
                  Colors.orange,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          // Quick Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/add-service');
                  },
                  icon: Icon(Icons.add, color: Colors.white),
                  label: Text('Add Service', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/service-requests');
                  },
                  icon: Icon(Icons.inbox, color: Colors.white),
                  label: Text('View Requests', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          // Recent Requests
          Text(
            'Recent Requests',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          serviceRequestProvider.garageRequests.isEmpty
              ? Card(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.inbox, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'No requests yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Service requests will appear here',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: serviceRequestProvider.garageRequests
                      .take(3)
                      .map((request) => Card(
                            margin: EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue[100],
                                child: Icon(Icons.person, color: Colors.blue),
                              ),
                              title: Text(request.service.name),
                              subtitle: Text(
                                request.customer?.fullName ?? 'Unknown Customer',
                              ),
                              trailing: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(request.status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  request.statusText,
                                  style: TextStyle(
                                    color: _getStatusColor(request.status),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              onTap: () {
                                Navigator.pushNamed(context, '/service-requests');
                              },
                            ),
                          ))
                      .toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.PENDING:
        return Colors.orange;
      case RequestStatus.ACCEPTED:
        return Colors.green;
      case RequestStatus.REJECTED:
        return Colors.red;
      case RequestStatus.IN_PROGRESS:
        return Colors.blue;
      case RequestStatus.COMPLETED:
        return Colors.green;
      case RequestStatus.CANCELLED:
        return Colors.grey;
    }
  }
}