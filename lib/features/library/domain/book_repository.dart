import 'book.dart';

abstract class BookRepository {
  List<Book> getBooks();

  Book? getBookById(String id);

  void addBook(Book book);

  void markOpened(String id, DateTime openedAt);

  Future<void> deleteBook(String id);
}
