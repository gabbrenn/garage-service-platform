import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Allow notifications to be delivered to the app while in foreground
    UNUserNotificationCenter.current().delegate = self
    // Register with APNs
    application.registerForRemoteNotifications()
    GeneratedPluginRegistrant.register(with: self)

    // Method channel to expose native configuration (e.g., Maps API key)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: "com.garageservice/native_config", binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler { call, result in
        if call.method == "getMapsApiKey" {
          let key = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String ?? ""
          result(key)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
