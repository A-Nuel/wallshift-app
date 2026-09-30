import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Keys MUST match the native Kotlin side.
/// Images are stored as a JSON array string so Kotlin can parse them
/// with org.json.JSONArray without depending on Flutter's internal
/// StringList encoding.
class PrefsKeys {
  static const images = 'wallshift_images';
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
    final raw = p.getString(PrefsKeys.images);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => e.toString()).toList();
    } catch (_) {
      // Legacy: older builds used StringList
      return p.getStringList(PrefsKeys.images) ?? [];
    }
  }

  Future<void> setImages(List<String> paths) async {
    final p = await _prefs;
    await p.setString(PrefsKeys.images, jsonEncode(paths));
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
