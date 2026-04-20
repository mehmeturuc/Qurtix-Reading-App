import 'package:flutter/material.dart';

class AppRadius {
  const AppRadius._();

  static const double sm = 8;
  static const double md = 24;
  static const double lg = 28;
  static const double xl = 32;
  static const double pill = 999;
}

class AppCorners {
  const AppCorners._();

  static BorderRadius get sm => BorderRadius.circular(AppRadius.sm);
  static BorderRadius get md => BorderRadius.circular(AppRadius.md);
  static BorderRadius get lg => BorderRadius.circular(AppRadius.lg);
  static BorderRadius get xl => BorderRadius.circular(AppRadius.xl);
  static BorderRadius get pill => BorderRadius.circular(AppRadius.pill);
}
