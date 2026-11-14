import 'package:flutter/material.dart';

class AppTheme {
  static const Color chinh = Color(0xFF2E2A7A);
  static const Color cam = Color(0xFFFFA000);
  static const Color nen = Color(0xFFEEF0F6);
  static const Color toi = Color(0xFF1B1B3A);

  static ButtonStyle get nutCam => FilledButton.styleFrom(
        backgroundColor: cam,
        foregroundColor: Colors.black87,
      );

  static ThemeData theme() {
    final scheme = ColorScheme.fromSeed(seedColor: chinh)
        .copyWith(primary: chinh, secondary: cam);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: nen,
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: toi,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: cam.withValues(alpha: 0.25),
      ),
    );
  }
}