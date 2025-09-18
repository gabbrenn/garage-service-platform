import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channelDefault = AndroidNotificationChannel(
    'garage_service_events',
    'Service Alerts',
    description: 'Notifications for garage service updates',
    importance: Importance.high,
    playSound: true,
  );

  // Urgent channel with custom sound (requires android/app/src/main/res/raw/urgent.(wav|mp3))
  static const AndroidNotificationChannel _channelUrgent = AndroidNotificationChannel(
    'garage_service_urgent',
    'Urgent Alerts',
    description: 'Urgent notifications requiring immediate attention',
    importance: Importance.high,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('urgent'),
  );

  static Future<void> ensureInitialized() async {
    if (kIsWeb) {
      // Local notifications plugin not supported on web; no-op
      return;
    }
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(const InitializationSettings(android: androidInit, iOS: iosInit));

    // Create channels on Android 8+
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(_channelDefault);
    await androidImpl?.createNotificationChannel(_channelUrgent);
  }

  static Future<void> requestPermissionsIfNeeded() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
    // Firebase can request notification permission on supported platforms; skip if web not initialized
    try {
      if (!kIsWeb) {
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );
      } else {
        // On web, request permission via Firebase messaging
        await FirebaseMessaging.instance.requestPermission();
      }
    } catch (_) {
      // ignore errors when messaging is unavailable
    }
  }

  static Future<void> showRemoteMessage(RemoteMessage m) async {
    if (kIsWeb) {
      // On web, rely on browser/FCM handling (service worker). Optionally, we could
      // display a simple in-app banner/snackbar here.
      return;
    }
    final title = m.notification?.title ?? m.data['title'] ?? 'Update';
    final body = m.notification?.body ?? m.data['body'] ?? '';
    final data = m.data;

    final requestedChannel = (data['channelId'] ?? data['channel'] ?? '').toString();
    final isUrgent = (data['urgent']?.toString().toLowerCase() == 'true') ||
        requestedChannel == _channelUrgent.id;
    final soundName = (data['sound'] ?? (isUrgent ? 'urgent' : null))?.toString();

    final androidDetails = AndroidNotificationDetails(
      isUrgent ? _channelUrgent.id : _channelDefault.id,
      isUrgent ? _channelUrgent.name : _channelDefault.name,
      channelDescription: isUrgent ? _channelUrgent.description : _channelDefault.description,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      sound: soundName != null && soundName.isNotEmpty
          ? RawResourceAndroidNotificationSound(soundName)
          : null,
    );

    final iosDetails = DarwinNotificationDetails(
      presentSound: true,
      sound: soundName != null && soundName.isNotEmpty
          ? (soundName.endsWith('.wav') || soundName.endsWith('.aiff') || soundName.endsWith('.caf')
              ? soundName
              : '$soundName.wav')
          : null,
    );

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _plugin.show(m.hashCode, title, body, details, payload: data.isNotEmpty ? data.toString() : null);
  }

  static void onMessageOpenedAppNavigation(BuildContext context, RemoteMessage m) {
    // Works on mobile platforms; on web, navigation from notifications happens
    // via clicks handled by app logic as needed.
    final type = m.data['type'];
    if (type == 'SERVICE_REQUEST' && m.data['requestId'] != null) {
      Navigator.of(context).pushNamed('/service-requests');
    } else {
      Navigator.of(context).pushNamed('/notifications');
    }
  }
}
