import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  final Future<bool> Function()? deleteAccount;
  const SettingsScreen({super.key, this.deleteAccount});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ThemeMode? _pending;

  @override
  void initState() {
    super.initState();
    final current = context.read<ThemeProvider>().mode;
    _pending = current;
  }

  @override
  Widget build(BuildContext context) {
  final themeProv = context.watch<ThemeProvider>();
    final current = themeProv.mode;

    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
  title: Text(loc.settingsTitle),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(loc.appearanceSection, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc.themeModeLabel, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _buildRadioRow(loc.themeSystem, ThemeMode.system, current),
                  _buildRadioRow(loc.themeLight, ThemeMode.light, current),
                  _buildRadioRow(loc.themeDark, ThemeMode.dark, current),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      key: const Key('applyThemeButton'),
                      onPressed: _pending == current ? null : () async {
                        if (_pending != null) {
                          await themeProv.setMode(_pending!);
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: Text(loc.applyButton),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkOrange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(loc.accountSection, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc.deleteAccountWarning, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      key: const Key('deleteAccountButton'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(loc.deleteAccount),
                            content: Text(loc.deleteAccountConfirm),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(loc.cancel)),
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: Text(loc.delete, style: const TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirmed != true) return;
                        try {
                          // Best-effort: call backend to delete account, then log out locally
                          final fn = widget.deleteAccount ?? ApiService.deleteAccount;
                          final ok = await fn();
                          if (ok) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(loc.accountDeleted)),
                              );
                            }
                            // Perform full logout and navigate to login
                            try { await context.read<AuthProvider>().logout(context); } catch(_) {}
                            if (mounted) {
                              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${loc.genericError}: $e')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.delete_forever),
                      label: Text(loc.deleteAccount),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioRow(String label, ThemeMode value, ThemeMode current) {
    return InkWell(
      onTap: () { setState(() { _pending = value; }); },
      child: Row(
        children: [
          Radio<ThemeMode>(
            value: value,
            groupValue: _pending,
            onChanged: (v) { setState(() { _pending = v; }); },
          ),
          const SizedBox(width: 4),
          Text(label),
          if (value == current) ...[
            const SizedBox(width: 8),
            const Icon(Icons.check, size: 16, color: AppColors.darkOrange)
          ]
        ],
      ),
    );
  }
}
