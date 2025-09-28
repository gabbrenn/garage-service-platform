import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../l10n/gen/app_localizations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(Duration(seconds: 2)); // Show splash for 2 seconds
    
    final token = await ApiService.getToken();
    if (token != null) {
      // We don't have user details cached yet, so still go to login, but try preload notifications (will be reloaded after actual login)
      try {
        final notif = Provider.of<NotificationProvider>(context, listen:false);
        // Without user id we can't configure realtime; skip configureUser until login returns id.
        await notif.preloadIfPossible();
      } catch(_){}
    }
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.build, size: 100, color: Colors.white),
            const SizedBox(height: 20),
            Text(
              loc.splashAppName,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              loc.splashTagline,
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
          ],
        ),
      ),
    );
  }
}