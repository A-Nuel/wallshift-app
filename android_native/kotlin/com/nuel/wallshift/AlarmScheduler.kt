package com.nuel.wallshift

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.SystemClock

/**
 * WorkManager's PeriodicWorkRequest has a hard 15-minute floor, so it can't
 * hit a 5-minute cadence by itself. This uses a self-rescheduling exact
 * alarm chain instead: each firing sets the *next* alarm before it does
 * anything else, so the chain survives even if wallpaper-setting throws.
 *
 * WorkManager (see RotationWorker) acts as the watchdog on top of this:
 * every 15 minutes it checks the chain is still armed and re-arms it if
 * the system cleared it (this happens after force-stop, and on some OEM
 * skins after long idle periods).
 */
object AlarmScheduler {
    private const val PREFS_FILE = "wallshift_alarm_prefs"
    private const val KEY_INTERVAL = "interval_minutes"
    private const val REQUEST_CODE = 9001

    fun arm(context: Context, intervalMinutes: Int) {
        context.getSharedPreferences(PREFS_FILE, Context.MODE_PRIVATE)
            .edit().putInt(KEY_INTERVAL, intervalMinutes).apply()
        scheduleNext(context, intervalMinutes)
    }

    fun cancel(context: Context) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        am.cancel(pendingIntent(context))
    }

    /** Re-arms using the last-known interval. No-op if never armed. */
    fun rearmIfNeeded(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_FILE, Context.MODE_PRIVATE)
        val interval = prefs.getInt(KEY_INTERVAL, -1)
        if (interval > 0 && WallpaperEngine.isEnabled(context)) {
            scheduleNext(context, interval)
        }
    }

    fun scheduleNext(context: Context, intervalMinutes: Int) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val triggerAt = SystemClock.elapsedRealtime() + intervalMinutes * 60_000L
        val pi = pendingIntent(context)
        // setExactAndAllowWhileIdle so it still fires (once) during Doze;
        // Android will space consecutive alarms out under deep Doze, which
        // is an OS-level ceiling this can't override.
        am.setExactAndAllowWhileIdle(AlarmManager.ELAPSED_REALTIME_WAKEUP, triggerAt, pi)
    }

    private fun pendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, AlarmReceiver::class.java)
        return PendingIntent.getBroadcast(
            context, REQUEST_CODE, intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
    }
}

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        // Reschedule first so a crash/exception below never breaks the chain.
        val prefs: SharedPreferences =
            context.getSharedPreferences("wallshift_alarm_prefs", Context.MODE_PRIVATE)
        val interval = prefs.getInt("interval_minutes", 5)
        AlarmScheduler.scheduleNext(context, interval)

        if (WallpaperEngine.isEnabled(context)) {
            WallpaperEngine.applyNext(context)
        }
    }
}
