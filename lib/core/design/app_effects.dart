import 'package:flutter/material.dart';

class AppBorders {
  const AppBorders._();

  static BorderSide ghost(ColorScheme colors) {
    return BorderSide(color: colors.outlineVariant.withValues(alpha: 0.15));
  }

  static BorderSide subtle(ColorScheme colors) => ghost(colors);
}

class AppEffects {
  const AppEffects._();

  static List<BoxShadow> ambient(ColorScheme colors) {
    return [
      BoxShadow(
        color: colors.onSurface.withValues(alpha: 0.04),
        blurRadius: 32,
        offset: const Offset(0, 12),
      ),
    ];
  }
}
