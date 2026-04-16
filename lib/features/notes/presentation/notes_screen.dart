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

  @override
  Widget build(BuildContext context) {
    final books = widget.bookRepository.getBooks();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
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

              return ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x5,
                  AppSpacing.x4,
                  AppSpacing.x5,
                  28,
                ),
                children: [
                  _NotesFilters(
                    books: books,
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
                  ),
                  const SizedBox(height: AppSpacing.x5),
                  if (filtered.isEmpty)
                    const _EmptyNotes()
                  else
                    for (final annotation in filtered)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.x3),
                        child: _NoteCard(
                          annotation: annotation,
                          bookTitle: _bookTitle(annotation.bookId),
                          onTap: () => _openAnnotation(annotation),
                          onDelete: () => _deleteAnnotation(annotation),
                        ),
                      ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<ReaderAnnotation> _applyFilters(List<ReaderAnnotation> annotations) {
    return annotations.where((annotation) {
      if (!annotation.isUserAnnotation) return false;

      final matchesBook = _bookId == null || annotation.bookId == _bookId;
      final matchesType = switch (_typeFilter) {
        _AnnotationTypeFilter.all => true,
        _AnnotationTypeFilter.highlight =>
          annotation.type == ReaderAnnotationType.highlight,
        _AnnotationTypeFilter.note => annotation.type == ReaderAnnotationType.note,
        _AnnotationTypeFilter.bookmark =>
          annotation.type == ReaderAnnotationType.bookmark,
      };
      final matchesFavorite = !_favoritesOnly || annotation.isFavorite;

      return matchesBook && matchesType && matchesFavorite;
    }).toList(growable: false);
  }

  String _bookTitle(String bookId) {
    return widget.bookRepository.getBookById(bookId)?.title ?? 'Unknown book';
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

  void _deleteAnnotation(ReaderAnnotation annotation) {
    widget.annotationRepository.deleteAnnotation(annotation.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleted ${annotation.displayTypeLabel.toLowerCase()}')),
    );
  }

  Future<void> _openExportDialog() async {
    final request = await showDialog<AnnotationExportRequest>(
      context: context,
      builder: (context) {
        return _ExportAnnotationsDialog(
          books: widget.bookRepository.getBooks(),
          initialBookId: _bookId,
          initialFavoritesOnly: _favoritesOnly,
        );
      },
    );
    if (request == null) return;

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
  State<_ExportAnnotationsDialog> createState() => _ExportAnnotationsDialogState();
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
  });

  final List<Book> books;
  final String? selectedBookId;
  final _AnnotationTypeFilter typeFilter;
  final bool favoritesOnly;
  final ValueChanged<String?> onBookChanged;
  final ValueChanged<_AnnotationTypeFilter?> onTypeChanged;
  final ValueChanged<bool> onFavoritesChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const allBooksValue = '__all_books__';

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;

        final bookMenu = DropdownMenu<String>(
          initialSelection: selectedBookId ?? allBooksValue,
          label: const Text('Book'),
          width: compact ? constraints.maxWidth : 260,
          onSelected: (value) {
            onBookChanged(value == allBooksValue ? null : value);
          },
          dropdownMenuEntries: [
            const DropdownMenuEntry<String>(
              value: allBooksValue,
              label: 'All books',
            ),
            for (final book in books)
              DropdownMenuEntry<String>(value: book.id, label: book.title),
          ],
        );

        final typeTabs = AppSegmentedControl<_AnnotationTypeFilter>(
          value: typeFilter,
          onChanged: (value) => onTypeChanged(value),
          options: const [
            AppSegmentedOption(
              value: _AnnotationTypeFilter.all,
              label: 'All',
            ),
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

        final favorites = FilterChip(
          selected: favoritesOnly,
          onSelected: onFavoritesChanged,
          avatar: Icon(
            favoritesOnly ? Icons.star_rounded : Icons.star_border_rounded,
            size: 18,
            color: favoritesOnly ? theme.colorScheme.primary : null,
          ),
          label: const Text('Favorites'),
          labelStyle: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              bookMenu,
              const SizedBox(height: AppSpacing.x3),
              typeTabs,
              const SizedBox(height: AppSpacing.x3),
              Align(
                alignment: Alignment.centerLeft,
                child: favorites,
              ),
            ],
          );
        }

        return Row(
          children: [
            bookMenu,
            const SizedBox(width: AppSpacing.x3),
            Expanded(child: typeTabs),
            const SizedBox(width: AppSpacing.x3),
            favorites,
          ],
        );
      },
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.annotation,
    required this.bookTitle,
    required this.onTap,
    required this.onDelete,
  });

  final ReaderAnnotation annotation;
  final String bookTitle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final markerColor = annotationColorById(annotation.colorId);
    final selectedText = annotationSelectedTextForDisplay(annotation);
    final noteText = plainAnnotationTextForDisplay(annotation.noteText);

    return Material(
      color: Colors.transparent,
      borderRadius: AppCorners.lg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: AppCorners.lg,
            border: Border.all(color: AppBorders.subtle(colors).color),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x4,
              AppSpacing.x4,
              AppSpacing.x3,
              AppSpacing.x4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: markerColor,
                        borderRadius: AppCorners.sm,
                      ),
                      child: const SizedBox(width: 8, height: 34),
                    ),
                    const SizedBox(width: AppSpacing.x3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: AppSpacing.x2,
                            runSpacing: AppSpacing.x1,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                annotation.displayTypeLabel,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                ),
                              ),
                              if (annotation.isFavorite)
                                Icon(
                                  Icons.star_rounded,
                                  size: 17,
                                  color: colors.primary,
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.x1),
                          Text(
                            bookTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline_rounded),
                      tooltip:
                          'Delete ${annotation.displayTypeLabel.toLowerCase()}',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.x3),
                Text(
                  selectedText,
                  textDirection: annotationTextDirection(selectedText),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.45,
                    color: colors.onSurface,
                  ),
                ),
                if (noteText.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.x3),
                  Text(
                    noteText,
                    textDirection: annotationTextDirection(noteText),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.4,
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
}

class _EmptyNotes extends StatelessWidget {
  const _EmptyNotes();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Icon(
            Icons.sticky_note_2_outlined,
            size: 48,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.x4),
          Text(
            'No annotations yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.x2),
          Text(
            'Select text in the reader to save highlights and notes, or save a bookmark from the reader toolbar.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
