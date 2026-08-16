package com.nuel.wallshift

import android.app.AlarmManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "wallshift/native"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setWallpaperNow" -> {
                        val ok = WallpaperEngine.applyNext(applicationContext)
                        result.success(ok)
                    }
                    "startRotation" -> {
                        val minutes = call.argument<Int>("intervalMinutes") ?: 5
                        RotationService.start(applicationContext, minutes)
                        RotationWorker.enqueue(applicationContext)
                        result.success(null)
                    }
                    "stopRotation" -> {
                        RotationService.stop(applicationContext)
                        RotationWorker.cancel(applicationContext)
                        result.success(null)
                    }
                    "isBatteryOptimizationIgnored" -> {
                        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                        val ignored = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            pm.isIgnoringBatteryOptimizations(packageName)
                        } else true
                        result.success(ignored)
                    }
                    "requestIgnoreBatteryOptimization" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val intent = Intent(
                                Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                                Uri.parse("package:$packageName")
                            )
                            startActivity(intent)
                        }
                        result.success(null)
                    }
                    "openAutostartSettings" -> {
                        result.success(openAutostartIfAvailable())
                    }
                    "canScheduleExactAlarms" -> {
                        val can = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                            am.canScheduleExactAlarms()
                        } else true
                        result.success(can)
                    }
                    "requestExactAlarmPermission" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
                                .setData(Uri.parse("package:$packageName"))
                            startActivity(intent)
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * MIUI/HyperOS hides the autostart toggle in the Security app, not in
     * standard Android settings. There's no public API for it, so this
     * tries the known component names and quietly fails on non-Xiaomi
     * devices (or if the OEM changes the component in a future build).
     */
    private fun openAutostartIfAvailable(): Boolean {
        val manufacturer = Build.MANUFACTURER.lowercase()
        if (!manufacturer.contains("xiaomi") && !manufacturer.contains("redmi") &&
            !manufacturer.contains("poco")
        ) {
            return false
        }
        val candidates = listOf(
            Pair(
                "com.miui.securitycenter",
                "com.miui.permcenter.autostart.AutoStartManagementActivity"
            ),
            Pair(
                "com.miui.securitycenter",
                "com.miui.permcenter.autostart.AutoStartManagementActivity2"
            )
        )
        for ((pkg, cls) in candidates) {
            try {
                val intent = Intent().apply {
                    component = android.content.ComponentName(pkg, cls)
                }
                startActivity(intent)
                return true
            } catch (e: Exception) {
                continue
            }
        }
        return false
    }
}
