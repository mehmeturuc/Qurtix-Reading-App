import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/design/app_design.dart';
import '../../../shared/widgets/app_page.dart';
import '../../library/domain/book.dart';
import '../../library/domain/book_repository.dart';
import '../../reader/domain/annotation_color.dart';
import '../../reader/domain/annotation_repository.dart';
import '../../reader/domain/reader_annotation.dart';
import '../../reader/presentation/annotation_display_text.dart';
import '../../reader/presentation/reader_screen.dart';
import '../application/annotation_export_service.dart';

enum _AnnotationTypeFilter { all, highlight, note, bookmark }

class NotesScreen extends StatefulWidget {
  const NotesScreen({
    required this.bookRepository,
    required this.annotationRepository,
    super.key,
  });

  final BookRepository bookRepository;
  final AnnotationRepository annotationRepository;

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String? _bookId;
  _AnnotationTypeFilter _typeFilter = _AnnotationTypeFilter.all;
  bool _favoritesOnly = false;
  bool _isLoadingAnnotations = false;
  late List<Book> _books;
  late Map<String, Book> _booksById;

  @override
  void initState() {
    super.initState();
    _refreshBookCache();
    _scheduleAnnotationLoad();
  }

  @override
  void didUpdateWidget(covariant NotesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.bookRepository != widget.bookRepository) {
      _refreshBookCache();
    }
    if (oldWidget.annotationRepository != widget.annotationRepository) {
      _isLoadingAnnotations = false;
      _scheduleAnnotationLoad();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notes',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: _openExportDialog,
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export annotations',
          ),
        ],
      ),
      body: SafeArea(
        child: AppPage(
          maxWidth: 900,
          child: ValueListenableBuilder<List<ReaderAnnotation>>(
            valueListenable: widget.annotationRepository.watchAnnotations(),
            builder: (context, annotations, _) {
              final filtered = _applyFilters(annotations);
              final userAnnotations = annotations
                  .where((annotation) => annotation.isUserAnnotation)
                  .toList(growable: false);
              final isLoading = _isLoadingAnnotations && annotations.isEmpty;
              final hasActiveFilters =
                  _bookId != null ||
                  _typeFilter != _AnnotationTypeFilter.all ||
                  _favoritesOnly;

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x4,
                  AppSpacing.x1,
                  AppSpacing.x4,
                  24,
                ),
                itemCount: (filtered.isEmpty || isLoading)
                    ? 4
                    : filtered.length + 3,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _NotesFilters(
                      books: _books,
                      selectedBookId: _bookId,
                      typeFilter: _typeFilter,
                      favoritesOnly: _favoritesOnly,
                      onBookChanged: (value) => setState(() => _bookId = value),
                      onTypeChanged: (value) {
                        if (value == null) return;
                        setState(() => _typeFilter = value);
                      },
                      onFavoritesChanged: (value) {
                        setState(() => _favoritesOnly = value);
                      },
                      onClearFilters: hasActiveFilters
                          ? () {
                              setState(() {
                                _bookId = null;
                                _typeFilter = _AnnotationTypeFilter.all;
                                _favoritesOnly = false;
                              });
                            }
                          : null,
                    );
                  }

                  if (index == 1) {
                    return Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.x1),
                      child: _NotesSummary(
                        visibleCount: filtered.length,
                        totalCount: userAnnotations.length,
                        hasActiveFilters: hasActiveFilters,
                      ),
                    );
                  }

                  if (index == 2) {
                    return const SizedBox(height: AppSpacing.x2);
                  }

                  if (isLoading) return const _LoadingNotes();
                  if (filtered.isEmpty) {
                    return _EmptyNotes(hasActiveFilters: hasActiveFilters);
                  }

                  final annotation = filtered[index - 3];
                  final book = _booksById[annotation.bookId];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.x2),
                    child: _NoteCard(
                      annotation: annotation,
                      bookTitle: book?.title ?? 'Unknown book',
                      bookType: book?.sourceType,
                      onTap: () => _openAnnotation(annotation),
                      onDelete: () => _deleteAnnotation(annotation),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  List<ReaderAnnotation> _applyFilters(List<ReaderAnnotation> annotations) {
    return annotations
        .where((annotation) {
          if (!annotation.isUserAnnotation) return false;

          final matchesBook = _bookId == null || annotation.bookId == _bookId;
          final matchesType = switch (_typeFilter) {
            _AnnotationTypeFilter.all => true,
            _AnnotationTypeFilter.highlight =>
              annotation.type == ReaderAnnotationType.highlight,
            _AnnotationTypeFilter.note =>
              annotation.type == ReaderAnnotationType.note,
            _AnnotationTypeFilter.bookmark =>
              annotation.type == ReaderAnnotationType.bookmark,
          };
          final matchesFavorite = !_favoritesOnly || annotation.isFavorite;

          return matchesBook && matchesType && matchesFavorite;
        })
        .toList(growable: false)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  void _openAnnotation(ReaderAnnotation annotation) {
    final book = widget.bookRepository.getBookById(annotation.bookId);
    if (book == null) return;

    widget.bookRepository.markOpened(book.id, DateTime.now());
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReaderScreen(
          book: book,
          annotationRepository: widget.annotationRepository,
          initialAnnotation: annotation,
        ),
      ),
    );
  }

  void _refreshBookCache() {
    _books = widget.bookRepository.getBooks();
    _booksById = {for (final book in _books) book.id: book};
  }

  void _scheduleAnnotationLoad() {
    if (widget.annotationRepository.isLoaded) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.annotationRepository.isLoaded) return;

      setState(() => _isLoadingAnnotations = true);
      unawaited(_loadAnnotations());
    });
  }

  Future<void> _loadAnnotations() async {
    try {
      await widget.annotationRepository.ensureLoaded();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not load notes')));
    }
    if (!mounted) return;

    setState(() => _isLoadingAnnotations = false);
  }

  void _deleteAnnotation(ReaderAnnotation annotation) {
    widget.annotationRepository.deleteAnnotation(annotation.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted ${annotation.displayTypeLabel.toLowerCase()}'),
      ),
    );
  }

  Future<void> _openExportDialog() async {
    final request = await showDialog<AnnotationExportRequest>(
      context: context,
      builder: (context) {
        return _ExportAnnotationsDialog(
          books: _books,
          initialBookId: _bookId,
          initialFavoritesOnly: _favoritesOnly,
        );
      },
    );
    if (request == null) return;
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final service = AnnotationExportService(
      annotationRepository: widget.annotationRepository,
      bookRepository: widget.bookRepository,
    );

    try {
      final result = await service.export(request);
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(content: Text('Exported ${result.fileName}')),
      );
    } catch (_) {
      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(content: Text('Could not export annotations')),
      );
    }
  }
}

class _ExportAnnotationsDialog extends StatefulWidget {
  const _ExportAnnotationsDialog({
    required this.books,
    required this.initialBookId,
    required this.initialFavoritesOnly,
  });

  final List<Book> books;
  final String? initialBookId;
  final bool initialFavoritesOnly;

  @override
  State<_ExportAnnotationsDialog> createState() =>
      _ExportAnnotationsDialogState();
}

class _ExportAnnotationsDialogState extends State<_ExportAnnotationsDialog> {
  static const _allBooksValue = '__all_books__';

  AnnotationExportFormat _format = AnnotationExportFormat.txt;
  String? _bookId;
  late bool _favoritesOnly;

  @override
  void initState() {
    super.initState();
    _bookId = widget.initialBookId;
    _favoritesOnly = widget.initialFavoritesOnly;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export annotations'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownMenu<AnnotationExportFormat>(
            initialSelection: _format,
            label: const Text('Format'),
            width: 260,
            onSelected: (value) {
              if (value == null) return;
              setState(() => _format = value);
            },
            dropdownMenuEntries: [
              for (final format in AnnotationExportFormat.values)
                DropdownMenuEntry<AnnotationExportFormat>(
                  value: format,
                  label: format.label,
                ),
            ],
          ),
          const SizedBox(height: 14),
          DropdownMenu<String>(
            initialSelection: _bookId ?? _allBooksValue,
            label: const Text('Scope'),
            width: 260,
            onSelected: (value) {
              setState(() {
                _bookId = value == _allBooksValue ? null : value;
              });
            },
            dropdownMenuEntries: [
              const DropdownMenuEntry<String>(
                value: _allBooksValue,
                label: 'All books',
              ),
              for (final book in widget.books)
                DropdownMenuEntry<String>(value: book.id, label: book.title),
            ],
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _favoritesOnly,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('Favorites only'),
            onChanged: (value) {
              setState(() => _favoritesOnly = value ?? false);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(
              AnnotationExportRequest(
                format: _format,
                bookId: _bookId,
                favoritesOnly: _favoritesOnly,
              ),
            );
          },
          child: const Text('Export'),
        ),
      ],
    );
  }
}

class _NotesFilters extends StatelessWidget {
  const _NotesFilters({
    required this.books,
    required this.selectedBookId,
    required this.typeFilter,
    required this.favoritesOnly,
    required this.onBookChanged,
    required this.onTypeChanged,
    required this.onFavoritesChanged,
    required this.onClearFilters,
  });

  final List<Book> books;
  final String? selectedBookId;
  final _AnnotationTypeFilter typeFilter;
  final bool favoritesOnly;
  final ValueChanged<String?> onBookChanged;
  final ValueChanged<_AnnotationTypeFilter?> onTypeChanged;
  final ValueChanged<bool> onFavoritesChanged;
  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        final colors = theme.colorScheme;
        final selectedBook = selectedBookId == null
            ? null
            : books.where((book) => book.id == selectedBookId).firstOrNull;

        final bookMenu = _BookFilterControl(
          books: books,
          selectedBookId: selectedBookId,
          selectedLabel: selectedBook?.title ?? 'All books',
          onChanged: onBookChanged,
        );

        final typeTabs = _NotesSegmentedControl<_AnnotationTypeFilter>(
          value: typeFilter,
          onChanged: (value) => onTypeChanged(value),
          options: const [
            AppSegmentedOption(value: _AnnotationTypeFilter.all, label: 'All'),
            AppSegmentedOption(
              value: _AnnotationTypeFilter.highlight,
              label: 'Highlights',
            ),
            AppSegmentedOption(
              value: _AnnotationTypeFilter.note,
              label: 'Notes',
            ),
            AppSegmentedOption(
              value: _AnnotationTypeFilter.bookmark,
              label: 'Bookmarks',
            ),
          ],
        );

        final favorites = _TonalToggleButton(
          selected: favoritesOnly,
          icon: favoritesOnly ? Icons.star_rounded : Icons.star_border_rounded,
          label: 'Favorites',
          onTap: () => onFavoritesChanged(!favoritesOnly),
        );
        final clearFilters = _SoftTextAction(
          onPressed: onClearFilters,
          icon: Icons.close_rounded,
          label: 'Clear',
        );

        return AppSection(
          backgroundColor: colors.surfaceContainerLow,
          padding: const EdgeInsets.all(6),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    bookMenu,
                    const SizedBox(height: AppSpacing.x2),
                    typeTabs,
                    const SizedBox(height: AppSpacing.x2),
                    Wrap(
                      spacing: AppSpacing.x2,
                      runSpacing: AppSpacing.x1,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        favorites,
                        if (onClearFilters != null) clearFilters,
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    SizedBox(width: 252, child: bookMenu),
                    const SizedBox(width: AppSpacing.x3),
                    Expanded(child: typeTabs),
                    const SizedBox(width: AppSpacing.x3),
                    favorites,
                    if (onClearFilters != null) ...[
                      const SizedBox(width: AppSpacing.x2),
                      clearFilters,
                    ],
                  ],
                ),
        );
      },
    );
  }
}

class _BookFilterControl extends StatelessWidget {
  const _BookFilterControl({
    required this.books,
    required this.selectedBookId,
    required this.selectedLabel,
    required this.onChanged,
  });

  static const _allBooksValue = '__all_books__';

  final List<Book> books;
  final String? selectedBookId;
  final String selectedLabel;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: colors.surfaceContainerLowest,
      borderRadius: AppCorners.lg,
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: AppCorners.lg,
          border: Border.fromBorderSide(AppBorders.ghost(colors)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, AppSpacing.x2, 6),
          child: Row(
            children: [
              Icon(Icons.menu_book_outlined, size: 15, color: colors.secondary),
              const SizedBox(width: AppSpacing.x2),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedBookId ?? _allBooksValue,
                    isExpanded: true,
                    borderRadius: AppCorners.lg,
                    dropdownColor: colors.surfaceContainerLowest,
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: colors.onSurfaceVariant,
                    ),
                    selectedItemBuilder: (context) {
                      return [
                        _BookFilterSelectedLabel(label: selectedLabel),
                        for (final book in books)
                          _BookFilterSelectedLabel(label: book.title),
                      ];
                    },
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: AppTypography.sans,
                      color: colors.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    items: [
                      DropdownMenuItem<String>(
                        value: _allBooksValue,
                        child: _BookFilterMenuItem(
                          label: 'All books',
                          selected: selectedBookId == null,
                        ),
                      ),
                      for (final book in books)
                        DropdownMenuItem<String>(
                          value: book.id,
                          child: _BookFilterMenuItem(
                            label: book.title,
                            selected: selectedBookId == book.id,
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      onChanged(value == _allBooksValue ? null : value);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookFilterSelectedLabel extends StatelessWidget {
  const _BookFilterSelectedLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Book',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            fontFamily: AppTypography.sans,
            color: colors.onSurfaceVariant,
            fontSize: 10,
            fontWeight: FontWeight.w500,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontFamily: AppTypography.sans,
            color: colors.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.08,
          ),
        ),
      ],
    );
  }
}

class _NotesSegmentedControl<T> extends StatelessWidget {
  const _NotesSegmentedControl({
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<AppSegmentedOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      height: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: AppCorners.lg,
        border: Border.fromBorderSide(AppBorders.ghost(colors)),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: _NotesSegment<T>(
                  option: option,
                  selected: option.value == value,
                  onTap: () => onChanged(option.value),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NotesSegment<T> extends StatelessWidget {
  const _NotesSegment({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final AppSegmentedOption<T> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      borderRadius: AppCorners.md,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x1),
          decoration: BoxDecoration(
            color: selected
                ? colors.surfaceContainerLowest
                : Colors.transparent,
            borderRadius: AppCorners.md,
          ),
          child: Text(
            option.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              fontFamily: AppTypography.sans,
              color: selected ? colors.onSurface : colors.onSurfaceVariant,
              fontSize: 10.5,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _BookFilterMenuItem extends StatelessWidget {
  const _BookFilterMenuItem({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: AppTypography.sans,
              color: colors.onSurface,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
        if (selected) ...[
          const SizedBox(width: AppSpacing.x2),
          Icon(Icons.check_rounded, size: 16, color: colors.secondary),
        ],
      ],
    );
  }
}

class _TonalToggleButton extends StatelessWidget {
  const _TonalToggleButton({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: selected
          ? colors.secondaryContainer
          : colors.surfaceContainerLowest,
      borderRadius: AppCorners.lg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppCorners.lg,
            border: Border.fromBorderSide(AppBorders.ghost(colors)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: selected
                      ? colors.onSecondaryContainer
                      : colors.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.x1),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontFamily: AppTypography.sans,
                    color: selected
                        ? colors.onSecondaryContainer
                        : colors.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SoftTextAction extends StatelessWidget {
  const _SoftTextAction({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: colors.onSurfaceVariant,
        textStyle: theme.textTheme.labelSmall?.copyWith(
          fontFamily: AppTypography.sans,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: AppCorners.lg),
      ),
    );
  }
}

class _NotesSummary extends StatelessWidget {
  const _NotesSummary({
    required this.visibleCount,
    required this.totalCount,
    required this.hasActiveFilters,
  });

  final int visibleCount;
  final int totalCount;
  final bool hasActiveFilters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = hasActiveFilters
        ? '$visibleCount of $totalCount shown'
        : '$totalCount saved ${totalCount == 1 ? 'item' : 'items'}';

    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: AppTypography.sans,
              color: colors.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Text(
          'Newest first',
          style: theme.textTheme.bodySmall?.copyWith(
            fontFamily: AppTypography.sans,
            color: colors.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.annotation,
    required this.bookTitle,
    required this.bookType,
    required this.onTap,
    required this.onDelete,
  });

  final ReaderAnnotation annotation;
  final String bookTitle;
  final BookFileType? bookType;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final markerColor = annotationColorById(annotation.colorId);
    final selectedText = annotationSelectedTextForDisplay(annotation);
    final noteText = plainAnnotationTextForDisplay(annotation.noteText);
    final locationLabel = _annotationLocationLabel(annotation, bookType);

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      backgroundColor: colors.surfaceContainerLowest,
      borderRadius: AppCorners.lg,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x3,
                AppSpacing.x3,
                0,
                AppSpacing.x3,
              ),
              child: _NoteColorRail(color: markerColor),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x3,
                  AppSpacing.x3,
                  AppSpacing.x3,
                  AppSpacing.x3,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bookTitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: colors.onSurface,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  height: 1.22,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.x1),
                              Wrap(
                                spacing: AppSpacing.x2,
                                runSpacing: AppSpacing.x1,
                                children: [
                                  _NoteMetaChip(
                                    label: annotation.displayTypeLabel,
                                  ),
                                  if (locationLabel != null)
                                    _NoteMetaChip(label: locationLabel),
                                  if (annotation.isFavorite)
                                    const _NoteMetaChip(
                                      label: 'Favorite',
                                      icon: Icons.star_rounded,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.x2),
                        _DeleteNoteButton(
                          onPressed: onDelete,
                          tooltip:
                              'Delete ${annotation.displayTypeLabel.toLowerCase()}',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    _SelectedTextPanel(text: selectedText, color: markerColor),
                    if (noteText.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.x2),
                      _ReaderNotePanel(text: noteText),
                    ],
                    const SizedBox(height: AppSpacing.x2),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _OpenReaderButton(onPressed: onTap),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _annotationLocationLabel(
    ReaderAnnotation annotation,
    BookFileType? bookType,
  ) {
    final pdfPage = annotation.pdfPageNumber;
    if (pdfPage != null) return 'Page $pdfPage';

    final progress = annotation.epubProgress;
    if (progress != null) {
      return '${(progress.clamp(0.0, 1.0) * 100).round()}%';
    }

    if (bookType == BookFileType.pdf) return 'PDF';
    if (bookType == BookFileType.epub) return 'EPUB';
    if (bookType == BookFileType.plainText) return 'Text';

    return null;
  }
}

class _NoteColorRail extends StatelessWidget {
  const _NoteColorRail({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 7,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: AppCorners.pill,
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.9),
                borderRadius: AppCorners.pill,
              ),
              child: const SizedBox(width: 5, height: 40),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteNoteButton extends StatelessWidget {
  const _DeleteNoteButton({required this.onPressed, required this.tooltip});

  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: AppCorners.pill,
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          Icons.delete_outline_rounded,
          color: colors.onSurfaceVariant,
        ),
        tooltip: tooltip,
        iconSize: 16,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      ),
    );
  }
}

class _SelectedTextPanel extends StatelessWidget {
  const _SelectedTextPanel({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.lerp(colors.surfaceContainerLow, color, 0.08),
        borderRadius: AppCorners.lg,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x3,
          10,
          AppSpacing.x3,
          10,
        ),
        child: Text(
          text,
          textDirection: annotationTextDirection(text),
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: 14,
            height: 1.56,
            color: colors.onSurface,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _ReaderNotePanel extends StatelessWidget {
  const _ReaderNotePanel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.secondaryContainer.withValues(alpha: 0.36),
        borderRadius: AppCorners.lg,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x3,
          10,
          AppSpacing.x3,
          10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Note',
              style: theme.textTheme.labelSmall?.copyWith(
                fontFamily: AppTypography.sans,
                color: colors.onSurfaceVariant,
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                height: 1.15,
              ),
            ),
            const SizedBox(height: AppSpacing.x1),
            Text(
              text,
              textDirection: annotationTextDirection(text),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.onSurface,
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpenReaderButton extends StatelessWidget {
  const _OpenReaderButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.arrow_forward_rounded, size: 14),
      label: const Text('Open in reader'),
      style: TextButton.styleFrom(
        foregroundColor: colors.secondary,
        backgroundColor: colors.secondaryContainer.withValues(alpha: 0.22),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: const Size(0, 30),
        shape: RoundedRectangleBorder(borderRadius: AppCorners.pill),
        textStyle: theme.textTheme.labelSmall?.copyWith(
          fontFamily: AppTypography.sans,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _NoteMetaChip extends StatelessWidget {
  const _NoteMetaChip({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: AppCorners.pill,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x2,
          vertical: 4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 11, color: colors.primary),
              const SizedBox(width: AppSpacing.x1),
            ],
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontFamily: AppTypography.sans,
                color: colors.onSurfaceVariant,
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyNotes extends StatelessWidget {
  const _EmptyNotes({required this.hasActiveFilters});

  final bool hasActiveFilters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: AppSection(
            backgroundColor: colors.surfaceContainerLow,
            padding: const EdgeInsets.all(AppSpacing.x5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLowest,
                    borderRadius: AppCorners.pill,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.x2),
                    child: Icon(
                      hasActiveFilters
                          ? Icons.filter_alt_off_outlined
                          : Icons.sticky_note_2_outlined,
                      size: 30,
                      color: colors.secondary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.x3),
                Text(
                  hasActiveFilters ? 'No matches' : 'No notes yet',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.x2),
                Text(
                  hasActiveFilters
                      ? 'Clear filters or choose another book.'
                      : 'Highlights, notes, and bookmarks will appear here.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingNotes extends StatelessWidget {
  const _LoadingNotes();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Center(
        child: AppSection(
          backgroundColor: colors.surfaceContainerLow,
          padding: const EdgeInsets.all(AppSpacing.x5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.x3),
              Text(
                'Loading notes',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
