import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Crop [sourcePath] to [aspect] (width/height), centered, then optionally
/// apply blur radius and dim percent. Returns path of saved JPEG in app docs.
Future<String> processWallpaperImage({
  required String sourcePath,
  required double aspect,
  Rect? normalizedCrop,
  int blurRadius = 0,
  int dimPercent = 0,
}) async {
  final bytes = await File(sourcePath).readAsBytes();
  var decoded = img.decodeImage(bytes);
  if (decoded == null) throw Exception('Could not decode image');

  decoded = img.bakeOrientation(decoded);

  final w = decoded.width;
  final h = decoded.height;

  int left, top, cw, ch;
  if (normalizedCrop != null) {
    left = (normalizedCrop.left * w).round().clamp(0, w - 1);
    top = (normalizedCrop.top * h).round().clamp(0, h - 1);
    cw = (normalizedCrop.width * w).round().clamp(1, w - left);
    ch = (normalizedCrop.height * h).round().clamp(1, h - top);
  } else {
    final srcAspect = w / h;
    if (srcAspect > aspect) {
      ch = h;
      cw = (h * aspect).round();
      left = ((w - cw) / 2).round();
      top = 0;
    } else {
      cw = w;
      ch = (w / aspect).round();
      left = 0;
      top = ((h - ch) / 2).round();
    }
  }

  var cropped = img.copyCrop(decoded, x: left, y: top, width: cw, height: ch);

  final maxSide = 1920;
  if (cropped.width > maxSide || cropped.height > maxSide) {
    if (cropped.width > cropped.height) {
      cropped = img.copyResize(cropped, width: maxSide);
    } else {
      cropped = img.copyResize(cropped, height: maxSide);
    }
  }

  if (blurRadius > 0) {
    cropped = img.gaussianBlur(cropped, radius: blurRadius.clamp(1, 25));
  }

  if (dimPercent > 0) {
    final amount = (dimPercent.clamp(0, 80) / 100.0);
    for (final pxl in cropped) {
      pxl
        ..r = (pxl.r * (1 - amount)).round()
        ..g = (pxl.g * (1 - amount)).round()
        ..b = (pxl.b * (1 - amount)).round();
    }
  }

  final dir = await getApplicationDocumentsDirectory();
  final wallDir = Directory(p.join(dir.path, 'wallpapers'));
  if (!await wallDir.exists()) await wallDir.create(recursive: true);
  final out = p.join(
    wallDir.path,
    '${DateTime.now().millisecondsSinceEpoch}_${p.basenameWithoutExtension(sourcePath)}.jpg',
  );
  await File(out).writeAsBytes(img.encodeJpg(cropped, quality: 90));
  return out;
}

double phoneAspect(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return size.width / size.height;
}

class CropResult {
  final String path;
  CropResult(this.path);
}

/// Swipe through every selected photo, then apply auto-fit to all in one go.
class BatchCropScreen extends StatefulWidget {
  final List<String> sourcePaths;
  final double aspect;
  final int blurRadius;
  final int dimPercent;

  const BatchCropScreen({
    super.key,
    required this.sourcePaths,
    required this.aspect,
    this.blurRadius = 0,
    this.dimPercent = 0,
  });

  @override
  State<BatchCropScreen> createState() => _BatchCropScreenState();
}

class _BatchCropScreenState extends State<BatchCropScreen> {
  late final PageController _page;
  int _index = 0;
  bool _busy = false;
  final Set<int> _skipped = {};

  @override
  void initState() {
    super.initState();
    _page = PageController();
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    setState(() => _busy = true);
    try {
      final out = <String>[];
      for (var i = 0; i < widget.sourcePaths.length; i++) {
        if (_skipped.contains(i)) continue;
        final path = await processWallpaperImage(
          sourcePath: widget.sourcePaths[i],
          aspect: widget.aspect,
          blurRadius: widget.blurRadius,
          dimPercent: widget.dimPercent,
        );
        out.add(path);
      }
      if (!mounted) return;
      Navigator.pop(context, out);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.sourcePaths.length;
    final keepCount = total - _skipped.length;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Review  ${_index + 1} / $total'),
        actions: [
          TextButton(
            onPressed: _busy || keepCount == 0 ? null : _finish,
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('Add $keepCount'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _page,
              itemCount: total,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                final skipped = _skipped.contains(i);
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Center(
                      child: AspectRatio(
                        aspectRatio: widget.aspect,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: skipped
                                  ? Colors.redAccent.withOpacity(0.6)
                                  : Colors.white38,
                              width: 2,
                            ),
                          ),
                          child: Image.file(
                            File(widget.sourcePaths[i]),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      ),
                    ),
                    if (skipped)
                      Container(
                        color: Colors.black54,
                        alignment: Alignment.center,
                        child: const Text(
                          'Skipped',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Swipe through all photos. Auto-fit crops to your phone screen. '
              'Skip any you don’t want, then tap Add.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.7), height: 1.35),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                      ),
                      onPressed: _busy
                          ? null
                          : () {
                              setState(() {
                                if (_skipped.contains(_index)) {
                                  _skipped.remove(_index);
                                } else {
                                  _skipped.add(_index);
                                }
                              });
                            },
                      child: Text(
                        _skipped.contains(_index) ? 'Unskip' : 'Skip',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B4A),
                        foregroundColor: Colors.black,
                      ),
                      onPressed: _busy || keepCount == 0 ? null : _finish,
                      child: Text('Add $keepCount'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
