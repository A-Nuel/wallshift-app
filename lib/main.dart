import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'services/prefs_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/shell_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WallShiftApp());
}

class WallShiftApp extends StatefulWidget {
  const WallShiftApp({super.key});

  @override
  State<WallShiftApp> createState() => WallShiftAppState();

  static WallShiftAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<WallShiftAppState>();
}

class WallShiftAppState extends State<WallShiftApp> {
  final _prefs = PrefsService();
  AppThemeId _themeId = AppThemeId.ember;
  bool? _onboarded;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tid = await _prefs.getThemeId();
    final onboarded = await _prefs.getOnboarded();
    setState(() {
      _themeId = _parseTheme(tid);
      AppColors.current = AppThemes.of(_themeId);
      _onboarded = onboarded;
    });
  }

  AppThemeId _parseTheme(String id) {
    return AppThemeId.values.firstWhere(
      (e) => e.name == id,
      orElse: () => AppThemeId.ember,
    );
  }

  Future<void> setTheme(AppThemeId id) async {
    setState(() {
      _themeId = id;
      AppColors.current = AppThemes.of(id);
    });
    await _prefs.setThemeId(id.name);
  }

  AppThemeId get themeId => _themeId;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WallShift',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.build(_themeId),
      home: _onboarded == null
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : (_onboarded! ? const ShellScreen() : const OnboardingScreen()),
    );
  }
}
