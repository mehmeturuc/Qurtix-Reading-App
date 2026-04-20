import 'package:flutter/material.dart';

import '../design/app_design.dart';

class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    required this.onPressed,
    required this.child,
    super.key,
  });

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: colors.secondary,
        shape: RoundedRectangleBorder(borderRadius: AppCorners.pill),
      ),
      child: child,
    );
  }
}
