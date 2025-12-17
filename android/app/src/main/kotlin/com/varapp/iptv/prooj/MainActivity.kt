package com.varapp.iptv

import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "var_app/device"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAndroidId" -> {
                    try {
                        val androidId = Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID)
                        if (androidId != null) {
                            result.success(androidId)
                        } else {
                            result.success("")
                        }
                    } catch (e: Exception) {
                        result.error("UNAVAILABLE", "Android ID not available: ${e.message}", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
