import 'package:flutter/material.dart';
import '../main.dart';
import '../theme/app_theme.dart';
import '../services/prefs_service.dart';
import '../services/wallpaper_channel.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _prefs = PrefsService();
  int _blur = 0;
  int _dim = 0;
  bool _hideIcon = false;
  bool _triggerUnlock = true;
  bool _triggerTimed = true;
  String _target = 'both';
  bool _shuffle = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final blur = await _prefs.getBlur();
    final dim = await _prefs.getDim();
    final hide = await _prefs.getHideIcon();
    final unlock = await _prefs.getTriggerUnlock();
    final timed = await _prefs.getTriggerTimed();
    final target = await _prefs.getTarget();
    final shuffle = await _prefs.getShuffle();
    setState(() {
      _blur = blur;
      _dim = dim;
      _hideIcon = hide;
      _triggerUnlock = unlock;
      _triggerTimed = timed;
      _target = target;
      _shuffle = shuffle;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = WallShiftApp.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text('Theme', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppThemeId.values.map((id) {
              final selected = app?.themeId == id;
              return ChoiceChip(
                label: Text(AppThemes.label(id)),
                selected: selected,
                onSelected: (_) => app?.setTheme(id),
                selectedColor: AppColors.accentDim,
                backgroundColor: AppColors.surfaceHigh,
                labelStyle: TextStyle(
                  color: selected ? AppColors.textPrimary : AppColors.textMuted,
                ),
                side: BorderSide.none,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text('Home screen', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Glass widget',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 16,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Long-press your home screen → Widgets → WallShift. '
                  'Change now and Start/Pause without opening the app.\n\n'
                  'Long-press the WallShift icon for shortcuts: Change now, Toggle, Packs.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Wallpaper look', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Blur and dim help icons stay readable. Applied when images are processed / on next set.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text('Blur: $_blur', style: Theme.of(context).textTheme.bodyMedium),
          Slider(
            value: _blur.toDouble(),
            min: 0,
            max: 25,
            divisions: 25,
            activeColor: AppColors.accent,
            onChanged: (v) => setState(() => _blur = v.round()),
            onChangeEnd: (v) => _prefs.setBlur(v.round()),
          ),
          Text('Dim: $_dim%', style: Theme.of(context).textTheme.bodyMedium),
          Slider(
            value: _dim.toDouble(),
            min: 0,
            max: 80,
            divisions: 16,
            activeColor: AppColors.accent,
            onChanged: (v) => setState(() => _dim = v.round()),
            onChangeEnd: (v) => _prefs.setDim(v.round()),
          ),
          const SizedBox(height: 16),
          Text('Apply to', style: Theme.of(context).textTheme.titleLarge),
          ...['home', 'lock', 'both'].map((v) {
            final labels = {
              'home': 'Home screen only',
              'lock': 'Lock screen only',
              'both': 'Both',
            };
            return RadioListTile<String>(
              title: Text(labels[v]!),
              value: v,
              groupValue: _target,
              activeColor: AppColors.accent,
              onChanged: (val) async {
                if (val == null) return;
                setState(() => _target = val);
                await _prefs.setTarget(val);
              },
            );
          }),
          SwitchListTile(
            title: const Text('Shuffle order'),
            value: _shuffle,
            activeColor: AppColors.accent,
            onChanged: (v) async {
              setState(() => _shuffle = v);
              await _prefs.setShuffle(v);
            },
          ),
          const Divider(height: 32),
          Text('Triggers', style: Theme.of(context).textTheme.titleLarge),
          SwitchListTile(
            title: const Text('On screen wake'),
            subtitle: Text('Change when the display turns on',
                style: Theme.of(context).textTheme.bodyMedium),
            value: _triggerUnlock,
            activeColor: AppColors.accent,
            onChanged: (v) async {
              setState(() => _triggerUnlock = v);
              await _prefs.setTriggerUnlock(v);
            },
          ),
          SwitchListTile(
            title: const Text('Timed backup'),
            subtitle: Text('Alarm + WorkManager interval',
                style: Theme.of(context).textTheme.bodyMedium),
            value: _triggerTimed,
            activeColor: AppColors.accent,
            onChanged: (v) async {
              setState(() => _triggerTimed = v);
              await _prefs.setTriggerTimed(v);
            },
          ),
          const Divider(height: 32),
          Text('Privacy', style: Theme.of(context).textTheme.titleLarge),
          SwitchListTile(
            title: const Text('Hide app icon'),
            subtitle: Text(
              'Removes WallShift from the launcher. Open again from the ongoing notification.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            value: _hideIcon,
            activeColor: AppColors.accent,
            onChanged: (v) async {
              if (v) {
                final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.surface,
                        title: const Text('Hide icon?'),
                        content: const Text(
                          'The app icon will disappear from your drawer. '
                          'Keep the WallShift notification — tap it to open the app. '
                          'You can show the icon again from Settings.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Hide'),
                          ),
                        ],
                      ),
                    ) ??
                    false;
                if (!ok) return;
              }
              setState(() => _hideIcon = v);
              await _prefs.setHideIcon(v);
              await WallpaperChannel.setLauncherIconVisible(!v);
              if (v) await WallpaperChannel.showKeepAliveNotification();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(v
                      ? 'Icon hidden — use the notification to reopen'
                      : 'Icon visible again'),
                  backgroundColor: AppColors.surfaceHigh,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'WallShift v1.2 — glass widget + shortcuts. Photos stay on device.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
