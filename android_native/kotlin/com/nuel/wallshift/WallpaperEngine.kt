package com.nuel.wallshift

import android.app.WallpaperManager
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.Paint
import android.net.Uri
import android.util.Log
import org.json.JSONArray
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream

object WallpaperEngine {
    private const val TAG = "WallShift/Engine"
    private const val PREFS_FILE = "FlutterSharedPreferences"

    private const val KEY_IMAGES = "flutter.wallshift_images"
    private const val KEY_INDEX = "flutter.wallshift_index"
    private const val KEY_TARGET = "flutter.wallshift_target"
    private const val KEY_SHUFFLE = "flutter.wallshift_shuffle"
    private const val KEY_ENABLED = "flutter.wallshift_enabled"
    private const val KEY_DIM = "flutter.wallshift_dim"
    private const val KEY_TRIGGER_UNLOCK = "flutter.wallshift_trigger_unlock"

    fun isEnabled(context: Context): Boolean {
        val prefs = context.getSharedPreferences(PREFS_FILE, Context.MODE_PRIVATE)
        return prefs.getBoolean(KEY_ENABLED, false)
    }

    fun isUnlockTriggerEnabled(context: Context): Boolean {
        val prefs = context.getSharedPreferences(PREFS_FILE, Context.MODE_PRIVATE)
        return if (prefs.contains(KEY_TRIGGER_UNLOCK)) {
            prefs.getBoolean(KEY_TRIGGER_UNLOCK, true)
        } else true
    }

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
        val dim = prefs.getInt(KEY_DIM, 0)
        val success = setWallpaperFromPath(
            context,
            path,
            prefs.getString(KEY_TARGET, "both")!!,
            dim
        )
        if (success) {
            prefs.edit().putInt(KEY_INDEX, nextIndex).apply()
        } else {
            val pruned = images.toMutableList().also { it.removeAt(nextIndex) }
            prefs.edit()
                .putString(KEY_IMAGES, JSONArray(pruned).toString())
                .apply()
        }
        return success
    }

    private fun setWallpaperFromPath(
        context: Context,
        path: String,
        target: String,
        dim: Int
    ): Boolean {
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

            if (dim <= 0) {
                stream.use { wm.setStream(it, null, true, flags) }
                return true
            }

            val original = stream.use { BitmapFactory.decodeStream(it) } ?: return false
            val bmp = applyDim(original, dim.coerceIn(0, 80) / 100f)
            val baos = ByteArrayOutputStream()
            bmp.compress(Bitmap.CompressFormat.JPEG, 90, baos)
            ByteArrayInputStream(baos.toByteArray()).use {
                wm.setStream(it, null, true, flags)
            }
            if (bmp !== original) original.recycle()
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to set wallpaper from $path", e)
            false
        }
    }

    private fun applyDim(src: Bitmap, amount: Float): Bitmap {
        val out = src.copy(Bitmap.Config.ARGB_8888, true) ?: return src
        val canvas = Canvas(out)
        val matrix = ColorMatrix().apply {
            setScale(1 - amount, 1 - amount, 1 - amount, 1f)
        }
        val paint = Paint().apply {
            colorFilter = ColorMatrixColorFilter(matrix)
        }
        canvas.drawBitmap(src, 0f, 0f, paint)
        return out
    }

    private fun readImageList(prefs: android.content.SharedPreferences): List<String> {
        val raw = prefs.getString(KEY_IMAGES, null) ?: return emptyList()
        return try {
            val arr = JSONArray(raw)
            List(arr.length()) { arr.getString(it) }
        } catch (e: Exception) {
            emptyList()
        }
    }
}
