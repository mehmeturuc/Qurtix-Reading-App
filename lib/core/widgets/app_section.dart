import 'package:flutter/material.dart';

import '../design/app_design.dart';

class AppSection extends StatelessWidget {
  const AppSection({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.x5),
    this.backgroundColor,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor ?? colors.surfaceContainerLow,
        borderRadius: AppCorners.lg,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
