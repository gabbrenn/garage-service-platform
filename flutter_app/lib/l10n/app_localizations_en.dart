// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Garage Service App';

  @override
  String get splashTagline => 'Find nearby garage services';

  @override
  String get loginTitle => 'Login';

  @override
  String get loginEmail => 'Email';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginButton => 'Sign In';

  @override
  String get logout => 'Logout';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirmLogoutMessage => 'Are you sure you want to logout?';

  @override
  String get myRequests => 'My Requests';

  @override
  String get notifications => 'Notifications';

  @override
  String get garageDashboard => 'Garage Dashboard';

  @override
  String get language => 'Language';

  @override
  String get chooseLanguage => 'Choose Language';
}
