# Garage Service Flutter App

This is the mobile/web client for the Garage Service Platform.

## Notifications overview

- Android/iOS: Uses Firebase Cloud Messaging (FCM) with `flutter_local_notifications` for rich in-app alerts, custom channels, and sounds.
- Web: FCM is supported with a service worker for background messages. When web Firebase options are not provided, the app runs normally but push notifications are disabled (graceful degradation).

### Web push setup

Prerequisites:
- You must have a Firebase project and a Web App configured in the Firebase console.
- Obtain the Web app config (apiKey, appId, messagingSenderId, projectId, etc.).
- Generate a Web Push certificate (VAPID key) in Firebase console → Project Settings → Cloud Messaging.

Files in this repo:
- `web/firebase-messaging-sw.js` – the service worker handling background notifications.
	- Edit the `firebaseConfig` placeholders with your web app config.
- `lib/firebase_options.dart` – reads Firebase config from `--dart-define` at runtime on web.

Run locally (no web push):
- You can run the app on Chrome without any defines; Firebase will be skipped on web and the app will work without push.

Run with web push enabled:
1) Fill `web/firebase-messaging-sw.js` with your Firebase web config.
2) Start the app with your Firebase defines and VAPID key.

PowerShell example:
```powershell
flutter pub get
flutter run -d chrome `
	--dart-define=FIREBASE_API_KEY=your_api_key `
	--dart-define=FIREBASE_APP_ID=your_app_id `
	--dart-define=FIREBASE_MESSAGING_SENDER_ID=your_sender_id `
	--dart-define=FIREBASE_PROJECT_ID=your_project_id `
	--dart-define=FIREBASE_AUTH_DOMAIN=your_project_id.firebaseapp.com `
	--dart-define=FIREBASE_STORAGE_BUCKET=your_project_id.appspot.com `
	--dart-define=FIREBASE_MEASUREMENT_ID=G-XXXXXXXXXX `
	--dart-define=FIREBASE_VAPID_KEY=your_web_push_key
```

Notes:
- Web push requires HTTPS or localhost.
- Custom notification sounds/channels aren't supported on web notifications; the browser controls sound.
- Device token registration on web uses the VAPID key; on mobile it's not required.

Troubleshooting:
- White screen on web: ensure you either provide all `FIREBASE_*` defines or run without them (the app will skip Firebase on web and still load).
- Background messages not showing: confirm `web/firebase-messaging-sw.js` is deployed at the app root and has the correct Firebase config.
