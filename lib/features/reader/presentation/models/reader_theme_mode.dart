import 'package:flutter/material.dart';

enum ReaderThemeMode { light, dark, sepia }

extension ReaderThemeModeX on ReaderThemeMode {
  String get label {
    return switch (this) {
      ReaderThemeMode.light => 'Light',
      ReaderThemeMode.dark => 'Dark',
      ReaderThemeMode.sepia => 'Sepia',
    };
  }

  Color get backgroundColor {
    return switch (this) {
      ReaderThemeMode.light => const Color(0xFFFAFAF7),
      ReaderThemeMode.dark => const Color(0xFF111412),
      ReaderThemeMode.sepia => const Color(0xFFF3E7D0),
    };
  }

  Color get textColor {
    return switch (this) {
      ReaderThemeMode.light => const Color(0xFF20231F),
      ReaderThemeMode.dark => const Color(0xFFE4E7E1),
      ReaderThemeMode.sepia => const Color(0xFF35291D),
    };
  }

  Color get mutedColor {
    return switch (this) {
      ReaderThemeMode.light => const Color(0xFF686D64),
      ReaderThemeMode.dark => const Color(0xFFABB2A8),
      ReaderThemeMode.sepia => const Color(0xFF776149),
    };
  }

  Brightness get brightness {
    return this == ReaderThemeMode.dark ? Brightness.dark : Brightness.light;
  }
}
