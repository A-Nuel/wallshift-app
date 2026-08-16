import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import '../theme/app_theme.dart';
import '../services/prefs_service.dart';
import '../services/wallpaper_channel.dart';

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
  String _target = 'both';
  bool _shuffle = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final images = await _prefs.getImages();
    final enabled = await _prefs.getEnabled();
    final interval = await _prefs.getIntervalMinutes();
    final target = await _prefs.getTarget();
    final shuffle = await _prefs.getShuffle();
    setState(() {
      _images = images;
      _enabled = enabled;
      _interval = interval;
      _target = target;
      _shuffle = shuffle;
    });
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 92);
    if (picked.isEmpty) return;
    final updated = [..._images, ...picked.map((x) => x.path)];
    setState(() => _images = updated);
    await _prefs.setImages(updated);
  }

  Future<void> _removeAt(int index) async {
    final updated = [..._images]..removeAt(index);
    setState(() => _images = updated);
    await _prefs.setImages(updated);
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
    if (_enabled) {
      await WallpaperChannel.startRotation(minutes);
    }
  }

  Future<void> _setTarget(String value) async {
    setState(() => _target = value);
    await _prefs.setTarget(value);
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
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => _openSettingsSheet(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImages,
        child: const Icon(Icons.add_photo_alternate_rounded),
      ),
      body: Column(
        children: [
          _ControlCard(
            enabled: _enabled,
            interval: _interval,
            busy: _busy,
            onToggle: _toggleEnabled,
            onChangeNow: _changeNow,
            onIntervalTap: () => _openIntervalSheet(context),
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
              'Screen-wake changes happen instantly regardless of this. '
              'This sets the timed backup interval.',
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
                    color: selected ? AppColors.textPrimary : AppColors.textMuted,
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

  void _openSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Apply to', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _TargetOption(
                label: 'Home screen only',
                value: 'home',
                groupValue: _target,
                onChanged: (v) {
                  _setTarget(v);
                  setSheetState(() {});
                },
              ),
              _TargetOption(
                label: 'Lock screen only',
                value: 'lock',
                groupValue: _target,
                onChanged: (v) {
                  _setTarget(v);
                  setSheetState(() {});
                },
              ),
              _TargetOption(
                label: 'Both',
                value: 'both',
                groupValue: _target,
                onChanged: (v) {
                  _setTarget(v);
                  setSheetState(() {});
                },
              ),
              const Divider(height: 28),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Shuffle order'),
                subtitle: Text('Off plays images in the order shown',
                    style: Theme.of(context).textTheme.bodyMedium),
                value: _shuffle,
                onChanged: (v) async {
                  setState(() => _shuffle = v);
                  setSheetState(() {});
                  await _prefs.setShuffle(v);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TargetOption extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;
  const _TargetOption({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.accent : AppColors.textMuted,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _ControlCard extends StatelessWidget {
  final bool enabled;
  final int interval;
  final bool busy;
  final ValueChanged<bool> onToggle;
  final VoidCallback onChangeNow;
  final VoidCallback onIntervalTap;
  const _ControlCard({
    required this.enabled,
    required this.interval,
    required this.busy,
    required this.onToggle,
    required this.onChangeNow,
    required this.onIntervalTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
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
                      enabled ? 'Changes on every screen wake' : 'Currently off',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Switch(value: enabled, onChanged: onToggle),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onIntervalTap,
                  icon: const Icon(Icons.timer_outlined, size: 18),
                  label: Text(interval < 60
                      ? 'Every $interval min'
                      : 'Every ${interval ~/ 60} hr'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: busy ? null : onChangeNow,
                  child: busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black),
                        )
                      : const Text('Change now'),
                ),
              ),
            ],
          ),
        ],
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
          child: Image.file(File(path), fit: BoxFit.cover),
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
              child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
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
            const Icon(Icons.photo_library_outlined,
                size: 40, color: AppColors.textMuted),
            const SizedBox(height: 14),
            Text('No images yet', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Add a few and WallShift will cycle through them.',
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
