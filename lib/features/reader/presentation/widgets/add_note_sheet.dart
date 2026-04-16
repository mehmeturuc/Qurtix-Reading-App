import 'package:flutter/material.dart';

import '../../../../shared/design/app_design.dart';
import '../../domain/annotation_color.dart';
import '../annotation_display_text.dart';

class AnnotationDraft {
  const AnnotationDraft({
    required this.colorId,
    required this.isFavorite,
    this.noteText = '',
  });

  final String noteText;
  final String colorId;
  final bool isFavorite;
}

class AddNoteSheet extends StatefulWidget {
  const AddNoteSheet({
    required this.selectedText,
    required this.onSave,
    this.includeNoteField = true,
    this.title = 'Add note',
    this.saveLabel = 'Save note',
    super.key,
  });

  final String selectedText;
  final ValueChanged<AnnotationDraft> onSave;
  final bool includeNoteField;
  final String title;
  final String saveLabel;

  @override
  State<AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends State<AddNoteSheet> {
  final TextEditingController _controller = TextEditingController();
  String _colorId = annotationColors.first.id;
  bool _isFavorite = false;

  bool get _canSave {
    return !widget.includeNoteField || _controller.text.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleTextChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final keyboardInset = mediaQuery.viewInsets.bottom;
    final availableHeight =
        mediaQuery.size.height - mediaQuery.padding.top - keyboardInset;
    final maxSheetHeight = (availableHeight * 0.86)
        .clamp(180.0, 640.0)
        .toDouble();
    final previewText = pdfAnnotationTextForDisplay(widget.selectedText);

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxSheetHeight),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x5,
              AppSpacing.x2,
              AppSpacing.x5,
              AppSpacing.x5,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
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
                const SizedBox(height: AppSpacing.x2),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest.withValues(
                      alpha: 0.62,
                    ),
                    borderRadius: AppCorners.lg,
                    border: Border.all(color: AppBorders.subtle(colors).color),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.x3),
                    child: Text(
                      previewText,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      textDirection: annotationTextDirection(previewText),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.42,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.x5),
                Text(
                  'Highlight color',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.x3),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Wrap(
                      spacing: AppSpacing.x2,
                      runSpacing: AppSpacing.x2,
                      children: [
                        for (final item in annotationColors)
                          SizedBox(
                            width: constraints.maxWidth >= 420
                                ? (constraints.maxWidth - AppSpacing.x4) / 3
                                : null,
                            child: _ColorChoice(
                              label: item.label,
                              color: item.color,
                              selected: _colorId == item.id,
                              onTap: () => setState(() => _colorId = item.id),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.x4),
                Material(
                  color: colors.surface,
                  borderRadius: AppCorners.lg,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => setState(() => _isFavorite = !_isFavorite),
                    child: Ink(
                      decoration: BoxDecoration(
                        borderRadius: AppCorners.lg,
                        border: Border.all(
                          color: AppBorders.subtle(colors).color,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.x4,
                          vertical: AppSpacing.x3,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isFavorite
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: _isFavorite
                                  ? colors.primary
                                  : colors.onSurfaceVariant,
                            ),
                            const SizedBox(width: AppSpacing.x3),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Add to favorites',
                                    style:
                                        theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.x1),
                                  Text(
                                    'Keep this easy to find later.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: _isFavorite,
                              onChanged: (value) {
                                setState(() => _isFavorite = value);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.includeNoteField) ...[
                  const SizedBox(height: AppSpacing.x4),
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    maxLines: 4,
                    minLines: 3,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: 'Write a note...',
                      border: OutlineInputBorder(
                        borderRadius: AppCorners.lg,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppCorners.lg,
                        borderSide: AppBorders.subtle(colors),
                      ),
                      contentPadding: const EdgeInsets.all(AppSpacing.x3),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.x5),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x3),
                    Expanded(
                      child: FilledButton(
                        onPressed: _canSave ? _save : null,
                        child: Text(widget.saveLabel),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleTextChanged() {
    setState(() {});
  }

  void _save() {
    widget.onSave(
      AnnotationDraft(
        noteText: _controller.text.trim(),
        colorId: _colorId,
        isFavorite: _isFavorite,
      ),
    );
    Navigator.of(context).pop();
  }

}

class _ColorChoice extends StatelessWidget {
  const _ColorChoice({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: AppCorners.md,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x3,
          vertical: AppSpacing.x3,
        ),
        decoration: BoxDecoration(
          color: selected
              ? colors.primaryContainer.withValues(alpha: 0.7)
              : colors.surface,
          borderRadius: AppCorners.md,
          border: Border.all(
            color: selected ? colors.primary : AppBorders.subtle(colors).color,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.onSurface.withValues(alpha: 0.12),
                ),
              ),
              child: SizedBox.square(
                dimension: 18,
                child: selected
                    ? Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: colors.onPrimary,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: AppSpacing.x2),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color:
                      selected ? colors.onPrimaryContainer : colors.onSurface,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
