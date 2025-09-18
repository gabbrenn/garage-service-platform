import 'package:flutter/material.dart';
import 'dart:async';
import '../models/user.dart';
import '../services/api_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:provider/provider.dart';
import 'notification_provider.dart';
import '../l10n/gen/app_localizations.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<String>? _fcmTokenSub;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Future<bool> login(String email, String password, {BuildContext? context}) async {
    try {
      setLoading(true);
      setError(null);

      final response = await ApiService.login(email, password);
      
      _user = User(
        id: response['id'],
        firstName: response['firstName'],
        lastName: response['lastName'],
        email: response['email'],
        phoneNumber: '', // Not returned in login response
        userType: UserType.values.firstWhere(
          (e) => e.toString().split('.').last == response['userType'],
        ),
        createdAt: DateTime.now(), // Not returned in login response
      );

      setLoading(false);
      // Preload notifications & start realtime if context provided
      if(context != null){
        try {
          final notif = Provider.of<NotificationProvider>(context, listen:false);
          notif.configureUser(_user!.id);
          await notif.preloadIfPossible();
          notif.startRealtime();
        } catch(_) {}
      }
      // Register FCM device token and listen for refresh (best-effort)
      try {
        String? token;
        if (kIsWeb) {
          // On web, getToken requires a VAPID key
          const vapid = String.fromEnvironment('FIREBASE_VAPID_KEY');
          if (Firebase.apps.isNotEmpty) {
            token = await FirebaseMessaging.instance.getToken(vapidKey: vapid.isEmpty ? null : vapid);
          } else {
            token = null; // Firebase not initialized on web; skip
          }
        } else {
          token = await FirebaseMessaging.instance.getToken();
        }
        if (token != null) {
          await ApiService.registerDeviceToken(token);
        }
        await _fcmTokenSub?.cancel();
        _fcmTokenSub = FirebaseMessaging.instance.onTokenRefresh.listen((t) async {
          await ApiService.registerDeviceToken(t);
        });
      } catch (_) {}
      return true;
    } catch (e) {
      setError(_mapError(e, context));
      setLoading(false);
      return false;
    }
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
    required UserType userType,
    BuildContext? context,
  }) async {
    try {
      setLoading(true);
      setError(null);

      await ApiService.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
        userType: userType,
      );

      setLoading(false);
      return true;
    } catch (e) {
      setError(_mapError(e, context));
      setLoading(false);
      return false;
    }
  }

  Future<void> logout(BuildContext? context) async {
    try {
      // Best-effort: remove current device token from backend before clearing auth
      final t = await FirebaseMessaging.instance.getToken();
      if (t != null) {
        await ApiService.removeDeviceToken(t);
      }
    } catch (_) {}
    await ApiService.fullLogout();
    _user = null;
    if(context != null){
      try { Provider.of<NotificationProvider>(context, listen:false).clearAll(); } catch(_){}
    }
    try { await _fcmTokenSub?.cancel(); } catch(_) {}
    _fcmTokenSub = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _mapError(Object e, BuildContext? context) {
    final raw = e.toString();
    AppLocalizations? loc;
    if (context != null) {
      try { loc = AppLocalizations.of(context); } catch (_) {}
    }
    String pick(String english, String Function(AppLocalizations l)? getter) {
      // Generated getters may not yet exist until intl build runs; fallback to English.
      if (loc != null && getter != null) {
        try { return getter(loc); } catch (_) { return english; }
      }
      return english;
    }
    // backend messages we expect
    if (raw.contains('Email is already in use')) {
      return pick('Email is already in use', (_) => 'Email is already in use');
    }
    if (raw.contains('Phone number is already in use')) {
      return pick('Phone number is already in use', (_) => 'Phone number is already in use');
    }
    if (raw.contains('Invalid email or password')) {
      return pick('Invalid email or password', (_) => 'Invalid email or password');
    }
    if (raw.contains('Password must contain upper')) {
      return pick('Password does not meet requirements', (_) => 'Password does not meet requirements');
    }
    if (raw.contains('Failed host lookup') || raw.contains('Network is unreachable')) {
      return pick('Network error. Check your connection', (_) => 'Network error. Check your connection');
    }
    if (raw.contains('500') || raw.contains('Internal Server Error')) {
      return pick('Server error. Please try again later', (_) => 'Server error. Please try again later');
    }
    return pick('Something went wrong', (_) => 'Something went wrong');
  }
}