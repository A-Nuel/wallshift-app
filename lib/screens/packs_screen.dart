import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/pack_service.dart';
import '../services/prefs_service.dart';
import '../services/wallpaper_channel.dart';

class PacksScreen extends StatefulWidget {
  const PacksScreen({super.key});

  @override
  State<PacksScreen> createState() => _PacksScreenState();
}

class _PacksScreenState extends State<PacksScreen> {
  final _prefs = PrefsService();
  String? _busyId;

  Future<void> _applyPack(WallpaperPack pack) async {
    setState(() => _busyId = pack.id);
    try {
      final paths = await generatePackImages(pack);
      final existing = await _prefs.getImages();
      final merged = [...existing, ...paths.where((p) => !existing.contains(p))];
      await _prefs.setImages(merged);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${paths.length} from ${pack.title}'),
          backgroundColor: AppColors.surfaceHigh,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _useOnlyPack(WallpaperPack pack) async {
    setState(() => _busyId = pack.id);
    try {
      final paths = await generatePackImages(pack);
      await _prefs.setImages(paths);
      await _prefs.setEnabled(true);
      final interval = await _prefs.getIntervalMinutes();
      await WallpaperChannel.startRotation(interval);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rotating ${pack.title} only'),
          backgroundColor: AppColors.surfaceHigh,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Packs')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            'Offline quote packs — generated on your device, nothing uploaded.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ...packs.map((pack) {
            final busy = _busyId == pack.id;
            return GlassCard(
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: pack.gradient),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(pack.icon, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pack.title,
                                style: Theme.of(context).textTheme.titleLarge),
                            Text(pack.subtitle,
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: busy ? null : () => _applyPack(pack),
                          child: Text(busy ? '…' : 'Add to rotation'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: busy ? null : () => _useOnlyPack(pack),
                          child: const Text('Use only'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Text(
            'Video wallpapers are planned for a later release (live wallpaper engine).',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
