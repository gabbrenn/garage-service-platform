import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/garage_provider.dart';
import '../../l10n/gen/app_localizations.dart';

class AddServiceScreen extends StatefulWidget {
  const AddServiceScreen({super.key});

  @override
  _AddServiceScreenState createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _addService() async {
    if (_formKey.currentState!.validate()) {
      final garageProvider = Provider.of<GarageProvider>(context, listen: false);
      
      final success = await garageProvider.createService(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        estimatedDurationMinutes: _durationController.text.trim().isEmpty ? null : int.parse(_durationController.text.trim()),
      );

      final loc = AppLocalizations.of(context);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.serviceAddedSuccess),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(garageProvider.error ?? loc.serviceAddFailed),
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
      appBar: AppBar(
        title: Text(loc.addServiceTitle),
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
              Text(
                loc.addNewServiceHeading,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                loc.addServiceDescription,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 24),
              
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: loc.serviceNameLabel,
                  hintText: loc.serviceNameHint,
                  prefixIcon: Icon(Icons.build),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return loc.serviceNameRequired;
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: loc.serviceDescriptionOptional,
                  hintText: loc.serviceDescriptionHint,
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: loc.price,
                  hintText: loc.priceHint,
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return loc.priceRequired;
                  }
                  final price = double.tryParse(value.trim());
                  if (price == null || price <= 0) {
                    return loc.enterValidPrice;
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: loc.estimatedDurationOptional,
                  hintText: loc.durationMinutesHint,
                  prefixIcon: Icon(Icons.access_time),
                  suffixText: loc.minutesUnit,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final duration = int.tryParse(value.trim());
                    if (duration == null || duration <= 0) {
                      return loc.enterValidDuration;
                    }
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          loc.serviceTipsTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      loc.serviceTipsBullets,
                      style: TextStyle(color: Colors.blue[700]),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
              
              Consumer<GarageProvider>(
                builder: (context, garageProvider, child) {
                  return SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: garageProvider.isLoading ? null : _addService,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: garageProvider.isLoading
                          ? CircularProgressIndicator(color: Colors.white)
              : Text(
                loc.addServiceTitle,
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