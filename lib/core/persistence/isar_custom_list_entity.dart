import 'package:isar/isar.dart';

part 'isar_custom_list_entity.g.dart';

@collection
class IsarCustomListEntity {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  String domainId = '';

  String name = '';
  DateTime createdAt = DateTime.fromMillisecondsSinceEpoch(0);
}
