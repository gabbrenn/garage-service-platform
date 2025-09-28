import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.flutter_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        // Required for libraries that use newer Java APIs on older Android API levels
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.flutter_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Raise minSdk to satisfy firebase_messaging (requires >= 23)
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        // Provide manifest placeholder for Google Maps API key.
        // Priority: project property > system env > .env file > empty
    val envProps = Properties()
        val envFile = file("../../.env")
        if (envFile.exists()) {
            envFile.inputStream().use { ins -> envProps.load(ins) }
        }
        val mapsKeyFromEnvFile = envProps.getProperty("GOOGLE_MAPS_API_KEY_ANDROID")
            ?: envProps.getProperty("GOOGLE_MAPS_API_KEY")
            ?: ""
        manifestPlaceholders["MAPS_API_KEY"] = (
            (project.findProperty("GOOGLE_MAPS_API_KEY_ANDROID") as String?)
                ?: System.getenv("GOOGLE_MAPS_API_KEY_ANDROID")
                ?: System.getenv("GOOGLE_MAPS_API_KEY")
                ?: mapsKeyFromEnvFile
        )
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Desugaring support library to backport newer Java language/library APIs
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

// Workaround: Flutter expects APK under ../../build/app/outputs/flutter-apk
// Copy APKs produced by AGP into Flutter's expected location after assemble tasks.
val copyFlutterApk by tasks.registering(Copy::class) {
    val sourceDir = layout.buildDirectory.dir("outputs/flutter-apk")
    from(sourceDir)
    include("*.apk")
    into(file("../../build/app/outputs/flutter-apk"))
}

tasks.matching { it.name == "assembleDebug" || it.name == "assembleRelease" }.configureEach {
    finalizedBy(copyFlutterApk)
}
