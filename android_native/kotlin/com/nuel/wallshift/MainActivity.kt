package com.nuel.wallshift

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import androidx.core.app.NotificationCompat
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
                    "setLauncherIconVisible" -> {
                        val visible = call.argument<Boolean>("visible") ?: true
                        setLauncherIconVisible(visible)
                        result.success(null)
                    }
                    "showKeepAliveNotification" -> {
                        showReopenNotification()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun setLauncherIconVisible(visible: Boolean) {
        val pm = packageManager
        val component = ComponentName(this, MainActivity::class.java)
        val state = if (visible) {
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED
        } else {
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED
        }
        pm.setComponentEnabledSetting(
            component,
            state,
            PackageManager.DONT_KILL_APP
        )
    }

    private fun showReopenNotification() {
        val channelId = "wallshift_reopen"
        val nm = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            nm.createNotificationChannel(
                NotificationChannel(
                    channelId,
                    "Open WallShift",
                    NotificationManager.IMPORTANCE_LOW
                ).apply {
                    description = "Tap to open WallShift when the icon is hidden"
                }
            )
        }
        val open = packageManager.getLaunchIntentForPackage(packageName)
            ?: Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
        // When launcher component is disabled, explicit activity still works
        val explicit = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pi = PendingIntent.getActivity(
            this, 0, explicit,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        val notif = NotificationCompat.Builder(this, channelId)
            .setContentTitle("WallShift")
            .setContentText("Tap to open · icon is hidden")
            .setSmallIcon(android.R.drawable.ic_menu_gallery)
            .setOngoing(true)
            .setContentIntent(pi)
            .build()
        nm.notify(4202, notif)
    }

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
                    component = ComponentName(pkg, cls)
                }
                startActivity(intent)
                return true
            } catch (_: Exception) {
                continue
            }
        }
        return false
    }
}
