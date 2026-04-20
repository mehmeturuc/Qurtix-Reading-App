import 'package:flutter/material.dart';

import '../design/app_design.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.x4),
    this.backgroundColor,
    this.borderRadius,
    this.clipBehavior = Clip.antiAlias,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final radius = borderRadius ?? AppCorners.md;

    return Material(
      color: backgroundColor ?? colors.surfaceContainerLowest,
      borderRadius: radius,
      clipBehavior: clipBehavior,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.fromBorderSide(AppBorders.ghost(colors)),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
