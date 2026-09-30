import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'services/prefs_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WallShiftApp());
}

class WallShiftApp extends StatelessWidget {
  const WallShiftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WallShift',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const _Root(),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  final _prefs = PrefsService();
  bool? _onboarded;

  @override
  void initState() {
    super.initState();
    _prefs.getOnboarded().then((v) => setState(() => _onboarded = v));
  }

  @override
  Widget build(BuildContext context) {
    if (_onboarded == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _onboarded! ? const HomeScreen() : const OnboardingScreen();
  }
}
