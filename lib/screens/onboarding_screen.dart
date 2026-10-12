import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';
import '../services/prefs_service.dart';
import '../services/wallpaper_channel.dart';
import 'shell_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _prefs = PrefsService();
  final _pageController = PageController();
  int _page = 0;
  bool _photosGranted = false;
  bool _batteryExempt = false;

  Future<void> _finish() async {
    await _prefs.setOnboarded(true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ShellScreen()),
    );
  }

  void _goTo(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final on = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: on ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: on ? AppColors.accent : AppColors.divider,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _page = i),
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _pageIntro(),
                  _pagePhotos(),
                  _pageBattery(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageIntro() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.wallpaper_rounded,
                color: AppColors.accent, size: 30),
          ),
          const SizedBox(height: 28),
          Text('Your wallpaper,\nnever the same twice.',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text(
            'Rotate your photos on every screen wake, pull offline quote packs, '
            'and keep icons readable with blur and dim.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _goTo(1),
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pagePhotos() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Access to your photos',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text(
            'Needed to pick images. Everything stays on your device — '
            'WallShift never uploads your library.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 28),
          if (!_photosGranted)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final status = await Permission.photos.request();
                  setState(() =>
                      _photosGranted = status.isGranted || status.isLimited);
                },
                child: const Text('Grant photo access'),
              ),
            )
          else
            Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    color: AppColors.accent, size: 20),
                const SizedBox(width: 8),
                const Text('Access granted'),
              ],
            ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _goTo(2),
              child: Text(_photosGranted ? 'Continue' : 'Skip for now'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageBattery() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('One more thing for HyperOS',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text(
            'MIUI/HyperOS kills background apps aggressively. Two switches fix that.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          GlassCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('1. Battery: No restrictions',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('Settings → Battery',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await WallpaperChannel.requestIgnoreBatteryOptimization();
                    await Future.delayed(const Duration(milliseconds: 600));
                    final v =
                        await WallpaperChannel.isBatteryOptimizationIgnored();
                    setState(() => _batteryExempt = v);
                  },
                  child: const Text('Open'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          GlassCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('2. Enable Autostart',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('Security → Permissions',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => WallpaperChannel.openAutostartSettings(),
                  child: const Text('Open'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _finish,
              child: Text(_batteryExempt ? "I'm set" : "I'm set"),
            ),
          ),
        ],
      ),
    );
  }
}
