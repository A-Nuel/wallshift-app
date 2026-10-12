import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class WallpaperPack {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final List<String> quotes;

  const WallpaperPack({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.quotes,
  });
}

const packs = <WallpaperPack>[
  WallpaperPack(
    id: 'motivation',
    title: 'Motivation',
    subtitle: 'Short pushes for hard days',
    icon: Icons.local_fire_department_rounded,
    gradient: [Color(0xFF1A0A00), Color(0xFF5C1A00), Color(0xFFFF6B4A)],
    quotes: [
      'Start before you feel ready.',
      'Small steps still move you.',
      'Discipline beats motivation.',
      'Show up. Especially today.',
      'Your future self is watching.',
      'One more rep. One more try.',
    ],
  ),
  WallpaperPack(
    id: 'faith',
    title: 'Faith',
    subtitle: 'Quiet strength & gratitude',
    icon: Icons.auto_awesome_rounded,
    gradient: [Color(0xFF0A0F1A), Color(0xFF1A2744), Color(0xFFC9A227)],
    quotes: [
      'Be still and know.',
      'Grace for this moment.',
      'Walk by faith, not by sight.',
      'This too is held.',
      'Gratitude changes the light.',
      'Peace begins within.',
    ],
  ),
  WallpaperPack(
    id: 'focus',
    title: 'Focus',
    subtitle: 'Minimal lines for deep work',
    icon: Icons.center_focus_strong_rounded,
    gradient: [Color(0xFF050505), Color(0xFF1A1A1A), Color(0xFF4A90D9)],
    quotes: [
      'One thing at a time.',
      'Protect the deep work.',
      'Silence the noise.',
      'Clarity over clutter.',
      'Finish what matters.',
      'Attention is a craft.',
    ],
  ),
  WallpaperPack(
    id: 'calm',
    title: 'Calm',
    subtitle: 'Soft gradients, soft mind',
    icon: Icons.water_drop_rounded,
    gradient: [Color(0xFF0B1C1A), Color(0xFF1A3A36), Color(0xFF7FDBCA)],
    quotes: [
      'Breathe in. Breathe out.',
      'You are allowed to rest.',
      'Soft is not weak.',
      'This moment is enough.',
      'Let the day be gentle.',
      'Presence over pace.',
    ],
  ),
  WallpaperPack(
    id: 'dark',
    title: 'Dark Aesthetic',
    subtitle: 'AMOLED-friendly statements',
    icon: Icons.dark_mode_rounded,
    gradient: [Color(0xFF000000), Color(0xFF111111), Color(0xFF333333)],
    quotes: [
      'Less noise. More signal.',
      'Built in the dark.',
      'Stay dangerous.',
      'No audience required.',
      'Ship it.',
      'Midnight oil.',
    ],
  ),
];

Future<List<String>> generatePackImages(WallpaperPack pack) async {
  final dir = await getApplicationDocumentsDirectory();
  final outDir = Directory(p.join(dir.path, 'packs', pack.id));
  if (!await outDir.exists()) await outDir.create(recursive: true);

  final paths = <String>[];
  for (var i = 0; i < pack.quotes.length; i++) {
    final file = File(p.join(outDir.path, 'q$i.png'));
    if (!await file.exists()) {
      final bytes = await _renderQuotePng(
        quote: pack.quotes[i],
        colors: pack.gradient,
        width: 1080,
        height: 1920,
      );
      await file.writeAsBytes(bytes);
    }
    paths.add(file.path);
  }
  return paths;
}

Future<List<int>> _renderQuotePng({
  required String quote,
  required List<Color> colors,
  required int width,
  required int height,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(
    recorder,
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
  );

  final paint = Paint()
    ..shader = ui.Gradient.linear(
      const Offset(0, 0),
      Offset(width.toDouble(), height.toDouble()),
      colors,
    );
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    paint,
  );

  final vignette = Paint()
    ..shader = ui.Gradient.radial(
      Offset(width / 2, height / 2),
      height * 0.7,
      [Colors.transparent, Colors.black.withOpacity(0.45)],
    );
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    vignette,
  );

  final builder = ui.ParagraphBuilder(
    ui.ParagraphStyle(
      textAlign: TextAlign.center,
      fontSize: 52,
      fontWeight: FontWeight.w600,
      height: 1.25,
    ),
  )
    ..pushStyle(ui.TextStyle(color: Colors.white, fontFamily: 'sans-serif'))
    ..addText(quote);
  final paragraph = builder.build()
    ..layout(ui.ParagraphConstraints(width: width * 0.78));

  final dy = (height - paragraph.height) / 2;
  canvas.drawParagraph(paragraph, Offset(width * 0.11, dy));

  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}
