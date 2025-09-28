import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/garage_provider.dart';
import '../../widgets/map_location_picker.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../theme/app_colors.dart';

class EditGarageScreen extends StatefulWidget {
  const EditGarageScreen({super.key});

  @override
  State<EditGarageScreen> createState() => _EditGarageScreenState();
}

class _EditGarageScreenState extends State<EditGarageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<GarageProvider>(context, listen: false);
    final g = provider.myGarage;
    if (g != null) {
      _nameCtrl.text = g.name;
      _addressCtrl.text = g.address;
      _latCtrl.text = g.latitude.toStringAsFixed(6);
      _lngCtrl.text = g.longitude.toStringAsFixed(6);
      _descCtrl.text = g.description ?? '';
      _hoursCtrl.text = g.workingHours ?? '';
    } else {
      // If not loaded yet, fetch
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await provider.loadMyGarage();
        final gg = provider.myGarage;
        if (gg != null) {
          setState(() {
            _nameCtrl.text = gg.name;
            _addressCtrl.text = gg.address;
            _latCtrl.text = gg.latitude.toStringAsFixed(6);
            _lngCtrl.text = gg.longitude.toStringAsFixed(6);
            _descCtrl.text = gg.description ?? '';
            _hoursCtrl.text = gg.workingHours ?? '';
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GarageProvider>(context);

    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(loc.editGarageTitle),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            MapLocationPicker(
              initialLat: double.tryParse(_latCtrl.text),
              initialLng: double.tryParse(_lngCtrl.text),
              onLocationPicked: (lat, lng) {
                _latCtrl.text = lat.toStringAsFixed(6);
                _lngCtrl.text = lng.toStringAsFixed(6);
                setState(() {});
              },
            ),
            const SizedBox(height: 8),
            if (_latCtrl.text.isNotEmpty && _lngCtrl.text.isNotEmpty)
              Text(
                loc.selectedCoordinatesLabel(_latCtrl.text, _lngCtrl.text),
                style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w600),
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(labelText: loc.name, border: const OutlineInputBorder(), filled: true, fillColor: AppColors.adaptiveCard(Theme.of(context).brightness)),
              validator: (v) => v == null || v.trim().isEmpty ? loc.nameRequired : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              decoration: InputDecoration(labelText: loc.garageAddressLabel, border: const OutlineInputBorder(), filled: true, fillColor: AppColors.adaptiveCard(Theme.of(context).brightness)),
              validator: (v) => v == null || v.trim().isEmpty ? loc.garageAddressRequired : null,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              decoration: InputDecoration(labelText: loc.descriptionLabel, border: const OutlineInputBorder(), filled: true, fillColor: AppColors.adaptiveCard(Theme.of(context).brightness)),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _hoursCtrl,
              decoration: InputDecoration(labelText: loc.garageWorkingHoursLabel, hintText: loc.garageWorkingHoursHint, border: const OutlineInputBorder(), filled: true, fillColor: AppColors.adaptiveCard(Theme.of(context).brightness)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: provider.isLoading ? null : _save,
                icon: const Icon(Icons.save, color: Colors.white),
                label: Text(provider.isLoading ? loc.savingInProgress : loc.saveChanges, style: const TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkOrange, padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = Provider.of<GarageProvider>(context, listen: false);
    final ok = await provider.updateMyGarage(
      name: _nameCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      latitude: double.parse(_latCtrl.text.trim()),
      longitude: double.parse(_lngCtrl.text.trim()),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      workingHours: _hoursCtrl.text.trim().isEmpty ? null : _hoursCtrl.text.trim(),
    );

    final loc = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? loc.garageUpdatedSuccess : provider.error ?? loc.garageUpdateFailed),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );

    if (ok && mounted) Navigator.pop(context);
  }
}
