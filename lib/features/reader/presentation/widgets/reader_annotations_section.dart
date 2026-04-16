import 'package:flutter/material.dart';

import '../annotation_display_text.dart';
import '../../domain/annotation_color.dart';
import '../../domain/reader_annotation.dart';

class ReaderAnnotationsSection extends StatelessWidget {
  const ReaderAnnotationsSection({
    required this.annotations,
    required this.textColor,
    required this.mutedColor,
    required this.surfaceColor,
    required this.borderColor,
    required this.maxWidth,
    required this.onTap,
    required this.onDelete,
    super.key,
  });

  final List<ReaderAnnotation> annotations;
  final Color textColor;
  final Color mutedColor;
  final Color surfaceColor;
  final Color borderColor;
  final double maxWidth;
  final ValueChanged<ReaderAnnotation> onTap;
  final ValueChanged<ReaderAnnotation> onDelete;

  @override
  Widget build(BuildContext context) {
    if (annotations.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Annotations and bookmarks',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              for (final annotation in annotations)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AnnotationCard(
                    annotation: annotation,
                    textColor: textColor,
                    mutedColor: mutedColor,
                    surfaceColor: surfaceColor,
                    borderColor: borderColor,
                    onTap: onTap,
                    onDelete: onDelete,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnnotationCard extends StatelessWidget {
  const _AnnotationCard({
    required this.annotation,
    required this.textColor,
    required this.mutedColor,
    required this.surfaceColor,
    required this.borderColor,
    required this.onTap,
    required this.onDelete,
  });

  final ReaderAnnotation annotation;
  final Color textColor;
  final Color mutedColor;
  final Color surfaceColor;
  final Color borderColor;
  final ValueChanged<ReaderAnnotation> onTap;
  final ValueChanged<ReaderAnnotation> onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final markerColor = annotationColorById(annotation.colorId);
    final selectedText = annotationSelectedTextForDisplay(annotation);
    final noteText = plainAnnotationTextForDisplay(annotation.noteText);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onTap(annotation),
        borderRadius: BorderRadius.circular(8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: markerColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const SizedBox(width: 8, height: 32),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            annotation.displayTypeLabel,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: mutedColor,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          if (annotation.isFavorite)
                            Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: mutedColor,
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => onDelete(annotation),
                      icon: const Icon(Icons.delete_outline_rounded),
                      color: mutedColor,
                      tooltip:
                          'Delete ${annotation.displayTypeLabel.toLowerCase()}',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    selectedText,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    textDirection: annotationTextDirection(selectedText),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: textColor,
                      height: 1.42,
                    ),
                  ),
                ),
                if (noteText.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      noteText,
                      textDirection: annotationTextDirection(noteText),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                        height: 1.38,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
