import 'package:flutter/material.dart';

import '../../../../core/design/app_design.dart';
import '../../domain/annotation_color.dart';
import '../../domain/reader_annotation.dart';

class ReaderSelection {
  const ReaderSelection({
    required this.text,
    required this.startIndex,
    required this.endIndex,
    this.locationRef,
  });

  final String text;
  final int startIndex;
  final int endIndex;
  final String? locationRef;
}

class ReaderContent extends StatefulWidget {
  const ReaderContent({
    required this.text,
    required this.annotations,
    required this.textColor,
    required this.fontSize,
    required this.lineHeight,
    required this.maxWidth,
    required this.onSelectionChanged,
    this.focusedAnnotationId,
    this.indexOffset = 0,
    this.annotationStartOffset,
    this.annotationEndOffset,
    this.locationOffsetToRenderedOffset,
    this.renderedOffsetToLocationOffset,
    this.textScaler,
    this.selectionResetToken = 0,
    super.key,
  });

  final String text;
  final List<ReaderAnnotation> annotations;
  final Color textColor;
  final double fontSize;
  final double lineHeight;
  final double maxWidth;
  final ValueChanged<ReaderSelection?> onSelectionChanged;
  final String? focusedAnnotationId;
  final int indexOffset;
  final int? Function(ReaderAnnotation annotation)? annotationStartOffset;
  final int? Function(ReaderAnnotation annotation)? annotationEndOffset;
  final int? Function(int locationOffset)? locationOffsetToRenderedOffset;
  final int Function(int renderedOffset)? renderedOffsetToLocationOffset;
  final TextScaler? textScaler;
  final int selectionResetToken;

  @override
  State<ReaderContent> createState() => _ReaderContentState();
}

class _ReaderContentState extends State<ReaderContent> {
  late List<TextSpan> _spans;

  @override
  void initState() {
    super.initState();
    _spans = _buildTextSpans();
  }

  @override
  void didUpdateWidget(covariant ReaderContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.text != widget.text ||
        oldWidget.indexOffset != widget.indexOffset ||
        oldWidget.focusedAnnotationId != widget.focusedAnnotationId ||
        oldWidget.annotationStartOffset != widget.annotationStartOffset ||
        oldWidget.annotationEndOffset != widget.annotationEndOffset ||
        oldWidget.locationOffsetToRenderedOffset !=
            widget.locationOffsetToRenderedOffset ||
        oldWidget.textScaler != widget.textScaler ||
        oldWidget.selectionResetToken != widget.selectionResetToken ||
        !_sameAnnotations(oldWidget.annotations, widget.annotations)) {
      _spans = _buildTextSpans();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.maxWidth),
        child: DefaultSelectionStyle(
          selectionColor: annotationColorById('yellow').withValues(alpha: 0.28),
          cursorColor: widget.textColor.withValues(alpha: 0.72),
          child: SelectableText.rich(
            key: ValueKey(widget.selectionResetToken),
            TextSpan(children: _spans),
            onSelectionChanged: (selection, cause) {
              if (selection.isCollapsed) {
                widget.onSelectionChanged(null);
                return;
              }

              final range = _trimmedSelection(selection);
              if (range == null) {
                widget.onSelectionChanged(null);
                return;
              }

              widget.onSelectionChanged(range);
            },
            textAlign: TextAlign.start,
            textScaler: widget.textScaler,
            style: TextStyle(
              color: widget.textColor,
              fontFamily: AppTypography.serif,
              fontSize: widget.fontSize,
              fontWeight: FontWeight.w400,
              height: widget.lineHeight,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }

  List<TextSpan> _buildTextSpans() {
    final segments = _highlightSegments();
    if (segments.isEmpty) {
      return [TextSpan(text: widget.text)];
    }

    final spans = <TextSpan>[];
    var index = 0;

    for (final segment in segments) {
      if (index < segment.start) {
        spans.add(TextSpan(text: widget.text.substring(index, segment.start)));
      }

      spans.add(
        TextSpan(
          text: widget.text.substring(segment.start, segment.end),
          style: _highlightStyle(segment.annotation),
        ),
      );

      index = segment.end;
    }

    if (index < widget.text.length) {
      spans.add(TextSpan(text: widget.text.substring(index)));
    }

    return spans;
  }

  TextStyle _highlightStyle(ReaderAnnotation annotation) {
    final color = annotationColorById(annotation.colorId);
    final isFocused = annotation.id == widget.focusedAnnotationId;

    return TextStyle(
      backgroundColor: color.withValues(alpha: isFocused ? 0.48 : 0.26),
      decoration: isFocused ? TextDecoration.underline : TextDecoration.none,
      decorationColor: color,
      decorationThickness: 1.6,
    );
  }

  List<_HighlightSegment> _highlightSegments() {
    final ranges = _annotationRanges();
    if (ranges.isEmpty) return const [];

    final boundaries = <int>{0, widget.text.length};
    for (final range in ranges) {
      boundaries
        ..add(range.start)
        ..add(range.end);
    }

    final sortedBoundaries = boundaries.toList()..sort();
    final segments = <_HighlightSegment>[];
    var activeIndex = 0;

    for (var i = 0; i < sortedBoundaries.length - 1; i++) {
      final start = sortedBoundaries[i];
      final end = sortedBoundaries[i + 1];
      if (start >= end) continue;

      while (activeIndex < ranges.length && ranges[activeIndex].end <= start) {
        activeIndex++;
      }

      _AnnotationRange? activeRange;
      for (var j = activeIndex; j < ranges.length; j++) {
        final range = ranges[j];
        if (range.start > start) break;
        if (range.end >= end) activeRange = range;
      }

      if (activeRange == null) continue;

      final previous = segments.isEmpty ? null : segments.last;
      if (previous != null &&
          previous.end == start &&
          previous.annotation.id == activeRange.annotation.id) {
        segments[segments.length - 1] = previous.copyWith(end: end);
      } else {
        segments.add(
          _HighlightSegment(
            annotation: activeRange.annotation,
            start: start,
            end: end,
          ),
        );
      }
    }

    return segments;
  }

  List<_AnnotationRange> _annotationRanges() {
    final ranges = <_AnnotationRange>[];

    for (var i = 0; i < widget.annotations.length; i++) {
      final annotation = widget.annotations[i];
      if (!annotation.canHighlightText) continue;

      final range = _AnnotationRange.from(
        annotation,
        widget.text.length,
        widget.indexOffset,
        i,
        annotationStartOffset: widget.annotationStartOffset,
        annotationEndOffset: widget.annotationEndOffset,
        locationOffsetToRenderedOffset: widget.locationOffsetToRenderedOffset,
      );
      if (range != null) ranges.add(range);
    }

    ranges.sort((a, b) {
      final start = a.start.compareTo(b.start);
      if (start != 0) return start;

      final end = b.end.compareTo(a.end);
      if (end != 0) return end;

      return a.order.compareTo(b.order);
    });

    return ranges;
  }

  ReaderSelection? _trimmedSelection(TextSelection selection) {
    var start = selection.start < selection.end
        ? selection.start
        : selection.end;
    var end = selection.start < selection.end ? selection.end : selection.start;

    start = start.clamp(0, widget.text.length).toInt();
    end = end.clamp(0, widget.text.length).toInt();

    while (start < end && widget.text.codeUnitAt(start) <= 32) {
      start++;
    }

    while (end > start && widget.text.codeUnitAt(end - 1) <= 32) {
      end--;
    }

    if (start >= end) return null;

    final startIndex =
        widget.renderedOffsetToLocationOffset?.call(start) ??
        widget.indexOffset + start;
    final endIndex =
        widget.renderedOffsetToLocationOffset?.call(end) ??
        widget.indexOffset + end;

    return ReaderSelection(
      text: widget.text.substring(start, end),
      startIndex: startIndex,
      endIndex: endIndex,
    );
  }

  bool _sameAnnotations(
    List<ReaderAnnotation> previous,
    List<ReaderAnnotation> current,
  ) {
    if (identical(previous, current)) return true;
    if (previous.length != current.length) return false;

    for (var i = 0; i < previous.length; i++) {
      final oldAnnotation = previous[i];
      final newAnnotation = current[i];

      if (oldAnnotation.id != newAnnotation.id ||
          oldAnnotation.colorId != newAnnotation.colorId ||
          oldAnnotation.locationRef != newAnnotation.locationRef) {
        return false;
      }
    }

    return true;
  }
}

class _AnnotationRange {
  const _AnnotationRange({
    required this.annotation,
    required this.start,
    required this.end,
    required this.order,
  });

  final ReaderAnnotation annotation;
  final int start;
  final int end;
  final int order;

  static _AnnotationRange? from(
    ReaderAnnotation annotation,
    int textLength,
    int indexOffset,
    int order, {
    int? Function(ReaderAnnotation annotation)? annotationStartOffset,
    int? Function(ReaderAnnotation annotation)? annotationEndOffset,
    int? Function(int locationOffset)? locationOffsetToRenderedOffset,
  }) {
    final start =
        annotationStartOffset?.call(annotation) ??
        annotation.locationStartIndex;
    final end =
        annotationEndOffset?.call(annotation) ?? annotation.locationEndIndex;
    if (start == null || end == null) return null;

    final localStart =
        locationOffsetToRenderedOffset?.call(start) ?? start - indexOffset;
    final localEnd =
        locationOffsetToRenderedOffset?.call(end) ?? end - indexOffset;
    if (localEnd <= 0 || localStart >= textLength) return null;

    final clampedStart = localStart.clamp(0, textLength).toInt();
    final clampedEnd = localEnd.clamp(0, textLength).toInt();
    final safeStart = clampedStart < clampedEnd ? clampedStart : clampedEnd;
    final safeEnd = clampedStart < clampedEnd ? clampedEnd : clampedStart;
    if (safeStart >= safeEnd) return null;

    return _AnnotationRange(
      annotation: annotation,
      start: safeStart,
      end: safeEnd,
      order: order,
    );
  }
}

class _HighlightSegment {
  const _HighlightSegment({
    required this.annotation,
    required this.start,
    required this.end,
  });

  final ReaderAnnotation annotation;
  final int start;
  final int end;

  _HighlightSegment copyWith({int? end}) {
    return _HighlightSegment(
      annotation: annotation,
      start: start,
      end: end ?? this.end,
    );
  }
}
