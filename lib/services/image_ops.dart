import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Crop [sourcePath] to [aspect] (width/height), centered, then optionally
/// apply blur radius and dim percent. Returns path of saved JPEG in app docs.
Future<String> processWallpaperImage({
  required String sourcePath,
  required double aspect,
  Rect? normalizedCrop, // 0-1 rect; if null, center-crop to aspect
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

  // Target ~1080 on short side for storage
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
    '${DateTime.now().millisecondsSinceEpoch}.jpg',
  );
  await File(out).writeAsBytes(img.encodeJpg(cropped, quality: 90));
  return out;
}

/// Device-ish portrait aspect for phones.
double phoneAspect(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return size.width / size.height;
}

/// Interactive crop screen result.
class CropResult {
  final String path;
  CropResult(this.path);
}

class CropScreen extends StatefulWidget {
  final String sourcePath;
  final double aspect;

  const CropScreen({
    super.key,
    required this.sourcePath,
    required this.aspect,
  });

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  final _controller = TransformationController();
  bool _busy = false;

  Future<void> _apply() async {
    setState(() => _busy = true);
    try {
      // Center-crop to aspect from the full image (simple reliable path).
      // Full free-form matrix crop is complex; aspect-fit center is what
      // most wallpaper apps default to and matches "fit my phone".
      final out = await processWallpaperImage(
        sourcePath: widget.sourcePath,
        aspect: widget.aspect,
      );
      if (!mounted) return;
      Navigator.pop(context, CropResult(out));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Crop failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Fit to screen'),
        actions: [
          TextButton(
            onPressed: _busy ? null : _apply,
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Use'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: widget.aspect,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white54, width: 2),
                  ),
                  child: ClipRect(
                    child: InteractiveViewer(
                      transformationController: _controller,
                      minScale: 1,
                      maxScale: 4,
                      child: Image.file(
                        File(widget.sourcePath),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Preview uses your phone aspect ratio. '
              'Pinch to zoom — Use saves a center-fit crop.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
