import 'package:isar/isar.dart';

part 'isar_custom_list_entity.g.dart';

@collection
class IsarCustomListEntity {
  Id isarId = Isar.autoIncrement;
  late String domainId;
  late String name;
  late DateTime createdAt;
}
