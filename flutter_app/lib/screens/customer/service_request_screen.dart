import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/service_request_provider.dart';
import '../../models/garage.dart';
import '../../models/garage_service.dart';
import '../../widgets/map_location_picker.dart';
import '../../l10n/gen/app_localizations.dart';

class ServiceRequestScreen extends StatefulWidget {
  const ServiceRequestScreen({super.key});

  @override
  _ServiceRequestScreenState createState() => _ServiceRequestScreenState();
}

class _ServiceRequestScreenState extends State<ServiceRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  Garage? garage;
  GarageService? service;
  Position? _currentPosition;
  bool _isLoadingLocation = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (garage == null) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      garage = args['garage'] as Garage;
      service = args['service'] as GarageService;
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
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

  Future<void> _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      if (_currentPosition == null) {
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.locationRequiredSubmitRequest),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final serviceRequestProvider = Provider.of<ServiceRequestProvider>(context, listen: false);
      
      final success = await serviceRequestProvider.createServiceRequest(
        garageId: garage!.id,
        serviceId: service!.id,
        customerLatitude: _currentPosition!.latitude,
        customerLongitude: _currentPosition!.longitude,
        customerAddress: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      );

      final loc = AppLocalizations.of(context);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.serviceRequestSubmittedSuccess),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(serviceRequestProvider.error ?? loc.serviceRequestSubmitFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (garage == null || service == null) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.requestServiceTitle)),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.requestServiceTitle),
        backgroundColor: Colors.blue,
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
                onLocationPicked: (lat, lng) {
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
                  style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w600),
                )
              else if (_isLoadingLocation)
                Row(
                  children: [
                    const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    const SizedBox(width: 8),
                    Text(loc.fetchingCurrentLocation)
                  ],
                )
              else
                Text(loc.mapTapToSetLocation, style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.serviceDetailsHeading,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.build, color: Colors.blue),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              garage!.name,
                              style: TextStyle(
                                fontSize: 16,
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
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              garage!.address,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        ],
                      ),
                      Divider(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              service!.name,
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
                              service!.formattedPrice,
                              style: TextStyle(
                                color: Colors.green[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (service!.description != null) ...[
                        SizedBox(height: 8),
                        Text(
                          service!.description!,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time, color: Colors.grey[600], size: 16),
                          SizedBox(width: 4),
                          Text(
                            service!.formattedDuration,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.yourLocationHeading,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      SizedBox(height: 12),
                      if (_isLoadingLocation)
                        Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text(loc.gettingLocation),
                            Text(loc.gettingLocation),
                          ],
                        )
                      else if (_currentPosition != null)
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.green),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                loc.currentLocationLabel(
                                  _currentPosition!.latitude.toStringAsFixed(4),
                                  _currentPosition!.longitude.toStringAsFixed(4),
                                ),
                                style: TextStyle(color: Colors.green[800]),
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Icon(Icons.location_off, color: Colors.red),
                            SizedBox(width: 8),
                            Expanded(child: Text(loc.locationNotAvailable)),
                            TextButton(
                              onPressed: _getCurrentLocation,
                              child: Text(loc.retry),
                            ),
                          ],
                        ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: loc.addressOptionalLabel,
                          hintText: loc.addressOptionalHint,
                          prefixIcon: Icon(Icons.home),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.additionalDetailsHeading,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: loc.descriptionOptionalLabel,
                          hintText: loc.descriptionOptionalHint,
                          prefixIcon: Icon(Icons.description),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),
              Consumer<ServiceRequestProvider>(
                builder: (context, serviceRequestProvider, child) {
                  return SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: serviceRequestProvider.isLoading ? null : _submitRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: serviceRequestProvider.isLoading
                          ? CircularProgressIndicator(color: Colors.white)
              : Text(
                loc.submitRequestButton,
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