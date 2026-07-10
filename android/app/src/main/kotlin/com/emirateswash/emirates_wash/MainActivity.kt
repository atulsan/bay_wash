package com.emirateswash.emirates_wash

import android.content.ComponentName
import android.content.pm.PackageManager
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "bay_wash/app_icon"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (!BuildConfig.DEBUG) {
            window.setFlags(
                WindowManager.LayoutParams.FLAG_SECURE,
                WindowManager.LayoutParams.FLAG_SECURE
            )
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            if (call.method != "setIcon") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val icon = call.argument<String>("icon") ?: "light"
            if (icon != "light" && icon != "dark") {
                result.error("INVALID_ICON", "Unsupported app icon variant.", null)
                return@setMethodCallHandler
            }
            val enabledAlias = if (icon == "dark") {
                "com.emirateswash.emirates_wash.MainActivityDarkAlias"
            } else {
                "com.emirateswash.emirates_wash.MainActivityLightAlias"
            }
            val disabledAlias = if (icon == "dark") {
                "com.emirateswash.emirates_wash.MainActivityLightAlias"
            } else {
                "com.emirateswash.emirates_wash.MainActivityDarkAlias"
            }

            try {
                packageManager.setComponentEnabledSetting(
                    ComponentName(this, enabledAlias),
                    PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                    PackageManager.DONT_KILL_APP
                )
                packageManager.setComponentEnabledSetting(
                    ComponentName(this, disabledAlias),
                    PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                    PackageManager.DONT_KILL_APP
                )
                result.success(true)
            } catch (e: Exception) {
                result.error("ICON_SWITCH_FAILED", e.localizedMessage, null)
            }
        }
    }
}
