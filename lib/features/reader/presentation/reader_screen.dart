import 'dart:async';

import 'package:flutter/material.dart';

import '../../library/domain/book.dart';
import '../domain/annotation_repository.dart';
import '../domain/reader_annotation.dart';
import 'models/reader_theme_mode.dart';
import 'widgets/add_note_sheet.dart';
import 'widgets/epub_reader_view.dart';
import 'widgets/pdf_reader_view.dart';
import 'widgets/reader_annotations_section.dart';
import 'widgets/reader_content.dart';
import 'widgets/reader_controls_sheet.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({
    required this.book,
    required this.annotationRepository,
    this.initialAnnotation,
    super.key,
  });

  final Book book;
  final AnnotationRepository annotationRepository;
  final ReaderAnnotation? initialAnnotation;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  static const _maxInitialAnnotationAttempts = 5;
  static const _readingPositionSaveDelay = Duration(milliseconds: 900);

  final ScrollController _scrollController = ScrollController();
  final EpubReaderController _epubReaderController = EpubReaderController();
  final PdfReaderController _pdfReaderController = PdfReaderController();

  double _fontSize = 15;
  double _lineHeight = 1.7;
  bool _isWideText = false;
  ReaderSelection? _selection;
  String? _focusedAnnotationId;
  String? _annotationFeedback;
  ReaderAnnotation? _openingTarget;
  bool _didHandleInitialAnnotation = false;
  int _initialAnnotationAttempts = 0;
  final ValueNotifier<double> _readingProgress = ValueNotifier<double>(0);
  final ValueNotifier<String> _positionLabel = ValueNotifier<String>(
    '0%',
  );
  ReaderThemeMode _themeMode = ReaderThemeMode.light;

  double get _textMaxWidth => _isWideText ? 760 : 620;
  String get _readerText => _mockReaderContent(widget.book);
  BookFileType get _sourceType {
    if (!widget.book.isDocumentBacked) return BookFileType.plainText;

    return widget.book.sourceType;
  }

  bool get _usesTextReader => _sourceType == BookFileType.plainText;
  bool get _blocksBackForSelection =>
      _sourceType != BookFileType.pdf && _selection != null;
  bool get _supportsTypographyControls => _sourceType != BookFileType.pdf;
  bool get _supportsTextWidthControls => _sourceType != BookFileType.pdf;
  String get _bookmarkId => 'bookmark:${widget.book.id}';
  String get _readingPositionId => 'reading-position:${widget.book.id}';
  String? _currentLocationRef;
  double _currentProgress = 0;
  int _currentPdfPage = 1;
  int _currentPdfTotalPages = 0;
  String? _lastSavedLocationRef;
  String? _pendingReadingLocationRef;
  Timer? _readingPositionSaveTimer;
  Timer? _focusedAnnotationTimer;
  Timer? _annotationFeedbackTimer;
  int _annotationHydrationGeneration = 0;

  @override
  void initState() {
    super.initState();
    _openingTarget = _resolveOpeningTarget();
    _scrollController.addListener(_updateReadingProgress);
    _updateReadingProgressAfterLayout();
    if (_usesTextReader) _scheduleInitialAnnotationJump();
    _scheduleAnnotationHydration();
  }

  @override
  void didUpdateWidget(covariant ReaderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialAnnotation?.id != widget.initialAnnotation?.id) {
      _openingTarget = _resolveOpeningTarget();
      _didHandleInitialAnnotation = false;
      _initialAnnotationAttempts = 0;
      if (_usesTextReader) _scheduleInitialAnnotationJump();
    }
    if (oldWidget.annotationRepository != widget.annotationRepository ||
        oldWidget.book.id != widget.book.id) {
      _scheduleAnnotationHydration();
    }
  }

  @override
  void dispose() {
    _readingPositionSaveTimer?.cancel();
    _focusedAnnotationTimer?.cancel();
    _annotationFeedbackTimer?.cancel();
    _commitReadingPosition();
    _scrollController
      ..removeListener(_updateReadingProgress)
      ..dispose();
    _readingProgress.dispose();
    _positionLabel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = _themeMode;

    return Theme(
      data: Theme.of(context).copyWith(
        brightness: mode.brightness,
        scaffoldBackgroundColor: mode.backgroundColor,
        appBarTheme: AppBarTheme(
          backgroundColor: mode.backgroundColor,
          foregroundColor: mode.textColor,
          elevation: 0,
          centerTitle: false,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      child: PopScope(
        canPop: !_blocksBackForSelection,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && _blocksBackForSelection) {
            _clearSelection();
          }
        },
        child: Scaffold(
          backgroundColor: mode.backgroundColor,
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.book.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.book.displayAuthor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: mode.mutedColor),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: _openBookAnnotations,
                icon: const Icon(Icons.notes_rounded),
                tooltip: 'Notes and highlights',
              ),
              PopupMenuButton<_ReaderOverflowAction>(
              tooltip: 'Reader options',
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: _handleReaderOverflowAction,
              itemBuilder: (context) {
                final hasBookmark = _bookmarkAnnotation() != null;

                return [
                  PopupMenuItem<_ReaderOverflowAction>(
                    value: _ReaderOverflowAction.goToPosition,
                    child: Text(
                      _sourceType == BookFileType.pdf
                          ? 'Go to page'
                          : 'Go to progress',
                    ),
                  ),
                  const PopupMenuItem<_ReaderOverflowAction>(
                    value: _ReaderOverflowAction.saveBookmark,
                    child: Text('Save bookmark'),
                  ),
                  PopupMenuItem<_ReaderOverflowAction>(
                    value: _ReaderOverflowAction.goToBookmark,
                    enabled: hasBookmark,
                    child: const Text('Go to bookmark'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<_ReaderOverflowAction>(
                    value: _ReaderOverflowAction.readingSettings,
                    child: Text('Reading settings'),
                  ),
                ];
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(2),
            child: ValueListenableBuilder<double>(
              valueListenable: _readingProgress,
              builder: (context, progress, _) {
                return LinearProgressIndicator(
                  value: progress,
                  minHeight: 2,
                  backgroundColor: mode.mutedColor.withValues(alpha: 0.12),
                  color: mode.textColor.withValues(alpha: 0.56),
                );
              },
            ),
          ),
        ),
        body: SafeArea(child: _buildReaderBody(mode)),
      ),
    ),
  );
}

  Widget _buildReaderBody(ReaderThemeMode mode) {
    final reader = switch (_sourceType) {
      BookFileType.pdf => ValueListenableBuilder<List<ReaderAnnotation>>(
        valueListenable: widget.annotationRepository.watchAnnotations(),
        builder: (context, annotations, _) {
          final bookAnnotations = _annotationsForCurrentBook(annotations)
              .where((annotation) => annotation.isUserAnnotation)
              .toList(growable: false);
          _syncDeletedAnnotationState(bookAnnotations);

          return PdfReaderView(
            filePath: widget.book.filePath,
            annotations: bookAnnotations,
            backgroundColor: mode.backgroundColor,
            controller: _pdfReaderController,
            initialPage: _openingTarget?.pdfPageNumber,
            onPositionChanged: _handlePdfPositionChanged,
            onSelectionChanged: _handleTextSelectionChanged,
            onSelectionFailure: _showReaderMessage,
          );
        },
      ),
      BookFileType.epub => ValueListenableBuilder<List<ReaderAnnotation>>(
        valueListenable: widget.annotationRepository.watchAnnotations(),
        builder: (context, annotations, _) {
          final bookAnnotations = _annotationsForCurrentBook(annotations)
              .where((annotation) => annotation.isUserAnnotation)
              .toList(growable: false);
          _syncDeletedAnnotationState(bookAnnotations);

          return EpubReaderView(
            filePath: widget.book.filePath,
            annotations: bookAnnotations,
            textColor: mode.textColor,
            fontSize: _fontSize,
            lineHeight: _lineHeight,
            maxWidth: _textMaxWidth,
            focusedAnnotationId: _focusedAnnotationId,
            controller: _epubReaderController,
            initialAnnotation: _openingTarget,
            onPositionChanged: _handleEpubPositionChanged,
            onSelectionChanged: _handleTextSelectionChanged,
          );
        },
      ),
      BookFileType.plainText => _buildTextReaderBody(mode),
    };

    if (_sourceType == BookFileType.plainText) return reader;

    return Stack(
      children: [
        reader,
        _ReaderEdgeFade(
          alignment: Alignment.topCenter,
          backgroundColor: mode.backgroundColor,
        ),
        _ReaderEdgeFade(
          alignment: Alignment.bottomCenter,
          backgroundColor: mode.backgroundColor,
        ),
        _buildAnnotationFeedback(mode),
        _buildPositionBadge(mode),
        _buildSelectionActionBar(mode),
      ],
    );
  }

  Widget _buildTextReaderBody(ReaderThemeMode mode) {
    return Stack(
      children: [
        Scrollbar(
          controller: _scrollController,
          child: SingleChildScrollView(
            controller: _scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 80),
            child: ValueListenableBuilder<List<ReaderAnnotation>>(
              valueListenable: widget.annotationRepository.watchAnnotations(),
              builder: (context, annotations, _) {
                final bookAnnotations = _annotationsForCurrentBook(
                  annotations,
                ).where((annotation) => annotation.isUserAnnotation).toList(
                  growable: false,
                );
                _syncDeletedAnnotationState(bookAnnotations);

                return Column(
                  children: [
                    ReaderContent(
                      text: _readerText,
                      annotations: bookAnnotations,
                      textColor: mode.textColor,
                      fontSize: _fontSize,
                      lineHeight: _lineHeight,
                      maxWidth: _textMaxWidth,
                      focusedAnnotationId: _focusedAnnotationId,
                      onSelectionChanged: _handleTextSelectionChanged,
                    ),
                    ReaderAnnotationsSection(
                      annotations: bookAnnotations,
                      textColor: mode.textColor,
                      mutedColor: mode.mutedColor,
                      surfaceColor: mode.textColor.withValues(alpha: 0.05),
                      borderColor: mode.textColor.withValues(alpha: 0.10),
                      maxWidth: _textMaxWidth,
                      onTap: scrollToAnnotation,
                      onDelete: _deleteAnnotation,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        _ReaderEdgeFade(
          alignment: Alignment.topCenter,
          backgroundColor: mode.backgroundColor,
        ),
        _ReaderEdgeFade(
          alignment: Alignment.bottomCenter,
          backgroundColor: mode.backgroundColor,
        ),
        _buildAnnotationFeedback(mode),
        _buildPositionBadge(mode),
        _buildSelectionActionBar(mode),
      ],
    );
  }

  Widget _buildPositionBadge(ReaderThemeMode mode) {
    return Positioned(
      top: 12,
      right: 16,
      child: SafeArea(
        child: ValueListenableBuilder<String>(
          valueListenable: _positionLabel,
          builder: (context, label, _) {
            return _ReaderPositionBadge(
              label: label,
              backgroundColor: mode.backgroundColor,
              textColor: mode.textColor,
              borderColor: mode.textColor.withValues(alpha: 0.12),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSelectionActionBar(ReaderThemeMode mode) {
    return _SelectionActionBar(
      isVisible: _selection != null,
      backgroundColor: mode.backgroundColor,
      textColor: mode.textColor,
      borderColor: mode.textColor.withValues(alpha: 0.12),
      onHighlight: _openHighlightSheet,
      onAddNote: _openAddNoteSheet,
      onDismiss: _clearSelection,
    );
  }

  Widget _buildAnnotationFeedback(ReaderThemeMode mode) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 86,
      child: SafeArea(
        child: _AnnotationFeedbackPill(
          message: _annotationFeedback,
          backgroundColor: mode.backgroundColor,
          textColor: mode.textColor,
          borderColor: mode.textColor.withValues(alpha: 0.10),
        ),
      ),
    );
  }

  List<ReaderAnnotation> _annotationsForCurrentBook(
    List<ReaderAnnotation> annotations,
  ) {
    return annotations
        .where((annotation) => annotation.bookId == widget.book.id)
        .toList(growable: false);
  }

  ReaderAnnotation? _resolveOpeningTarget() {
    final initial = widget.initialAnnotation;
    if (initial != null && initial.bookId == widget.book.id) return initial;

    return _readingPositionAnnotation();
  }

  void _scheduleAnnotationHydration() {
    if (widget.annotationRepository.isLoaded) return;

    final generation = ++_annotationHydrationGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _annotationHydrationGeneration) return;
      unawaited(_hydrateAnnotationsAfterOpen(generation));
    });
  }

  Future<void> _hydrateAnnotationsAfterOpen(int generation) async {
    await Future<void>.delayed(Duration.zero);
    try {
      await widget.annotationRepository.ensureLoaded();
    } catch (_) {
      return;
    }
    if (!mounted || generation != _annotationHydrationGeneration) return;

    final target = _resolveOpeningTarget();
    if (_sameOpeningTarget(_openingTarget, target)) return;

    setState(() {
      _openingTarget = target;
      _didHandleInitialAnnotation = false;
      _initialAnnotationAttempts = 0;
    });
    _scheduleInitialAnnotationJump();
  }

  bool _sameOpeningTarget(ReaderAnnotation? a, ReaderAnnotation? b) {
    return a?.id == b?.id && a?.locationRef == b?.locationRef;
  }

  ReaderAnnotation? _bookmarkAnnotation() {
    return _annotationById(_bookmarkId);
  }

  ReaderAnnotation? _readingPositionAnnotation() {
    return _annotationById(_readingPositionId);
  }

  ReaderAnnotation? _annotationById(String id) {
    for (final annotation in widget.annotationRepository.getAnnotations()) {
      if (annotation.bookId == widget.book.id && annotation.id == id) {
        return annotation;
      }
    }

    return null;
  }

  void _handleReaderOverflowAction(_ReaderOverflowAction action) {
    switch (action) {
      case _ReaderOverflowAction.goToPosition:
        _openDirectNavigation();
      case _ReaderOverflowAction.saveBookmark:
        _saveBookmark();
      case _ReaderOverflowAction.goToBookmark:
        _jumpToBookmark();
      case _ReaderOverflowAction.readingSettings:
        _openControls();
    }
  }

  void _saveBookmark() {
    final locationRef = _sourceType == BookFileType.epub
        ? _epubReaderController.currentLocationRef() ?? _currentLocationRef
        : _currentLocationRef;
    if (locationRef == null) {
      _showReaderMessage('Open a position before saving a bookmark');
      return;
    }

    final now = DateTime.now();
    widget.annotationRepository.addAnnotation(
      ReaderAnnotation(
        id: _bookmarkId,
        bookId: widget.book.id,
        selectedText: _bookmarkLabel,
        noteText: '',
        type: ReaderAnnotationType.bookmark,
        colorId: 'yellow',
        isFavorite: false,
        createdAt: _bookmarkAnnotation()?.createdAt ?? now,
        updatedAt: now,
        locationRef: locationRef,
      ),
    );

    _showReaderMessage('Bookmark saved');
  }

  void _jumpToBookmark() {
    final bookmark = _bookmarkAnnotation();
    if (bookmark == null) return;

    _jumpToLocation(bookmark);
  }

  bool _jumpToLocation(ReaderAnnotation annotation) {
    switch (_sourceType) {
      case BookFileType.pdf:
        final page = annotation.pdfPageNumber;
        if (page == null) return false;
        _pdfReaderController.jumpToPage(page);
        if (annotation.isUserAnnotation) _showAnnotationFeedback('Annotation found');
        return true;
      case BookFileType.epub:
        final didJump = _epubReaderController.jumpToAnnotation(annotation);
        if (didJump && annotation.isUserAnnotation) _focusAnnotation(annotation);
        return didJump;
      case BookFileType.plainText:
        final progress = annotation.epubProgress;
        if (progress != null && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent * progress,
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
          );
          return true;
        }
        return _scrollToAnnotation(annotation);
    }
  }

  String get _bookmarkLabel {
    return switch (_sourceType) {
      BookFileType.pdf => 'Page $_currentPdfPage',
      BookFileType.epub => '${_displayPercent(_currentProgress)}%',
      BookFileType.plainText => '${(_currentProgress * 100).round()}%',
    };
  }

  void _openDirectNavigation() {
    switch (_sourceType) {
      case BookFileType.pdf:
        _openPageNavigation();
      case BookFileType.epub:
        _openProgressNavigation();
      case BookFileType.plainText:
        _openProgressNavigation();
    }
  }

  Future<void> _openPageNavigation() async {
    final totalPages = _currentPdfTotalPages;
    final page = await showDialog<int>(
      context: context,
      builder: (context) => _PageNavigationDialog(
        initialPage: _currentPdfPage,
        totalPages: totalPages,
      ),
    );
    if (page == null) return;

    if (totalPages <= 0) {
      _showReaderMessage('PDF pages are still loading');
      return;
    }

    if (page <= 0 || (totalPages > 0 && page > totalPages)) {
      _showReaderMessage('Enter a page between 1 and $totalPages');
      return;
    }

    _pdfReaderController.jumpToPage(page);
  }

  Future<void> _openProgressNavigation() async {
    final percent = await showDialog<int>(
      context: context,
      builder: (context) {
        return _ProgressNavigationDialog(
          initialPercent: (_currentProgress * 100).round(),
        );
      },
    );
    if (percent == null) return;

    if (percent < 0 || percent > 100) {
      _showReaderMessage('Enter a progress value from 0 to 100');
      return;
    }

    final progress = percent / 100;
    if (_sourceType == BookFileType.epub) {
      final didJump = _epubReaderController.jumpToProgress(progress);
      if (!didJump) _showReaderMessage('EPUB progress is still loading');
    } else if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent * progress,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
      _handleDocumentProgressChanged(progress);
    }
  }

  void _showReaderMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openControls() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) {
        return ReaderControlsSheet(
          fontSize: _fontSize,
          lineHeight: _lineHeight,
          themeMode: _themeMode,
          isWideText: _isWideText,
          onFontSizeChanged: (value) {
            setState(() => _fontSize = value);
            _updateReadingProgressAfterLayout();
          },
          onLineHeightChanged: (value) {
            setState(() => _lineHeight = value);
            _updateReadingProgressAfterLayout();
          },
          onThemeModeChanged: (value) => setState(() => _themeMode = value),
          onTextWidthChanged: (value) {
            setState(() => _isWideText = value);
            _updateReadingProgressAfterLayout();
          },
          supportsTypography: _supportsTypographyControls,
          supportsTextWidth: _supportsTextWidthControls,
        );
      },
    );
  }

  void _handleTextSelectionChanged(ReaderSelection? value) {
    if (_selection?.text == value?.text &&
        _selection?.startIndex == value?.startIndex &&
        _selection?.endIndex == value?.endIndex &&
        _selection?.locationRef == value?.locationRef) {
      return;
    }

    setState(() => _selection = value);
  }

  Future<void> _openHighlightSheet() async {
    final selection = _selection;
    if (selection == null) return;

    _clearSelection();

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) {
        return AddNoteSheet(
          selectedText: selection.text,
          includeNoteField: false,
          title: 'Save highlight',
          saveLabel: 'Save highlight',
          onSave: (draft) => _saveHighlight(selection, draft),
        );
      },
    );
  }

  void _saveHighlight(ReaderSelection selection, AnnotationDraft draft) {
    _saveAnnotation(
      selection: selection,
      draft: draft,
      type: ReaderAnnotationType.highlight,
    );
  }

  Future<void> _openAddNoteSheet() async {
    final selection = _selection;
    if (selection == null) return;

    _clearSelection();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) {
        return AddNoteSheet(
          selectedText: selection.text,
          onSave: (draft) => _saveNote(selection, draft),
        );
      },
    );
  }

  void _saveNote(ReaderSelection selection, AnnotationDraft draft) {
    _saveAnnotation(
      selection: selection,
      draft: draft,
      type: ReaderAnnotationType.note,
    );
  }

  void _saveAnnotation({
    required ReaderSelection selection,
    required AnnotationDraft draft,
    required ReaderAnnotationType type,
  }) {
    if (_sourceType == BookFileType.pdf &&
        !_hasUsablePdfHighlightBounds(selection.locationRef)) {
      _clearSelection();
      _showReaderMessage(
        'This part of the PDF may not support clean text highlighting.',
      );
      return;
    }

    final now = DateTime.now();

    final annotation = ReaderAnnotation(
      id: now.microsecondsSinceEpoch.toString(),
      bookId: widget.book.id,
      selectedText: selection.text,
      noteText: type == ReaderAnnotationType.note ? draft.noteText : '',
      type: type,
      colorId: draft.colorId,
      isFavorite: draft.isFavorite,
      createdAt: now,
      updatedAt: now,
      locationRef:
          selection.locationRef ??
          '${selection.startIndex}:${selection.endIndex}',
    );
    widget.annotationRepository.addAnnotation(annotation);
    if (_sourceType == BookFileType.pdf) _clearSelection();
    _focusAnnotation(annotation);
    _showAnnotationFeedback(
      type == ReaderAnnotationType.highlight ? 'Highlight saved' : 'Note saved',
    );
  }

  bool _hasUsablePdfHighlightBounds(String? locationRef) {
    if (locationRef == null || !locationRef.startsWith('pdf:')) return false;

    for (final part in locationRef.substring(4).split(';')) {
      final separatorIndex = part.indexOf('=');
      if (separatorIndex <= 0) continue;

      final key = part.substring(0, separatorIndex).trim();
      if (key != 'rects') continue;

      final rects = part.substring(separatorIndex + 1).trim();
      if (rects.isEmpty) return false;

      for (final encodedRect in rects.split(',')) {
        final values = encodedRect.split('_');
        if (values.length != 4) continue;

        final width = double.tryParse(values[2]);
        final height = double.tryParse(values[3]);
        if (width != null && height != null && width > 0 && height > 0) {
          return true;
        }
      }
    }

    return false;
  }

  void _deleteAnnotation(ReaderAnnotation annotation) {
    widget.annotationRepository.deleteAnnotation(annotation.id);
    if (!mounted) return;

    setState(() {
      if (_focusedAnnotationId == annotation.id) _focusedAnnotationId = null;
      if (_openingTarget?.id == annotation.id) _openingTarget = _resolveOpeningTarget();
      _selection = null;
    });
    _showReaderMessage('Deleted ${annotation.displayTypeLabel.toLowerCase()}');
  }

  void _clearSelection() {
    if (_sourceType == BookFileType.pdf) _pdfReaderController.clearSelection();
    setState(() => _selection = null);
  }

  void _handleInitialAnnotation() {
    if (!mounted || _didHandleInitialAnnotation) return;

    final annotation = _openingTarget;
    if (annotation == null) return;

    if (_jumpToLocation(annotation)) {
      _didHandleInitialAnnotation = true;
      return;
    }

    _initialAnnotationAttempts++;
    if (_initialAnnotationAttempts < _maxInitialAnnotationAttempts) {
      _scheduleInitialAnnotationJump();
    }
  }

  void scrollToAnnotation(ReaderAnnotation annotation) {
    _jumpToLocation(annotation);
  }

  bool _scrollToAnnotation(ReaderAnnotation annotation) {
    final startIndex = annotation.locationStartIndex;
    final endIndex = annotation.locationEndIndex;
    if (startIndex == null || !_scrollController.hasClients) return false;

    final maxExtent = _scrollController.position.maxScrollExtent;
    final offset = _scrollOffsetForAnnotation(
      startIndex: startIndex,
      endIndex: endIndex,
      maxExtent: maxExtent,
    );

    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );

    _focusAnnotation(annotation);

    return true;
  }

  void _focusAnnotation(ReaderAnnotation annotation) {
    if (!annotation.isUserAnnotation) return;

    _focusedAnnotationTimer?.cancel();
    if (mounted) {
      setState(() => _focusedAnnotationId = annotation.id);
    } else {
      _focusedAnnotationId = annotation.id;
    }

    _focusedAnnotationTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted || _focusedAnnotationId != annotation.id) return;
      setState(() => _focusedAnnotationId = null);
    });
  }

  void _showAnnotationFeedback(String message) {
    _annotationFeedbackTimer?.cancel();
    if (mounted) {
      setState(() => _annotationFeedback = message);
    } else {
      _annotationFeedback = message;
    }

    _annotationFeedbackTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted || _annotationFeedback != message) return;
      setState(() => _annotationFeedback = null);
    });
  }

  void _scheduleInitialAnnotationJump() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _handleInitialAnnotation(),
    );
  }

  double _scrollOffsetForAnnotation({
    required int startIndex,
    required int? endIndex,
    required double maxExtent,
  }) {
    final text = _readerText;
    if (text.isEmpty) return 0;

    final safeStart = startIndex.clamp(0, text.length).toInt();
    final safeEnd = (endIndex ?? safeStart).clamp(0, text.length).toInt();
    final lowerBound = safeStart < safeEnd ? safeStart : safeEnd;
    final upperBound = safeStart < safeEnd ? safeEnd : safeStart;
    final targetIndex = upperBound > lowerBound
        ? lowerBound + ((upperBound - lowerBound) ~/ 2)
        : lowerBound;
    final safeTargetIndex = targetIndex.clamp(0, text.length).toInt();

    final viewportWidth = MediaQuery.sizeOf(context).width;
    final textWidth = (viewportWidth - 48).clamp(0.0, _textMaxWidth).toDouble();
    if (textWidth <= 0) return 0;

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: _fontSize,
          height: _lineHeight,
          letterSpacing: 0,
        ),
      ),
      textAlign: TextAlign.start,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: textWidth);

    final caretOffset = textPainter.getOffsetForCaret(
      TextPosition(offset: safeTargetIndex),
      Rect.zero,
    );
    final lineHeight = _fontSize * _lineHeight;
    final viewportHeight = _scrollController.position.viewportDimension;
    final centeredOffset =
        caretOffset.dy + 24 - ((viewportHeight - lineHeight) / 2);

    return centeredOffset.clamp(0.0, maxExtent).toDouble();
  }

  void _updateReadingProgress() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final maxExtent = position.maxScrollExtent;
    final progress = maxExtent <= 0 ? 0.0 : position.pixels / maxExtent;
    final clampedProgress = progress.clamp(0.0, 1.0).toDouble();

    if ((clampedProgress - _readingProgress.value).abs() >= 0.001) {
      _readingProgress.value = clampedProgress;
    }
    _currentProgress = clampedProgress;
    _currentLocationRef = 'epub:progress=${clampedProgress.toStringAsFixed(4)}';
    _positionLabel.value = _percentLabel(clampedProgress);
    _saveReadingPosition();
  }

  void _updateReadingProgressAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateReadingProgress();
    });
  }

  void _handleDocumentProgressChanged(double value) {
    final clampedProgress = value.clamp(0.0, 1.0).toDouble();
    if ((clampedProgress - _readingProgress.value).abs() >= 0.001) {
      _readingProgress.value = clampedProgress;
    }

    _currentProgress = clampedProgress;
    _currentLocationRef = 'epub:progress=${clampedProgress.toStringAsFixed(4)}';
    _positionLabel.value = _percentLabel(clampedProgress);
    _saveReadingPosition();
  }

  void _handleEpubPositionChanged(EpubReaderPosition position) {
    final progress = position.progress;
    if ((progress - _readingProgress.value).abs() >= 0.001) {
      _readingProgress.value = progress;
    }

    _currentProgress = progress;
    _currentLocationRef = position.locationRef;
    _positionLabel.value = _percentLabel(progress);
    _saveReadingPosition();
  }

  void _handlePdfPositionChanged(PdfReaderPosition position) {
    final progress = position.progress;
    if ((progress - _readingProgress.value).abs() >= 0.001) {
      _readingProgress.value = progress;
    }

    _currentProgress = progress;
    _currentPdfPage = position.currentPage;
    _currentPdfTotalPages = position.totalPages;
    _currentLocationRef = 'pdf:page=${position.currentPage}';
    _positionLabel.value = _pdfPositionLabel(position);
    _saveReadingPosition();
  }

  void _saveReadingPosition() {
    final locationRef = _currentLocationRef;
    if (locationRef == null ||
        locationRef == _lastSavedLocationRef ||
        locationRef == _pendingReadingLocationRef) {
      return;
    }

    _pendingReadingLocationRef = locationRef;
    _readingPositionSaveTimer ??= Timer(
      _readingPositionSaveDelay,
      _commitReadingPosition,
    );
  }

  void _commitReadingPosition() {
    final locationRef = _pendingReadingLocationRef;
    _pendingReadingLocationRef = null;
    _readingPositionSaveTimer?.cancel();
    _readingPositionSaveTimer = null;

    if (locationRef == null || locationRef == _lastSavedLocationRef) return;

    final now = DateTime.now();
    final previous = _readingPositionAnnotation();
    _lastSavedLocationRef = locationRef;
    widget.annotationRepository.addAnnotation(
      ReaderAnnotation(
        id: _readingPositionId,
        bookId: widget.book.id,
        selectedText: 'Last reading position',
        noteText: '',
        type: ReaderAnnotationType.readingPosition,
        colorId: 'yellow',
        isFavorite: false,
        createdAt: previous?.createdAt ?? now,
        updatedAt: now,
        locationRef: locationRef,
      ),
    );
  }

  Future<void> _openBookAnnotations() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) {
        final mode = _themeMode;

        return ValueListenableBuilder<List<ReaderAnnotation>>(
          valueListenable: widget.annotationRepository.watchAnnotations(),
          builder: (context, annotations, _) {
            final bookAnnotations = _annotationsForCurrentBook(annotations)
                .where((annotation) => annotation.isUserAnnotation)
                .toList(growable: false);

            if (bookAnnotations.isEmpty) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                child: Text(
                  'No notes or highlights yet.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: ReaderAnnotationsSection(
                annotations: bookAnnotations,
                textColor: mode.textColor,
                mutedColor: mode.mutedColor,
                surfaceColor: mode.textColor.withValues(alpha: 0.05),
                borderColor: mode.textColor.withValues(alpha: 0.10),
                maxWidth: 720,
                onTap: (annotation) {
                  Navigator.of(context).pop();
                  _jumpToLocation(annotation);
                },
                onDelete: (annotation) {
                  Navigator.of(context).pop();
                  _deleteAnnotation(annotation);
                },
              ),
            );
          },
        );
      },
    );
  }

  void _syncDeletedAnnotationState(List<ReaderAnnotation> annotations) {
    final ids = annotations.map((annotation) => annotation.id).toSet();
    final focusedWasDeleted =
        _focusedAnnotationId != null && !ids.contains(_focusedAnnotationId);
    final targetWasDeleted =
        _openingTarget != null &&
        _openingTarget!.isUserAnnotation &&
        !ids.contains(_openingTarget!.id);
    if (!focusedWasDeleted && !targetWasDeleted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        if (focusedWasDeleted) _focusedAnnotationId = null;
        if (targetWasDeleted) _openingTarget = _resolveOpeningTarget();
      });
    });
  }

  int _displayPercent(double progress) {
    return (progress.clamp(0.0, 1.0) * 100).floor();
  }

  String _percentLabel(double progress) {
    return '${(progress.clamp(0.0, 1.0) * 100).round()}%';
  }

  String _pdfPositionLabel(PdfReaderPosition position) {
    if (position.totalPages <= 0) return 'Page ${position.currentPage}';

    return '${position.currentPage} / ${position.totalPages}';
  }
}

class _ReaderEdgeFade extends StatelessWidget {
  const _ReaderEdgeFade({
    required this.alignment,
    required this.backgroundColor,
  });

  final Alignment alignment;
  final Color backgroundColor;

  bool get _isTop => alignment == Alignment.topCenter;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: alignment,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: _isTop ? Alignment.topCenter : Alignment.bottomCenter,
              end: _isTop ? Alignment.bottomCenter : Alignment.topCenter,
              colors: [backgroundColor, backgroundColor.withValues(alpha: 0)],
            ),
          ),
          child: const SizedBox(height: 28, width: double.infinity),
        ),
      ),
    );
  }
}

enum _ReaderOverflowAction {
  goToPosition,
  saveBookmark,
  goToBookmark,
  readingSettings,
}

class _PageNavigationDialog extends StatefulWidget {
  const _PageNavigationDialog({
    required this.initialPage,
    required this.totalPages,
  });

  final int initialPage;
  final int totalPages;

  @override
  State<_PageNavigationDialog> createState() => _PageNavigationDialogState();
}

class _PageNavigationDialogState extends State<_PageNavigationDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialPage.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Go to page'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: widget.totalPages > 0 ? 'Page 1-${widget.totalPages}' : 'Page',
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Go'),
        ),
      ],
    );
  }

  void _submit() {
    final value = int.tryParse(_controller.text.trim());
    Navigator.of(context).pop(value);
  }
}

class _ProgressNavigationDialog extends StatefulWidget {
  const _ProgressNavigationDialog({required this.initialPercent});

  final int initialPercent;

  @override
  State<_ProgressNavigationDialog> createState() {
    return _ProgressNavigationDialogState();
  }
}

class _ProgressNavigationDialogState extends State<_ProgressNavigationDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialPercent.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Go to progress'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Progress 0-100%'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Go'),
        ),
      ],
    );
  }

  void _submit() {
    final value = int.tryParse(_controller.text.trim());
    Navigator.of(context).pop(value);
  }
}

class _ReaderPositionBadge extends StatelessWidget {
  const _ReaderPositionBadge({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.08),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: DecoratedBox(
        key: ValueKey(label),
        decoration: BoxDecoration(
          color: backgroundColor.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: textColor.withValues(alpha: 0.78),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionActionBar extends StatelessWidget {
  const _SelectionActionBar({
    required this.isVisible,
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
    required this.onHighlight,
    required this.onAddNote,
    required this.onDismiss,
  });

  final bool isVisible;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
  final VoidCallback onHighlight;
  final VoidCallback onAddNote;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 18,
      child: SafeArea(
        child: AnimatedSlide(
          offset: isVisible ? Offset.zero : const Offset(0, 0.18),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: isVisible ? 1 : 0,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            child: IgnorePointer(
              ignoring: !isVisible,
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: backgroundColor.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton.icon(
                          onPressed: onHighlight,
                          icon: const Icon(Icons.border_color_rounded, size: 17),
                          label: const Text('Highlight'),
                        ),
                        const SizedBox(width: 2),
                        FilledButton.tonalIcon(
                          onPressed: onAddNote,
                          icon: const Icon(Icons.note_add_outlined, size: 17),
                          label: const Text('Note'),
                        ),
                        const SizedBox(width: 1),
                        IconButton(
                          onPressed: onDismiss,
                          icon: Icon(
                            Icons.close_rounded,
                            color: textColor.withValues(alpha: 0.72),
                          ),
                          tooltip: 'Dismiss',
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnnotationFeedbackPill extends StatelessWidget {
  const _AnnotationFeedbackPill({
    required this.message,
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
  });

  final String? message;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final message = this.message;

    return AnimatedSlide(
      offset: message == null ? const Offset(0, 0.14) : Offset.zero,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: message == null ? 0 : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        child: IgnorePointer(
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: backgroundColor.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                child: Text(
                  message ?? '',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: textColor.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _mockReaderContent(Book book) {
  return '''
${book.title}

Reading well is less about moving quickly and more about staying close to the page. A good reader notices the rhythm of an argument, the quiet pressure of a sentence, and the way an idea changes shape after a few paragraphs.

This is where a reading app should disappear. The screen should give the words enough room to breathe, keep controls nearby without asking for attention, and make long sessions feel calm instead of crowded.

The chapter begins with a simple observation: every book asks for a slightly different pace. Some pages want a careful walk. Others can be crossed in a few quick strides. The reader needs small controls that adapt to that pace without becoming another task.

Margins matter. Line height matters. A little more space can turn a dense paragraph into something the eye can follow. A darker background can make evening reading easier. Sepia can soften the screen when bright white feels too sharp.

Notes will eventually live beside this text, but the first job is trust. The reader should open fast, scroll smoothly, and preserve a sense of place. Everything else grows from that foundation.

Local-first software has a particular feeling when it is done well. It feels immediate. It respects the user's library as something personal, close, and available even without a network. The app can become more powerful later without losing that original quietness.

There is also a product lesson here. The first version does not need every tool. It needs the right defaults, clear gestures, and a path that can grow. A focused reader with a small settings sheet is better than a complicated reader that keeps interrupting the book.

When the typography is comfortable, the interface starts to feel slower in the best way. The reader stops thinking about settings and returns to the sentence in front of them.

That is the goal for this screen: calm colors, readable text, enough control to feel personal, and no extra ceremony.

The next section would bring annotations into the same rhythm. Selecting text should feel natural. Saving a note should feel lightweight. Returning to the note later should feel like finding a marker exactly where it was left.

For now, this long mock passage gives the scroll view enough weight to test the core experience. It should be readable on a small phone, comfortable on a tablet, and restrained on a desktop-sized viewport.

Good reading software does not compete with the book. It holds the page steady.
''';
}
