import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'packs_screen.dart';
import 'settings_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;
  static const _channel = MethodChannel('wallshift/native');

  final _pages = const [
    HomeScreen(),
    PacksScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'openRoute') {
        final route = call.arguments?.toString();
        if (route == 'packs' && mounted) {
          setState(() => _index = 1);
        } else if (route == 'settings' && mounted) {
          setState(() => _index = 2);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.accentDim.withOpacity(0.4),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.wallpaper_outlined),
            selectedIcon: Icon(Icons.wallpaper_rounded),
            label: 'Rotate',
          ),
          NavigationDestination(
            icon: Icon(Icons.collections_outlined),
            selectedIcon: Icon(Icons.collections_rounded),
            label: 'Packs',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
