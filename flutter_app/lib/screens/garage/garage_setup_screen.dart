import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../providers/garage_provider.dart';
import '../../widgets/map_location_picker.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../theme/app_colors.dart';

class GarageSetupScreen extends StatefulWidget {
  const GarageSetupScreen({super.key});

  @override
  _GarageSetupScreenState createState() => _GarageSetupScreenState();
}

class _GarageSetupScreenState extends State<GarageSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _workingHoursController = TextEditingController();
  
  Position? _currentPosition;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _workingHoursController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check and request location permission
      var status = await Permission.location.status;
      if (!status.isGranted) {
        status = await Permission.location.request();
        if (!status.isGranted) {
          final loc = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.locationPermissionRequiredSetup),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() {
            _isLoadingLocation = false;
          });
          return;
        }
      }

      // Get current position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.failedToGetLocationWithError(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoadingLocation = false;
    });
  }

  Future<void> _createGarage() async {
    if (_formKey.currentState!.validate()) {
      if (_currentPosition == null) {
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.locationRequiredCreateGarage),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final garageProvider = Provider.of<GarageProvider>(context, listen: false);
      
      final success = await garageProvider.createGarage(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        workingHours: _workingHoursController.text.trim().isEmpty ? null : _workingHoursController.text.trim(),
      );

      final loc = AppLocalizations.of(context);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.garageCreatedSuccess),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/garage-home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(garageProvider.error ?? loc.garageCreateFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background.withOpacity(0.98),
      appBar: AppBar(
        title: Text(loc.setUpYourGarage),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MapLocationPicker(
                initialLat: _currentPosition?.latitude,
                initialLng: _currentPosition?.longitude,
                onLocationPicked: (lat,lng){
                  _currentPosition = Position(
                    longitude: lng,
                    latitude: lat,
                    timestamp: DateTime.now(),
                    accuracy: 1,
                    altitude: 0,
                    heading: 0,
                    speed: 0,
                    speedAccuracy: 0,
                    altitudeAccuracy: 1,
                    headingAccuracy: 1,
                  );
                  setState(() {});
                },
              ),
              const SizedBox(height: 8),
              if (_currentPosition != null)
                Text(
                  loc.selectedCoordinatesLabel(
                    _currentPosition!.latitude.toStringAsFixed(6),
                    _currentPosition!.longitude.toStringAsFixed(6),
                  ),
                  style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w600)),
              if (_currentPosition == null && !_isLoadingLocation)
                Text(loc.mapTapToChooseLocation, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              
              Text(
                loc.createGarageProfileHeading,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                loc.createGarageProfileIntro,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 24),
              
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '${loc.garageNameLabel} *',
                  hintText: loc.garageNameHint,
                  prefixIcon: Icon(Icons.store),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.adaptiveCard(Theme.of(context).brightness),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return loc.garageNameRequired;
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: '${loc.garageAddressLabel} *',
                  hintText: loc.garageAddressHint,
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.adaptiveCard(Theme.of(context).brightness),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return loc.garageAddressRequired;
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: '${loc.garageDescriptionLabel} (Optional)',
                  hintText: loc.garageDescriptionHint,
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.adaptiveCard(Theme.of(context).brightness),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              
              TextFormField(
                controller: _workingHoursController,
                decoration: InputDecoration(
                  labelText: '${loc.garageWorkingHoursLabel} (Optional)',
                  hintText: loc.garageWorkingHoursHint,
                  prefixIcon: Icon(Icons.access_time),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.adaptiveCard(Theme.of(context).brightness),
                ),
              ),
              SizedBox(height: 30),
              
              Consumer<GarageProvider>(
                builder: (context, garageProvider, child) {
                  return SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: garageProvider.isLoading ? null : _createGarage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: garageProvider.isLoading
                          ? CircularProgressIndicator(color: Colors.white)
              : Text(
                loc.createGarageTitle,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}