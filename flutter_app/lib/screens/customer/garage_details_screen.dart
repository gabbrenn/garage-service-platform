import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/garage_provider.dart';
import '../../models/garage.dart';
import '../../models/garage_service.dart';

class GarageDetailsScreen extends StatefulWidget {
  @override
  _GarageDetailsScreenState createState() => _GarageDetailsScreenState();
}

class _GarageDetailsScreenState extends State<GarageDetailsScreen> {
  Garage? garage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (garage == null) {
      garage = ModalRoute.of(context)!.settings.arguments as Garage;
      _loadServices();
    }
  }

  Future<void> _loadServices() async {
    if (garage != null) {
      final garageProvider = Provider.of<GarageProvider>(context, listen: false);
      await garageProvider.loadGarageServices(garage!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (garage == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Garage Details')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final garageProvider = Provider.of<GarageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(garage!.name),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            color: Colors.blue[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  garage!.name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.grey[600], size: 16),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        garage!.address,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
                if (garage!.description != null) ...[
                  SizedBox(height: 8),
                  Text(
                    garage!.description!,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
                if (garage!.workingHours != null) ...[
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.grey[600], size: 16),
                      SizedBox(width: 4),
                      Text(
                        garage!.workingHours!,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.build, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Available Services',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: garageProvider.isLoading
                ? Center(child: CircularProgressIndicator())
                : garageProvider.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, size: 64, color: Colors.red),
                            SizedBox(height: 16),
                            Text('Error loading services'),
                            SizedBox(height: 8),
                            Text(garageProvider.error!),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadServices,
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : garageProvider.garageServices.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.build_circle, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'No services available',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8),
                                Text('This garage hasn\'t added any services yet'),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            itemCount: garageProvider.garageServices.length,
                            itemBuilder: (context, index) {
                              final service = garageProvider.garageServices[index];
                              return _buildServiceCard(service);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(GarageService service) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    service.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    service.formattedPrice,
                    style: TextStyle(
                      color: Colors.green[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (service.description != null) ...[
              SizedBox(height: 8),
              Text(
                service.description!,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.grey[600], size: 16),
                SizedBox(width: 4),
                Text(
                  service.formattedDuration,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Spacer(),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/service-request',
                      arguments: {
                        'garage': garage,
                        'service': service,
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Request Service',
                    style: TextStyle(color: Colors.white),
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