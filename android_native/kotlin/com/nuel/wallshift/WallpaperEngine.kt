package com.nuel.wallshift

import android.app.WallpaperManager
import android.content.Context
import android.net.Uri
import android.util.Log
import org.json.JSONArray

/**
 * Single source of truth for "pick the next image and set it as wallpaper".
 * Called from the screen-on receiver, the alarm receiver, and the
 * WorkManager worker — so however the trigger fires, the behaviour (and
 * the stored index) stays consistent.
 *
 * Reads directly from the Flutter-owned SharedPreferences file, since this
 * code often runs with no Flutter engine alive (pure background trigger).
 */
object WallpaperEngine {
    private const val TAG = "WallShift/Engine"
    private const val PREFS_FILE = "FlutterSharedPreferences"

    private const val KEY_IMAGES = "flutter.wallshift_images"
    private const val KEY_INDEX = "flutter.wallshift_index"
    private const val KEY_TARGET = "flutter.wallshift_target"
    private const val KEY_SHUFFLE = "flutter.wallshift_shuffle"
    private const val KEY_ENABLED = "flutter.wallshift_enabled"

    fun isEnabled(context: Context): Boolean {
        val prefs = context.getSharedPreferences(PREFS_FILE, Context.MODE_PRIVATE)
        return prefs.getBoolean(KEY_ENABLED, false)
    }

    /** Returns true if a wallpaper was actually set. */
    fun applyNext(context: Context): Boolean {
        val prefs = context.getSharedPreferences(PREFS_FILE, Context.MODE_PRIVATE)
        val images = readImageList(prefs)
        if (images.isEmpty()) {
            Log.w(TAG, "No images configured, skipping")
            return false
        }

        val shuffle = prefs.getBoolean(KEY_SHUFFLE, true)
        val currentIndex = prefs.getInt(KEY_INDEX, -1)
        val nextIndex = if (shuffle && images.size > 1) {
            var candidate: Int
            do {
                candidate = (0 until images.size).random()
            } while (candidate == currentIndex)
            candidate
        } else {
            (currentIndex + 1) % images.size
        }

        val path = images[nextIndex]
        val success = setWallpaperFromPath(context, path, prefs.getString(KEY_TARGET, "both")!!)
        if (success) {
            prefs.edit().putInt(KEY_INDEX, nextIndex).apply()
        } else {
            // File likely no longer accessible (e.g. cache cleared). Drop it
            // so we don't keep tripping over the same dead entry.
            val pruned = images.toMutableList().also { it.removeAt(nextIndex) }
            prefs.edit()
                .putString(KEY_IMAGES, JSONArray(pruned).toString())
                .apply()
        }
        return success
    }

    private fun setWallpaperFromPath(context: Context, path: String, target: String): Boolean {
        return try {
            val wm = WallpaperManager.getInstance(context)
            val flags = when (target) {
                "home" -> WallpaperManager.FLAG_SYSTEM
                "lock" -> WallpaperManager.FLAG_LOCK
                else -> WallpaperManager.FLAG_SYSTEM or WallpaperManager.FLAG_LOCK
            }
            val stream = if (path.startsWith("content://")) {
                context.contentResolver.openInputStream(Uri.parse(path))
            } else {
                java.io.FileInputStream(path)
            } ?: return false

            stream.use { wm.setStream(it, null, true, flags) }
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to set wallpaper from $path", e)
            false
        }
    }

    private fun readImageList(prefs: android.content.SharedPreferences): List<String> {
        val raw = prefs.getString(KEY_IMAGES, null) ?: return emptyList()
        return try {
            val arr = JSONArray(raw)
            List(arr.length()) { arr.getString(it) }
        } catch (e: Exception) {
            // shared_preferences on Flutter stores StringList as a JSON array
            // string internally; if the format ever changes, fail soft.
            emptyList()
        }
    }
}
