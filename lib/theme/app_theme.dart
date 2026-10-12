import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppThemeId { ember, glass, light, amoled }

class ThemePalette {
  final Color bg;
  final Color surface;
  final Color surfaceHigh;
  final Color accent;
  final Color accentDim;
  final Color textPrimary;
  final Color textMuted;
  final Color divider;
  final Color danger;
  final bool glass;
  final Brightness brightness;

  const ThemePalette({
    required this.bg,
    required this.surface,
    required this.surfaceHigh,
    required this.accent,
    required this.accentDim,
    required this.textPrimary,
    required this.textMuted,
    required this.divider,
    required this.danger,
    this.glass = false,
    this.brightness = Brightness.dark,
  });
}

class AppThemes {
  static const ember = ThemePalette(
    bg: Color(0xFF121014),
    surface: Color(0xFF1B181E),
    surfaceHigh: Color(0xFF242028),
    accent: Color(0xFFFF6B4A),
    accentDim: Color(0xFF7A3D2E),
    textPrimary: Color(0xFFF3EFEE),
    textMuted: Color(0xFF938C93),
    divider: Color(0xFF2C2731),
    danger: Color(0xFFE0574A),
  );

  static const glass = ThemePalette(
    bg: Color(0xFF0A0C12),
    surface: Color(0x99141822),
    surfaceHigh: Color(0xB01C2230),
    accent: Color(0xFF5AC8FA),
    accentDim: Color(0xFF2A5A78),
    textPrimary: Color(0xFFF5F7FA),
    textMuted: Color(0xFF9AA3B2),
    divider: Color(0x33FFFFFF),
    danger: Color(0xFFFF6B6B),
    glass: true,
  );

  static const light = ThemePalette(
    bg: Color(0xFFF4F2F0),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFECE8E4),
    accent: Color(0xFFE85D3B),
    accentDim: Color(0xFFFFD4C8),
    textPrimary: Color(0xFF1A1614),
    textMuted: Color(0xFF6B6560),
    divider: Color(0xFFE0DAD4),
    danger: Color(0xFFD1433A),
    brightness: Brightness.light,
  );

  static const amoled = ThemePalette(
    bg: Color(0xFF000000),
    surface: Color(0xFF0A0A0A),
    surfaceHigh: Color(0xFF161616),
    accent: Color(0xFFFF6B4A),
    accentDim: Color(0xFF4A2018),
    textPrimary: Color(0xFFF0F0F0),
    textMuted: Color(0xFF888888),
    divider: Color(0xFF222222),
    danger: Color(0xFFFF5555),
  );

  static ThemePalette of(AppThemeId id) {
    switch (id) {
      case AppThemeId.glass:
        return glass;
      case AppThemeId.light:
        return light;
      case AppThemeId.amoled:
        return amoled;
      case AppThemeId.ember:
        return ember;
    }
  }

  static String label(AppThemeId id) {
    switch (id) {
      case AppThemeId.ember:
        return 'Ember';
      case AppThemeId.glass:
        return 'Glass';
      case AppThemeId.light:
        return 'Light';
      case AppThemeId.amoled:
        return 'AMOLED';
    }
  }

  static ThemeData build(AppThemeId id) {
    final p = of(id);
    final base = p.brightness == Brightness.dark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);
    final headingFont = GoogleFonts.sora();
    final bodyFont = GoogleFonts.inter();

    return base.copyWith(
      scaffoldBackgroundColor: p.bg,
      colorScheme: base.colorScheme.copyWith(
        surface: p.bg,
        primary: p.accent,
        secondary: p.accentDim,
        error: p.danger,
        brightness: p.brightness,
      ),
      textTheme: base.textTheme
          .apply(bodyColor: p.textPrimary, displayColor: p.textPrimary)
          .copyWith(
            headlineMedium: headingFont.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
              color: p.textPrimary,
            ),
            titleLarge: headingFont.copyWith(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              color: p.textPrimary,
            ),
            bodyMedium: bodyFont.copyWith(
              fontSize: 14.5,
              color: p.textMuted,
              height: 1.4,
            ),
            labelLarge: bodyFont.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.glass ? Colors.transparent : p.bg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: headingFont.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: p.textPrimary,
        ),
        iconTheme: IconThemeData(color: p.textPrimary),
      ),
      iconTheme: IconThemeData(color: p.textPrimary),
      dividerColor: p.divider,
      cardColor: p.surface,
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.accent : p.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.accentDim : p.surfaceHigh,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.accent,
        foregroundColor:
            p.brightness == Brightness.light ? Colors.white : Colors.black,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor:
              p.brightness == Brightness.light ? Colors.white : Colors.black,
          textStyle: bodyFont.copyWith(fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.textPrimary,
          side: BorderSide(color: p.divider),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.surface,
        selectedItemColor: p.accent,
        unselectedItemColor: p.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.surfaceHigh,
        contentTextStyle: bodyFont.copyWith(color: p.textPrimary),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class AppColors {
  static ThemePalette current = AppThemes.ember;

  static Color get bg => current.bg;
  static Color get surface => current.surface;
  static Color get surfaceHigh => current.surfaceHigh;
  static Color get accent => current.accent;
  static Color get accentDim => current.accentDim;
  static Color get textPrimary => current.textPrimary;
  static Color get textMuted => current.textMuted;
  static Color get divider => current.divider;
  static Color get danger => current.danger;
  static bool get glass => current.glass;
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppColors.current;
    final body = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: p.glass ? p.divider : p.divider.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: p.glass
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (!p.glass) {
      return Container(margin: margin, child: body);
    }

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: body,
        ),
      ),
    );
  }
}
