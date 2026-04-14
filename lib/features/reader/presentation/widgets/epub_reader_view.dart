import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../domain/reader_annotation.dart';
import 'reader_content.dart';

class EpubReaderView extends StatefulWidget {
  const EpubReaderView({
    required this.filePath,
    required this.annotations,
    required this.textColor,
    required this.fontSize,
    required this.lineHeight,
    required this.maxWidth,
    required this.focusedAnnotationId,
    required this.onSelectionChanged,
    this.controller,
    this.initialAnnotation,
    this.onProgressChanged,
    this.onPositionChanged,
    super.key,
  });

  final String filePath;
  final List<ReaderAnnotation> annotations;
  final Color textColor;
  final double fontSize;
  final double lineHeight;
  final double maxWidth;
  final String? focusedAnnotationId;
  final ValueChanged<ReaderSelection?> onSelectionChanged;
  final EpubReaderController? controller;
  final ReaderAnnotation? initialAnnotation;
  final ValueChanged<double>? onProgressChanged;
  final ValueChanged<EpubReaderPosition>? onPositionChanged;

  @override
  State<EpubReaderView> createState() => _EpubReaderViewState();
}

class EpubReaderController {
  _EpubReaderViewState? _state;

  bool jumpToProgress(double progress) {
    return _state?._jumpToProgress(progress) ?? false;
  }

  bool jumpToPage(int pageNumber) {
    return _state?._jumpToPageNumber(pageNumber) ?? false;
  }

  bool jumpToAnnotation(ReaderAnnotation annotation) {
    return _state?._jumpToAnnotation(annotation) ?? false;
  }

  String? currentLocationRef() => _state?._currentLocationRef();
}

class EpubReaderPosition {
  const EpubReaderPosition({
    required this.progress,
    required this.locationRef,
    required this.currentPage,
    required this.totalPages,
  });

  final double progress;
  final String locationRef;
  final int currentPage;
  final int totalPages;

  int get percent {
    if (totalPages <= 0) return 0;
    final progressPercent = (currentPage / totalPages) * 100;
    return progressPercent.clamp(0, 100).floor();
  }

  String get label => 'Progress $percent%';
}

class EpubPaginationLayout {
  const EpubPaginationLayout({
    required this.viewportWidth,
    required this.viewportHeight,
    required this.fontSize,
    required this.lineHeight,
    required this.maxWidth,
    required this.horizontalPadding,
    required this.verticalPadding,
  });

  final double viewportWidth;
  final double viewportHeight;
  final double fontSize;
  final double lineHeight;
  final double maxWidth;
  final double horizontalPadding;
  final double verticalPadding;

  double get textWidth {
    return (viewportWidth - (horizontalPadding * 2))
        .clamp(0.0, maxWidth)
        .toDouble();
  }

  double get pageTextHeight => math.max(1, viewportHeight - verticalPadding);

  String get cacheKey {
    return [
      viewportWidth.toStringAsFixed(1),
      viewportHeight.toStringAsFixed(1),
      fontSize.toStringAsFixed(2),
      lineHeight.toStringAsFixed(2),
      maxWidth.toStringAsFixed(1),
      horizontalPadding.toStringAsFixed(1),
      verticalPadding.toStringAsFixed(1),
    ].join('|');
  }
}

class EpubPageAnchor {
  const EpubPageAnchor({
    required this.chapterPath,
    required this.localStart,
    required this.localEnd,
    required this.virtualPageNumber,
    required this.sourceIndex,
  });

  final String chapterPath;
  final int localStart;
  final int localEnd;
  final int virtualPageNumber;
  final int sourceIndex;
}

class EpubVirtualPage {
  const EpubVirtualPage({
    required this.pageNumber,
    required this.chapterPath,
    required this.sourceIndex,
    required this.localStart,
    required this.localEnd,
    required this.text,
  });

  final int pageNumber;
  final String chapterPath;
  final int sourceIndex;
  final int localStart;
  final int localEnd;
  final String text;

  bool containsLocalOffset(int offset) => offset >= localStart && offset <= localEnd;

  int renderedToSourceOffset(int renderedOffset) {
    final safeRendered = renderedOffset.clamp(0, text.length).toInt();
    return (localStart + safeRendered).clamp(localStart, localEnd).toInt();
  }

  int? sourceToRenderedOffset(int sourceOffset) {
    if (sourceOffset < localStart || sourceOffset > localEnd) return null;
    return (sourceOffset - localStart).clamp(0, text.length).toInt();
  }

  EpubPageAnchor anchorAt({required int localStart, required int localEnd}) {
    return EpubPageAnchor(
      chapterPath: chapterPath,
      localStart: localStart.clamp(this.localStart, this.localEnd).toInt(),
      localEnd: localEnd.clamp(this.localStart, this.localEnd).toInt(),
      virtualPageNumber: pageNumber,
      sourceIndex: sourceIndex,
    );
  }
}

class EpubPageMap {
  const EpubPageMap({required this.pages, required this.layout});

  final List<EpubVirtualPage> pages;
  final EpubPaginationLayout layout;

  int get totalPages => pages.length;
  bool get isEmpty => pages.isEmpty;

  EpubVirtualPage? pageAtIndex(int index) {
    if (index < 0 || index >= pages.length) return null;
    return pages[index];
  }

  EpubVirtualPage? pageNumber(int pageNumber) {
    if (pageNumber <= 0 || pageNumber > pages.length) return null;
    return pages[pageNumber - 1];
  }

  EpubVirtualPage? pageForAnchor(EpubPageAnchor anchor) {
    return pageForLocation(
      chapterPath: anchor.chapterPath,
      localOffset: anchor.localStart,
      preferredPageNumber: anchor.virtualPageNumber,
    );
  }

  EpubVirtualPage? pageForLocation({
    required String chapterPath,
    required int localOffset,
    int? preferredPageNumber,
  }) {
    final preferred = preferredPageNumber == null ? null : pageNumber(preferredPageNumber);
    if (preferred != null &&
        preferred.chapterPath == chapterPath &&
        preferred.containsLocalOffset(localOffset)) {
      return preferred;
    }

    for (final page in pages) {
      if (page.chapterPath == chapterPath && page.containsLocalOffset(localOffset)) {
        return page;
      }
    }

    return nearestPageInChapter(chapterPath: chapterPath, localOffset: localOffset);
  }

  EpubVirtualPage? nearestPageInChapter({
    required String chapterPath,
    required int localOffset,
  }) {
    EpubVirtualPage? nearest;
    var nearestDistance = 1 << 30;
    for (final page in pages) {
      if (page.chapterPath != chapterPath) continue;
      final distance = localOffset < page.localStart
          ? page.localStart - localOffset
          : localOffset > page.localEnd
              ? localOffset - page.localEnd
              : 0;
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = page;
      }
    }
    return nearest;
  }

  EpubVirtualPage? pageForProgress(double progress) {
    if (pages.isEmpty) return null;
    final clamped = progress.clamp(0.0, 1.0).toDouble();
    final index = math.max(0, (clamped * pages.length).ceil() - 1);
    return pageAtIndex(index);
  }
}

class _EpubReaderViewState extends State<EpubReaderView> {
  static const _horizontalPadding = 24.0;
  static const _verticalPadding = 100.0;
  static const _anchorContextLength = 48;
  static const _anchorTextLength = 80;
  static const _sameChapterSearchRadius = 5000;
  static const _maxInitialAnnotationAttempts = 3;

  final Map<String, EpubPageMap> _pageMapCache = {};

  late Future<_EpubDocument> _document;
  PageController? _pageController;
  _EpubDocument? _loadedDocument;
  EpubPageMap? _pageMap;
  String? _pageMapKey;
  String? _handledInitialAnnotationId;
  int _initialAnnotationAttempts = 0;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
    _document = _loadDocument();
  }

  @override
  void didUpdateWidget(covariant EpubReaderView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._state = null;
      widget.controller?._state = this;
    }

    if (oldWidget.filePath != widget.filePath) {
      _document = _loadDocument();
      _loadedDocument = null;
      _pageMap = null;
      _pageMapKey = null;
      _handledInitialAnnotationId = null;
      _initialAnnotationAttempts = 0;
      _currentPageIndex = 0;
      _pageController?.dispose();
      _pageController = null;
      _pageMapCache.clear();
      widget.onProgressChanged?.call(0);
      widget.onPositionChanged?.call(
        const EpubReaderPosition(
          progress: 0,
          locationRef: 'epub:page=1;totalPages=0;progress=0.0000',
          currentPage: 1,
          totalPages: 0,
        ),
      );
    } else if (oldWidget.initialAnnotation?.id != widget.initialAnnotation?.id) {
      _handledInitialAnnotationId = null;
      _initialAnnotationAttempts = 0;
      _scheduleInitialAnnotationJump();
    }
  }

  @override
  void dispose() {
    widget.controller?._state = null;
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_EpubDocument>(
      future: _document,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _DocumentError(message: 'This EPUB file could not be opened.');
        }

        final document = snapshot.data;
        if (document == null) return const Center(child: CircularProgressIndicator());
        if (document.isEmpty) {
          return const _DocumentError(
            message: 'This EPUB file does not contain readable text.',
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final layout = EpubPaginationLayout(
              viewportWidth: constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : MediaQuery.sizeOf(context).width,
              viewportHeight: constraints.maxHeight.isFinite
                  ? constraints.maxHeight
                  : MediaQuery.sizeOf(context).height,
              fontSize: widget.fontSize,
              lineHeight: widget.lineHeight,
              maxWidth: widget.maxWidth,
              horizontalPadding: _horizontalPadding,
              verticalPadding: _verticalPadding,
            );
            final pageMap = _pageMapFor(document, layout);

            if (!identical(_loadedDocument, document)) {
              _loadedDocument = document;
              _handledInitialAnnotationId = null;
              _initialAnnotationAttempts = 0;
              _currentPageIndex = 0;
            }

            if (_pageMapKey != layout.cacheKey) {
              final anchor = _currentPageAnchor();
              _pageMap = pageMap;
              _pageMapKey = layout.cacheKey;
              _currentPageIndex = _indexForAnchorAfterRepagination(pageMap, anchor);
              _resetPageController(_currentPageIndex);
              _schedulePositionUpdate();
              _scheduleInitialAnnotationJump();
            } else {
              _pageMap = pageMap;
              _ensurePageController();
            }

            if (pageMap.isEmpty) {
              return const _DocumentError(
                message: 'This EPUB file does not contain readable text.',
              );
            }

            return PageView.builder(
              controller: _pageController,
              itemCount: pageMap.totalPages,
              onPageChanged: (index) {
                _currentPageIndex = index;
                _notifyPositionChanged();
              },
              itemBuilder: (context, index) {
                final page = pageMap.pages[index];
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    _horizontalPadding,
                    24,
                    _horizontalPadding,
                    76,
                  ),
                  child: ReaderContent(
                    text: page.text,
                    annotations: _annotationsForPage(page),
                    textColor: widget.textColor,
                    fontSize: widget.fontSize,
                    lineHeight: widget.lineHeight,
                    maxWidth: widget.maxWidth,
                    focusedAnnotationId: widget.focusedAnnotationId,
                    annotationStartOffset: (annotation) {
                      return _annotationLocalStartForPage(annotation, page);
                    },
                    annotationEndOffset: (annotation) {
                      return _annotationLocalEndForPage(annotation, page);
                    },
                    locationOffsetToRenderedOffset: page.sourceToRenderedOffset,
                    renderedOffsetToLocationOffset: page.renderedToSourceOffset,
                    onSelectionChanged: (selection) {
                      _handleSelectionChanged(page, selection);
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<_EpubDocument> _loadDocument() async {
    final file = File(widget.filePath);
    if (!await file.exists()) throw StateError('File not found');
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return const _EpubDocument(sources: []);
    return compute(_extractEpubDocumentFromBytes, bytes);
  }

  EpubPageMap _pageMapFor(_EpubDocument document, EpubPaginationLayout layout) {
    final cacheKey = '${document.cacheSeed}:${layout.cacheKey}';
    final cached = _pageMapCache[cacheKey];
    if (cached != null) return cached;

    final pageMap = _buildPageMap(document, layout);
    _pageMapCache[cacheKey] = pageMap;
    if (_pageMapCache.length > 4) _pageMapCache.remove(_pageMapCache.keys.first);
    return pageMap;
  }

  EpubPageMap _buildPageMap(_EpubDocument document, EpubPaginationLayout layout) {
    final pages = <EpubVirtualPage>[];
    var pageNumber = 1;
    for (final source in document.sources) {
      final sourcePages = _paginateSource(
        source: source,
        layout: layout,
        firstPageNumber: pageNumber,
      );
      pages.addAll(sourcePages);
      pageNumber += sourcePages.length;
    }
    return EpubPageMap(
      pages: List<EpubVirtualPage>.unmodifiable(pages),
      layout: layout,
    );
  }

  List<EpubVirtualPage> _paginateSource({
    required _EpubChapterSource source,
    required EpubPaginationLayout layout,
    required int firstPageNumber,
  }) {
    final text = source.text;
    if (text.isEmpty) return const [];
    if (layout.textWidth <= 0) {
      return [_pageFromRange(source, firstPageNumber, 0, text.length)];
    }

    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: layout.fontSize,
          height: layout.lineHeight,
          letterSpacing: 0,
        ),
      ),
      textAlign: TextAlign.start,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: layout.textWidth);

    final lines = painter.computeLineMetrics();
    if (lines.isEmpty) return [_pageFromRange(source, firstPageNumber, 0, text.length)];

    final pages = <EpubVirtualPage>[];
    var pageTop = lines.first.baseline - lines.first.ascent;
    var pageStart = 0;
    var pageNumber = firstPageNumber;

    for (var i = 1; i < lines.length; i++) {
      final line = lines[i];
      final lineBottom = line.baseline + line.descent;
      if (lineBottom - pageTop <= layout.pageTextHeight) continue;

      final lineStart = painter
          .getPositionForOffset(Offset(0, line.baseline))
          .offset
          .clamp(pageStart, text.length)
          .toInt();
      final pageEnd = _pageBreakBefore(text, lineStart, pageStart);
      if (pageEnd > pageStart) {
        pages.add(_pageFromRange(source, pageNumber, pageStart, pageEnd));
        pageNumber++;
      }
      pageStart = _skipLeadingWhitespace(text, pageEnd);
      pageTop = line.baseline - line.ascent;
    }

    if (pageStart < text.length || pages.isEmpty) {
      pages.add(_pageFromRange(source, pageNumber, pageStart, text.length));
    }
    return pages;
  }

  EpubVirtualPage _pageFromRange(
    _EpubChapterSource source,
    int pageNumber,
    int start,
    int end,
  ) {
    final safeStart = start.clamp(0, source.text.length).toInt();
    final safeEnd = end.clamp(safeStart, source.text.length).toInt();
    return EpubVirtualPage(
      pageNumber: pageNumber,
      chapterPath: source.path,
      sourceIndex: source.index,
      localStart: safeStart,
      localEnd: safeEnd,
      text: source.text.substring(safeStart, safeEnd),
    );
  }

  int _pageBreakBefore(String text, int proposedEnd, int pageStart) {
    final safeEnd = proposedEnd.clamp(pageStart, text.length).toInt();
    if (safeEnd >= text.length) return text.length;

    final paragraphBreak = text.lastIndexOf('\n', safeEnd);
    if (paragraphBreak > pageStart + 120) return paragraphBreak + 1;

    final sentenceBreak = text.lastIndexOf(RegExp(r'[.!?]\s'), safeEnd);
    if (sentenceBreak > pageStart + 120) return sentenceBreak + 1;

    final spaceBreak = text.lastIndexOf(RegExp(r'\s'), safeEnd);
    if (spaceBreak > pageStart + 40) return spaceBreak + 1;

    return safeEnd;
  }

  int _skipLeadingWhitespace(String text, int offset) {
    var index = offset.clamp(0, text.length).toInt();
    while (index < text.length && text.codeUnitAt(index) <= 32) {
      index++;
    }
    return index;
  }

  void _ensurePageController() {
    _pageController ??= PageController(initialPage: _currentPageIndex);
  }

  void _resetPageController(int initialPage) {
    _pageController?.dispose();
    _pageController = PageController(initialPage: initialPage);
  }

  EpubPageAnchor? _currentPageAnchor() {
    final page = _pageMap?.pageAtIndex(_currentPageIndex);
    if (page == null) return null;
    return page.anchorAt(localStart: page.localStart, localEnd: page.localStart);
  }

  int _indexForAnchorAfterRepagination(EpubPageMap pageMap, EpubPageAnchor? anchor) {
    if (pageMap.isEmpty) return 0;
    if (anchor == null) return _currentPageIndex.clamp(0, pageMap.totalPages - 1);
    final page = pageMap.pageForAnchor(anchor);
    if (page == null) return _currentPageIndex.clamp(0, pageMap.totalPages - 1);
    return page.pageNumber - 1;
  }

  List<ReaderAnnotation> _annotationsForPage(EpubVirtualPage page) {
    if (widget.annotations.isEmpty) return const [];
    final ranges = <ReaderAnnotation>[];
    for (final annotation in widget.annotations) {
      if (!annotation.canHighlightText) continue;
      final start = _annotationLocalStartForPage(annotation, page);
      final end = _annotationLocalEndForPage(annotation, page);
      if (start == null || end == null) continue;
      if (end > page.localStart && start < page.localEnd) ranges.add(annotation);
    }
    return ranges;
  }

  int? _annotationLocalStartForPage(
    ReaderAnnotation annotation,
    EpubVirtualPage page,
  ) {
    if (annotation.epubChapterPath != page.chapterPath) return null;
    final start = annotation.epubLocalStartIndex;
    if (start == null) return null;
    return start.clamp(page.localStart, page.localEnd).toInt();
  }

  int? _annotationLocalEndForPage(
    ReaderAnnotation annotation,
    EpubVirtualPage page,
  ) {
    if (annotation.epubChapterPath != page.chapterPath) return null;
    final end = annotation.epubLocalEndIndex ?? annotation.epubLocalStartIndex;
    if (end == null) return null;
    return end.clamp(page.localStart, page.localEnd).toInt();
  }

  void _scheduleInitialAnnotationJump() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleInitialAnnotation());
  }

  void _handleInitialAnnotation() {
    if (!mounted) return;
    final annotation = widget.initialAnnotation;
    final document = _loadedDocument;
    final pageMap = _pageMap;
    if (annotation == null ||
        document == null ||
        document.isEmpty ||
        pageMap == null ||
        pageMap.isEmpty ||
        _handledInitialAnnotationId == annotation.id) {
      return;
    }

    if (_jumpToAnnotation(annotation)) {
      _handledInitialAnnotationId = annotation.id;
      return;
    }

    _initialAnnotationAttempts++;
    if (_initialAnnotationAttempts < _maxInitialAnnotationAttempts) {
      _scheduleInitialAnnotationJump();
    }
  }

  bool _jumpToAnnotation(ReaderAnnotation annotation) {
    final document = _loadedDocument;
    final pageMap = _pageMap;
    if (document == null || pageMap == null || document.isEmpty || pageMap.isEmpty) {
      return false;
    }

    final target = _resolveAnnotationPage(annotation, document, pageMap);
    if (target == null) return false;
    _jumpToPage(target);
    return true;
  }

  EpubVirtualPage? _resolveAnnotationPage(
    ReaderAnnotation annotation,
    _EpubDocument document,
    EpubPageMap pageMap,
  ) {
    final path = annotation.epubChapterPath;
    final localStart = annotation.epubLocalStartIndex;
    if (path != null && path.isNotEmpty && localStart != null) {
      final source = document.sourceForPath(path);
      if (source != null) {
        final direct = pageMap.pageForLocation(
          chapterPath: path,
          localOffset: localStart,
          preferredPageNumber: annotation.epubVirtualPageNumber,
        );
        if (direct != null && _pageMatchesAnchor(direct, annotation)) return direct;

        final recoveredOffset = _recoverLocalOffsetFromContext(
          source: source,
          expectedLocalStart: localStart,
          anchorText: _anchorTextFor(annotation),
          prefixText: annotation.epubPrefixText ?? '',
          suffixText: annotation.epubSuffixText ?? '',
        );
        if (recoveredOffset != null) {
          return pageMap.pageForLocation(
            chapterPath: path,
            localOffset: recoveredOffset,
          );
        }
        if (direct != null) return direct;
        return pageMap.nearestPageInChapter(
          chapterPath: path,
          localOffset: localStart,
        );
      }
    }

    final pageNumber = annotation.epubVirtualPageNumber;
    final byPage = pageNumber == null ? null : pageMap.pageNumber(pageNumber);
    if (byPage != null) return byPage;

    final progress = annotation.epubProgress;
    return progress == null ? null : pageMap.pageForProgress(progress);
  }

  bool _pageMatchesAnchor(EpubVirtualPage page, ReaderAnnotation annotation) {
    final anchorText = _anchorTextFor(annotation);
    if (anchorText.isEmpty) return true;
    final localStart = annotation.epubLocalStartIndex;
    if (localStart == null || localStart < page.localStart) return false;
    final renderedStart = localStart - page.localStart;
    final renderedEnd = math.min(page.text.length, renderedStart + anchorText.length);
    return page.text.substring(renderedStart, renderedEnd) == anchorText;
  }

  int? _recoverLocalOffsetFromContext({
    required _EpubChapterSource source,
    required int expectedLocalStart,
    required String anchorText,
    required String prefixText,
    required String suffixText,
  }) {
    if (anchorText.isEmpty || anchorText.length > 600) return null;

    final searchStart = math.max(0, expectedLocalStart - _sameChapterSearchRadius);
    final searchEnd = math.min(
      source.text.length,
      expectedLocalStart + _sameChapterSearchRadius,
    );
    if (searchStart >= searchEnd) return null;

    int? bestIndex;
    var bestScore = -1;
    var localIndex = source.text.indexOf(anchorText, searchStart);
    while (localIndex >= 0 && localIndex < searchEnd) {
      final score = _anchorContextScore(
        sourceText: source.text,
        localIndex: localIndex,
        anchorText: anchorText,
        prefixText: prefixText,
        suffixText: suffixText,
      );
      final bestDistance = ((bestIndex ?? 1 << 30) - expectedLocalStart).abs();
      if (score > bestScore ||
          (score == bestScore && (localIndex - expectedLocalStart).abs() < bestDistance)) {
        bestScore = score;
        bestIndex = localIndex;
      }
      localIndex = source.text.indexOf(
        anchorText,
        localIndex + math.max(anchorText.length, 1),
      );
    }
    return bestIndex;
  }

  int _anchorContextScore({
    required String sourceText,
    required int localIndex,
    required String anchorText,
    required String prefixText,
    required String suffixText,
  }) {
    var score = 0;
    if (prefixText.isNotEmpty) {
      final prefixStart = math.max(0, localIndex - prefixText.length);
      final actualPrefix = sourceText.substring(prefixStart, localIndex);
      if (actualPrefix == prefixText) {
        score += 4;
      } else if (actualPrefix.endsWith(prefixText.trim())) {
        score += 2;
      }
    }
    if (suffixText.isNotEmpty) {
      final suffixStart = localIndex + anchorText.length;
      final suffixEnd = math.min(sourceText.length, suffixStart + suffixText.length);
      final actualSuffix = sourceText.substring(suffixStart, suffixEnd);
      if (actualSuffix == suffixText) {
        score += 4;
      } else if (actualSuffix.startsWith(suffixText.trim())) {
        score += 2;
      }
    }
    return score;
  }

  String _anchorTextFor(ReaderAnnotation annotation) {
    final storedAnchor = annotation.epubAnchorText;
    if (storedAnchor != null && storedAnchor.isNotEmpty) return storedAnchor;
    if (annotation.isBookmark || annotation.isReaderState) return '';
    return annotation.selectedText.trim();
  }

  void _jumpToPage(EpubVirtualPage page) {
    final index = page.pageNumber - 1;
    _currentPageIndex = index;
    if (_pageController?.hasClients ?? false) {
      _pageController!.jumpToPage(index);
    } else {
      _resetPageController(index);
    }
    _notifyPositionChanged();
  }

  bool _jumpToPageNumber(int pageNumber) {
    final page = _pageMap?.pageNumber(pageNumber);
    if (page == null) return false;
    _jumpToPage(page);
    return true;
  }

  bool _jumpToProgress(double progress) {
    final page = _pageMap?.pageForProgress(progress);
    if (page == null) return false;
    _jumpToPage(page);
    return true;
  }

  void _schedulePositionUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _notifyPositionChanged();
    });
  }

  void _notifyPositionChanged() {
    final pageMap = _pageMap;
    if (pageMap == null || pageMap.isEmpty) return;
    final page = pageMap.pageAtIndex(_currentPageIndex);
    if (page == null) return;

    final progress = pageMap.totalPages <= 0
        ? 0.0
        : (page.pageNumber / pageMap.totalPages).clamp(0.0, 1.0).toDouble();
    final locationRef = _locationRefForPage(
      page: page,
      localStart: page.localStart,
      localEnd: page.localStart,
      anchorText: _anchorTextAt(page),
    );

    widget.onProgressChanged?.call(progress);
    widget.onPositionChanged?.call(
      EpubReaderPosition(
        progress: progress,
        locationRef: locationRef,
        currentPage: page.pageNumber,
        totalPages: pageMap.totalPages,
      ),
    );
  }

  void _handleSelectionChanged(EpubVirtualPage page, ReaderSelection? selection) {
    if (selection == null) {
      widget.onSelectionChanged(null);
      return;
    }

    widget.onSelectionChanged(
      ReaderSelection(
        text: selection.text,
        startIndex: selection.startIndex,
        endIndex: selection.endIndex,
        locationRef: _locationRefForPage(
          page: page,
          localStart: selection.startIndex,
          localEnd: selection.endIndex,
          anchorText: selection.text,
        ),
      ),
    );
  }

  String? _currentLocationRef() {
    final page = _pageMap?.pageAtIndex(_currentPageIndex);
    if (page == null) return null;
    return _locationRefForPage(
      page: page,
      localStart: page.localStart,
      localEnd: page.localStart,
      anchorText: _anchorTextAt(page),
    );
  }

  String _locationRefForPage({
    required EpubVirtualPage page,
    required int localStart,
    required int localEnd,
    required String anchorText,
  }) {
    final pageMap = _pageMap;
    final totalPages = pageMap?.totalPages ?? 0;
    final source = _loadedDocument?.sourceAtIndex(page.sourceIndex);
    final sourceText = source?.text ?? page.text;
    final safeLocalStart = localStart.clamp(0, sourceText.length).toInt();
    final safeLocalEnd = localEnd.clamp(0, sourceText.length).toInt();
    final prefixStart = math.max(0, safeLocalStart - _anchorContextLength);
    final suffixEnd = math.min(sourceText.length, safeLocalEnd + _anchorContextLength);
    final progress = totalPages <= 0
        ? 0.0
        : (page.pageNumber / totalPages).clamp(0.0, 1.0).toDouble();

    return 'epub:page=${page.pageNumber};'
        'totalPages=$totalPages;'
        'chapter=${page.sourceIndex};'
        'path=${_encodeLocationValue(page.chapterPath)};'
        'localStart=$safeLocalStart;'
        'localEnd=$safeLocalEnd;'
        'anchor=${_encodeLocationValue(anchorText)};'
        'prefix=${_encodeLocationValue(sourceText.substring(prefixStart, safeLocalStart))};'
        'suffix=${_encodeLocationValue(sourceText.substring(safeLocalEnd, suffixEnd))};'
        'layout=${_encodeLocationValue(pageMap?.layout.cacheKey ?? '')};'
        'progress=${progress.toStringAsFixed(4)}';
  }

  String _anchorTextAt(EpubVirtualPage page) {
    final source = _loadedDocument?.sourceAtIndex(page.sourceIndex);
    final sourceText = source?.text ?? page.text;
    final localIndex = page.localStart.clamp(0, sourceText.length).toInt();
    final end = math.min(sourceText.length, localIndex + _anchorTextLength);
    return sourceText.substring(localIndex, end);
  }

  String _encodeLocationValue(String value) => Uri.encodeComponent(value);
}

_EpubDocument _extractEpubDocumentFromBytes(List<int> bytes) {
  final archive = ZipDecoder().decodeBytes(bytes, verify: false);
  final files = <String, ArchiveFile>{
    for (final file in archive.files) _normalizeZipPath(file.name): file,
  };
  final htmlPaths = files.keys.where(_isHtmlFile).toSet();
  if (htmlPaths.isEmpty) return const _EpubDocument(sources: []);

  final orderedPaths = _orderedHtmlPaths(files, htmlPaths);
  final paths = orderedPaths.isEmpty
      ? (htmlPaths.toList()..sort())
      : [
          ...orderedPaths,
          ...(htmlPaths.difference(orderedPaths.toSet()).toList()..sort()),
        ];
  final sources = <_EpubChapterSource>[];
  var bookCursor = 0;

  for (final path in paths) {
    final file = files[path];
    if (file == null || !file.isFile) continue;
    final content = file.content;
    if (content is! List<int>) continue;

    final text = _plainTextFromHtml(utf8.decode(content, allowMalformed: true));
    if (text.isEmpty) continue;

    sources.add(
      _EpubChapterSource(
        index: sources.length,
        path: path,
        text: text,
        bookStartOffset: bookCursor,
      ),
    );
    bookCursor += text.length + 2;
  }

  return _EpubDocument(sources: sources);
}

List<String> _orderedHtmlPaths(Map<String, ArchiveFile> files, Set<String> htmlPaths) {
  final opfPath = _packagePath(files);
  if (opfPath == null) return const [];
  final opfContent = files[opfPath]?.content;
  if (opfContent is! List<int>) return const [];

  final opf = utf8.decode(opfContent, allowMalformed: true);
  final packageDir = _dirname(opfPath);
  final manifest = <String, String>{};

  for (final match in RegExp(r'<item\b[^>]*>', caseSensitive: false).allMatches(opf)) {
    final tag = match.group(0) ?? '';
    final id = _xmlAttribute(tag, 'id');
    final href = _xmlAttribute(tag, 'href');
    if (id == null || href == null) continue;
    final path = _resolveZipPath(packageDir, href);
    if (_isHtmlFile(path)) manifest[id] = path;
  }

  final ordered = <String>[];
  for (final match in RegExp(r'<itemref\b[^>]*>', caseSensitive: false).allMatches(opf)) {
    final idref = _xmlAttribute(match.group(0) ?? '', 'idref');
    final path = idref == null ? null : manifest[idref];
    if (path != null && htmlPaths.contains(path)) ordered.add(path);
  }
  return ordered;
}

String? _packagePath(Map<String, ArchiveFile> files) {
  final container = files['META-INF/container.xml']?.content;
  if (container is List<int>) {
    final xml = utf8.decode(container, allowMalformed: true);
    final match = RegExp(
      r'''full-path\s*=\s*["']([^"']+)["']''',
      caseSensitive: false,
    ).firstMatch(xml);
    final path = match?.group(1);
    if (path != null) return _normalizeZipPath(path);
  }

  for (final path in files.keys) {
    if (path.toLowerCase().endsWith('.opf')) return path;
  }
  return null;
}

String? _xmlAttribute(String tag, String name) {
  final pattern = RegExp.escape(name) + r'''\s*=\s*["']([^"']+)["']''';
  final match = RegExp(pattern, caseSensitive: false).firstMatch(tag);
  return match?.group(1);
}

String _resolveZipPath(String baseDir, String href) {
  final path = href.split('#').first.split('?').first;
  return _normalizeZipPath(baseDir.isEmpty ? path : '$baseDir/$path');
}

String _dirname(String path) {
  final index = path.lastIndexOf('/');
  return index <= 0 ? '' : path.substring(0, index);
}

String _normalizeZipPath(String path) {
  final parts = <String>[];
  for (final part in path.replaceAll('\\', '/').split('/')) {
    if (part.isEmpty || part == '.') continue;
    if (part == '..') {
      if (parts.isNotEmpty) parts.removeLast();
      continue;
    }
    parts.add(part);
  }
  return parts.join('/');
}

bool _isHtmlFile(String name) {
  final lowerName = name.toLowerCase();
  return lowerName.endsWith('.html') ||
      lowerName.endsWith('.htm') ||
      lowerName.endsWith('.xhtml');
}

String _plainTextFromHtml(String html) {
  return html
      .replaceAll(RegExp(r'<(script|style)[^>]*>.*?</\1>', dotAll: true), '')
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(
        RegExp(r'</(p|div|h[1-6]|li|section|article|chapter)>', caseSensitive: false),
        '\n',
      )
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
        final codePoint = int.tryParse(match.group(1) ?? '');
        return codePoint == null ? match.group(0) ?? '' : String.fromCharCode(codePoint);
      })
      .replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (match) {
        final codePoint = int.tryParse(match.group(1) ?? '', radix: 16);
        return codePoint == null ? match.group(0) ?? '' : String.fromCharCode(codePoint);
      })
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&#39;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n')
      .trim();
}

class _EpubDocument {
  const _EpubDocument({required this.sources});

  final List<_EpubChapterSource> sources;

  bool get isEmpty => sources.isEmpty || textLength <= 0;

  int get textLength {
    if (sources.isEmpty) return 0;
    final last = sources.last;
    return last.bookStartOffset + last.text.length;
  }

  String get cacheSeed {
    return sources.map((source) => '${source.path}:${source.text.length}').join('|');
  }

  _EpubChapterSource? sourceAtIndex(int index) {
    if (index < 0 || index >= sources.length) return null;
    return sources[index];
  }

  _EpubChapterSource? sourceForPath(String path) {
    for (final source in sources) {
      if (source.path == path) return source;
    }
    return null;
  }
}

class _EpubChapterSource {
  const _EpubChapterSource({
    required this.index,
    required this.path,
    required this.text,
    required this.bookStartOffset,
  });

  final int index;
  final String path;
  final String text;
  final int bookStartOffset;
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
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      ),
    );
  }
}
