import 'package:flutter/material.dart';

import '../../../core/utils/responsive_grid.dart';
import '../../../shared/design/app_design.dart';
import '../../../shared/widgets/app_page.dart';
import '../../lists/domain/custom_list.dart';
import '../../lists/domain/list_repository.dart';
import '../../reader/domain/annotation_repository.dart';
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
  bool _isImporting = false;
  String? _selectedCollection;

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
            onPressed: _isImporting ? null : _importBook,
            icon: _isImporting
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file_rounded),
            tooltip: 'Import PDF or EPUB',
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search',
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
              Expanded(
                child: LayoutBuilder(
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
                                _selectedCollection == null
                                    ? 'Your shelf is ready'
                                    : 'No books in this folder',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: AppSpacing.x2),
                              Text(
                                _selectedCollection == null
                                    ? 'Import a PDF or EPUB to begin.'
                                    : 'Move a book here from its menu.',
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
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    if (selected == null) return books;

    return books
        .where((book) => collectionByBookId[book.id] == selected)
        .toList(growable: false);
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
        AppSpacing.x4,
        AppSpacing.x3,
        AppSpacing.x4,
        AppSpacing.x2,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 560;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              SizedBox(height: isCompact ? AppSpacing.x1 : AppSpacing.x2),
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
          final button = DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppGradients.primarySatin,
              borderRadius: AppCorners.pill,
            ),
            child: FilledButton.icon(
              onPressed: isImporting ? null : onImport,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.x3,
                  vertical: AppSpacing.x2,
                ),
                minimumSize: const Size(0, 34),
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

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copy,
                const SizedBox(height: AppSpacing.x3),
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
