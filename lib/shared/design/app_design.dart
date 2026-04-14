import 'package:flutter/material.dart';

class AppSpacing {
  const AppSpacing._();

  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
}

class AppRadius {
  const AppRadius._();

  static const double sm = 8;
  static const double md = 10;
  static const double lg = 12;
  static const double xl = 16;
}

class AppCorners {
  const AppCorners._();

  static BorderRadius get sm => BorderRadius.circular(AppRadius.sm);
  static BorderRadius get md => BorderRadius.circular(AppRadius.md);
  static BorderRadius get lg => BorderRadius.circular(AppRadius.lg);
  static BorderRadius get xl => BorderRadius.circular(AppRadius.xl);
}

class AppBorders {
  const AppBorders._();

  static BorderSide subtle(ColorScheme colors) {
    return BorderSide(color: colors.outlineVariant.withValues(alpha: 0.72));
  }
}

class AppSegmentedOption<T> {
  const AppSegmentedOption({
    required this.value,
    required this.label,
  });

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
