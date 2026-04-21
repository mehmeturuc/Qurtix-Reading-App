import 'package:flutter/material.dart';

import '../../../../core/design/app_design.dart';
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
    this.showTitle = true,
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
  final bool showTitle;

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
              if (showTitle) ...[
                Text(
                  'Annotations and bookmarks',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
              ],
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
    final locationLabel = _annotationLocationLabel(annotation);

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
                              fontFamily: AppTypography.sans,
                            ),
                          ),
                          if (locationLabel != null)
                            Text(
                              locationLabel,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: mutedColor.withValues(alpha: 0.78),
                                fontWeight: FontWeight.w600,
                                height: 1.1,
                                fontFamily: AppTypography.sans,
                                letterSpacing: 0,
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

  String? _annotationLocationLabel(ReaderAnnotation annotation) {
    final pdfPage = annotation.pdfPageNumber;
    if (pdfPage != null) return 'Page $pdfPage';

    final progress = annotation.epubProgress;
    if (progress != null) {
      final percent = (progress.clamp(0.0, 1.0) * 100).round();
      final chapter = annotation.epubChapterIndex;
      if (chapter != null) return 'Chapter ${chapter + 1} - $percent%';

      return 'Progress $percent%';
    }

    final chapter = annotation.epubChapterIndex;
    if (chapter != null) return 'Chapter ${chapter + 1}';

    final textStart = annotation.locationStartIndex;
    if (textStart != null) return 'Location ${_compactNumber(textStart + 1)}';

    if (annotation.isPdfLocation) return 'PDF';
    if (annotation.isEpubLocation) return 'EPUB';

    return null;
  }

  String _compactNumber(int value) {
    final text = value.toString();
    final buffer = StringBuffer();

    for (var index = 0; index < text.length; index++) {
      if (index > 0 && (text.length - index) % 3 == 0) buffer.write(',');
      buffer.write(text[index]);
    }

    return buffer.toString();
  }
}
