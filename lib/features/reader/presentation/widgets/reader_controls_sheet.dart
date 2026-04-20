import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/design/app_design.dart';
import '../models/reader_theme_mode.dart';

class ReaderControlsSheet extends StatefulWidget {
  const ReaderControlsSheet({
    required this.fontSize,
    required this.lineHeight,
    required this.themeMode,
    required this.isWideText,
    required this.onFontSizeChanged,
    required this.onLineHeightChanged,
    required this.onThemeModeChanged,
    required this.onTextWidthChanged,
    this.supportsTypography = true,
    this.supportsTextWidth = true,
    super.key,
  });

  final double fontSize;
  final double lineHeight;
  final ReaderThemeMode themeMode;
  final bool isWideText;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<double> onLineHeightChanged;
  final ValueChanged<ReaderThemeMode> onThemeModeChanged;
  final ValueChanged<bool> onTextWidthChanged;
  final bool supportsTypography;
  final bool supportsTextWidth;

  @override
  State<ReaderControlsSheet> createState() => _ReaderControlsSheetState();
}

class _ReaderControlsSheetState extends State<ReaderControlsSheet> {
  late double _fontSize = widget.fontSize;
  late double _lineHeight = widget.lineHeight;
  late ReaderThemeMode _themeMode = widget.themeMode;
  late bool _isWideText = widget.isWideText;

  bool get _hasDocumentLayout => !widget.supportsTypography;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = widget.themeMode.brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
            bottom: Radius.circular(AppRadius.md),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: isDark ? 0.82 : 0.90),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg),
                  bottom: Radius.circular(AppRadius.md),
                ),
                border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: 0.14),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.onSurface.withValues(alpha: 0.026),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Reading settings',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'Close',
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    Text(
                      _hasDocumentLayout
                          ? 'Theme stays available while the PDF keeps its original layout.'
                          : 'Tune the page until the words settle comfortably.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant.withValues(alpha: 0.78),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (_hasDocumentLayout)
                      _DocumentLayoutNotice(theme: theme)
                    else ...[
                      _ControlSlider(
                        label: 'Font size',
                        value: _fontSize,
                        min: 15,
                        max: 24,
                        divisions: 9,
                        displayValue: _fontSize.round().toString(),
                        onChanged: (value) {
                          setState(() => _fontSize = value);
                          widget.onFontSizeChanged(value);
                        },
                      ),
                      _ControlSlider(
                        label: 'Line height',
                        value: _lineHeight,
                        min: 1.35,
                        max: 1.9,
                        divisions: 11,
                        displayValue: _lineHeight.toStringAsFixed(2),
                        onChanged: (value) {
                          setState(() => _lineHeight = value);
                          widget.onLineHeightChanged(value);
                        },
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text('Theme', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ReaderThemeMode>(
                        segments: ReaderThemeMode.values
                            .map(
                              (mode) => ButtonSegment(
                                value: mode,
                                label: Text(mode.label),
                              ),
                            )
                            .toList(),
                        selected: {_themeMode},
                        style: ButtonStyle(
                          side: WidgetStatePropertyAll(
                            AppBorders.ghost(colors),
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        onSelectionChanged: (selected) {
                          final mode = selected.first;
                          setState(() => _themeMode = mode);
                          widget.onThemeModeChanged(mode);
                        },
                      ),
                    ),
                    if (widget.supportsTextWidth) ...[
                      const SizedBox(height: 10),
                      Material(
                        color: colors.onSurface.withValues(alpha: 0.026),
                        borderRadius: AppCorners.sm,
                        clipBehavior: Clip.antiAlias,
                        child: SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 0,
                          ),
                          title: const Text('Wider text column'),
                          subtitle: Text(
                            'Give long lines more room on wider screens.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant.withValues(
                                alpha: 0.78,
                              ),
                            ),
                          ),
                          value: _isWideText,
                          onChanged: (value) {
                            setState(() => _isWideText = value);
                            widget.onTextWidthChanged(value);
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DocumentLayoutNotice extends StatelessWidget {
  const _DocumentLayoutNotice({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.52),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.picture_as_pdf_outlined,
                size: 18,
                color: colors.onSurfaceVariant.withValues(alpha: 0.72),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'PDF typography comes from the document. Theme and page controls remain available.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant.withValues(alpha: 0.78),
                    height: 1.32,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlSlider extends StatelessWidget {
  const _ControlSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.displayValue,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String displayValue;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: theme.textTheme.labelLarge),
              const Spacer(),
              Text(displayValue, style: theme.textTheme.labelMedium),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
