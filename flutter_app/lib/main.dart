import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/notification_service.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/garage_provider.dart';
import 'providers/report_provider.dart';
import 'providers/service_request_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/language_provider.dart';
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

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize if needed
  await Firebase.initializeApp();
  await NotificationService.ensureInitialized();
  await NotificationService.showRemoteMessage(message);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, lang, _) {
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
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            primary: Colors.blue,
            secondary: Colors.orange,
          ),
          useMaterial3: true,
        ),
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
        },
          );
        },
      ),
    );
  }
}