import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/garage_provider.dart';
import '../../models/garage.dart';
import '../../models/garage_service.dart';
import '../../theme/app_colors.dart';

class GarageDetailsScreen extends StatefulWidget {
  const GarageDetailsScreen({super.key});

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
      WidgetsBinding.instance.addPostFrameCallback((_) { _loadServices(); });
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(garage!.name),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            color: AppColors.navy.withOpacity(0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  garage!.name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, color: AppColors.textSecondary, size: 16),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        garage!.address,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                if (garage!.description != null) ...[
                  SizedBox(height: 8),
                  Text(
                    garage!.description!,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
                if (garage!.workingHours != null) ...[
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, color: AppColors.textSecondary, size: 16),
                      SizedBox(width: 4),
                      Text(
                        garage!.workingHours!,
                        style: TextStyle(color: AppColors.textSecondary),
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
                Icon(Icons.build, color: AppColors.darkOrange),
                SizedBox(width: 8),
                Text(
                  'Available Services',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
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
                            Icon(Icons.error, size: 64, color: AppColors.error),
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
                                Icon(Icons.build_circle, size: 64, color: AppColors.textSecondary),
                                SizedBox(height: 16),
                                Text(
                                  'No services available',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                                SizedBox(height: 8),
                                Text('This garage hasn\'t added any services yet', style: TextStyle(color: AppColors.textSecondary)),
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
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    service.formattedPrice,
                    style: TextStyle(
                      color: AppColors.success,
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
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, color: AppColors.textSecondary, size: 16),
                SizedBox(width: 4),
                Text(
                  service.formattedDuration,
                  style: TextStyle(color: AppColors.textSecondary),
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
                    backgroundColor: AppColors.darkOrange,
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