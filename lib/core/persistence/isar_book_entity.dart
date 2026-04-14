import 'package:isar/isar.dart';

part 'isar_book_entity.g.dart';

@collection
class IsarBookEntity {
  Id isarId = Isar.autoIncrement;
  late String domainId;
  late String title;
  late String author;
  late String filePath;
  late String fileType;
  late String coverPath;
  late DateTime createdAt;
  late int lastOpenedAtMillis;
}
