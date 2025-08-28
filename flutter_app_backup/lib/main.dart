import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/garage_provider.dart';
import 'providers/service_request_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/customer/customer_home_screen.dart';
import 'screens/customer/garage_details_screen.dart';
import 'screens/customer/service_request_screen.dart';
import 'screens/customer/my_requests_screen.dart';
import 'screens/garage/garage_home_screen.dart';
import 'screens/garage/garage_setup_screen.dart';
import 'screens/garage/add_service_screen.dart';
import 'screens/garage/service_requests_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GarageProvider()),
        ChangeNotifierProvider(create: (_) => ServiceRequestProvider()),
      ],
      child: MaterialApp(
        title: 'Garage Service App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => SplashScreen(),
          '/login': (context) => LoginScreen(),
          '/register': (context) => RegisterScreen(),
          '/customer-home': (context) => CustomerHomeScreen(),
          '/garage-details': (context) => GarageDetailsScreen(),
          '/service-request': (context) => ServiceRequestScreen(),
          '/my-requests': (context) => MyRequestsScreen(),
          '/garage-home': (context) => GarageHomeScreen(),
          '/garage-setup': (context) => GarageSetupScreen(),
          '/add-service': (context) => AddServiceScreen(),
          '/service-requests': (context) => ServiceRequestsScreen(),
        },
      ),
    );
  }
}