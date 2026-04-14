import '../domain/book.dart';
import '../domain/book_repository.dart';
import 'mock_books.dart';

class InMemoryBookRepository implements BookRepository {
  InMemoryBookRepository({List<Book>? initialBooks})
      : _books = List<Book>.of(initialBooks ?? mockBooks);

  final List<Book> _books;

  @override
  List<Book> getBooks() {
    return List<Book>.unmodifiable(_books);
  }

  @override
  Book? getBookById(String id) {
    for (final book in _books) {
      if (book.id == id) return book;
    }

    return null;
  }

  @override
  void markOpened(String id, DateTime openedAt) {
    final index = _books.indexWhere((book) => book.id == id);
    if (index == -1) return;

    _books[index] = _books[index].copyWith(lastOpenedAt: openedAt);
  }
}
