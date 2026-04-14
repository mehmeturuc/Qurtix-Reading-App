import 'book.dart';

abstract class BookRepository {
  List<Book> getBooks();

  Book? getBookById(String id);

  void markOpened(String id, DateTime openedAt);
}
