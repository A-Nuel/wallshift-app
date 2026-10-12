import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PrefsKeys {
  static const images = 'wallshift_images';
  static const index = 'wallshift_index';
  static const intervalMinutes = 'wallshift_interval_minutes';
  static const enabled = 'wallshift_enabled';
  static const target = 'wallshift_target';
  static const shuffle = 'wallshift_shuffle';
  static const onboarded = 'wallshift_onboarded';
  static const theme = 'wallshift_theme';
  static const blur = 'wallshift_blur'; // 0-25
  static const dim = 'wallshift_dim'; // 0-80 percent
  static const albums = 'wallshift_albums';
  static const activeAlbum = 'wallshift_active_album';
  static const hideIcon = 'wallshift_hide_icon';
  static const triggerUnlock = 'wallshift_trigger_unlock'; // screen-on
  static const triggerTimed = 'wallshift_trigger_timed';
}

class Album {
  final String id;
  final String name;
  final List<String> images;

  Album({required this.id, required this.name, required this.images});

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'images': images};

  factory Album.fromJson(Map<String, dynamic> j) => Album(
        id: j['id'] as String,
        name: j['name'] as String,
        images: (j['images'] as List<dynamic>).map((e) => e.toString()).toList(),
      );

  Album copyWith({String? name, List<String>? images}) => Album(
        id: id,
        name: name ?? this.name,
        images: images ?? this.images,
      );
}

class PrefsService {
  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<List<String>> getImages() async {
    final p = await _prefs;
    final raw = p.getString(PrefsKeys.images);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => e.toString()).toList();
    } catch (_) {
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

  Future<String> getThemeId() async {
    final p = await _prefs;
    return p.getString(PrefsKeys.theme) ?? 'ember';
  }

  Future<void> setThemeId(String id) async {
    final p = await _prefs;
    await p.setString(PrefsKeys.theme, id);
  }

  Future<int> getBlur() async {
    final p = await _prefs;
    return p.getInt(PrefsKeys.blur) ?? 0;
  }

  Future<void> setBlur(int value) async {
    final p = await _prefs;
    await p.setInt(PrefsKeys.blur, value.clamp(0, 25));
  }

  Future<int> getDim() async {
    final p = await _prefs;
    return p.getInt(PrefsKeys.dim) ?? 0;
  }

  Future<void> setDim(int value) async {
    final p = await _prefs;
    await p.setInt(PrefsKeys.dim, value.clamp(0, 80));
  }

  Future<List<Album>> getAlbums() async {
    final p = await _prefs;
    final raw = p.getString(PrefsKeys.albums);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Album.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> setAlbums(List<Album> albums) async {
    final p = await _prefs;
    await p.setString(
      PrefsKeys.albums,
      jsonEncode(albums.map((a) => a.toJson()).toList()),
    );
  }

  Future<String?> getActiveAlbumId() async {
    final p = await _prefs;
    return p.getString(PrefsKeys.activeAlbum);
  }

  Future<void> setActiveAlbumId(String? id) async {
    final p = await _prefs;
    if (id == null) {
      await p.remove(PrefsKeys.activeAlbum);
    } else {
      await p.setString(PrefsKeys.activeAlbum, id);
    }
  }

  Future<bool> getHideIcon() async {
    final p = await _prefs;
    return p.getBool(PrefsKeys.hideIcon) ?? false;
  }

  Future<void> setHideIcon(bool value) async {
    final p = await _prefs;
    await p.setBool(PrefsKeys.hideIcon, value);
  }

  Future<bool> getTriggerUnlock() async {
    final p = await _prefs;
    return p.getBool(PrefsKeys.triggerUnlock) ?? true;
  }

  Future<void> setTriggerUnlock(bool value) async {
    final p = await _prefs;
    await p.setBool(PrefsKeys.triggerUnlock, value);
  }

  Future<bool> getTriggerTimed() async {
    final p = await _prefs;
    return p.getBool(PrefsKeys.triggerTimed) ?? true;
  }

  Future<void> setTriggerTimed(bool value) async {
    final p = await _prefs;
    await p.setBool(PrefsKeys.triggerTimed, value);
  }
}
