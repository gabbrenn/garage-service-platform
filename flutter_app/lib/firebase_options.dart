import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Provides FirebaseOptions for different platforms.
/// For web, values are sourced from --dart-define at build/run time.
/// Define the following at runtime for web:
///  - FIREBASE_API_KEY
///  - FIREBASE_APP_ID
///  - FIREBASE_MESSAGING_SENDER_ID
///  - FIREBASE_PROJECT_ID
/// Optional:
///  - FIREBASE_AUTH_DOMAIN
///  - FIREBASE_STORAGE_BUCKET
///  - FIREBASE_MEASUREMENT_ID
class DefaultFirebaseOptions {
  static FirebaseOptions? get currentPlatform {
    if (kIsWeb) return web;
    // Android/iOS/desktop use platform files; return null to use default init
    return null;
  }

  static FirebaseOptions? get web {
    const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
    const appId = String.fromEnvironment('FIREBASE_APP_ID');
    const messagingSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
    const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
    const authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN', defaultValue: '');
    const storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: '');
    const measurementId = String.fromEnvironment('FIREBASE_MEASUREMENT_ID', defaultValue: '');

    if (apiKey.isEmpty || appId.isEmpty || messagingSenderId.isEmpty || projectId.isEmpty) {
      return null;
    }

    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      authDomain: authDomain.isEmpty ? null : authDomain,
      storageBucket: storageBucket.isEmpty ? null : storageBucket,
      measurementId: measurementId.isEmpty ? null : measurementId,
    );
  }
}
