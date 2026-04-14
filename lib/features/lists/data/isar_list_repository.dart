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

  List<CustomList> _loadLists() {
    return _collection
        .where()
        .findAllSync()
        .map(_toDomain)
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
}
