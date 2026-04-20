import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../../core/design/app_design.dart';
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
    this.isSelectionActive = false,
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
  final bool isSelectionActive;
  final ValueChanged<PdfReaderPosition>? onPositionChanged;
  final ValueChanged<String>? onSelectionFailure;

  @override
  Widget build(BuildContext context) {
    final file = File(filePath);
    final surfaceColor = _pdfSurfaceColor;

    if (!file.existsSync()) {
      return const _DocumentError(message: 'This PDF file could not be found.');
    }

    return ColoredBox(
      color: surfaceColor,
      child: _PdfrxSelectionReader(
        file: file,
        annotations: annotations,
        controller: controller,
        initialPage: initialPage,
        isSelectionActive: isSelectionActive,
        surfaceColor: surfaceColor,
        onPositionChanged: onPositionChanged,
        onSelectionChanged: onSelectionChanged,
        onSelectionFailure: onSelectionFailure,
      ),
    );
  }

  Color get _pdfSurfaceColor {
    if (backgroundColor.computeLuminance() < 0.18) {
      return const Color(0xFF181917);
    }

    return const Color(0xFFF6F5F1);
  }
}

class PdfReaderController {
  _PdfrxSelectionReaderState? _state;

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

class _PdfrxSelectionReader extends StatefulWidget {
  const _PdfrxSelectionReader({
    required this.file,
    required this.annotations,
    required this.controller,
    required this.initialPage,
    required this.isSelectionActive,
    required this.surfaceColor,
    required this.onSelectionChanged,
    required this.onPositionChanged,
    required this.onSelectionFailure,
  });

  final File file;
  final List<ReaderAnnotation> annotations;
  final PdfReaderController? controller;
  final int? initialPage;
  final bool isSelectionActive;
  final Color surfaceColor;
  final ValueChanged<ReaderSelection?> onSelectionChanged;
  final ValueChanged<PdfReaderPosition>? onPositionChanged;
  final ValueChanged<String>? onSelectionFailure;

  @override
  State<_PdfrxSelectionReader> createState() => _PdfrxSelectionReaderState();
}

class _PdfrxSelectionReaderState extends State<_PdfrxSelectionReader> {
  static const double _documentPageSpacing = 16;
  static const Duration _pageJumpDuration = Duration(milliseconds: 260);

  late final PdfViewerController _pdfController = PdfViewerController();

  int _currentPage = 1;
  int _totalPages = 0;
  int _selectionGeneration = 0;
  bool _didJumpToInitialPage = false;
  bool _didReportWeakSelection = false;

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
  }

  @override
  void didUpdateWidget(covariant _PdfrxSelectionReader oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._state = null;
      widget.controller?._state = this;
    }

    if (oldWidget.file.path != widget.file.path) {
      _currentPage = 1;
      _totalPages = 0;
      _selectionGeneration++;
      _didJumpToInitialPage = false;
      _didReportWeakSelection = false;
      widget.onSelectionChanged(null);
      return;
    }

    if (oldWidget.initialPage != widget.initialPage) {
      _didJumpToInitialPage = false;
      _jumpToInitialPage();
    }
  }

  @override
  void dispose() {
    widget.controller?._state = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DefaultSelectionStyle(
            selectionColor: annotationColorById(
              'yellow',
            ).withValues(alpha: 0.20),
            cursorColor: Theme.of(context).colorScheme.primary,
            child: PdfViewer.file(
              widget.file.path,
              controller: _pdfController,
              initialPageNumber: _initialPageNumber,
              params: PdfViewerParams(
                margin: _documentPageSpacing,
                backgroundColor: widget.surfaceColor,
                pageDropShadow: null,
                scrollHorizontallyByMouseWheel: true,
                layoutPages: _horizontalPageLayout,
                enableTextSelection: true,
                onTextSelectionChange: _handlePdfTextSelectionChanged,
                onViewerReady: _handleViewerReady,
                onPageChanged: _handlePageChanged,
                pagePaintCallbacks: [_paintSavedHighlights],
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 14,
          child: SafeArea(
            child: AnimatedSlide(
              offset: widget.isSelectionActive
                  ? const Offset(0, 0.36)
                  : Offset.zero,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: widget.isSelectionActive ? 0 : 1,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutCubic,
                child: IgnorePointer(
                  ignoring: widget.isSelectionActive,
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
            ),
          ),
        ),
      ],
    );
  }

  PdfPageLayout _horizontalPageLayout(
    List<PdfPage> pages,
    PdfViewerParams params,
  ) {
    final height =
        pages.fold<double>(
          0,
          (previous, page) => math.max(previous, page.height),
        ) +
        params.margin * 2;
    final pageLayouts = <Rect>[];
    var x = params.margin;

    for (final page in pages) {
      pageLayouts.add(
        Rect.fromLTWH(x, (height - page.height) / 2, page.width, page.height),
      );
      x += page.width + params.margin;
    }

    return PdfPageLayout(
      pageLayouts: pageLayouts,
      documentSize: Size(x, height),
    );
  }

  int get _safeTotalPages => _totalPages <= 0 ? 1 : _totalPages;

  int get _initialPageNumber {
    final page = widget.initialPage;
    if (page == null || page <= 0) return 1;

    return page;
  }

  void _handleViewerReady(
    PdfDocument document,
    PdfViewerController controller,
  ) {
    final pageCount = document.pages.length;
    final page = (controller.pageNumber ?? _initialPageNumber)
        .clamp(1, pageCount <= 0 ? 1 : pageCount)
        .toInt();

    setState(() {
      _totalPages = pageCount;
      _currentPage = page;
    });
    _notifyPositionChanged();
    _jumpToInitialPage();
  }

  void _handlePageChanged(int? pageNumber) {
    if (pageNumber == null || pageNumber <= 0) return;

    setState(() => _currentPage = pageNumber.clamp(1, _safeTotalPages).toInt());
    _notifyPositionChanged();
  }

  void _handlePdfTextSelectionChanged(List<PdfTextRanges> selections) {
    final generation = ++_selectionGeneration;

    if (selections.isEmpty) {
      _didReportWeakSelection = false;
      widget.onSelectionChanged(null);
      return;
    }

    if (!mounted || generation != _selectionGeneration) return;

    final selectedText = _normalizedSelectedText(
      selections.map((selection) => selection.text).join('\n'),
    );
    if (selectedText.isEmpty) {
      _didReportWeakSelection = false;
      widget.onSelectionChanged(null);
      return;
    }

    final pdfSelection = _usablePdfSelection(selections);
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
          pdfSelection.rects,
        ),
      ),
    );
  }

  _UsablePdfSelection? _usablePdfSelection(List<PdfTextRanges> selections) {
    if (selections.isEmpty || !_pdfController.isReady) return null;

    final pages = selections.map((selection) => selection.pageNumber).toSet();
    if (pages.length != 1) return null;

    final pageNumber = pages.first;
    if (pageNumber <= 0 || (_totalPages > 0 && pageNumber > _totalPages)) {
      return null;
    }

    final page = _pageByNumber(pageNumber);
    if (page == null) return null;

    final rects = <Rect>[];
    for (final selection in selections) {
      for (final range in selection.ranges) {
        final fragmentRange = range.toTextRangeWithFragments(
          selection.pageText,
        );
        if (fragmentRange == null) continue;

        for (final pdfRect in fragmentRange.enumerateRectsForRange()) {
          final rect = pdfRect.toRect(page: page);
          if (_hasUsableBounds(rect)) rects.add(rect);
        }
      }
    }

    if (rects.isEmpty) return null;

    return _UsablePdfSelection(
      page: pageNumber,
      rects: List<Rect>.unmodifiable(rects),
    );
  }

  PdfPage? _pageByNumber(int pageNumber) {
    if (!_pdfController.isReady) return null;

    final pageIndex = pageNumber - 1;
    if (pageIndex < 0 || pageIndex >= _pdfController.pages.length) return null;

    return _pdfController.pages[pageIndex];
  }

  bool _hasUsableBounds(Rect rect) {
    return rect.left.isFinite &&
        rect.top.isFinite &&
        rect.width.isFinite &&
        rect.height.isFinite &&
        rect.width > 0 &&
        rect.height > 0;
  }

  void _reportWeakSelection() {
    if (_didReportWeakSelection) return;

    _didReportWeakSelection = true;
    widget.onSelectionFailure?.call(
      'This part of the PDF may not support clean text highlighting.',
    );
  }

  void _jumpToInitialPage() {
    if (_didJumpToInitialPage) return;

    final page = widget.initialPage;
    if (page == null || page <= 0 || _totalPages <= 0) return;

    _didJumpToInitialPage = true;
    final safePage = page.clamp(1, _totalPages).toInt();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _jumpToPage(safePage);
    });
  }

  void _jumpToPage(int page) {
    if (!_pdfController.isReady || _totalPages <= 0) return;

    final safePage = page.clamp(1, _totalPages).toInt();
    unawaited(
      _pdfController.goToPage(
        pageNumber: safePage,
        duration: _pageJumpDuration,
      ),
    );
    setState(() => _currentPage = safePage);
    _notifyPositionChanged();
  }

  void _notifyPositionChanged() {
    widget.onPositionChanged?.call(
      PdfReaderPosition(currentPage: _currentPage, totalPages: _totalPages),
    );
  }

  void _goToPreviousPage() {
    if (_currentPage <= 1) return;

    _jumpToPage(_currentPage - 1);
  }

  void _goToNextPage() {
    if (_totalPages > 0 && _currentPage >= _totalPages) return;

    _jumpToPage(_currentPage + 1);
  }

  void _clearSelection() {
    _selectionGeneration++;
    _didReportWeakSelection = false;
    widget.onSelectionChanged(null);
  }

  void _paintSavedHighlights(Canvas canvas, Rect pageRect, PdfPage page) {
    final highlights = <_PdfSavedHighlight>[];
    for (final annotation in widget.annotations) {
      if (!annotation.canHighlightText ||
          !annotation.isPdfLocation ||
          annotation.pdfPageNumber != page.pageNumber) {
        continue;
      }

      final rects = _pdfRects(annotation.locationRef);
      if (rects.isEmpty) continue;

      highlights.add(
        _PdfSavedHighlight(
          color: annotationColorById(annotation.colorId),
          rects: rects,
        ),
      );
    }

    if (highlights.isEmpty) return;

    final scaleX = pageRect.width / page.width;
    final scaleY = pageRect.height / page.height;
    if (scaleX <= 0 || scaleY <= 0) return;

    for (final highlight in highlights) {
      final paint = Paint()
        ..color = highlight.color.withValues(alpha: 0.20)
        ..style = PaintingStyle.fill;

      for (final rect in highlight.rects) {
        final scaledRect = Rect.fromLTWH(
          pageRect.left + rect.left * scaleX,
          pageRect.top + rect.top * scaleY,
          rect.width * scaleX,
          rect.height * scaleY,
        );
        canvas.drawRect(scaledRect, paint);
      }
    }
  }

  List<Rect> _pdfRects(String locationRef) {
    final rectsValue = _pdfValue(locationRef, 'rects');
    if (rectsValue == null || rectsValue.isEmpty) return const [];

    final rects = <Rect>[];
    for (final encodedRect in rectsValue.split(',')) {
      final parts = encodedRect.split('_');
      if (parts.length != 4) continue;

      final left = double.tryParse(parts[0]);
      final top = double.tryParse(parts[1]);
      final width = double.tryParse(parts[2]);
      final height = double.tryParse(parts[3]);
      if (left == null ||
          top == null ||
          width == null ||
          height == null ||
          !left.isFinite ||
          !top.isFinite ||
          !width.isFinite ||
          !height.isFinite) {
        continue;
      }
      if (width <= 0 || height <= 0) continue;

      rects.add(Rect.fromLTWH(left, top, width, height));
    }

    return List<Rect>.unmodifiable(rects);
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

  String _pdfLocationRef(
    int page,
    String selectedText,
    List<Rect> selectedRects,
  ) {
    final rects = selectedRects
        .map((rect) {
          return [
            rect.left,
            rect.top,
            rect.width,
            rect.height,
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

class _PdfSavedHighlight {
  const _PdfSavedHighlight({required this.color, required this.rects});

  final Color color;
  final List<Rect> rects;
}

class _UsablePdfSelection {
  const _UsablePdfSelection({required this.page, required this.rects});

  final int page;
  final List<Rect> rects;
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

    return ClipRRect(
      borderRadius: AppCorners.pill,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: isDark ? 0.72 : 0.76),
            borderRadius: AppCorners.pill,
            border: Border.all(
              color: colors.outlineVariant.withValues(
                alpha: isDark ? 0.16 : 0.18,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: colors.onSurface.withValues(alpha: 0.035),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PdfPageButton(
                  onPressed: canGoBack ? onPrevious : null,
                  icon: Icons.keyboard_arrow_left_rounded,
                  tooltip: 'Previous page',
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
                        fontFamily: AppTypography.sans,
                        color: colors.onSurface.withValues(alpha: 0.60),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
                _PdfPageButton(
                  onPressed: canGoForward ? onNext : null,
                  icon: Icons.keyboard_arrow_right_rounded,
                  tooltip: 'Next page',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _pageLabel {
    if (totalPages <= 0) return 'Page $currentPage';

    return '$currentPage / $totalPages';
  }
}

class _PdfPageButton extends StatelessWidget {
  const _PdfPageButton({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      tooltip: tooltip,
      iconSize: 19,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        foregroundColor: colors.onSurface.withValues(alpha: 0.64),
        disabledForegroundColor: colors.onSurface.withValues(alpha: 0.22),
        backgroundColor: colors.onSurface.withValues(alpha: 0.026),
        disabledBackgroundColor: Colors.transparent,
        minimumSize: const Size.square(32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const CircleBorder(),
      ),
    );
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
