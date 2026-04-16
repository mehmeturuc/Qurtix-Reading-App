import 'package:isar/isar.dart';

part 'isar_book_entity.g.dart';

@collection
class IsarBookEntity {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  String domainId = '';

  String title = '';
  String? author;
  String filePath = '';
  String fileType = '';
  String? coverPath;
  DateTime createdAt = DateTime.fromMillisecondsSinceEpoch(0);
  int lastOpenedAtMillis = -1;
}
