import 'package:flutter/material.dart';

class AppTypography {
  const AppTypography._();

  static const String serif = 'Noto Serif';
  static const String sans = 'Inter';

  static TextTheme textTheme(ColorScheme colors) {
    final base = Typography.material2021(platform: TargetPlatform.android).black
        .apply(
          bodyColor: colors.onSurface,
          displayColor: colors.onSurface,
          fontFamily: sans,
        );

    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontFamily: serif,
        fontSize: 48,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.05,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontFamily: serif,
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.1,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontFamily: serif,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.16,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontFamily: serif,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.16,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontFamily: serif,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.22,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontFamily: serif,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.24,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontFamily: serif,
        fontSize: 16,
        letterSpacing: 0,
        height: 1.6,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontFamily: sans,
        fontSize: 14,
        letterSpacing: 0,
        height: 1.5,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontFamily: sans,
        fontSize: 12,
        letterSpacing: 0,
        height: 1.45,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontFamily: sans,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.15,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontFamily: sans,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.15,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontFamily: sans,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.15,
      ),
    );
  }
}
