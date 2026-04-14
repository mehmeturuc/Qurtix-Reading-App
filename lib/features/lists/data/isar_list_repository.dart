import 'package:isar/isar.dart';

import '../../../core/persistence/isar_collections.dart';
import '../domain/custom_list.dart';
import '../domain/list_repository.dart';

class IsarListRepository implements ListRepository {
  IsarListRepository(this._isar) {
    _lists = _loadLists();
  }

  final Isar _isar;
  late List<CustomList> _lists;

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
    _lists = _loadLists();
  }

  @override
  String? getCollectionForBook(String bookId) {
    final entity = _entityByDomainId(_bookCollectionId(bookId));
    final value = entity?.name.trim();

    return value == null || value.isEmpty ? null : value;
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
      _lists = _loadLists();
      return;
    }

    final entity = IsarCustomListEntity()
      ..isarId = existing?.isarId ?? Isar.autoIncrement
      ..domainId = id
      ..name = value
      ..createdAt = existing?.createdAt ?? DateTime.now();

    _isar.writeTxnSync(() => _collection.putSync(entity));
    _lists = _loadLists();
  }

  List<CustomList> _loadLists() {
    return _collection
        .where()
        .findAllSync()
        .map(_toDomain)
        .where((list) => !list.id.startsWith('book-collection:'))
        .toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  IsarCustomListEntity? _entityByDomainId(String id) {
    for (final entity in _collection.where().findAllSync()) {
      if (entity.domainId == id) return entity;
    }

    return null;
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

  String _bookCollectionId(String bookId) => 'book-collection:$bookId';
}
