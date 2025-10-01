import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../l10n/gen/app_localizations.dart';

class LanguagePickerSheet extends StatelessWidget {
  const LanguagePickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final current = langProvider.locale.languageCode;
    final loc = AppLocalizations.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(
              loc.chooseLanguage,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          RadioListTile<String>(
            title: const Text('English'),
            value: 'en',
            groupValue: current,
            onChanged: (v) {
              if (v != null) {
                langProvider.setLocale(const Locale('en'));
                Navigator.pop(context);
              }
            },
          ),
          RadioListTile<String>(
            title: const Text('Français'),
            value: 'fr',
            groupValue: current,
            onChanged: (v) {
              if (v != null) {
                langProvider.setLocale(const Locale('fr'));
                Navigator.pop(context);
              }
            },
          ),
          RadioListTile<String>(
            title: const Text('Kinyarwanda'),
            value: 'rw',
            groupValue: current,
            onChanged: (v) {
              if (v != null) {
                langProvider.setLocale(const Locale('rw'));
                Navigator.pop(context);
              }
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

void showLanguagePickerSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (_) => const LanguagePickerSheet(),
  );
}
