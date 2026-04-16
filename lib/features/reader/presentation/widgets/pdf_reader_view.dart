import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../domain/annotation_color.dart';
import '../../domain/reader_annotation.dart';
import 'reader_content.dart';

class PdfReaderView extends StatelessWidget {
  const PdfReaderView({
    required this.filePath,
    required this.annotations,
    required this.backgroundColor,
    required this.onSelectionChanged,
    this.controller,
    this.initialPage,
    this.onPositionChanged,
    this.onSelectionFailure,
    super.key,
  });

  final String filePath;
  final List<ReaderAnnotation> annotations;
  final Color backgroundColor;
  final ValueChanged<ReaderSelection?> onSelectionChanged;
  final PdfReaderController? controller;
  final int? initialPage;
  final ValueChanged<PdfReaderPosition>? onPositionChanged;
  final ValueChanged<String>? onSelectionFailure;

  @override
  Widget build(BuildContext context) {
    final file = File(filePath);
    final surfaceColor = _pdfSurfaceColor;

    if (!file.existsSync()) {
      return const _DocumentError(message: 'This PDF file could not be found.');
    }

    return SfPdfViewerTheme(
      data: SfPdfViewerThemeData(backgroundColor: surfaceColor),
      child: ColoredBox(
        color: surfaceColor,
        child: _PdfSelectionReader(
          file: file,
          annotations: annotations,
          controller: controller,
          initialPage: initialPage,
          onPositionChanged: onPositionChanged,
          onSelectionChanged: onSelectionChanged,
          onSelectionFailure: onSelectionFailure,
        ),
      ),
    );
  }

  Color get _pdfSurfaceColor {
    if (backgroundColor.computeLuminance() < 0.18) {
      return const Color(0xFF191A18);
    }

    return const Color(0xFFF4F3EF);
  }
}

class PdfReaderController {
  _PdfSelectionReaderState? _state;

  int get currentPage => _state?._currentPage ?? 1;

  int get totalPages => _state?._totalPages ?? 0;

  void jumpToPage(int page) {
    _state?._jumpToPage(page);
  }

  void clearSelection() {
    _state?._clearSelection();
  }
}

class PdfReaderPosition {
  const PdfReaderPosition({
    required this.currentPage,
    required this.totalPages,
  });

  final int currentPage;
  final int totalPages;

  double get progress {
    if (totalPages <= 1) return totalPages == 1 ? 1 : 0;

    return ((currentPage - 1) / (totalPages - 1)).clamp(0.0, 1.0).toDouble();
  }

  String get label {
    if (totalPages <= 0) return 'Page $currentPage';

    return 'Page $currentPage of $totalPages';
  }
}

class _PdfSelectionReader extends StatefulWidget {
  const _PdfSelectionReader({
    required this.file,
    required this.annotations,
    required this.controller,
    required this.onSelectionChanged,
    required this.initialPage,
    required this.onPositionChanged,
    required this.onSelectionFailure,
  });

  final File file;
  final List<ReaderAnnotation> annotations;
  final PdfReaderController? controller;
  final ValueChanged<ReaderSelection?> onSelectionChanged;
  final int? initialPage;
  final ValueChanged<PdfReaderPosition>? onPositionChanged;
  final ValueChanged<String>? onSelectionFailure;

  @override
  State<_PdfSelectionReader> createState() => _PdfSelectionReaderState();
}

class _PdfSelectionReaderState extends State<_PdfSelectionReader> {
  static const int _annotationSyncBatchSize = 12;
  static const double _documentZoomLevel = 1;
  static const double _documentPageSpacing = 12;
  static const PdfPageLayoutMode _documentLayoutMode =
      PdfPageLayoutMode.single;
  static const PdfScrollDirection _documentScrollDirection =
      PdfScrollDirection.horizontal;

  late final PdfViewerController _controller = PdfViewerController();
  final GlobalKey<SfPdfViewerState> _viewerKey = GlobalKey<SfPdfViewerState>();
  final Map<String, Annotation> _visibleAnnotations = {};
  int _currentPage = 1;
  int _totalPages = 0;
  bool _didJumpToInitialPage = false;
  bool _documentLoaded = false;
  bool _didReportWeakSelection = false;
  bool _annotationSyncScheduled = false;
  int _annotationSyncGeneration = 0;

  @override
  void didUpdateWidget(covariant _PdfSelectionReader oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._state = null;
      widget.controller?._state = this;
    }

    if (oldWidget.file.path != widget.file.path) {
      for (final annotation in _visibleAnnotations.values) {
        _controller.removeAnnotation(annotation);
      }
      _currentPage = 1;
      _totalPages = 0;
      _didJumpToInitialPage = false;
      _documentLoaded = false;
      _didReportWeakSelection = false;
      _annotationSyncScheduled = false;
      _annotationSyncGeneration++;
      _visibleAnnotations.clear();
      widget.onSelectionChanged(null);
      return;
    }

    if (!_sameAnnotations(oldWidget.annotations, widget.annotations)) {
      _scheduleAnnotationSync();
    }

    if (oldWidget.initialPage != widget.initialPage) {
      _didJumpToInitialPage = false;
      _jumpToInitialPage();
    }
  }

  @override
  void dispose() {
    widget.controller?._state = null;
    _annotationSyncGeneration++;
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: SfPdfViewer.file(
            widget.file,
            key: _viewerKey,
            controller: _controller,
            canShowHyperlinkDialog: false,
            canShowPaginationDialog: false,
            canShowScrollHead: false,
            canShowScrollStatus: false,
            canShowSignaturePadDialog: false,
            canShowTextSelectionMenu: false,
            enableTextSelection: true,
            initialPageNumber: _initialPageNumber,
            initialZoomLevel: _documentZoomLevel,
            pageLayoutMode: _documentLayoutMode,
            pageSpacing: _documentPageSpacing,
            scrollDirection: _documentScrollDirection,
            onDocumentLoaded: (details) {
              setState(() {
                _totalPages = details.document.pages.count;
                _currentPage =
                    _controller.pageNumber.clamp(1, _safeTotalPages).toInt();
                _documentLoaded = true;
              });
              _notifyPositionChanged();
              _jumpToInitialPage();
              _scheduleAnnotationSync();
            },
            onPageChanged: (details) {
              setState(() => _currentPage = details.newPageNumber);
              _notifyPositionChanged();
            },
            onTextSelectionChanged: (details) {
              final selectedText = _normalizedSelectedText(details.selectedText);
              if (selectedText.isEmpty) {
                _didReportWeakSelection = false;
                widget.onSelectionChanged(null);
                return;
              }

              final pdfSelection = _usablePdfSelection();
              if (pdfSelection == null) {
                widget.onSelectionChanged(null);
                _reportWeakSelection();
                return;
              }

              _didReportWeakSelection = false;
              widget.onSelectionChanged(
                ReaderSelection(
                  text: selectedText,
                  startIndex: 0,
                  endIndex: selectedText.length,
                  locationRef: _pdfLocationRef(
                    pdfSelection.page,
                    selectedText,
                    pdfSelection.lines,
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _PdfPageBar(
                currentPage: _currentPage,
                totalPages: _totalPages,
                canGoBack: _currentPage > 1,
                canGoForward:
                    _totalPages > 0 && _currentPage < _totalPages,
                onPrevious: _goToPreviousPage,
                onNext: _goToNextPage,
              ),
            ),
          ),
        ),
      ],
    );
  }

  int get _safeTotalPages => _totalPages <= 0 ? 1 : _totalPages;

  int get _initialPageNumber {
    final page = widget.initialPage;
    if (page == null || page <= 0) return 1;

    return page;
  }

  _UsablePdfSelection? _usablePdfSelection() {
    final selectedLines = _viewerKey.currentState?.getSelectedTextLines() ?? const [];
    if (selectedLines.isEmpty) return null;

    final usableLines = selectedLines
        .where(_hasUsableBounds)
        .toList(growable: false);
    if (usableLines.isEmpty) return null;

    final pages = usableLines.map((line) => line.pageNumber).toSet();
    if (pages.length != 1) return null;

    final page = pages.first;
    if (page <= 0 || (_totalPages > 0 && page > _totalPages)) return null;

    return _UsablePdfSelection(
      page: page,
      lines: usableLines,
    );
  }

  bool _hasUsableBounds(PdfTextLine line) {
    final bounds = line.bounds;
    if (!bounds.left.isFinite ||
        !bounds.top.isFinite ||
        !bounds.width.isFinite ||
        !bounds.height.isFinite) {
      return false;
    }

    return bounds.width > 0 && bounds.height > 0;
  }

  void _reportWeakSelection() {
    if (_didReportWeakSelection) return;

    _didReportWeakSelection = true;
    widget.onSelectionFailure?.call(
      'This part of the PDF may not support clean text highlighting.',
    );
  }

  void _scheduleAnnotationSync() {
    if (_annotationSyncScheduled) return;
    _annotationSyncScheduled = true;
    final generation = ++_annotationSyncGeneration;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _annotationSyncGeneration) return;

      _annotationSyncScheduled = false;
      unawaited(_syncVisibleAnnotations(generation));
    });
  }

  Future<void> _syncVisibleAnnotations(int generation) async {
    if (!_documentLoaded) return;

    final nextAnnotations = <String, ReaderAnnotation>{
      for (final annotation in widget.annotations)
        if (annotation.canHighlightText &&
            annotation.isPdfLocation &&
            annotation.pdfPageNumber != null)
          annotation.id: annotation,
    };

    var operationsSinceYield = 0;
    for (final entry in _visibleAnnotations.entries.toList()) {
      if (!mounted || generation != _annotationSyncGeneration) return;

      final current = nextAnnotations[entry.key];
      if (current != null &&
          _annotationSignature(current) == entry.value.subject) {
        continue;
      }

      _controller.removeAnnotation(entry.value);
      _visibleAnnotations.remove(entry.key);
      operationsSinceYield++;
      if (operationsSinceYield >= _annotationSyncBatchSize) {
        operationsSinceYield = 0;
        await Future<void>.delayed(Duration.zero);
      }
    }

    for (final annotation in nextAnnotations.values) {
      if (!mounted || generation != _annotationSyncGeneration) return;
      if (_visibleAnnotations.containsKey(annotation.id)) continue;

      final visibleAnnotation = _highlightAnnotationFor(annotation);
      if (visibleAnnotation == null) continue;

      _visibleAnnotations[annotation.id] = visibleAnnotation;
      _controller.addAnnotation(visibleAnnotation);
      operationsSinceYield++;
      if (operationsSinceYield >= _annotationSyncBatchSize) {
        operationsSinceYield = 0;
        await Future<void>.delayed(Duration.zero);
      }
    }
  }

  HighlightAnnotation? _highlightAnnotationFor(ReaderAnnotation annotation) {
    final lines = _pdfTextLinesFor(annotation);
    if (lines.isEmpty) return null;

    final highlight = HighlightAnnotation(textBoundsCollection: lines)
      ..color = annotationColorById(annotation.colorId)
      ..opacity = 1
      ..isLocked = true
      ..author = 'Qurtix'
      ..subject = _annotationSignature(annotation);

    return highlight;
  }

  List<PdfTextLine> _pdfTextLinesFor(ReaderAnnotation annotation) {
    final page = annotation.pdfPageNumber;
    if (page == null) return const [];

    final rectsValue = _pdfValue(annotation.locationRef, 'rects');
    if (rectsValue == null || rectsValue.isEmpty) return const [];

    final lines = <PdfTextLine>[];
    for (final encodedRect in rectsValue.split(',')) {
      final parts = encodedRect.split('_');
      if (parts.length != 4) continue;

      final left = double.tryParse(parts[0]);
      final top = double.tryParse(parts[1]);
      final width = double.tryParse(parts[2]);
      final height = double.tryParse(parts[3]);
      if (left == null || top == null || width == null || height == null) {
        continue;
      }
      if (width <= 0 || height <= 0) continue;

      lines.add(
        PdfTextLine(
          Rect.fromLTWH(left, top, width, height),
          annotation.selectedText,
          page,
        ),
      );
    }

    return lines;
  }

  String _annotationSignature(ReaderAnnotation annotation) {
    return [
      annotation.id,
      annotation.colorId,
      annotation.locationRef,
    ].join('|');
  }

  String? _pdfValue(String locationRef, String key) {
    if (!locationRef.startsWith('pdf:')) return null;

    for (final part in locationRef.substring(4).split(';')) {
      final separatorIndex = part.indexOf('=');
      if (separatorIndex <= 0) continue;

      final partKey = part.substring(0, separatorIndex).trim();
      if (partKey != key) continue;

      final value = part.substring(separatorIndex + 1).trim();
      if (value.isNotEmpty) return value;
    }

    return null;
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
          oldAnnotation.locationRef != newAnnotation.locationRef ||
          oldAnnotation.type != newAnnotation.type) {
        return false;
      }
    }

    return true;
  }

  void _jumpToInitialPage() {
    if (_didJumpToInitialPage) return;

    final page = widget.initialPage;
    if (page == null || page <= 0 || _totalPages <= 0) return;

    _didJumpToInitialPage = true;
    final safePage = page.clamp(1, _totalPages).toInt();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _controller.jumpToPage(safePage);
      setState(() => _currentPage = safePage);
      _notifyPositionChanged();
    });
  }

  void _jumpToPage(int page) {
    if (_totalPages <= 0) return;

    final safePage = page.clamp(1, _totalPages).toInt();
    _controller.jumpToPage(safePage);
    setState(() => _currentPage = safePage);
    _notifyPositionChanged();
  }

  void _notifyPositionChanged() {
    widget.onPositionChanged?.call(
      PdfReaderPosition(
        currentPage: _currentPage,
        totalPages: _totalPages,
      ),
    );
  }

  void _goToPreviousPage() {
    if (_currentPage <= 1) return;

    _controller.previousPage();
  }

  void _goToNextPage() {
    if (_totalPages > 0 && _currentPage >= _totalPages) return;

    _controller.nextPage();
  }

  void _clearSelection() {
    _controller.clearSelection();
    _didReportWeakSelection = false;
    widget.onSelectionChanged(null);
  }

  String _pdfLocationRef(
    int page,
    String selectedText,
    List<PdfTextLine> selectedLines,
  ) {
    final rects = selectedLines
        .map((line) {
          final bounds = line.bounds;
          return [
            bounds.left,
            bounds.top,
            bounds.width,
            bounds.height,
          ].map((value) => value.toStringAsFixed(2)).join('_');
        })
        .join(',');

    final parts = [
      'pdf:page=$page',
      'text=${_selectionFingerprint(selectedText)}',
      if (rects.isNotEmpty) 'rects=$rects',
    ];

    return parts.join(';');
  }

  String _selectionFingerprint(String selectedText) {
    final normalized = selectedText.replaceAll(RegExp(r'\s+'), ' ').trim();
    final prefix = String.fromCharCodes(normalized.runes.take(32));
    final safePrefix = base64Url.encode(utf8.encode(prefix));

    return '${normalized.length}-$safePrefix';
  }

  String _normalizedSelectedText(String? value) {
    if (value == null) return '';

    final repaired = _repairLikelyMojibake(value);

    return repaired
        .replaceAll('\u0000', '')
        .replaceAll('\u00ad', '')
        .replaceAll(RegExp(r'[\u0001-\u0008\u000b\u000c\u000e-\u001f]'), ' ')
        .replaceAll(RegExp(r'[ \t\r\f]+'), ' ')
        .replaceAll(RegExp(r'\n\s+'), '\n')
        .replaceAll(RegExp(r'\s+\n'), '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  String _repairLikelyMojibake(String value) {
    if (!_looksLikeMojibake(value)) return value;
    if (value.codeUnits.any((unit) => unit > 255)) return value;

    try {
      final repaired = utf8.decode(value.codeUnits, allowMalformed: false);
      if (repaired.runes.length < value.runes.length / 2) return value;

      return repaired;
    } catch (_) {
      return value;
    }
  }

  bool _looksLikeMojibake(String value) {
    if (RegExp(r'[\u0600-\u06ff]').hasMatch(value)) return false;

    return RegExp(r'[\u00c3\u00c2\u00d8\u00d9]').hasMatch(value);
  }
}

class _UsablePdfSelection {
  const _UsablePdfSelection({
    required this.page,
    required this.lines,
  });

  final int page;
  final List<PdfTextLine> lines;
}

class _PdfPageBar extends StatelessWidget {
  const _PdfPageBar({
    required this.currentPage,
    required this.totalPages,
    required this.canGoBack,
    required this.canGoForward,
    required this.onPrevious,
    required this.onNext,
  });

  final int currentPage;
  final int totalPages;
  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = colors.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: isDark ? 0.88 : 0.90),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: isDark ? 0.34 : 0.48),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.07),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: canGoBack ? onPrevious : null,
              icon: const Icon(Icons.keyboard_arrow_left_rounded),
              tooltip: 'Previous page',
              iconSize: 22,
              visualDensity: VisualDensity.compact,
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeOutCubic,
              child: Padding(
                key: ValueKey('$currentPage-$totalPages'),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  _pageLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: canGoForward ? onNext : null,
              icon: const Icon(Icons.keyboard_arrow_right_rounded),
              tooltip: 'Next page',
              iconSize: 22,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  String get _pageLabel {
    if (totalPages <= 0) return 'Page $currentPage';

    return '$currentPage / $totalPages';
  }
}

class _DocumentError extends StatelessWidget {
  const _DocumentError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
      ),
    );
  }
}
