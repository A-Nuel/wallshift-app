package com.nuel.wallshift

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Constraints
import java.util.concurrent.TimeUnit

/**
 * Backup layer #2. Android enforces a 15-minute floor on periodic
 * WorkManager jobs, so this can't replace the AlarmManager chain for a
 * 5-minute cadence — but WorkManager jobs are the most OS-resilient
 * primitive available (survive reboots once re-enqueued, get special
 * handling from Doze/App Standby), so it's used as:
 *
 *  1. A watchdog that re-arms the AlarmManager chain if it went missing.
 *  2. A guaranteed wallpaper change at least every 15 minutes even if
 *     everything else (service, alarm, screen-on receiver) got killed.
 */
class RotationWorker(context: Context, params: WorkerParameters) :
    CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        return try {
            AlarmScheduler.rearmIfNeeded(applicationContext)
            if (WallpaperEngine.isEnabled(applicationContext)) {
                WallpaperEngine.applyNext(applicationContext)
            }
            Result.success()
        } catch (e: Exception) {
            Result.retry()
        }
    }

    companion object {
        private const val UNIQUE_NAME = "wallshift_rotation_watchdog"

        fun enqueue(context: Context) {
            val request = PeriodicWorkRequestBuilder<RotationWorker>(
                15, TimeUnit.MINUTES
            ).setConstraints(
                Constraints.Builder().setRequiresBatteryNotLow(false).build()
            ).build()

            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                UNIQUE_NAME,
                ExistingPeriodicWorkPolicy.KEEP,
                request
            )
        }

        fun cancel(context: Context) {
            WorkManager.getInstance(context).cancelUniqueWork(UNIQUE_NAME)
        }
    }
}
