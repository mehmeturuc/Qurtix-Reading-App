import 'package:flutter/material.dart';

import '../../../core/utils/responsive_grid.dart';
import '../../../shared/widgets/app_page.dart';
import '../../reader/domain/annotation_repository.dart';
import '../../reader/presentation/reader_screen.dart';
import '../domain/book.dart';
import '../domain/book_repository.dart';
import 'widgets/book_card.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({
    required this.bookRepository,
    required this.annotationRepository,
    super.key,
  });

  final BookRepository bookRepository;
  final AnnotationRepository annotationRepository;

  @override
  Widget build(BuildContext context) {
    final books = bookRepository.getBooks();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search',
          ),
        ],
      ),
      body: SafeArea(
        child: AppPage(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = ResponsiveGrid.columnsForWidth(
                constraints.maxWidth,
              );

              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                itemCount: books.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 18,
                  childAspectRatio: 0.62,
                ),
                itemBuilder: (context, index) {
                  final book = books[index];

                  return BookCard(
                    book: book,
                    onTap: () => _openBook(context, book),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _openBook(BuildContext context, Book book) {
    bookRepository.markOpened(book.id, DateTime.now());

    Navigator.of(
      context,
    ).push(
      MaterialPageRoute<void>(
        builder: (_) => ReaderScreen(
          book: book,
          annotationRepository: annotationRepository,
        ),
      ),
    );
  }
}
