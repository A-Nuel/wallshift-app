package com.nuel.wallshift

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.widget.RemoteViews
import org.json.JSONArray

/**
 * Glass-styled home screen widget: preview + Change now + open app.
 */
class WallShiftWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (id in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, id)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            ACTION_CHANGE_NOW -> {
                WallpaperEngine.applyNext(context)
                refreshAll(context)
            }
            ACTION_TOGGLE -> {
                toggleRotation(context)
                refreshAll(context)
            }
            AppWidgetManager.ACTION_APPWIDGET_UPDATE -> refreshAll(context)
        }
    }

    companion object {
        const val ACTION_CHANGE_NOW = "com.nuel.wallshift.WIDGET_CHANGE_NOW"
        const val ACTION_TOGGLE = "com.nuel.wallshift.WIDGET_TOGGLE"

        fun refreshAll(context: Context) {
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(
                ComponentName(context, WallShiftWidget::class.java)
            )
            if (ids.isEmpty()) return
            for (id in ids) {
                updateAppWidget(context, mgr, id)
            }
        }

        private fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.wallshift_widget)

            val prefs = context.getSharedPreferences(
                "FlutterSharedPreferences",
                Context.MODE_PRIVATE
            )
            val enabled = prefs.getBoolean("flutter.wallshift_enabled", false)
            val images = readImages(prefs)
            val index = prefs.getInt("flutter.wallshift_index", -1)

            val status = when {
                images.isEmpty() -> "Add photos in WallShift"
                enabled -> "Rotating · ${images.size} images"
                else -> "Paused · ${images.size} images"
            }
            views.setTextViewText(R.id.widget_status, status)
            views.setTextViewText(
                R.id.widget_toggle_label,
                if (enabled) "Pause" else "Start"
            )

            // Preview: current or first image
            val previewPath = when {
                images.isEmpty() -> null
                index in images.indices -> images[index]
                else -> images.first()
            }
            if (previewPath != null) {
                try {
                    val opts = BitmapFactory.Options().apply {
                        inSampleSize = 4
                    }
                    val bmp = BitmapFactory.decodeFile(previewPath, opts)
                    if (bmp != null) {
                        views.setImageViewBitmap(R.id.widget_preview, bmp)
                    } else {
                        views.setImageViewResource(
                            R.id.widget_preview,
                            android.R.drawable.ic_menu_gallery
                        )
                    }
                } catch (_: Exception) {
                    views.setImageViewResource(
                        R.id.widget_preview,
                        android.R.drawable.ic_menu_gallery
                    )
                }
            } else {
                views.setImageViewResource(
                    R.id.widget_preview,
                    android.R.drawable.ic_menu_gallery
                )
            }

            // Open app
            val openIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val openPi = PendingIntent.getActivity(
                context,
                10,
                openIntent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
            views.setOnClickPendingIntent(R.id.widget_root, openPi)
            views.setOnClickPendingIntent(R.id.widget_preview, openPi)

            // Change now
            val changeIntent = Intent(context, WallShiftWidget::class.java).apply {
                action = ACTION_CHANGE_NOW
            }
            val changePi = PendingIntent.getBroadcast(
                context,
                11,
                changeIntent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
            views.setOnClickPendingIntent(R.id.widget_change, changePi)

            // Toggle
            val toggleIntent = Intent(context, WallShiftWidget::class.java).apply {
                action = ACTION_TOGGLE
            }
            val togglePi = PendingIntent.getBroadcast(
                context,
                12,
                toggleIntent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
            views.setOnClickPendingIntent(R.id.widget_toggle, togglePi)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun readImages(
            prefs: android.content.SharedPreferences
        ): List<String> {
            val raw = prefs.getString("flutter.wallshift_images", null) ?: return emptyList()
            return try {
                val arr = JSONArray(raw)
                List(arr.length()) { arr.getString(it) }
            } catch (_: Exception) {
                emptyList()
            }
        }

        private fun toggleRotation(context: Context) {
            val prefs = context.getSharedPreferences(
                "FlutterSharedPreferences",
                Context.MODE_PRIVATE
            )
            val enabled = prefs.getBoolean("flutter.wallshift_enabled", false)
            val next = !enabled
            prefs.edit().putBoolean("flutter.wallshift_enabled", next).apply()
            if (next) {
                val minutes = prefs.getInt("flutter.wallshift_interval_minutes", 5)
                RotationService.start(context, minutes.coerceAtLeast(5))
                RotationWorker.enqueue(context)
            } else {
                RotationService.stop(context)
                RotationWorker.cancel(context)
            }
        }
    }
}
