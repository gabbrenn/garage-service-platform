// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Application Garage';

  @override
  String get splashTagline => 'Trouvez des services de garage à proximité';

  @override
  String get loginTitle => 'Connexion';

  @override
  String get loginEmail => 'Email';

  @override
  String get loginPassword => 'Mot de passe';

  @override
  String get loginButton => 'Se connecter';

  @override
  String get logout => 'Se déconnecter';

  @override
  String get cancel => 'Annuler';

  @override
  String get confirmLogoutMessage => 'Êtes-vous sûr de vouloir vous déconnecter ?';

  @override
  String get myRequests => 'Mes Demandes';

  @override
  String get notifications => 'Notifications';

  @override
  String get garageDashboard => 'Tableau Garage';

  @override
  String get language => 'Langue';

  @override
  String get chooseLanguage => 'Choisir la langue';
}
