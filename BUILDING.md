# Building the Garage Service App

This guide explains how to set up your environment and build the Flutter app across platforms on Windows.

## Prerequisites

- Flutter SDK 3.32.x (stable) with Dart 3.8.x installed and on PATH
- Java 17 JDK on PATH (`JAVA_HOME` recommended)
- Android build toolchain
  - Android SDK + Platform Tools
  - Android SDK Build-Tools 34+ and Android Platform API level matching `compileSdk`
  - ANDROID_HOME (or ANDROID_SDK_ROOT) environment variable pointing to the SDK root
  - Accept all Android SDK licenses
- Windows 10/11 for desktop builds (optional)
- Node not required for web builds (Flutter includes tools)

## First-time setup (Windows PowerShell)

1. Clone repo and fetch dependencies
   - Open PowerShell in `flutter_app/`
   - Run: `flutter pub get`

2. Validate toolchains
   - `flutter doctor -v`
   - If Android toolchain shows issues, install missing SDKs via Android Studio or `sdkmanager` and accept licenses:
     - `yes | sdkmanager --licenses`

3. Optional: Clear caches when switching machines
   - `flutter clean`; then `flutter pub get`

## Android build

- Debug APK (recommended during setup):
  - If `flutter build apk --debug` reports an artifact path issue, use Gradle directly:
    - In `flutter_app/android/`: `./gradlew.bat --no-daemon assembleDebug -x lint -x test`
  - Output: `flutter_app/android/app/build/outputs/flutter-apk/app-debug.apk`

- Run on a device/emulator:
  - `flutter run -d <deviceId>`

- Release AAB (Play Store):
  - Configure signing in `android/app/build.gradle.kts` (release signingConfig)
  - `flutter build appbundle`

## Web build

- Build:
  - `flutter build web`
  - Output: `flutter_app/build/web/`
- Serve locally:
  - `flutter run -d chrome`

## Notes about recent fixes

- CSV export utility now uses conditional imports to avoid bringing `dart:html` into mobile builds.
- Gradle/Kotlin stability:
  - Custom buildDir relocation was removed; default paths are used.
  - Kotlin incremental compilation is disabled to avoid cache root mismatch crashes on some Windows setups.
  - If you re-enable incrementals, ensure consistent paths and avoid moving build outputs.

## Troubleshooting

- android/Gradle daemon crashes with messages like "Could not close incremental caches" or "different roots":
  - Run `flutter clean`; delete `~/.gradle/caches` (optional, can be large)
  - Ensure project `android/build.gradle.kts` keeps default buildDir
  - Keep Kotlin in-process compilation (set in `android/gradle.properties`)

- Flutter tool says ".apk not found" but Gradle succeeded:
  - Check `android/app/build/outputs/flutter-apk/` for `app-debug.apk`.
  - Install APK with `adb install -r app-debug.apk`.
  - Optional: run `flutter_app/scripts/copy-apk.ps1` to copy the APK into `build/app/outputs/flutter-apk/` where the Flutter tool expects it.

- Android toolchain missing:
  - Install Android Studio (recommended easiest path) and run it once to install SDKs; then `flutter doctor` should pass.

- Web build errors with missing assets:
  - Ensure `flutter gen-l10n` runs (enabled via `flutter: generate: true`), then `flutter pub get` and rebuild.

## CI

GitHub Actions workflow `.github/workflows/flutter-ci.yml` builds the app on pushes and PRs to `main`:

- Runs analyze and tests
- Builds Android debug APK via Gradle and uploads it as an artifact
- Builds Web and uploads the `build/web` folder as an artifact
