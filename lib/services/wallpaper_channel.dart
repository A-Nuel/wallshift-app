import 'package:flutter/services.dart';

/// Bridge to the native Android side. WallpaperManager, the foreground
/// service, AlarmManager and WorkManager all live in Kotlin.
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

  /// Best-effort: opens MIUI/HyperOS Security autostart screen if present.
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
