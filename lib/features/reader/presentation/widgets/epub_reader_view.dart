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
    return false;
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
    final progressPercent = progress.clamp(0.0, 1.0) * 100;
    return progressPercent.clamp(0, 100).floor();
  }

  String get label => 'Progress $percent%';
}

class EpubSourceLocation {
  const EpubSourceLocation({
    required this.chapterPath,
    required this.sourceIndex,
    required this.localOffset,
    required this.globalOffset,
  });

  final String chapterPath;
  final int sourceIndex;
  final int localOffset;
  final int globalOffset;
}

class EpubSourceRange {
  const EpubSourceRange({
    required this.start,
    required this.end,
  });

  final EpubSourceLocation start;
  final EpubSourceLocation end;

  String get chapterPath => start.chapterPath;
  int get sourceIndex => start.sourceIndex;
  int get localStart => start.localOffset;
  int get localEnd => end.localOffset;
  int get globalStartOffset => start.globalOffset;
  int get globalEndOffset => end.globalOffset;
}

class _EpubReaderViewState extends State<EpubReaderView> {
  static const _horizontalPadding = 24.0;
  static const _topPadding = 40.0;
  static const _bottomPadding = 96.0;
  static const _chapterSpacing = 32.0;
  static const _visibleProbeInset = 72.0;
  static const _anchorContextLength = 48;
  static const _anchorTextLength = 80;
  static const _sameChapterSearchRadius = 5000;
  static const _contextExactScore = 8;
  static const _contextSoftScore = 3;
  static const _contextWeakScore = 1;
  static const _maxInitialAnnotationAttempts = 3;

  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _chapterKeys = {};

  late Future<_EpubSourceModel> _document;
  _EpubSourceModel? _loadedDocument;
  EpubSourceRange? _activeSourceRange;
  EpubSourceRange? _pendingRestoreRange;
  String? _handledInitialAnnotationId;
  int _initialAnnotationAttempts = 0;
  int? _lastNotifiedSourceOffset;

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
    _scrollController.addListener(_notifyPositionChanged);
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
      _activeSourceRange = null;
      _pendingRestoreRange = null;
      _handledInitialAnnotationId = null;
      _initialAnnotationAttempts = 0;
      _lastNotifiedSourceOffset = null;
      _chapterKeys.clear();
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
      widget.onProgressChanged?.call(0);
      widget.onPositionChanged?.call(
        const EpubReaderPosition(
          progress: 0,
          locationRef: 'epub:sourceOffset=0;sourceLength=0;progress=0.0000',
          currentPage: 1,
          totalPages: 1,
        ),
      );
    } else if (_typographyChanged(oldWidget)) {
      _pendingRestoreRange = _currentVisibleSourceRange();
      _schedulePendingRestore();
    }

    if (oldWidget.initialAnnotation?.id != widget.initialAnnotation?.id) {
      _handledInitialAnnotationId = null;
      _initialAnnotationAttempts = 0;
      _scheduleInitialAnnotationJump();
    }
  }

  @override
  void dispose() {
    widget.controller?._state = null;
    _scrollController
      ..removeListener(_notifyPositionChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_EpubSourceModel>(
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

        if (!identical(_loadedDocument, document)) {
          _loadedDocument = document;
          _activeSourceRange = document.rangeAtStart;
          _pendingRestoreRange = null;
          _handledInitialAnnotationId = null;
          _initialAnnotationAttempts = 0;
          _lastNotifiedSourceOffset = null;
          _ensureChapterKeys(document);
          _schedulePositionUpdate();
          _scheduleInitialAnnotationJump();
        }

        _ensureChapterKeys(document);
        _schedulePendingRestore();

        return Scrollbar(
          controller: _scrollController,
          child: SingleChildScrollView(
            controller: _scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              children: [
                for (final source in document.sources)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      _horizontalPadding,
                      source.index == 0 ? _topPadding : _chapterSpacing,
                      _horizontalPadding,
                      source.index == document.sources.length - 1 ? _bottomPadding : 0,
                    ),
                    child: Align(
                      key: _chapterKeys[source.index],
                      alignment: Alignment.topCenter,
                      child: ReaderContent(
                        text: source.text,
                        annotations: _annotationsForSource(source),
                        textColor: widget.textColor,
                        fontSize: widget.fontSize,
                        lineHeight: widget.lineHeight,
                        maxWidth: widget.maxWidth,
                        textScaler: MediaQuery.textScalerOf(context),
                        focusedAnnotationId: widget.focusedAnnotationId,
                        annotationStartOffset: (annotation) {
                          return _annotationLocalStartForSource(annotation, source);
                        },
                        annotationEndOffset: (annotation) {
                          return _annotationLocalEndForSource(annotation, source);
                        },
                        onSelectionChanged: (selection) {
                          _handleSelectionChanged(source, selection);
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _typographyChanged(EpubReaderView oldWidget) {
    return oldWidget.fontSize != widget.fontSize ||
        oldWidget.lineHeight != widget.lineHeight ||
        oldWidget.maxWidth != widget.maxWidth;
  }

  Future<_EpubSourceModel> _loadDocument() async {
    final file = File(widget.filePath);
    if (!await file.exists()) throw StateError('File not found');
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return const _EpubSourceModel(sources: []);
    return compute(_extractEpubDocumentFromBytes, bytes);
  }

  void _ensureChapterKeys(_EpubSourceModel document) {
    for (final source in document.sources) {
      _chapterKeys.putIfAbsent(source.index, GlobalKey.new);
    }
  }

  List<ReaderAnnotation> _annotationsForSource(_EpubChapterSource source) {
    if (widget.annotations.isEmpty) return const [];

    final annotations = <ReaderAnnotation>[];
    final document = _loadedDocument;
    if (document == null) return annotations;

    for (final annotation in widget.annotations) {
      if (!annotation.canHighlightText) continue;

      final range = _resolveAnnotationRange(annotation, document);
      if (range == null || range.sourceIndex != source.index) continue;
      if (range.localEnd > 0 && range.localStart < source.text.length) {
        annotations.add(annotation);
      }
    }

    return annotations;
  }

  int? _annotationLocalStartForSource(
    ReaderAnnotation annotation,
    _EpubChapterSource source,
  ) {
    final range = _resolveAnnotationRange(annotation, _loadedDocument);
    if (range == null || range.sourceIndex != source.index) return null;
    return range.localStart.clamp(0, source.text.length).toInt();
  }

  int? _annotationLocalEndForSource(
    ReaderAnnotation annotation,
    _EpubChapterSource source,
  ) {
    final range = _resolveAnnotationRange(annotation, _loadedDocument);
    if (range == null || range.sourceIndex != source.index) return null;
    return range.localEnd.clamp(range.localStart, source.text.length).toInt();
  }

  void _handleSelectionChanged(
    _EpubChapterSource source,
    ReaderSelection? selection,
  ) {
    if (selection == null) {
      widget.onSelectionChanged(null);
      return;
    }

    final range = _loadedDocument?.sourceRangeFor(
      source: source,
      localStart: selection.startIndex,
      localEnd: selection.endIndex,
    );
    if (range == null) {
      widget.onSelectionChanged(null);
      return;
    }

    widget.onSelectionChanged(
      ReaderSelection(
        text: selection.text,
        startIndex: range.localStart,
        endIndex: range.localEnd,
        locationRef: _locationRefForRange(
          range: range,
          anchorText: selection.text,
        ),
      ),
    );
  }

  void _scheduleInitialAnnotationJump() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleInitialAnnotation());
  }

  void _handleInitialAnnotation() {
    if (!mounted) return;
    final annotation = widget.initialAnnotation;
    final document = _loadedDocument;
    if (annotation == null ||
        document == null ||
        document.isEmpty ||
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
    if (document == null || document.isEmpty) return false;

    final range = _resolveAnnotationRange(annotation, document);
    if (range == null) return false;

    _activeSourceRange = range;
    return _scrollToSourceLocation(range.start);
  }

  bool _jumpToProgress(double progress) {
    final document = _loadedDocument;
    if (document == null || document.isEmpty) return false;

    final location = document.sourceLocationForProgress(progress);
    if (location == null) return false;

    final range = document.sourceRangeFor(
      source: location.source,
      localStart: location.localOffset,
      localEnd: location.localOffset,
    );
    _activeSourceRange = range;
    return _scrollToSourceLocation(range.start);
  }

  bool _scrollToSourceLocation(EpubSourceLocation location) {
    final document = _loadedDocument;
    if (document == null || !_scrollController.hasClients) return false;

    final source = document.sourceAtIndex(location.sourceIndex);
    final key = _chapterKeys[location.sourceIndex];
    final targetContext = key?.currentContext;
    if (source == null || targetContext == null) return false;

    final box = targetContext.findRenderObject() as RenderBox?;
    final scrollBox = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || scrollBox == null || !scrollBox.hasSize) {
      return false;
    }

    final textWidth = math.min(box.size.width, widget.maxWidth);
    if (textWidth <= 0) return false;

    final localOffset = location.localOffset.clamp(0, source.text.length).toInt();
    final textPainter = _textPainter(source.text, textWidth);
    final caretOffset = textPainter.getOffsetForCaret(
      TextPosition(offset: localOffset),
      Rect.zero,
    );
    final chapterTop = box.localToGlobal(Offset.zero).dy -
        scrollBox.localToGlobal(Offset.zero).dy +
        _scrollController.offset;
    final target = chapterTop + caretOffset.dy - _visibleProbeInset;
    final safeTarget = target
        .clamp(0.0, _scrollController.position.maxScrollExtent)
        .toDouble();

    _scrollController.animateTo(
      safeTarget,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
    _schedulePositionUpdate();
    return true;
  }

  EpubSourceRange? _resolveAnnotationRange(
    ReaderAnnotation annotation,
    _EpubSourceModel? document,
  ) {
    if (document == null || document.isEmpty) return null;

    final source = _sourceForAnnotation(document, annotation);
    final localStart = annotation.epubLocalStartIndex;
    if (source != null && localStart != null) {
      final safeStart = localStart.clamp(0, source.text.length).toInt();
      final safeEnd = (annotation.epubLocalEndIndex ?? safeStart)
          .clamp(safeStart, source.text.length)
          .toInt();
      final direct = document.sourceRangeFor(
        source: source,
        localStart: safeStart,
        localEnd: safeEnd,
      );
      final anchorText = _anchorTextFor(annotation);
      final prefixText = annotation.epubPrefixText ?? '';
      final suffixText = annotation.epubSuffixText ?? '';

      if (_sourceMatchesAnchor(
        source: source,
        localIndex: safeStart,
        anchorText: anchorText,
        prefixText: prefixText,
        suffixText: suffixText,
      )) {
        return direct;
      }

      final recoveredOffset = _recoverLocalOffsetFromContext(
        source: source,
        expectedLocalStart: localStart,
        anchorText: anchorText,
        prefixText: prefixText,
        suffixText: suffixText,
      );
      if (recoveredOffset != null) {
        final recoveredLength = math.max(
          math.max(0, safeEnd - safeStart),
          anchorText.length,
        );
        return document.sourceRangeFor(
          source: source,
          localStart: recoveredOffset.clamp(0, source.text.length).toInt(),
          localEnd: (recoveredOffset + recoveredLength)
              .clamp(recoveredOffset, source.text.length)
              .toInt(),
        );
      }

      return direct;
    }

    final sourceOffset = annotation.epubSourceOffset;
    if (sourceOffset != null) {
      final location = document.sourceLocationForOffset(sourceOffset);
      if (location == null) return null;

      return document.sourceRangeFor(
        source: location.source,
        localStart: location.localOffset,
        localEnd: location.localOffset,
      );
    }

    final progress = annotation.epubProgress;
    if (progress != null) {
      final location = document.sourceLocationForProgress(progress);
      if (location == null) return null;

      return document.sourceRangeFor(
        source: location.source,
        localStart: location.localOffset,
        localEnd: location.localOffset,
      );
    }

    return null;
  }

  _EpubChapterSource? _sourceForAnnotation(
    _EpubSourceModel document,
    ReaderAnnotation annotation,
  ) {
    final path = annotation.epubChapterPath;
    if (path != null && path.isNotEmpty) {
      final byPath = document.sourceForPath(path);
      if (byPath != null) return byPath;
    }

    final chapterIndex = annotation.epubChapterIndex;
    return chapterIndex == null ? null : document.sourceAtIndex(chapterIndex);
  }

  bool _sourceMatchesAnchor({
    required _EpubChapterSource source,
    required int localIndex,
    required String anchorText,
    required String prefixText,
    required String suffixText,
  }) {
    if (anchorText.isEmpty) return true;
    if (localIndex < 0 || localIndex >= source.text.length) return false;

    final anchorEnd = math.min(source.text.length, localIndex + anchorText.length);
    final actualAnchor = source.text.substring(localIndex, anchorEnd);
    if (actualAnchor == anchorText) return true;
    if (_normalizedAnchor(actualAnchor) != _normalizedAnchor(anchorText)) {
      return false;
    }
    if (_normalizedAnchor(anchorText).length >= 12) return true;

    return _anchorContextScore(
          sourceText: source.text,
          localIndex: localIndex,
          anchorText: actualAnchor,
          prefixText: prefixText,
          suffixText: suffixText,
        ) > 0;
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

    final exactMatches = <int>[];
    var localIndex = source.text.indexOf(anchorText, searchStart);
    while (localIndex >= 0 && localIndex < searchEnd) {
      exactMatches.add(localIndex);
      localIndex = source.text.indexOf(
        anchorText,
        localIndex + math.max(anchorText.length, 1),
      );
    }

    final candidates = exactMatches.isEmpty
        ? _normalizedAnchorCandidates(
            sourceText: source.text,
            anchorText: anchorText,
            searchStart: searchStart,
            searchEnd: searchEnd,
          )
        : exactMatches;
    if (candidates.isEmpty) return null;

    int? bestIndex;
    var bestScore = -1;
    for (final localIndex in candidates) {
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
        score += _contextExactScore;
      } else if (_normalizedAnchor(actualPrefix).endsWith(_normalizedAnchor(prefixText))) {
        score += _contextSoftScore;
      } else if (actualPrefix.trimRight().endsWith(prefixText.trim())) {
        score += _contextWeakScore;
      }
    }
    if (suffixText.isNotEmpty) {
      final suffixStart = localIndex + anchorText.length;
      final suffixEnd = math.min(sourceText.length, suffixStart + suffixText.length);
      final actualSuffix = sourceText.substring(suffixStart, suffixEnd);
      if (actualSuffix == suffixText) {
        score += _contextExactScore;
      } else if (_normalizedAnchor(actualSuffix).startsWith(_normalizedAnchor(suffixText))) {
        score += _contextSoftScore;
      } else if (actualSuffix.trimLeft().startsWith(suffixText.trim())) {
        score += _contextWeakScore;
      }
    }
    return score;
  }

  List<int> _normalizedAnchorCandidates({
    required String sourceText,
    required String anchorText,
    required int searchStart,
    required int searchEnd,
  }) {
    final normalizedNeedle = _normalizedAnchor(anchorText);
    if (normalizedNeedle.length < 12) return const [];

    final windowStart = searchStart.clamp(0, sourceText.length).toInt();
    final windowEnd = searchEnd.clamp(windowStart, sourceText.length).toInt();
    final candidates = <int>[];
    final step = math.max(1, anchorText.length ~/ 3);
    for (var index = windowStart; index < windowEnd; index += step) {
      final end = math.min(sourceText.length, index + anchorText.length + 24);
      final normalizedWindow = _normalizedAnchor(sourceText.substring(index, end));
      if (normalizedWindow.startsWith(normalizedNeedle)) candidates.add(index);
    }
    return candidates;
  }

  String _normalizedAnchor(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _anchorTextFor(ReaderAnnotation annotation) {
    final storedAnchor = annotation.epubAnchorText;
    if (storedAnchor != null && storedAnchor.isNotEmpty) return storedAnchor;
    if (annotation.isBookmark || annotation.isReaderState) return '';
    return annotation.selectedText.trim();
  }

  void _schedulePendingRestore() {
    final range = _pendingRestoreRange;
    if (range == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pending = _pendingRestoreRange;
      if (pending == null) return;

      _pendingRestoreRange = null;
      _scrollToSourceLocation(pending.start);
    });
  }

  void _schedulePositionUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _notifyPositionChanged();
    });
  }

  void _notifyPositionChanged() {
    final range = _currentVisibleSourceRange();
    if (range == null) return;

    _activeSourceRange = range;
    if (_lastNotifiedSourceOffset == range.globalStartOffset) return;
    _lastNotifiedSourceOffset = range.globalStartOffset;

    final progress = _progressForRange(range);
    final locationRef = _locationRefForRange(
      range: range,
      anchorText: _anchorTextAt(range),
    );

    widget.onProgressChanged?.call(progress);
    widget.onPositionChanged?.call(
      EpubReaderPosition(
        progress: progress,
        locationRef: locationRef,
        currentPage: range.sourceIndex + 1,
        totalPages: _loadedDocument?.sources.length ?? 1,
      ),
    );
  }

  EpubSourceRange? _currentVisibleSourceRange() {
    final document = _loadedDocument;
    if (document == null || document.isEmpty) return null;

    if (!_scrollController.hasClients) {
      return _activeSourceRange ?? document.rangeAtStart;
    }

    final position = _scrollController.position;
    if ((position.maxScrollExtent - position.pixels).abs() <= 1) {
      return document.rangeAtEnd;
    }

    final scrollBox = context.findRenderObject() as RenderBox?;
    if (scrollBox == null || !scrollBox.hasSize) {
      return _activeSourceRange ?? document.rangeAtStart;
    }

    final viewportTop = scrollBox.localToGlobal(Offset.zero).dy;
    final viewportHeight = position.viewportDimension;
    final probeY = viewportTop + math.min(_visibleProbeInset, viewportHeight * 0.35);

    _EpubChapterSource? closestSource;
    double closestDistance = double.infinity;

    for (final source in document.sources) {
      final keyContext = _chapterKeys[source.index]?.currentContext;
      final box = keyContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;

      final top = box.localToGlobal(Offset.zero).dy;
      final bottom = top + box.size.height;
      if (probeY >= top && probeY <= bottom) {
        final localOffset = _localOffsetForY(
          source: source,
          localY: probeY - top,
          textWidth: math.min(box.size.width, widget.maxWidth),
        );
        return document.sourceRangeFor(
          source: source,
          localStart: localOffset,
          localEnd: localOffset,
        );
      }

      final distance = probeY < top ? top - probeY : probeY - bottom;
      if (distance < closestDistance) {
        closestDistance = distance;
        closestSource = source;
      }
    }

    final source = closestSource ?? document.sources.first;
    final offset = position.pixels <= 0 ? 0 : source.text.length;
    return document.sourceRangeFor(
      source: source,
      localStart: offset,
      localEnd: offset,
    );
  }

  int _localOffsetForY({
    required _EpubChapterSource source,
    required double localY,
    required double textWidth,
  }) {
    if (source.text.isEmpty || textWidth <= 0) return 0;

    final textPainter = _textPainter(source.text, textWidth);
    final safeY = localY.clamp(0.0, textPainter.height).toDouble();
    final position = textPainter.getPositionForOffset(Offset(0, safeY));
    return position.offset.clamp(0, source.text.length).toInt();
  }

  TextPainter _textPainter(String text, double maxWidth) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: widget.fontSize,
          height: widget.lineHeight,
          letterSpacing: 0,
        ),
      ),
      textAlign: TextAlign.start,
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: maxWidth);
  }

  String? _currentLocationRef() {
    final range = _currentVisibleSourceRange();
    if (range == null) return null;

    return _locationRefForRange(
      range: range,
      anchorText: _anchorTextAt(range),
    );
  }

  String _locationRefForRange({
    required EpubSourceRange range,
    required String anchorText,
  }) {
    final document = _loadedDocument;
    final source = document?.sourceAtIndex(range.sourceIndex);
    final sourceText = source?.text ?? '';
    final safeLocalStart = range.localStart.clamp(0, sourceText.length).toInt();
    final safeLocalEnd = range.localEnd.clamp(safeLocalStart, sourceText.length).toInt();
    final prefixStart = math.max(0, safeLocalStart - _anchorContextLength);
    final suffixEnd = math.min(sourceText.length, safeLocalEnd + _anchorContextLength);
    final sourceLength = document?.textLength ?? 0;
    final progress = _progressForRange(range);

    return 'epub:chapter=${range.sourceIndex};'
        'path=${_encodeLocationValue(range.chapterPath)};'
        'localStart=$safeLocalStart;'
        'localEnd=$safeLocalEnd;'
        'sourceOffset=${range.globalStartOffset};'
        'sourceLength=$sourceLength;'
        'anchor=${_encodeLocationValue(anchorText)};'
        'prefix=${_encodeLocationValue(sourceText.substring(prefixStart, safeLocalStart))};'
        'suffix=${_encodeLocationValue(sourceText.substring(safeLocalEnd, suffixEnd))};'
        'progress=${progress.toStringAsFixed(4)}';
  }

  double _progressForRange(EpubSourceRange range) {
    final document = _loadedDocument;
    final source = document?.sourceAtIndex(range.sourceIndex);
    if (document == null || source == null) return 0.0;

    return document.progressForSourceLocation(
      source: source,
      localOffset: range.localStart,
    );
  }

  String _anchorTextAt(EpubSourceRange range) {
    final source = _loadedDocument?.sourceAtIndex(range.sourceIndex);
    final sourceText = source?.text ?? '';
    final localIndex = range.localStart.clamp(0, sourceText.length).toInt();
    final end = math.min(sourceText.length, localIndex + _anchorTextLength);
    return sourceText.substring(localIndex, end);
  }

  String _encodeLocationValue(String value) => Uri.encodeComponent(value);
}

_EpubSourceModel _extractEpubDocumentFromBytes(List<int> bytes) {
  final archive = ZipDecoder().decodeBytes(bytes, verify: false);
  final files = <String, ArchiveFile>{
    for (final file in archive.files) _normalizeZipPath(file.name): file,
  };
  final htmlPaths = files.keys.where(_isHtmlFile).toSet();
  if (htmlPaths.isEmpty) return const _EpubSourceModel(sources: []);

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
    bookCursor += text.length;
  }

  return _EpubSourceModel(sources: sources);
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

class _EpubSourceModel {
  const _EpubSourceModel({required this.sources});

  final List<_EpubChapterSource> sources;

  bool get isEmpty => sources.isEmpty || textLength <= 0;

  int get textLength {
    if (sources.isEmpty) return 0;
    final last = sources.last;
    return last.bookStartOffset + last.text.length;
  }

  EpubSourceRange get rangeAtStart {
    final source = sources.first;
    return sourceRangeFor(source: source, localStart: 0, localEnd: 0);
  }

  EpubSourceRange get rangeAtEnd {
    final source = sources.last;
    return sourceRangeFor(
      source: source,
      localStart: source.text.length,
      localEnd: source.text.length,
    );
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

  _EpubSourceLocation? sourceLocationForProgress(double progress) {
    if (isEmpty || progress.isNaN) return null;

    final clamped = progress.isFinite
        ? progress.clamp(0.0, 1.0).toDouble()
        : progress.isNegative
            ? 0.0
            : 1.0;
    final sourceOffset = clamped >= 1.0
        ? textLength
        : (textLength * clamped).floor().clamp(0, textLength).toInt();
    return sourceLocationForOffset(sourceOffset);
  }

  _EpubSourceLocation? sourceLocationForOffset(int sourceOffset) {
    if (isEmpty) return null;

    final safeOffset = sourceOffset.clamp(0, textLength).toInt();
    _EpubChapterSource? previousSource;

    for (var index = 0; index < sources.length; index++) {
      final source = sources[index];
      if (safeOffset < source.bookStartOffset) {
        if (previousSource == null) {
          return _EpubSourceLocation(source: source, localOffset: 0);
        }
        return _EpubSourceLocation(
          source: previousSource,
          localOffset: previousSource.text.length,
        );
      }

      final sourceEndOffset = source.bookStartOffset + source.text.length;
      final isLastSource = index == sources.length - 1;
      if (safeOffset < sourceEndOffset || (isLastSource && safeOffset <= sourceEndOffset)) {
        return _EpubSourceLocation(
          source: source,
          localOffset: (safeOffset - source.bookStartOffset)
              .clamp(0, source.text.length)
              .toInt(),
        );
      }

      previousSource = source;
    }

    final last = sources.last;
    return _EpubSourceLocation(source: last, localOffset: last.text.length);
  }

  double progressForSourceLocation({
    required _EpubChapterSource source,
    required int localOffset,
  }) {
    if (textLength <= 0) return 0.0;

    final safeLocalOffset = localOffset.clamp(0, source.text.length).toInt();
    final sourceOffset = source.bookStartOffset + safeLocalOffset;
    return (sourceOffset / textLength).clamp(0.0, 1.0).toDouble();
  }

  EpubSourceRange sourceRangeFor({
    required _EpubChapterSource source,
    required int localStart,
    required int localEnd,
  }) {
    final safeStart = localStart.clamp(0, source.text.length).toInt();
    final safeEnd = localEnd.clamp(safeStart, source.text.length).toInt();
    final start = EpubSourceLocation(
      chapterPath: source.path,
      sourceIndex: source.index,
      localOffset: safeStart,
      globalOffset: source.bookStartOffset + safeStart,
    );
    final end = EpubSourceLocation(
      chapterPath: source.path,
      sourceIndex: source.index,
      localOffset: safeEnd,
      globalOffset: source.bookStartOffset + safeEnd,
    );

    return EpubSourceRange(start: start, end: end);
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

class _EpubSourceLocation {
  const _EpubSourceLocation({
    required this.source,
    required this.localOffset,
  });

  final _EpubChapterSource source;
  final int localOffset;
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
