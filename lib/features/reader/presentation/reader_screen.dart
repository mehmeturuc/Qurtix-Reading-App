import 'package:flutter/material.dart';

import '../../library/domain/book.dart';
import '../domain/annotation_repository.dart';
import '../domain/reader_annotation.dart';
import 'models/reader_theme_mode.dart';
import 'widgets/add_note_sheet.dart';
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

  final ScrollController _scrollController = ScrollController();

  double _fontSize = 18;
  double _lineHeight = 1.65;
  bool _isWideText = false;
  ReaderSelection? _selection;
  String? _focusedAnnotationId;
  bool _didHandleInitialAnnotation = false;
  int _initialAnnotationAttempts = 0;
  final ValueNotifier<double> _readingProgress = ValueNotifier<double>(0);
  ReaderThemeMode _themeMode = ReaderThemeMode.light;

  double get _textMaxWidth => _isWideText ? 760 : 620;
  String get _readerText => _mockReaderContent(widget.book);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateReadingProgress);
    _scheduleInitialAnnotationJump();
  }

  @override
  void didUpdateWidget(covariant ReaderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialAnnotation?.id != widget.initialAnnotation?.id) {
      _didHandleInitialAnnotation = false;
      _initialAnnotationAttempts = 0;
      _scheduleInitialAnnotationJump();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_updateReadingProgress)
      ..dispose();
    _readingProgress.dispose();
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
                widget.book.author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: mode.mutedColor),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: _openControls,
              icon: const Icon(Icons.tune_rounded),
              tooltip: 'Reading settings',
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
        body: SafeArea(
          child: Stack(
            children: [
              Scrollbar(
                controller: _scrollController,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 56),
                  child: ValueListenableBuilder<List<ReaderAnnotation>>(
                    valueListenable: widget.annotationRepository.watchAnnotations(),
                    builder: (context, annotations, _) {
                      final bookAnnotations = annotations
                          .where(
                            (annotation) => annotation.bookId == widget.book.id,
                          )
                          .toList(growable: false);

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
              if (_selection != null)
                _SelectionActionBar(
                  backgroundColor: mode.backgroundColor,
                  textColor: mode.textColor,
                  borderColor: mode.textColor.withValues(alpha: 0.12),
                  onHighlight: _openHighlightSheet,
                  onAddNote: _openAddNoteSheet,
                  onDismiss: _clearSelection,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openControls() {
    showModalBottomSheet<void>(
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
        );
      },
    );
  }

  void _handleTextSelectionChanged(ReaderSelection? value) {
    setState(() => _selection = value);
  }

  void _openHighlightSheet() {
    final selection = _selection;
    if (selection == null) return;

    setState(() => _selection = null);

    showModalBottomSheet<void>(
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

  void _openAddNoteSheet() {
    final selection = _selection;
    if (selection == null) return;

    setState(() => _selection = null);

    showModalBottomSheet<void>(
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
    final now = DateTime.now();

    widget.annotationRepository.addAnnotation(
      ReaderAnnotation(
        id: now.microsecondsSinceEpoch.toString(),
        bookId: widget.book.id,
        selectedText: selection.text,
        noteText: type == ReaderAnnotationType.note ? draft.noteText : '',
        type: type,
        colorId: draft.colorId,
        isFavorite: draft.isFavorite,
        createdAt: now,
        updatedAt: now,
        locationRef: '${selection.startIndex}:${selection.endIndex}',
      ),
    );
  }

  void _deleteAnnotation(String id) {
    widget.annotationRepository.deleteAnnotation(id);
  }

  void _clearSelection() {
    setState(() => _selection = null);
  }

  void _handleInitialAnnotation() {
    if (!mounted || _didHandleInitialAnnotation) return;

    final annotation = widget.initialAnnotation;
    if (annotation == null) return;

    if (_scrollToAnnotation(annotation)) {
      _didHandleInitialAnnotation = true;
      return;
    }

    _initialAnnotationAttempts++;
    if (_initialAnnotationAttempts < _maxInitialAnnotationAttempts) {
      _scheduleInitialAnnotationJump();
    }
  }

  void scrollToAnnotation(ReaderAnnotation annotation) {
    _scrollToAnnotation(annotation);
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

    setState(() => _focusedAnnotationId = annotation.id);
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted || _focusedAnnotationId != annotation.id) return;
      setState(() => _focusedAnnotationId = null);
    });

    return true;
  }

  void _scheduleInitialAnnotationJump() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleInitialAnnotation());
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
    final centeredOffset = caretOffset.dy + 24 - ((viewportHeight - lineHeight) / 2);

    return centeredOffset.clamp(0.0, maxExtent).toDouble();
  }

  void _updateReadingProgress() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final maxExtent = position.maxScrollExtent;
    final progress = maxExtent <= 0 ? 0.0 : position.pixels / maxExtent;
    final clampedProgress = progress.clamp(0.0, 1.0).toDouble();

    if ((clampedProgress - _readingProgress.value).abs() < 0.001) return;

    _readingProgress.value = clampedProgress;
  }

  void _updateReadingProgressAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateReadingProgress();
    });
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
          child: const SizedBox(height: 36, width: double.infinity),
        ),
      ),
    );
  }
}

class _SelectionActionBar extends StatelessWidget {
  const _SelectionActionBar({
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
    required this.onHighlight,
    required this.onAddNote,
    required this.onDismiss,
  });

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
      bottom: 16,
      child: SafeArea(
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    onPressed: onHighlight,
                    icon: const Icon(Icons.border_color_rounded, size: 18),
                    label: const Text('Highlight'),
                  ),
                  const SizedBox(width: 4),
                  FilledButton.tonalIcon(
                    onPressed: onAddNote,
                    icon: const Icon(Icons.note_add_outlined, size: 18),
                    label: const Text('Note'),
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    onPressed: onDismiss,
                    icon: Icon(Icons.close_rounded, color: textColor),
                    tooltip: 'Dismiss',
                  ),
                ],
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
