import 'package:flutter/material.dart';

import '../design/app_design.dart';

class AppPill extends StatelessWidget {
  const AppPill({
    required this.child,
    this.backgroundColor,
    this.foregroundColor,
    super.key,
  });

  final Widget child;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DefaultTextStyle.merge(
      style: TextStyle(
        color: foregroundColor ?? colors.onSurface,
        fontWeight: FontWeight.w800,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor ?? colors.surfaceContainerLow,
          borderRadius: AppCorners.pill,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x3,
            vertical: AppSpacing.x1,
          ),
          child: child,
        ),
      ),
    );
  }
}
