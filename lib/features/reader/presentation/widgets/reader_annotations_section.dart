import 'package:flutter/material.dart';

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
  final ValueChanged<String> onDelete;

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
                'Annotations',
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
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNote = annotation.type == ReaderAnnotationType.note;
    final markerColor = annotationColorById(annotation.colorId);

    return Material(
      color: Colors.transparent,
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
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: markerColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const SizedBox(width: 8, height: 48),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isNote ? 'Note' : 'Highlight',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: mutedColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (annotation.isFavorite) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: mutedColor,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        annotation.selectedText,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: textColor,
                          height: 1.35,
                        ),
                      ),
                      if (isNote && annotation.noteText.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          annotation.noteText,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => onDelete(annotation.id),
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: mutedColor,
                  tooltip: 'Delete annotation',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
