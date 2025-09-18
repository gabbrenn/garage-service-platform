import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/garage_service.dart';
import '../../providers/garage_provider.dart';
import '../../l10n/gen/app_localizations.dart';

class ManageServicesScreen extends StatefulWidget {
  const ManageServicesScreen({super.key});

  @override
  State<ManageServicesScreen> createState() => _ManageServicesScreenState();
}

class _ManageServicesScreenState extends State<ManageServicesScreen> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final garageProvider = Provider.of<GarageProvider>(context, listen: false);
    await garageProvider.loadMyServices();
  }

  @override
  Widget build(BuildContext context) {
  final garageProvider = Provider.of<GarageProvider>(context);
  final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.manageServices),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add-service'),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: garageProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : garageProvider.error != null
              ? _buildError(garageProvider.error!, _load)
              : garageProvider.myServices.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: garageProvider.myServices.length,
                        itemBuilder: (context, index) {
                          final service = garageProvider.myServices[index];
                          return _buildServiceTile(service);
                        },
                      ),
                    ),
    );
  }

  Widget _buildEmpty() {
    final loc = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.build, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              loc.noServicesYet,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              loc.addFirstServiceMessage,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/add-service'),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(loc.addService, style: const TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String error, Future<void> Function() retry) {
    final loc = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              loc.failedToLoadServices,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: retry,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: Text(loc.retry, style: const TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildServiceTile(GarageService service) {
    final loc = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[50],
          child: const Icon(Icons.build, color: Colors.blue),
        ),
        title: Text(service.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(service.description ?? loc.noDescription, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.attach_money, color: Colors.green[700], size: 16),
                const SizedBox(width: 2),
                Text(service.formattedPrice, style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                if (service.estimatedDurationMinutes != null) ...[
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 2),
                  Text('${service.estimatedDurationMinutes} min', style: const TextStyle(color: Colors.grey)),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showEditServiceDialog(service);
            } else if (value == 'delete') {
              _confirmDelete(service);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'edit', child: Text(loc.editServiceTitle)),
            PopupMenuItem(value: 'delete', child: Text(loc.delete)),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(GarageService service) async {
    final loc = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
  title: Text(loc.deleteServiceTitle),
  content: Text(loc.deleteServiceConfirm(service.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(loc.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(loc.delete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = Provider.of<GarageProvider>(context, listen: false);
      final ok = await provider.deleteService(service.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? loc.serviceDeletedSuccess : provider.error ?? loc.serviceDeleteFailed),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _showEditServiceDialog(GarageService service) {
    final nameCtrl = TextEditingController(text: service.name);
    final descCtrl = TextEditingController(text: service.description ?? '');
    final priceCtrl = TextEditingController(text: service.price.toStringAsFixed(2));
    final durationCtrl = TextEditingController(text: service.estimatedDurationMinutes?.toString() ?? '');

    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final loc = AppLocalizations.of(context);
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(loc.editServiceTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: nameCtrl,
                  decoration: InputDecoration(labelText: loc.name, border: const OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? loc.nameRequired : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  decoration: InputDecoration(labelText: loc.descriptionLabel, border: const OutlineInputBorder()),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: priceCtrl,
                        decoration: InputDecoration(labelText: loc.price, border: const OutlineInputBorder(), prefixText: '4'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return loc.priceRequired;
                          final d = double.tryParse(v);
                          if (d == null || d < 0) return loc.invalidPrice;
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: durationCtrl,
                        decoration: InputDecoration(labelText: loc.durationMinutes, border: const OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final provider = Provider.of<GarageProvider>(context, listen: false);
                      final ok = await provider.updateService(
                        serviceId: service.id,
                        name: nameCtrl.text.trim(),
                        description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                        price: double.tryParse(priceCtrl.text.trim()),
                        estimatedDurationMinutes: durationCtrl.text.trim().isEmpty
                            ? null
                            : int.tryParse(durationCtrl.text.trim()),
                      );
                      if (ok) {
                        if (mounted) Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(loc.serviceUpdatedSuccess), backgroundColor: Colors.green),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(provider.error ?? loc.serviceUpdateFailed), backgroundColor: Colors.red),
                        );
                      }
                    },
                    icon: const Icon(Icons.save, color: Colors.white),
                    label: Text(loc.saveChanges, style: const TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
