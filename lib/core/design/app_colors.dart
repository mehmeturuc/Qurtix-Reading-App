import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color surface = Color(0xFFF9F9F7);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF4F4F2);
  static const Color surfaceContainer = Color(0xFFECEDEA);
  static const Color surfaceVariant = Color(0xFFE5E7E2);

  static const Color onSurface = Color(0xFF1A1C1B);
  static const Color onSurfaceVariant = Color(0xFF5D625F);
  static const Color outlineVariant = Color(0xFFCDD2CC);

  static const Color primary = Color(0xFF455565);
  static const Color primaryContainer = Color(0xFF5D6D7E);
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color secondary = Color(0xFF36684E);
  static const Color secondaryContainer = Color(0xFFB8EFCE);
  static const Color onSecondaryContainer = Color(0xFF153824);

  static const Color error = Color(0xFFBA1A1A);

  static ColorScheme get lightScheme {
    return ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: primary,
      primaryContainer: primaryContainer,
      onPrimary: onPrimary,
      secondary: secondary,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onSecondaryContainer,
      error: error,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      outlineVariant: outlineVariant,
      surfaceContainerLowest: surfaceContainerLowest,
      surfaceContainerLow: surfaceContainerLow,
      surfaceContainer: surfaceContainer,
      surfaceContainerHighest: surfaceVariant,
      shadow: onSurface,
    );
  }

  static ColorScheme get darkScheme {
    return ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFFC4D4E5),
      primaryContainer: const Color(0xFF394858),
      secondary: const Color(0xFF9EDDBA),
      secondaryContainer: const Color(0xFF224A35),
      surface: const Color(0xFF111412),
      onSurface: const Color(0xFFE4E7E2),
      onSurfaceVariant: const Color(0xFFC4C9C3),
      outlineVariant: const Color(0xFF424842),
      surfaceContainerLowest: const Color(0xFF191C1A),
      surfaceContainerLow: const Color(0xFF1F2421),
      surfaceContainer: const Color(0xFF262B28),
      surfaceContainerHighest: const Color(0xFF333936),
      shadow: const Color(0xFFE4E7E2),
    );
  }
}
