import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/garage_provider.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Garage Profile'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
              validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
              validator: (v) => v == null || v.trim().isEmpty ? 'Address is required' : null,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latCtrl,
                    decoration: const InputDecoration(labelText: 'Latitude', border: OutlineInputBorder()),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      final d = double.tryParse(v ?? '');
                      if (d == null) return 'Invalid latitude';
                      if (d < -90 || d > 90) return 'Latitude out of range';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lngCtrl,
                    decoration: const InputDecoration(labelText: 'Longitude', border: OutlineInputBorder()),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      final d = double.tryParse(v ?? '');
                      if (d == null) return 'Invalid longitude';
                      if (d < -180 || d > 180) return 'Longitude out of range';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _hoursCtrl,
              decoration: const InputDecoration(labelText: 'Working Hours', hintText: 'e.g. Mon-Fri 8:00 - 18:00', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: provider.isLoading ? null : _save,
                icon: const Icon(Icons.save, color: Colors.white),
                label: Text(provider.isLoading ? 'Saving...' : 'Save Changes', style: const TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(vertical: 14)),
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Garage updated' : provider.error ?? 'Failed to update'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );

    if (ok && mounted) Navigator.pop(context);
  }
}
