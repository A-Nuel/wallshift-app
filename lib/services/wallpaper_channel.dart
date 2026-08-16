import 'package:flutter/services.dart';

/// Bridge to the native Android side. Everything that actually touches
/// WallpaperManager, the foreground service, AlarmManager or WorkManager
/// lives in Kotlin — Flutter can't do any of that reliably in the
/// background on its own.
class WallpaperChannel {
  static const _channel = MethodChannel('wallshift/native');

  static Future<void> setWallpaperNow() async {
    await _channel.invokeMethod('setWallpaperNow');
  }

  static Future<void> startRotation(int intervalMinutes) async {
    await _channel.invokeMethod('startRotation', {
      'intervalMinutes': intervalMinutes,
    });
  }

  static Future<void> stopRotation() async {
    await _channel.invokeMethod('stopRotation');
  }

  static Future<bool> isBatteryOptimizationIgnored() async {
    final result =
        await _channel.invokeMethod<bool>('isBatteryOptimizationIgnored');
    return result ?? false;
  }

  static Future<void> requestIgnoreBatteryOptimization() async {
    await _channel.invokeMethod('requestIgnoreBatteryOptimization');
  }

  /// Best-effort: opens the MIUI/HyperOS Security app's autostart screen
  /// if it exists on this device. No-op (returns false) on non-Xiaomi
  /// devices so callers can hide the step.
  static Future<bool> openAutostartSettings() async {
    final result = await _channel.invokeMethod<bool>('openAutostartSettings');
    return result ?? false;
  }

  static Future<bool> canScheduleExactAlarms() async {
    final result =
        await _channel.invokeMethod<bool>('canScheduleExactAlarms');
    return result ?? true;
  }

  static Future<void> requestExactAlarmPermission() async {
    await _channel.invokeMethod('requestExactAlarmPermission');
  }
}
