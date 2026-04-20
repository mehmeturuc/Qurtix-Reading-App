import 'package:flutter/material.dart';

import '../../core/design/app_design.dart';

export '../../core/design/app_design.dart';
export '../../core/widgets/app_card.dart';
export '../../core/widgets/app_chip.dart';
export '../../core/widgets/app_glass_container.dart';
export '../../core/widgets/app_pill.dart';
export '../../core/widgets/app_secondary_button.dart';
export '../../core/widgets/app_section.dart';

class AppSegmentedOption<T> {
  const AppSegmentedOption({required this.value, required this.label});

  final T value;
  final String label;
}

class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    required this.options,
    required this.value,
    required this.onChanged,
    this.height = 42,
    super.key,
  });

  final List<AppSegmentedOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      height: height,
      padding: const EdgeInsets.all(AppSpacing.x1),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.58),
        borderRadius: AppCorners.lg,
        border: Border.all(color: AppBorders.subtle(colors).color),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: _Segment<T>(
                  option: option,
                  selected: option.value == value,
                  onTap: () => onChanged(option.value),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final AppSegmentedOption<T> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      borderRadius: AppCorners.md,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x2),
          decoration: BoxDecoration(
            color: selected ? colors.surface : Colors.transparent,
            borderRadius: AppCorners.md,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            option.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              color: selected ? colors.onSurface : colors.onSurfaceVariant,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
