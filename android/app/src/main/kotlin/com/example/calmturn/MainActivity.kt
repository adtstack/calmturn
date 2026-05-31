package com.example.calmturn

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "calmturn/app_settings"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getFilesDir" -> result.success(filesDir.absolutePath)
                else -> result.notImplemented()
            }
        }
    }
}
