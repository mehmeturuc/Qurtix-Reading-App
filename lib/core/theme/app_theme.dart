import 'package:flutter/material.dart';

import '../design/app_design.dart';

class AppTheme {
  static final _cardShape = RoundedRectangleBorder(borderRadius: AppCorners.md);
  static final _sheetShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
  );

  static ThemeData get light {
    final colors = AppColors.lightScheme;
    final textTheme = AppTypography.textTheme(colors);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: _cardShape,
        color: colors.surfaceContainerLowest,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surfaceContainerLowest,
        modalBackgroundColor: colors.surfaceContainerLowest,
        shape: _sheetShape,
        clipBehavior: Clip.antiAlias,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceContainerLowest,
        selectedColor: colors.secondaryContainer,
        disabledColor: colors.surfaceContainer,
        labelStyle: textTheme.labelMedium?.copyWith(
          color: colors.onSurfaceVariant,
        ),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: colors.onSecondaryContainer,
          fontWeight: FontWeight.w800,
        ),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.15)),
        shape: RoundedRectangleBorder(borderRadius: AppCorners.md),
        showCheckmark: false,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: AppCorners.md),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: AppCorners.pill),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x5,
            vertical: AppSpacing.x3,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.secondary,
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: AppCorners.pill),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: AppCorners.md,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppCorners.md,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppCorners.md,
          borderSide: AppBorders.ghost(colors),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface.withValues(alpha: 0.94),
        indicatorColor: colors.secondaryContainer,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colors.onSecondaryContainer
                : colors.onSurfaceVariant,
          );
        }),
      ),
    );
  }

  static ThemeData get dark {
    final colors = AppColors.darkScheme;
    final textTheme = AppTypography.textTheme(colors);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: _cardShape,
        color: colors.surfaceContainerLowest,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surfaceContainerLowest,
        modalBackgroundColor: colors.surfaceContainerLowest,
        shape: _sheetShape,
        clipBehavior: Clip.antiAlias,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceContainerLowest,
        selectedColor: colors.secondaryContainer,
        disabledColor: colors.surfaceContainer,
        labelStyle: textTheme.labelMedium?.copyWith(
          color: colors.onSurfaceVariant,
        ),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: colors.onSecondaryContainer,
          fontWeight: FontWeight.w800,
        ),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.15)),
        shape: RoundedRectangleBorder(borderRadius: AppCorners.md),
        showCheckmark: false,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: AppCorners.md),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: AppCorners.pill),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x5,
            vertical: AppSpacing.x3,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.secondary,
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: AppCorners.pill),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: AppCorners.md,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppCorners.md,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppCorners.md,
          borderSide: AppBorders.ghost(colors),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface.withValues(alpha: 0.94),
        indicatorColor: colors.secondaryContainer,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colors.onSecondaryContainer
                : colors.onSurfaceVariant,
          );
        }),
      ),
    );
  }
}
