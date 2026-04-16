import 'dart:developer';
import 'dart:io';

import 'package:isar/isar.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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
    final entity = _toEntity(book)
      ..isarId = existing?.isarId ?? Isar.autoIncrement;

    _isar.writeTxnSync(() => _collection.putSync(entity));
    _upsertCachedBook(book);
  }

  @override
  void markOpened(String id, DateTime openedAt) {
    final entity = _entityByDomainId(id);
    if (entity == null) return;

    entity.lastOpenedAtMillis = openedAt.millisecondsSinceEpoch;
    _isar.writeTxnSync(() => _collection.putSync(entity));
    _upsertCachedBook(_toDomain(entity));
  }

  @override
  Future<void> deleteBook(String id) async {
    final entity = _entityByDomainId(id);
    if (entity == null) return;

    _isar.writeTxnSync(() => _collection.deleteSync(entity.isarId));
    _books = _books.where((book) => book.id != id).toList(growable: false);
    await _deleteManagedLocalFile(entity.filePath);
  }

  void _seedMockBooksIfNeeded() {
    if (_collection.countSync() > 0) return;

    _isar.writeTxnSync(() {
      _collection.putAllSync(mockBooks.map(_toEntity).toList(growable: false));
    });
  }

  List<Book> _loadBooks() {
    final books = _collection
        .where()
        .findAllSync()
        .map(_toDomain)
        .toList(growable: false);

    return _sortBooksByRecency(books);
  }

  IsarBookEntity? _entityByDomainId(String id) {
    return _collection.getByDomainIdSync(id);
  }

  void _upsertCachedBook(Book book) {
    final next = List<Book>.of(_books);
    final index = next.indexWhere((item) => item.id == book.id);
    if (index == -1) {
      next.add(book);
    } else {
      next[index] = book;
    }

    _books = _sortBooksByRecency(next);
  }

  List<Book> _sortBooksByRecency(List<Book> books) {
    final next = List<Book>.of(books);
    next.sort((a, b) {
      final aDate = a.lastOpenedAt ?? a.createdAt;
      final bDate = b.lastOpenedAt ?? b.createdAt;
      return bDate.compareTo(aDate);
    });

    return next.toList(growable: false);
  }

  Future<void> _deleteManagedLocalFile(String filePath) async {
    if (filePath.trim().isEmpty) return;

    try {
      final appDirectory = await getApplicationDocumentsDirectory();
      final importDirectory = Directory(
        p.join(appDirectory.path, 'qurtix_imports'),
      );
      final normalizedImportPath = p.normalize(
        p.absolute(importDirectory.path),
      );
      final normalizedFilePath = p.normalize(p.absolute(filePath));

      if (!p.isWithin(normalizedImportPath, normalizedFilePath)) return;

      final file = File(normalizedFilePath);
      if (!file.existsSync()) return;

      await file.delete();
    } catch (error, stackTrace) {
      log(
        'Failed to delete managed book file at $filePath',
        name: 'IsarBookRepository',
        error: error,
        stackTrace: stackTrace,
      );
    }
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

    final author = entity.author;
    final coverPath = entity.coverPath;

    return Book(
      id: entity.domainId,
      title: entity.title,
      author: (author == null || author.isEmpty) ? null : author,
      filePath: entity.filePath,
      fileType: entity.fileType,
      coverPath: (coverPath == null || coverPath.isEmpty) ? null : coverPath,
      createdAt: entity.createdAt,
      lastOpenedAt: lastOpenedAt,
    );
  }
}
