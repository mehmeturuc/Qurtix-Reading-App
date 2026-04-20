import 'package:flutter/material.dart';

import '../design/app_design.dart';

class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ChoiceChip(
      selected: selected,
      showCheckmark: false,
      label: Text(label),
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        color: selected ? colors.onSecondaryContainer : colors.onSurfaceVariant,
        fontWeight: FontWeight.w800,
      ),
      backgroundColor: colors.surfaceContainerLowest,
      selectedColor: colors.secondaryContainer,
      side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.15)),
      shape: RoundedRectangleBorder(borderRadius: AppCorners.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x3,
        vertical: AppSpacing.x2,
      ),
      onSelected: onSelected,
    );
  }
}
