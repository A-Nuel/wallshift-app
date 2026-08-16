package com.nuel.wallshift

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
        if (!WallpaperEngine.isEnabled(context)) return

        val prefs = context.getSharedPreferences("wallshift_alarm_prefs", Context.MODE_PRIVATE)
        val interval = prefs.getInt("interval_minutes", 5)

        RotationService.start(context, interval)
        RotationWorker.enqueue(context)
    }
}
