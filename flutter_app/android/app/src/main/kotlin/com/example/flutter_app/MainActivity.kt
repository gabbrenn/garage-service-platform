package com.example.flutter_app

import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val CHANNEL = "com.garageservice/native_config"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"getMapsApiKey" -> {
						try {
							val appInfo = packageManager.getApplicationInfo(packageName, PackageManager.GET_META_DATA)
							val metaData = appInfo.metaData
							val key = metaData?.getString("com.google.android.geo.API_KEY") ?: ""
							result.success(key)
						} catch (e: Exception) {
							result.success("")
						}
					}
					else -> result.notImplemented()
				}
			}
	}
}
