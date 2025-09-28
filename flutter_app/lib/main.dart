import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// Conditional web map script loader
// ignore: avoid_web_libraries_in_flutter
import 'utils/maps_script_loader_stub.dart'
  if (dart.library.html) 'utils/maps_script_loader_web.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/notification_service.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/garage_provider.dart';
import 'providers/report_provider.dart';
import 'providers/service_request_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/language_provider.dart';
import 'providers/theme_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// Using explicit localization output (see l10n.yaml synthetic-package: false)
import 'l10n/gen/app_localizations.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/customer/customer_home_screen.dart';
import 'screens/customer/garage_details_screen.dart';
import 'screens/customer/service_request_screen.dart';
import 'screens/customer/my_requests_screen.dart';
import 'screens/garage/garage_home_screen.dart';
import 'screens/garage/garage_setup_screen.dart';
import 'screens/garage/add_service_screen.dart';
import 'screens/garage/service_requests_screen.dart';
import 'screens/garage/manage_services_screen.dart';
import 'screens/garage/edit_garage_screen.dart';
import 'screens/garage/garage_report_screen.dart';
import 'screens/notifications_screen.dart';
import 'theme/app_theme.dart';
import 'screens/settings/settings_screen.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize if needed
  await Firebase.initializeApp();
  await NotificationService.ensureInitialized();
  await NotificationService.showRemoteMessage(message);
}

/// Helper accessor that prefers compile-time --dart-define over .env runtime values.
class Env {
  static String? _getDefine(String key) {
    // We can't call String.fromEnvironment with a dynamic key in a const context.
    // Whitelist known keys; add more as needed.
    String val = '';
    switch (key) {
      case 'GOOGLE_MAPS_API_KEY':
        val = const String.fromEnvironment('GOOGLE_MAPS_API_KEY');
        break;
      case 'GOOGLE_DIRECTIONS_API_KEY':
        val = const String.fromEnvironment('GOOGLE_DIRECTIONS_API_KEY');
        break;
      case 'FIREBASE_API_KEY':
        val = const String.fromEnvironment('FIREBASE_API_KEY');
        break;
      case 'FIREBASE_APP_ID':
        val = const String.fromEnvironment('FIREBASE_APP_ID');
        break;
      case 'FIREBASE_MESSAGING_SENDER_ID':
        val = const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
        break;
      case 'FIREBASE_PROJECT_ID':
        val = const String.fromEnvironment('FIREBASE_PROJECT_ID');
        break;
      case 'FIREBASE_AUTH_DOMAIN':
        val = const String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
        break;
      case 'FIREBASE_STORAGE_BUCKET':
        val = const String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
        break;
      case 'FIREBASE_MEASUREMENT_ID':
        val = const String.fromEnvironment('FIREBASE_MEASUREMENT_ID');
        break;
      case 'FIREBASE_VAPID_KEY':
        val = const String.fromEnvironment('FIREBASE_VAPID_KEY');
        break;
      case 'API_BASE_URL':
        val = const String.fromEnvironment('API_BASE_URL');
        break;
      case 'GOOGLE_MAPS_API_KEY_WEB':
        val = const String.fromEnvironment('GOOGLE_MAPS_API_KEY_WEB');
        break;
      case 'GOOGLE_MAPS_API_KEY_ANDROID':
        val = const String.fromEnvironment('GOOGLE_MAPS_API_KEY_ANDROID');
        break;
      case 'GOOGLE_MAPS_API_KEY_IOS':
        val = const String.fromEnvironment('GOOGLE_MAPS_API_KEY_IOS');
        break;
      default:
        // Unknown key not whitelisted; can't retrieve via compile-time define generically.
        val = '';
    }
    return val.isEmpty ? null : val;
  }

  static String? get(String key) {
    final defineVal = _getDefine(key);
    if (defineVal != null) return defineVal;
    return dotenv.maybeGet(key);
  }

  static String require(String key) {
    final v = get(key);
    if (v == null || v.isEmpty) {
      throw StateError('Missing required env variable: ' + key);
    }
    return v;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Prefer hybrid composition (surface-based renderer) to reduce SurfaceTexture/ImageReader churn on Android.
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    final GoogleMapsFlutterAndroid maps = GoogleMapsFlutterAndroid();
    // Prefer surface-based view backend when available.
    maps.useAndroidViewSurface = true;
    // Initialize with the latest available renderer (plugin may select SurfaceView internally).
    try {
      maps.initializeWithRenderer(AndroidMapRenderer.latest);
    } catch (_) {
      // Safe to ignore on older plugin versions.
    }
  }
  // Load .env file early; do not fail hard if absent (e.g., production using only dart-defines)
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('[env] .env load skipped/failed: $e');
  }
  // On web, ensure the Maps JS script is present early to avoid google.maps undefined errors.
  if (kIsWeb) {
    try {
      await ensureMapsScriptLoaded();
    } catch (e) {
      debugPrint('[maps] Failed to ensure Google Maps script: $e');
    }
  }
  try {
    final opts = DefaultFirebaseOptions.currentPlatform;
    if (opts != null) {
      await Firebase.initializeApp(options: opts);
    } else {
      // On non-web, default initialization is fine; on web we need explicit options.
      if (!kIsWeb) {
        await Firebase.initializeApp();
      } else {
        // Skip Firebase init on web if options are missing; app will run without FCM.
        debugPrint('[main] Skipping Firebase initialization on web: options missing');
      }
    }
  } catch (e) {
    // Do not crash app; log and continue without Firebase features.
    debugPrint('[main] Firebase initialization failed: $e');
  }
  if (!kIsWeb && Firebase.apps.isNotEmpty) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
  await NotificationService.ensureInitialized();
  // Request permissions (iOS + Android 13+)
  await NotificationService.requestPermissionsIfNeeded();
  // Example: read some values (safe optional)
  debugPrint('[env] GOOGLE_MAPS_API_KEY (effective) = ' + (Env.get('GOOGLE_MAPS_API_KEY') ?? '<null>'));
  debugPrint('[env] FIREBASE_PROJECT_ID (effective) = ' + (Env.get('FIREBASE_PROJECT_ID') ?? '<null>'));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GarageProvider()),
        ChangeNotifierProvider(create: (_) => ServiceRequestProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()..loadSavedLocale()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..load()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, lang, _) {
          final themeProv = context.watch<ThemeProvider>();
          // Foreground message display (only when Firebase is available)
          if (Firebase.apps.isNotEmpty) {
            FirebaseMessaging.onMessage.listen((m) async {
              await NotificationService.showRemoteMessage(m);
            });
            FirebaseMessaging.onMessageOpenedApp.listen((m) {
              NotificationService.onMessageOpenedAppNavigation(context, m);
            });
          }

          return MaterialApp(
        title: 'Garage Service App',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeProv.mode,
        locale: lang.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        initialRoute: '/',
  routes: {
          '/': (context) => SplashScreen(),
          '/login': (context) => LoginScreen(),
    '/forgot-password': (context) => const ForgotPasswordScreen(),
    '/reset-password': (context) => const ResetPasswordScreen(),
          '/register': (context) => RegisterScreen(),
          '/customer-home': (context) => CustomerHomeScreen(),
          '/garage-details': (context) => GarageDetailsScreen(),
          '/service-request': (context) => ServiceRequestScreen(),
          '/my-requests': (context) => MyRequestsScreen(),
          '/garage-home': (context) => GarageHomeScreen(),
          '/garage-setup': (context) => GarageSetupScreen(),
          '/add-service': (context) => AddServiceScreen(),
          '/service-requests': (context) => ServiceRequestsScreen(),
          '/manage-services': (context) => ManageServicesScreen(),
          '/edit-garage': (context) => EditGarageScreen(),
          '/garage-report': (context) => GarageReportScreen(),
          '/notifications': (context) => const NotificationsScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
        // Example usage of Env inside widget tree: you could pass a config object
        // or use Env.get('SOME_KEY') directly where needed.
          );
        },
      ),
    );
  }
}