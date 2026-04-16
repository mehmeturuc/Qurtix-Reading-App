import '../domain/book.dart';
import '../domain/book_repository.dart';
import 'mock_books.dart';

class InMemoryBookRepository implements BookRepository {
  InMemoryBookRepository({List<Book>? initialBooks})
      : _books = _sortBooksByRecency(initialBooks ?? mockBooks);

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
  void addBook(Book book) {
    final existingIndex = _books.indexWhere((item) => item.id == book.id);
    if (existingIndex == -1) {
      _books.add(book);
    } else {
      _books[existingIndex] = book;
    }
    _sortCachedBooks();
  }

  @override
  void markOpened(String id, DateTime openedAt) {
    final index = _books.indexWhere((book) => book.id == id);
    if (index == -1) return;

    _books[index] = _books[index].copyWith(lastOpenedAt: openedAt);
    _sortCachedBooks();
  }

  @override
  Future<void> deleteBook(String id) async {
    _books.removeWhere((book) => book.id == id);
  }

  void _sortCachedBooks() {
    final sorted = _sortBooksByRecency(_books);
    _books
      ..clear()
      ..addAll(sorted);
  }

  static List<Book> _sortBooksByRecency(Iterable<Book> books) {
    final next = List<Book>.of(books);
    next.sort((a, b) {
      final aDate = a.lastOpenedAt ?? a.createdAt;
      final bDate = b.lastOpenedAt ?? b.createdAt;
      return bDate.compareTo(aDate);
    });

    return next;
  }
}
