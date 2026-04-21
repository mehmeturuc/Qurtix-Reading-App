import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/utils/responsive_grid.dart';
import '../../../shared/design/app_design.dart';
import '../../../shared/widgets/app_page.dart';
import '../../lists/domain/custom_list.dart';
import '../../lists/domain/list_repository.dart';
import '../../reader/domain/annotation_repository.dart';
import '../../reader/domain/reader_annotation.dart';
import '../../reader/presentation/reader_screen.dart';
import '../application/document_import_service.dart';
import '../domain/book.dart';
import '../domain/book_repository.dart';
import 'widgets/book_card.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({
    required this.bookRepository,
    required this.annotationRepository,
    required this.listRepository,
    super.key,
  });

  final BookRepository bookRepository;
  final AnnotationRepository annotationRepository;
  final ListRepository listRepository;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final DocumentImportService _importService = DocumentImportService();
  final TextEditingController _searchController = TextEditingController();
  bool _isImporting = false;
  bool _isSearchVisible = false;
  String _searchQuery = '';
  String? _selectedCollection;

  @override
  void initState() {
    super.initState();
    _scheduleAnnotationLoad();
  }

  @override
  void didUpdateWidget(covariant LibraryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.annotationRepository != widget.annotationRepository) {
      _scheduleAnnotationLoad();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final allBooks = widget.bookRepository.getBooks();
    final collectionByBookId = _collectionMapFor(allBooks);
    final books = _filteredBooks(allBooks, collectionByBookId);
    final collections = _collections(allBooks, collectionByBookId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            onPressed: _toggleSearch,
            icon: Icon(
              _isSearchVisible || _searchQuery.isNotEmpty
                  ? Icons.close_rounded
                  : Icons.search_rounded,
            ),
            tooltip: _isSearchVisible || _searchQuery.isNotEmpty
                ? 'Close search'
                : 'Search',
          ),
        ],
      ),
      body: SafeArea(
        child: AppPage(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x5,
                  0,
                  AppSpacing.x6,
                  AppSpacing.x1,
                ),
                child: _LibraryHeader(
                  visibleCount: books.length,
                  totalCount: allBooks.length,
                  collectionCount: collections.length,
                  selectedCollection: _selectedCollection,
                  isImporting: _isImporting,
                  onImport: _importBook,
                ),
              ),
              if (collections.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.x5,
                    AppSpacing.x1,
                    AppSpacing.x6,
                    0,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: AppSpacing.x2,
                      runSpacing: AppSpacing.x2,
                      children: [
                        AppFilterChip(
                          selected: _selectedCollection == null,
                          label: 'All',
                          onSelected: (_) {
                            setState(() => _selectedCollection = null);
                          },
                        ),
                        for (final collection in collections)
                          AppFilterChip(
                            selected: _selectedCollection == collection,
                            label: collection,
                            onSelected: (_) {
                              setState(() => _selectedCollection = collection);
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeOutCubic,
                child: _isSearchVisible
                    ? Padding(
                        key: const ValueKey('library-search'),
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.x5,
                          AppSpacing.x2,
                          AppSpacing.x6,
                          0,
                        ),
                        child: _LibrarySearchField(
                          controller: _searchController,
                          onChanged: _setSearchQuery,
                          onClear: () => _clearSearch(),
                        ),
                      )
                    : const SizedBox.shrink(
                        key: ValueKey('library-search-hidden'),
                      ),
              ),
              Expanded(
                child: ValueListenableBuilder<List<ReaderAnnotation>>(
                  valueListenable: widget.annotationRepository
                      .watchAnnotations(),
                  builder: (context, annotations, _) {
                    final progressByBookId = _progressByBookId(annotations);

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = ResponsiveGrid.columnsForWidth(
                          constraints.maxWidth,
                        );
                        final cardExtent = _bookCardExtent(
                          width: constraints.maxWidth,
                          columns: columns,
                        );

                        if (books.isEmpty) {
                          return Center(
                            child: AppSection(
                              padding: const EdgeInsets.all(AppSpacing.x8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.menu_book_outlined,
                                    color: colors.secondary,
                                    size: 36,
                                  ),
                                  const SizedBox(height: AppSpacing.x4),
                                  Text(
                                    _emptyTitle,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: AppSpacing.x2),
                                  Text(
                                    _emptyMessage,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.x5,
                            AppSpacing.x2,
                            AppSpacing.x6,
                            28,
                          ),
                          itemCount: books.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: AppSpacing.x4,
                                mainAxisSpacing: AppSpacing.x4,
                                mainAxisExtent: cardExtent,
                              ),
                          itemBuilder: (context, index) {
                            final book = books[index];

                            return BookCard(
                              book: book,
                              collectionName: collectionByBookId[book.id],
                              progress: progressByBookId[book.id],
                              onTap: () => _openBook(context, book),
                              onActionSelected: (action) {
                                switch (action) {
                                  case BookCardAction.organize:
                                    _organizeBook(book);
                                  case BookCardAction.removeFromCollection:
                                    _removeBookFromCollection(book);
                                  case BookCardAction.delete:
                                    _confirmDeleteBook(book);
                                }
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _scheduleAnnotationLoad() {
    if (widget.annotationRepository.isLoaded) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.annotationRepository.isLoaded) return;
      unawaited(_loadAnnotations());
    });
  }

  Future<void> _loadAnnotations() async {
    try {
      await widget.annotationRepository.ensureLoaded();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load reading progress')),
      );
    }
  }

  Map<String, BookCardProgress> _progressByBookId(
    List<ReaderAnnotation> annotations,
  ) {
    final values = <String, BookCardProgress>{};

    for (final annotation in annotations) {
      if (!annotation.isReaderState) continue;

      final book = widget.bookRepository.getBookById(annotation.bookId);
      if (book == null) continue;

      final progress = _progressForBook(book, annotation);
      if (progress != null) values[book.id] = progress;
    }

    return values;
  }

  BookCardProgress? _progressForBook(Book book, ReaderAnnotation annotation) {
    switch (book.sourceType) {
      case BookFileType.pdf:
        final page = annotation.pdfPageNumber;
        if (page == null) return null;

        final progress = annotation.pdfProgress;
        final totalPages = annotation.pdfTotalPages;
        final label = totalPages == null
            ? 'Page $page'
            : 'Page $page of $totalPages - ${_percentLabel(progress ?? 0)}';

        return BookCardProgress(label: label, progress: progress ?? 0);
      case BookFileType.epub:
        final progress = annotation.epubProgress;
        if (progress == null) return null;

        final chapter = annotation.epubChapterIndex;
        final sourceOffset = annotation.epubSourceOffset;
        final place = chapter != null
            ? 'Chapter ${chapter + 1}'
            : sourceOffset != null
            ? 'Location ${_compactNumber(sourceOffset + 1)}'
            : 'Progress';

        return BookCardProgress(
          label: '$place - ${_percentLabel(progress)}',
          progress: progress,
        );
      case BookFileType.plainText:
        final progress = annotation.epubProgress;
        if (progress == null) return null;

        return BookCardProgress(
          label: 'Progress - ${_percentLabel(progress)}',
          progress: progress,
        );
    }
  }

  String _percentLabel(double progress) {
    return '${(progress.clamp(0.0, 1.0) * 100).round()}%';
  }

  String _compactNumber(int value) {
    final text = value.toString();
    final buffer = StringBuffer();

    for (var index = 0; index < text.length; index++) {
      if (index > 0 && (text.length - index) % 3 == 0) buffer.write(',');
      buffer.write(text[index]);
    }

    return buffer.toString();
  }

  double _bookCardExtent({required double width, required int columns}) {
    const horizontalPadding = AppSpacing.x5 + AppSpacing.x6;
    const crossAxisSpacing = AppSpacing.x4;
    final totalSpacing = crossAxisSpacing * (columns - 1);
    final tileWidth = (width - horizontalPadding - totalSpacing) / columns;

    return BookCard.heightForWidth(tileWidth);
  }

  List<Book> _filteredBooks(
    List<Book> books,
    Map<String, String> collectionByBookId,
  ) {
    final selected = _selectedCollection;
    final query = _searchQuery.trim().toLowerCase();

    return books
        .where((book) {
          final matchesCollection =
              selected == null || collectionByBookId[book.id] == selected;
          if (!matchesCollection) return false;
          if (query.isEmpty) return true;

          final collection = collectionByBookId[book.id] ?? '';
          final fields = [
            book.title,
            book.author ?? '',
            book.fileType,
            book.sourceType.label,
            collection,
          ].join(' ').toLowerCase();

          return fields.contains(query);
        })
        .toList(growable: false);
  }

  String get _emptyTitle {
    if (_searchQuery.trim().isNotEmpty) return 'No matching books';
    if (_selectedCollection == null) return 'Your shelf is ready';

    return 'No books in this folder';
  }

  String get _emptyMessage {
    if (_searchQuery.trim().isNotEmpty) {
      return 'Try a title, author, format, or folder name.';
    }
    if (_selectedCollection == null) return 'Import a PDF or EPUB to begin.';

    return 'Move a book here from its menu.';
  }

  Map<String, String> _collectionMapFor(List<Book> books) {
    final values = <String, String>{};

    for (final book in books) {
      final collection = widget.listRepository.getCollectionForBook(book.id);
      if (collection != null && collection.isNotEmpty) {
        values[book.id] = collection;
      }
    }

    return values;
  }

  List<String> _collections(
    List<Book> books,
    Map<String, String> collectionByBookId,
  ) {
    final values = <String>{};

    for (final list in widget.listRepository.getLists()) {
      final value = list.name.trim();
      if (value.isNotEmpty) values.add(value);
    }

    for (final book in books) {
      final value = collectionByBookId[book.id];
      if (value != null && value.isNotEmpty) values.add(value);
    }

    return values.toList()..sort();
  }

  Future<void> _importBook() async {
    setState(() => _isImporting = true);

    try {
      final book = await _importService.pickDocument();
      if (!mounted || book == null) return;

      widget.bookRepository.addBook(book);
      setState(() {});

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Imported ${book.title}')));
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not import this document')),
      );
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  void _toggleSearch() {
    setState(() {
      if (_isSearchVisible || _searchQuery.isNotEmpty) {
        _clearSearch(shouldSetState: false);
        _isSearchVisible = false;
      } else {
        _isSearchVisible = true;
      }
    });
  }

  void _setSearchQuery(String value) {
    setState(() => _searchQuery = value);
  }

  void _clearSearch({bool shouldSetState = true}) {
    _searchController.clear();
    if (shouldSetState) {
      setState(() => _searchQuery = '');
    } else {
      _searchQuery = '';
    }
  }

  void _openBook(BuildContext context, Book book) {
    widget.bookRepository.markOpened(book.id, DateTime.now());
    setState(() {});

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReaderScreen(
          book: book,
          annotationRepository: widget.annotationRepository,
        ),
      ),
    );
  }

  Future<void> _organizeBook(Book book) async {
    final books = widget.bookRepository.getBooks();
    final collectionByBookId = _collectionMapFor(books);
    final result = await showDialog<_CollectionEditResult>(
      context: context,
      builder: (_) => _OrganizeBookDialog(
        initialCollection: widget.listRepository.getCollectionForBook(book.id),
        collections: _collections(books, collectionByBookId),
      ),
    );
    if (!mounted) return;
    if (result == null || result.action == _CollectionEditAction.cancel) {
      return;
    }

    if (result.action == _CollectionEditAction.remove) {
      _removeBookFromCollection(book);
    } else {
      final value = result.collection.trim();
      if (value.isEmpty) {
        widget.listRepository.setBookCollection(book.id, null);
      } else {
        final exists = widget.listRepository.getLists().any(
          (list) => list.name.trim() == value,
        );
        if (!exists) {
          widget.listRepository.addList(
            CustomList(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              name: value,
              createdAt: DateTime.now(),
            ),
          );
        }
        widget.listRepository.setBookCollection(book.id, value);
      }
    }

    _refreshLibraryState();
  }

  void _removeBookFromCollection(Book book, {bool showMessage = true}) {
    final collection = widget.listRepository.getCollectionForBook(book.id);
    if (collection == null) return;

    widget.listRepository.setBookCollection(book.id, null);
    _refreshLibraryState();

    if (!showMessage || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Removed ${book.title} from $collection')),
    );
  }

  void _refreshLibraryState() {
    if (!mounted) return;

    final selected = _selectedCollection;
    final books = widget.bookRepository.getBooks();
    final availableCollections = _collections(books, _collectionMapFor(books));
    setState(() {
      if (selected != null && !availableCollections.contains(selected)) {
        _selectedCollection = null;
      }
    });
  }

  Future<void> _confirmDeleteBook(Book book) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete book completely?'),
          content: Text(
            'This permanently removes "${book.title}" from your library and deletes its notes, highlights, bookmarks, and reading position.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (shouldDelete != true) return;

    try {
      widget.annotationRepository.deleteAnnotationsForBook(book.id);
      widget.listRepository.setBookCollection(book.id, null);
      await widget.bookRepository.deleteBook(book.id);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete this book')),
      );
      return;
    }

    if (!mounted) return;
    _refreshLibraryState();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Deleted ${book.title}')));
  }
}

class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader({
    required this.visibleCount,
    required this.totalCount,
    required this.collectionCount,
    required this.selectedCollection,
    required this.isImporting,
    required this.onImport,
  });

  final int visibleCount;
  final int totalCount;
  final int collectionCount;
  final String? selectedCollection;
  final bool isImporting;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final title = selectedCollection ?? 'Curated shelf';
    final countLabel = selectedCollection == null
        ? '$totalCount books'
        : '$visibleCount of $totalCount books';

    return AppSection(
      backgroundColor: colors.surfaceContainerLow,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x5,
        AppSpacing.x3,
        AppSpacing.x5,
        AppSpacing.x3,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 560;
          final eyebrow = selectedCollection == null ? 'Library' : 'Folder';
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontFamily: AppTypography.sans,
                  color: colors.secondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: isCompact
                    ? theme.textTheme.titleMedium?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      )
                    : theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
              ),
              SizedBox(height: isCompact ? AppSpacing.x2 : AppSpacing.x3),
              Wrap(
                spacing: AppSpacing.x2,
                runSpacing: AppSpacing.x1,
                children: [
                  AppPill(
                    backgroundColor: colors.surfaceContainerLowest,
                    foregroundColor: colors.onSurfaceVariant,
                    child: Text(countLabel, style: theme.textTheme.labelSmall),
                  ),
                  AppPill(
                    backgroundColor: colors.secondaryContainer,
                    foregroundColor: colors.onSecondaryContainer,
                    child: Text(
                      '$collectionCount folders',
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                ],
              ),
            ],
          );
          final button = _ImportButton(
            isImporting: isImporting,
            onTap: onImport,
          );

          if (isCompact) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: copy),
                const SizedBox(width: AppSpacing.x3),
                button,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: copy),
              const SizedBox(width: AppSpacing.x4),
              button,
            ],
          );
        },
      ),
    );
  }
}

class _LibrarySearchField extends StatelessWidget {
  const _LibrarySearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AppSection(
      backgroundColor: colors.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x3,
        vertical: AppSpacing.x1,
      ),
      child: TextField(
        controller: controller,
        autofocus: true,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontFamily: AppTypography.sans,
          color: colors.onSurface,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Search title, author, format, or folder',
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            fontFamily: AppTypography.sans,
            color: colors.onSurfaceVariant,
            fontSize: 13,
          ),
          border: InputBorder.none,
          isDense: true,
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 18,
            color: colors.onSurfaceVariant,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 34,
            minHeight: 34,
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              if (value.text.isEmpty) return const SizedBox.shrink();

              return IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded),
                iconSize: 17,
                tooltip: 'Clear search',
                visualDensity: VisualDensity.compact,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ImportButton extends StatelessWidget {
  const _ImportButton({required this.isImporting, required this.onTap});

  final bool isImporting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppGradients.primarySatin,
        borderRadius: AppCorners.pill,
      ),
      child: FilledButton.icon(
        onPressed: isImporting ? null : onTap,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x3,
            vertical: AppSpacing.x2,
          ),
          minimumSize: const Size(0, 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: isImporting
            ? SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.onPrimary,
                ),
              )
            : const Icon(Icons.upload_file_rounded),
        label: const Text('Import'),
      ),
    );
  }
}

enum _CollectionEditAction { save, remove, cancel }

class _CollectionEditResult {
  const _CollectionEditResult._(this.action, [this.collection = '']);

  const _CollectionEditResult.save(String collection)
    : this._(_CollectionEditAction.save, collection);

  const _CollectionEditResult.remove() : this._(_CollectionEditAction.remove);

  const _CollectionEditResult.cancel() : this._(_CollectionEditAction.cancel);

  final _CollectionEditAction action;
  final String collection;
}

class _OrganizeBookDialog extends StatefulWidget {
  const _OrganizeBookDialog({
    required this.initialCollection,
    required this.collections,
  });

  final String? initialCollection;
  final List<String> collections;

  @override
  State<_OrganizeBookDialog> createState() => _OrganizeBookDialogState();
}

class _OrganizeBookDialogState extends State<_OrganizeBookDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialCollection ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Move to folder'),
      scrollable: true,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.collections.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in widget.collections)
                    ActionChip(
                      label: Text(item),
                      onPressed: () => _selectCollection(item),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Folder',
                hintText: 'Favorites, Research, Fiction...',
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.initialCollection != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(const _CollectionEditResult.remove());
            },
            child: const Text('Remove from folder'),
          ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(const _CollectionEditResult.cancel());
          },
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }

  void _selectCollection(String collection) {
    _controller.value = TextEditingValue(
      text: collection,
      selection: TextSelection.collapsed(offset: collection.length),
    );
  }

  void _save() {
    Navigator.of(
      context,
    ).pop(_CollectionEditResult.save(_controller.text.trim()));
  }
}
