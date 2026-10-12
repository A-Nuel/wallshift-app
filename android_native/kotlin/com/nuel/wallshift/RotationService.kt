package com.nuel.wallshift

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class RotationService : Service() {

    private var screenReceiver: BroadcastReceiver? = null

    override fun onCreate() {
        super.onCreate()
        startForeground(NOTIFICATION_ID, buildNotification())

        screenReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                if (intent.action == Intent.ACTION_SCREEN_ON) {
                    if (WallpaperEngine.isUnlockTriggerEnabled(context)) {
                        WallpaperEngine.applyNext(context)
                    }
                }
            }
        }
        registerReceiver(screenReceiver, IntentFilter(Intent.ACTION_SCREEN_ON))
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val intervalMinutes = intent?.getIntExtra(EXTRA_INTERVAL_MINUTES, 5) ?: 5
        AlarmScheduler.arm(applicationContext, intervalMinutes)
        return START_STICKY
    }

    override fun onDestroy() {
        screenReceiver?.let { runCatching { unregisterReceiver(it) } }
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun buildNotification(): android.app.Notification {
        val channelId = "wallshift_rotation"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)
            val channel = NotificationChannel(
                channelId,
                "Wallpaper rotation",
                NotificationManager.IMPORTANCE_MIN
            ).apply {
                description = "Keeps automatic wallpaper rotation running"
                setShowBadge(false)
            }
            manager.createNotificationChannel(channel)
        }

        val openApp = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val contentIntent = PendingIntent.getActivity(
            this, 0, openApp,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        return NotificationCompat.Builder(this, channelId)
            .setContentTitle("WallShift is running")
            .setContentText("Rotating your wallpaper in the background")
            .setSmallIcon(android.R.drawable.ic_menu_gallery)
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .setOngoing(true)
            .setContentIntent(contentIntent)
            .build()
    }

    companion object {
        const val NOTIFICATION_ID = 4201
        const val EXTRA_INTERVAL_MINUTES = "intervalMinutes"

        fun start(context: Context, intervalMinutes: Int) {
            val intent = Intent(context, RotationService::class.java)
                .putExtra(EXTRA_INTERVAL_MINUTES, intervalMinutes)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            AlarmScheduler.cancel(context)
            context.stopService(Intent(context, RotationService::class.java))
        }
    }
}
