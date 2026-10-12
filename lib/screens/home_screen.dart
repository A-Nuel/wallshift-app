import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

import '../theme/app_theme.dart';
import '../services/prefs_service.dart';
import '../services/wallpaper_channel.dart';
import '../services/image_ops.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _prefs = PrefsService();
  final _picker = ImagePicker();

  List<String> _images = [];
  bool _enabled = false;
  int _interval = 5;
  bool _busy = false;
  int _blur = 0;
  int _dim = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final images = await _prefs.getImages();
    final enabled = await _prefs.getEnabled();
    final interval = await _prefs.getIntervalMinutes();
    final blur = await _prefs.getBlur();
    final dim = await _prefs.getDim();
    setState(() {
      _images = images;
      _enabled = enabled;
      _interval = interval;
      _blur = blur;
      _dim = dim;
    });
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 95);
    if (picked.isEmpty) return;

    final paths = picked.map((x) => x.path).toList();
    final aspect = phoneAspect(context);

    // One screen: swipe through all, then Add once — no per-image dialogs
    final result = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (_) => BatchCropScreen(
          sourcePaths: paths,
          aspect: aspect,
          blurRadius: _blur,
          dimPercent: _dim,
        ),
      ),
    );

    if (result == null || result.isEmpty) return;

    final updated = [..._images, ...result];
    setState(() => _images = updated);
    await _prefs.setImages(updated);
    _showSnack('Added ${result.length} image${result.length == 1 ? '' : 's'}');
  }

  Future<void> _removeAt(int index) async {
    final path = _images[index];
    final updated = [..._images]..removeAt(index);
    setState(() => _images = updated);
    await _prefs.setImages(updated);
    try {
      final f = File(path);
      if (await f.exists() && path.contains('wallpapers')) await f.delete();
    } catch (_) {}
  }

  Future<void> _toggleEnabled(bool value) async {
    if (value && _images.length < 2) {
      _showSnack('Add at least 2 images first');
      return;
    }
    setState(() => _enabled = value);
    await _prefs.setEnabled(value);
    if (value) {
      await WallpaperChannel.startRotation(_interval);
    } else {
      await WallpaperChannel.stopRotation();
    }
  }

  Future<void> _setInterval(int minutes) async {
    setState(() => _interval = minutes);
    await _prefs.setIntervalMinutes(minutes);
    if (_enabled) await WallpaperChannel.startRotation(minutes);
  }

  Future<void> _changeNow() async {
    if (_images.isEmpty) {
      _showSnack('Add images first');
      return;
    }
    setState(() => _busy = true);
    try {
      await WallpaperChannel.setWallpaperNow();
      _showSnack('Wallpaper changed');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.surfaceHigh,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WallShift'),
        actions: [
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _busy ? null : _pickImages,
        child: const Icon(Icons.add_photo_alternate_rounded),
      ),
      body: Column(
        children: [
          GlassCard(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Auto-rotate',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 2),
                          Text(
                            _enabled
                                ? 'On screen wake + timed backup'
                                : 'Currently off',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Switch(value: _enabled, onChanged: _toggleEnabled),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openIntervalSheet(context),
                        icon: const Icon(Icons.timer_outlined, size: 18),
                        label: Text(_interval < 60
                            ? 'Every $_interval min'
                            : 'Every ${_interval ~/ 60} hr'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _busy ? null : _changeNow,
                        child: const Text('Change now'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(
              children: [
                Text(
                  '${_images.length} in rotation',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Expanded(
            child: _images.isEmpty
                ? _EmptyState(onAdd: _pickImages)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                    child: ReorderableGridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _images.length,
                      onReorder: (oldIndex, newIndex) async {
                        final updated = [..._images];
                        final item = updated.removeAt(oldIndex);
                        updated.insert(newIndex, item);
                        setState(() => _images = updated);
                        await _prefs.setImages(updated);
                      },
                      itemBuilder: (context, index) {
                        final path = _images[index];
                        return _ImageTile(
                          key: ValueKey(path),
                          path: path,
                          onRemove: () => _removeAt(index),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _openIntervalSheet(BuildContext context) {
    final options = [5, 10, 15, 30, 60, 120];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Change every', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Screen-wake is instant. This is the timed backup interval.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: options.map((m) {
                final label = m < 60 ? '$m min' : '${m ~/ 60} hr';
                final selected = m == _interval;
                return ChoiceChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (_) {
                    _setInterval(m);
                    Navigator.pop(context);
                  },
                  selectedColor: AppColors.accentDim,
                  backgroundColor: AppColors.surfaceHigh,
                  labelStyle: TextStyle(
                    color:
                        selected ? AppColors.textPrimary : AppColors.textMuted,
                  ),
                  side: BorderSide.none,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  final String path;
  final VoidCallback onRemove;
  const _ImageTile({super.key, required this.path, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(path),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.surfaceHigh,
              child: const Icon(Icons.broken_image_outlined),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_library_outlined,
                size: 40, color: AppColors.textMuted),
            const SizedBox(height: 14),
            Text('No images yet', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Add photos or open Packs for offline quote sets.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            ElevatedButton(onPressed: onAdd, child: const Text('Add images')),
          ],
        ),
      ),
    );
  }
}
