import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'reader_content.dart';

class PdfReaderView extends StatelessWidget {
  const PdfReaderView({
    required this.filePath,
    required this.backgroundColor,
    required this.onSelectionChanged,
    this.controller,
    this.initialPage,
    this.onPositionChanged,
    super.key,
  });

  final String filePath;
  final Color backgroundColor;
  final ValueChanged<ReaderSelection?> onSelectionChanged;
  final PdfReaderController? controller;
  final int? initialPage;
  final ValueChanged<PdfReaderPosition>? onPositionChanged;

  @override
  Widget build(BuildContext context) {
    final file = File(filePath);

    if (!file.existsSync()) {
      return const _DocumentError(message: 'This PDF file could not be found.');
    }

    return ColoredBox(
      color: backgroundColor,
      child: _PdfSelectionReader(
        file: file,
        controller: controller,
        initialPage: initialPage,
        onPositionChanged: onPositionChanged,
        onSelectionChanged: onSelectionChanged,
      ),
    );
  }
}

class PdfReaderController {
  _PdfSelectionReaderState? _state;

  int get currentPage => _state?._currentPage ?? 1;

  int get totalPages => _state?._totalPages ?? 0;

  void jumpToPage(int page) {
    _state?._jumpToPage(page);
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
    required this.controller,
    required this.onSelectionChanged,
    required this.initialPage,
    required this.onPositionChanged,
  });

  final File file;
  final PdfReaderController? controller;
  final ValueChanged<ReaderSelection?> onSelectionChanged;
  final int? initialPage;
  final ValueChanged<PdfReaderPosition>? onPositionChanged;

  @override
  State<_PdfSelectionReader> createState() => _PdfSelectionReaderState();
}

class _PdfSelectionReaderState extends State<_PdfSelectionReader> {
  late final PdfViewerController _controller = PdfViewerController();
  int _currentPage = 1;
  int _totalPages = 0;
  bool _didJumpToInitialPage = false;

  @override
  void didUpdateWidget(covariant _PdfSelectionReader oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._state = null;
      widget.controller?._state = this;
    }

    if (oldWidget.file.path != widget.file.path) {
      _currentPage = 1;
      _totalPages = 0;
      _didJumpToInitialPage = false;
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
        SfPdfViewer.file(
          widget.file,
          controller: _controller,
          canShowHyperlinkDialog: false,
          canShowPaginationDialog: false,
          canShowScrollHead: false,
          canShowScrollStatus: false,
          canShowSignaturePadDialog: false,
          canShowTextSelectionMenu: false,
          enableTextSelection: true,
          onDocumentLoaded: (details) {
            setState(() {
              _totalPages = details.document.pages.count;
              _currentPage =
                  _controller.pageNumber.clamp(1, _safeTotalPages).toInt();
            });
            _notifyPositionChanged();
            _jumpToInitialPage();
          },
          onPageChanged: (details) {
            setState(() => _currentPage = details.newPageNumber);
            _notifyPositionChanged();
          },
          onTextSelectionChanged: (details) {
            final selectedText = _normalizedSelectedText(details.selectedText);
            if (selectedText.isEmpty) {
              widget.onSelectionChanged(null);
              return;
            }

            final page = _controller.pageNumber.clamp(1, _safeTotalPages).toInt();
            widget.onSelectionChanged(
              ReaderSelection(
                text: selectedText,
                startIndex: 0,
                endIndex: selectedText.length,
                locationRef: _pdfLocationRef(page, selectedText),
              ),
            );
          },
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _PdfPageBar(
                canGoBack: _currentPage > 1,
                canGoForward: _totalPages > 0 && _currentPage < _totalPages,
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

  String _pdfLocationRef(int page, String selectedText) {
    return 'pdf:page=$page;text=${_selectionFingerprint(selectedText)}';
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

class _PdfPageBar extends StatelessWidget {
  const _PdfPageBar({
    required this.canGoBack,
    required this.canGoForward,
    required this.onPrevious,
    required this.onNext,
  });

  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: canGoBack ? onPrevious : null,
              icon: const Icon(Icons.keyboard_arrow_left_rounded),
              tooltip: 'Previous page',
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: canGoForward ? onNext : null,
              icon: const Icon(Icons.keyboard_arrow_right_rounded),
              tooltip: 'Next page',
            ),
          ],
        ),
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
