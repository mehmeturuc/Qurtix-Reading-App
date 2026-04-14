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
    final books = _filteredBooks(widget.bookRepository.getBooks());
    final collections = _collections();

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
              if (collections.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.x5,
                    AppSpacing.x4,
                    AppSpacing.x5,
                    0,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: AppSpacing.x2,
                      runSpacing: AppSpacing.x2,
                      children: [
                        ChoiceChip(
                          selected: _selectedCollection == null,
                          label: const Text('All'),
                          onSelected: (_) {
                            setState(() => _selectedCollection = null);
                          },
                        ),
                        for (final collection in collections)
                          ChoiceChip(
                            selected: _selectedCollection == collection,
                            label: Text(collection),
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

                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.x5,
                        AppSpacing.x4,
                        AppSpacing.x5,
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
                          collectionName: _collectionFor(book.id),
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

  double _bookCardExtent({
    required double width,
    required int columns,
  }) {
    const horizontalPadding = 40.0;
    const crossAxisSpacing = AppSpacing.x4;
    final totalSpacing = crossAxisSpacing * (columns - 1);
    final tileWidth = (width - horizontalPadding - totalSpacing) / columns;

    return BookCard.heightForWidth(tileWidth);
  }

  List<Book> _filteredBooks(List<Book> books) {
    final selected = _selectedCollection;
    if (selected == null) return books;

    return books
        .where((book) => _collectionFor(book.id) == selected)
        .toList(growable: false);
  }

  List<String> _collections() {
    final values = <String>{};

    for (final list in widget.listRepository.getLists()) {
      final value = list.name.trim();
      if (value.isNotEmpty) values.add(value);
    }

    for (final book in widget.bookRepository.getBooks()) {
      final value = _collectionFor(book.id);
      if (value != null && value.isNotEmpty) values.add(value);
    }

    return values.toList()..sort();
  }

  String? _collectionFor(String bookId) {
    return widget.listRepository.getCollectionForBook(bookId);
  }

  Future<void> _importBook() async {
    setState(() => _isImporting = true);

    try {
      final book = await _importService.pickDocument();
      if (!mounted || book == null) return;

      widget.bookRepository.addBook(book);
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported ${book.title}')),
      );
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

    Navigator.of(
      context,
    ).push(
      MaterialPageRoute<void>(
        builder: (_) => ReaderScreen(
          book: book,
          annotationRepository: widget.annotationRepository,
        ),
      ),
    );
  }

  Future<void> _organizeBook(Book book) async {
    final result = await showDialog<_CollectionEditResult>(
      context: context,
      builder: (_) => _OrganizeBookDialog(
        initialCollection: widget.listRepository.getCollectionForBook(book.id),
        collections: _collections(),
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
        final exists = widget.listRepository
            .getLists()
            .any((list) => list.name.trim() == value);
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
    final availableCollections = _collections();
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

    widget.annotationRepository.deleteAnnotationsForBook(book.id);
    widget.listRepository.setBookCollection(book.id, null);
    widget.bookRepository.deleteBook(book.id);

    if (!mounted) return;
    _refreshLibraryState();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleted ${book.title}')),
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
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
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
