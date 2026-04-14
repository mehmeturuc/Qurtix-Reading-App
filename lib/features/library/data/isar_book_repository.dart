import 'package:isar/isar.dart';

import '../../../core/persistence/isar_collections.dart';
import '../domain/book.dart';
import '../domain/book_repository.dart';
import 'mock_books.dart';

class IsarBookRepository implements BookRepository {
  IsarBookRepository(this._isar) {
    _seedMockBooksIfNeeded();
    _books = _loadBooks();
  }

  final Isar _isar;
  late List<Book> _books;

  IsarCollection<IsarBookEntity> get _collection {
    return _isar.collection<IsarBookEntity>();
  }

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
    final existing = _entityByDomainId(book.id);
    final entity = _toEntity(book)..isarId = existing?.isarId ?? Isar.autoIncrement;

    _isar.writeTxnSync(() => _collection.putSync(entity));
    _books = _loadBooks();
  }

  @override
  void markOpened(String id, DateTime openedAt) {
    final entity = _entityByDomainId(id);
    if (entity == null) return;

    entity.lastOpenedAtMillis = openedAt.millisecondsSinceEpoch;
    _isar.writeTxnSync(() => _collection.putSync(entity));
    _books = _loadBooks();
  }

  @override
  void deleteBook(String id) {
    final entity = _entityByDomainId(id);
    if (entity == null) return;

    _isar.writeTxnSync(() => _collection.deleteSync(entity.isarId));
    _books = _loadBooks();
  }

  void _seedMockBooksIfNeeded() {
    if (_collection.countSync() > 0) return;

    _isar.writeTxnSync(() {
      _collection.putAllSync(mockBooks.map(_toEntity).toList(growable: false));
    });
  }

  List<Book> _loadBooks() {
    return _collection
        .where()
        .findAllSync()
        .map(_toDomain)
        .toList(growable: false);
  }

  IsarBookEntity? _entityByDomainId(String id) {
    for (final entity in _collection.where().findAllSync()) {
      if (entity.domainId == id) return entity;
    }

    return null;
  }

  IsarBookEntity _toEntity(Book book) {
    return IsarBookEntity()
      ..domainId = book.id
      ..title = book.title
      ..author = book.author ?? ''
      ..filePath = book.filePath
      ..fileType = book.fileType
      ..coverPath = book.coverPath ?? ''
      ..createdAt = book.createdAt
      ..lastOpenedAtMillis = book.lastOpenedAt?.millisecondsSinceEpoch ?? -1;
  }

  Book _toDomain(IsarBookEntity entity) {
    final lastOpenedAt = entity.lastOpenedAtMillis < 0
        ? null
        : DateTime.fromMillisecondsSinceEpoch(entity.lastOpenedAtMillis);

    return Book(
      id: entity.domainId,
      title: entity.title,
      author: entity.author.isEmpty ? null : entity.author,
      filePath: entity.filePath,
      fileType: entity.fileType,
      coverPath: entity.coverPath.isEmpty ? null : entity.coverPath,
      createdAt: entity.createdAt,
      lastOpenedAt: lastOpenedAt,
    );
  }
}
