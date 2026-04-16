import 'package:isar/isar.dart';

import '../../../core/persistence/isar_collections.dart';
import '../domain/custom_list.dart';
import '../domain/list_repository.dart';

class IsarListRepository implements ListRepository {
  IsarListRepository(this._isar) {
    _loadState();
  }

  final Isar _isar;
  late List<CustomList> _lists;
  Map<String, String> _bookCollections = const {};

  IsarCollection<IsarCustomListEntity> get _collection {
    return _isar.collection<IsarCustomListEntity>();
  }

  @override
  List<CustomList> getLists() {
    return List<CustomList>.unmodifiable(_lists);
  }

  @override
  void addList(CustomList list) {
    final existing = _entityByDomainId(list.id);
    final entity = _toEntity(list)..isarId = existing?.isarId ?? Isar.autoIncrement;

    _isar.writeTxnSync(() => _collection.putSync(entity));
    _upsertCachedList(list);
  }

  @override
  String? getCollectionForBook(String bookId) {
    return _bookCollections[bookId];
  }

  @override
  void setBookCollection(String bookId, String? collectionName) {
    final id = _bookCollectionId(bookId);
    final existing = _entityByDomainId(id);
    final value = collectionName?.trim();

    if (value == null || value.isEmpty) {
      if (existing != null) {
        _isar.writeTxnSync(() => _collection.deleteSync(existing.isarId));
      }
      _removeCachedBookCollection(bookId);
      return;
    }

    final entity = IsarCustomListEntity()
      ..isarId = existing?.isarId ?? Isar.autoIncrement
      ..domainId = id
      ..name = value
      ..createdAt = existing?.createdAt ?? DateTime.now();

    _isar.writeTxnSync(() => _collection.putSync(entity));
    _setCachedBookCollection(bookId, value);
  }

  void _loadState() {
    final lists = <CustomList>[];
    final bookCollections = <String, String>{};

    for (final entity in _collection.where().findAllSync()) {
      if (entity.domainId.startsWith('book-collection:')) {
        final bookId = entity.domainId.substring('book-collection:'.length);
        final value = entity.name.trim();
        if (bookId.isNotEmpty && value.isNotEmpty) {
          bookCollections[bookId] = value;
        }
        continue;
      }

      lists.add(_toDomain(entity));
    }

    lists.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _lists = lists.toList(growable: false);
    _bookCollections = Map<String, String>.unmodifiable(bookCollections);
  }

  IsarCustomListEntity? _entityByDomainId(String id) {
    return _collection.getByDomainIdSync(id);
  }

  IsarCustomListEntity _toEntity(CustomList list) {
    return IsarCustomListEntity()
      ..domainId = list.id
      ..name = list.name
      ..createdAt = list.createdAt;
  }

  CustomList _toDomain(IsarCustomListEntity entity) {
    return CustomList(
      id: entity.domainId,
      name: entity.name,
      createdAt: entity.createdAt,
    );
  }

  void _upsertCachedList(CustomList list) {
    final next = List<CustomList>.of(_lists);
    final index = next.indexWhere((item) => item.id == list.id);
    if (index == -1) {
      next.insert(0, list);
    } else {
      next[index] = list;
    }
    next.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _lists = next.toList(growable: false);
  }

  void _setCachedBookCollection(String bookId, String collectionName) {
    _bookCollections = Map<String, String>.unmodifiable({
      ..._bookCollections,
      bookId: collectionName,
    });
  }

  void _removeCachedBookCollection(String bookId) {
    if (!_bookCollections.containsKey(bookId)) return;

    final next = Map<String, String>.of(_bookCollections)..remove(bookId);
    _bookCollections = Map<String, String>.unmodifiable(next);
  }

  String _bookCollectionId(String bookId) => 'book-collection:$bookId';
}
