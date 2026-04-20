import 'dart:ui';

import 'package:flutter/material.dart';

import '../design/app_design.dart';

class AppGlassContainer extends StatelessWidget {
  const AppGlassContainer({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.x4),
    this.borderRadius,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final radius = borderRadius ?? AppCorners.md;

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.7),
            borderRadius: radius,
            border: Border.fromBorderSide(AppBorders.ghost(colors)),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
