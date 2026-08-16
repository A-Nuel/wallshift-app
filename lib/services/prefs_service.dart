import 'package:shared_preferences/shared_preferences.dart';

/// Keys here MUST match the ones read on the native (Kotlin) side, since
/// the background service and alarm/worker code read the same
/// SharedPreferences file directly (Flutter stores its prefs under the
/// "FlutterSharedPreferences" file, keys prefixed "flutter.").
class PrefsKeys {
  static const images = 'wallshift_images'; // JSON-encoded list of URIs/paths
  static const index = 'wallshift_index';
  static const intervalMinutes = 'wallshift_interval_minutes';
  static const enabled = 'wallshift_enabled';
  static const target = 'wallshift_target'; // home | lock | both
  static const shuffle = 'wallshift_shuffle';
  static const onboarded = 'wallshift_onboarded';
}

class PrefsService {
  Future<SharedPreferences> get _prefs async =>
      SharedPreferences.getInstance();

  Future<List<String>> getImages() async {
    final p = await _prefs;
    return p.getStringList(PrefsKeys.images) ?? [];
  }

  Future<void> setImages(List<String> paths) async {
    final p = await _prefs;
    await p.setStringList(PrefsKeys.images, paths);
  }

  Future<int> getIntervalMinutes() async {
    final p = await _prefs;
    return p.getInt(PrefsKeys.intervalMinutes) ?? 5;
  }

  Future<void> setIntervalMinutes(int minutes) async {
    final p = await _prefs;
    await p.setInt(PrefsKeys.intervalMinutes, minutes);
  }

  Future<bool> getEnabled() async {
    final p = await _prefs;
    return p.getBool(PrefsKeys.enabled) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    final p = await _prefs;
    await p.setBool(PrefsKeys.enabled, value);
  }

  Future<String> getTarget() async {
    final p = await _prefs;
    return p.getString(PrefsKeys.target) ?? 'both';
  }

  Future<void> setTarget(String value) async {
    final p = await _prefs;
    await p.setString(PrefsKeys.target, value);
  }

  Future<bool> getShuffle() async {
    final p = await _prefs;
    return p.getBool(PrefsKeys.shuffle) ?? true;
  }

  Future<void> setShuffle(bool value) async {
    final p = await _prefs;
    await p.setBool(PrefsKeys.shuffle, value);
  }

  Future<bool> getOnboarded() async {
    final p = await _prefs;
    return p.getBool(PrefsKeys.onboarded) ?? false;
  }

  Future<void> setOnboarded(bool value) async {
    final p = await _prefs;
    await p.setBool(PrefsKeys.onboarded, value);
  }
}
