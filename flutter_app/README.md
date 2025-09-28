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

## Environment JSON & Google Maps/Web Run Script

To keep real API keys out of source control while still making local runs easy, the project supports a JSON-based dart-define file plus a helper PowerShell script.

### 1. Create an env JSON (not committed)
Example: `.env.dev.json`
```json
{
	"GOOGLE_MAPS_API_KEY": "YOUR_BROWSER_MAPS_JS_KEY",
	"GOOGLE_DIRECTIONS_API_KEY": "(optional – if different)",
	"FIREBASE_API_KEY": "...",
	"FIREBASE_APP_ID": "...",
	"FIREBASE_MESSAGING_SENDER_ID": "...",
	"FIREBASE_PROJECT_ID": "...",
	"FIREBASE_AUTH_DOMAIN": "your_project.firebaseapp.com",
	"FIREBASE_STORAGE_BUCKET": "your_project.appspot.com",
	"FIREBASE_MEASUREMENT_ID": "G-XXXXXXX",
	"FIREBASE_VAPID_KEY": "YOUR_WEB_PUSH_VAPID_KEY"
}
```
You can add any other keys you access via `const String.fromEnvironment('NAME')`.

### 2. Run with automatic injection
```powershell
pwsh -File .\scripts\run-web-with-env.ps1 -EnvFile .env.dev.json -Device chrome
```
What the script does:
1. Reads JSON values.
2. Picks `GOOGLE_MAPS_API_KEY` (fallback: `GOOGLE_DIRECTIONS_API_KEY`).
3. Temporarily rewrites `web/index.html` meta tag (and ensures a `<script>` tag if needed) so the Google Maps JS API loads.
4. Executes `flutter run` passing all JSON entries using `--dart-define-from-file`.
5. Restores the original `web/index.html` after the run (even if aborted).

### 3. Direct alternative (without script)
You can still run manually:
```powershell
flutter run -d chrome --dart-define-from-file=.env.dev.json
```
If you do that, ensure `web/index.html` has either a placeholder meta tag plus a script injected some other way, or manually edit it (but never commit real keys).

### 4. Production / CI
- Provide a different file (e.g. `.env.prod.json`) and pass it the same way.
- Or convert keys into secure build pipeline secrets and echo a JSON file before running the build.

### 5. Common Issues
- `google is not defined`: The Maps JS failed to load; likely missing/blocked key.
- `ApiTargetBlockedMapError`: Key restrictions mismatch (fix referrers, enable APIs, billing active).
- White screen but no error: Missing/partial firebase defines; either supply all or none for web.

The script includes `-Help` for usage details.

## Unified Environment (.env + --dart-define) Strategy

The app now supports a layered precedence for configuration values:

1. Explicit `--dart-define=KEY=VALUE` at build/run time
2. Values loaded from `.env` via `flutter_dotenv`
3. Hard-coded fallback (only where absolutely necessary, e.g. API base URL)

Helper access class: `Env.get('KEY')` (nullable) / `Env.require('KEY')` (throws if missing).

Central convenience wrapper: `AppConfig` (see `lib/config/app_config.dart`).

### Key Reference
| Purpose | Keys (checked in order) | Notes |
|---------|------------------------|-------|
| API Base URL | `API_BASE_URL` | Trailing slashes removed; fallback points to Render deployment |
| Google Maps (Web) | `GOOGLE_MAPS_API_KEY_WEB`, `GOOGLE_MAPS_API_KEY`, `GOOGLE_DIRECTIONS_API_KEY` | Web run script also injects meta/script |
| Google Maps (Android) | `GOOGLE_MAPS_API_KEY_ANDROID`, `GOOGLE_MAPS_API_KEY`, `GOOGLE_DIRECTIONS_API_KEY` | Native manifest key can still override via method channel |
| Google Maps (iOS) | `GOOGLE_MAPS_API_KEY_IOS`, `GOOGLE_MAPS_API_KEY`, `GOOGLE_DIRECTIONS_API_KEY` | Same method channel logic |
| Firebase | `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_PROJECT_ID`, `FIREBASE_AUTH_DOMAIN`, `FIREBASE_STORAGE_BUCKET`, `FIREBASE_MEASUREMENT_ID`, `FIREBASE_VAPID_KEY` | Provide all for full web support |

### Example `.env`
```
API_BASE_URL=https://garage-service-platform.onrender.com/api
GOOGLE_MAPS_API_KEY_WEB=YOUR_WEB_KEY
GOOGLE_MAPS_API_KEY_ANDROID=YOUR_ANDROID_KEY
GOOGLE_MAPS_API_KEY_IOS=YOUR_IOS_KEY
FIREBASE_API_KEY=...
FIREBASE_APP_ID=...
FIREBASE_MESSAGING_SENDER_ID=...
FIREBASE_PROJECT_ID=...
FIREBASE_AUTH_DOMAIN=...firebaseapp.com
FIREBASE_STORAGE_BUCKET=...firebasestorage.app
FIREBASE_MEASUREMENT_ID=G-XXXXXXX
FIREBASE_VAPID_KEY=YOUR_VAPID
```

### Production Recommendation
- Keep a committed `.env.sample` (no secrets) documenting required keys.
- Provide real keys via CI environment variables mapped to `--dart-define`.
- Do not commit the real `.env` file.

### Access Examples
```dart
import 'config/app_config.dart';

final api = AppConfig.apiBaseUrl; // cleaned and resolved
final mapsKey = AppConfig.effectiveMapsKey; // platform-specific resolution
final projectId = Env.require('FIREBASE_PROJECT_ID');
```
