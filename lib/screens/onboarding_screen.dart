import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';
import '../services/prefs_service.dart';
import '../services/wallpaper_channel.dart';
import 'home_screen.dart';

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
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            _Dots(count: 3, active: _page),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _page = i),
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _IntroPage(onNext: () => _goTo(1)),
                  _PermissionPage(
                    granted: _photosGranted,
                    onGrant: () async {
                      final status = await Permission.photos.request();
                      setState(() =>
                          _photosGranted = status.isGranted || status.isLimited);
                    },
                    onNext: () => _goTo(2),
                  ),
                  _BatteryPage(
                    exempt: _batteryExempt,
                    onCheckExempt: () async {
                      final v =
                          await WallpaperChannel.isBatteryOptimizationIgnored();
                      setState(() => _batteryExempt = v);
                    },
                    onRequestExempt: () async {
                      await WallpaperChannel.requestIgnoreBatteryOptimization();
                    },
                    onOpenAutostart: () async {
                      await WallpaperChannel.openAutostartSettings();
                    },
                    onFinish: _finish,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goTo(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int active;
  const _Dots({required this.count, required this.active});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final on = i == active;
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
    );
  }
}

class _IntroPage extends StatelessWidget {
  final VoidCallback onNext;
  const _IntroPage({required this.onNext});

  @override
  Widget build(BuildContext context) {
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
            child: const Icon(Icons.wallpaper_rounded,
                color: AppColors.accent, size: 30),
          ),
          const SizedBox(height: 28),
          Text('Your wallpaper,\nnever the same twice.',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text(
            'Pick a set of images. WallShift rotates them every time your '
            'screen wakes up — and keeps rotating on a timer even if the '
            'system decides to nap your app in the background.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: onNext, child: const Text('Continue')),
          ),
        ],
      ),
    );
  }
}

class _PermissionPage extends StatelessWidget {
  final bool granted;
  final VoidCallback onGrant;
  final VoidCallback onNext;
  const _PermissionPage({
    required this.granted,
    required this.onGrant,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
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
            'Needed to let you pick images and to keep using them after a '
            'restart. WallShift never uploads anything — everything stays '
            'on your device.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 28),
          if (!granted)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onGrant,
                child: const Text('Grant photo access'),
              ),
            )
          else
            Row(
              children: const [
                Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 20),
                SizedBox(width: 8),
                Text('Access granted'),
              ],
            ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onNext,
              child: Text(granted ? 'Continue' : 'Skip for now'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BatteryPage extends StatelessWidget {
  final bool exempt;
  final VoidCallback onCheckExempt;
  final VoidCallback onRequestExempt;
  final VoidCallback onOpenAutostart;
  final VoidCallback onFinish;
  const _BatteryPage({
    required this.exempt,
    required this.onCheckExempt,
    required this.onRequestExempt,
    required this.onOpenAutostart,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
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
            'MIUI/HyperOS aggressively kills background apps by default. '
            'Two switches fix that — takes 20 seconds:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          _StepRow(
            number: '1',
            title: 'Disable battery restrictions',
            subtitle: 'Settings → Battery → No restrictions',
            action: TextButton(
              onPressed: () async {
                onRequestExempt();
                await Future.delayed(const Duration(milliseconds: 600));
                onCheckExempt();
              },
              child: const Text('Open'),
            ),
          ),
          const SizedBox(height: 14),
          _StepRow(
            number: '2',
            title: 'Enable Autostart',
            subtitle: 'Security app → Permissions → Autostart',
            action: TextButton(onPressed: onOpenAutostart, child: const Text('Open')),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: onFinish, child: const Text("I'm set")),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final Widget action;
  const _StepRow({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.surfaceHigh,
              shape: BoxShape.circle,
            ),
            child: Text(number,
                style: const TextStyle(
                    color: AppColors.accent, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          action,
        ],
      ),
    );
  }
}
