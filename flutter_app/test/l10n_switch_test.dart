import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:garage_service_app/l10n/gen/app_localizations.dart';

void main() {
  test('lookupAppLocalizations provides translations for en/fr/rw', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final fr = lookupAppLocalizations(const Locale('fr'));
    final rw = lookupAppLocalizations(const Locale('rw'));

    expect(en.chooseLanguage, 'Choose Language');
    expect(fr.chooseLanguage, 'Choisir la langue');
    expect(rw.chooseLanguage, 'Hitamo ururimi');
  });

  test('supportedLocales include rw', () {
    expect(AppLocalizations.supportedLocales, contains(const Locale('rw')));
  });
}
