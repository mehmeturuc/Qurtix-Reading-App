import 'package:isar/isar.dart';

part 'isar_reader_annotation_entity.g.dart';

@collection
class IsarReaderAnnotationEntity {
  Id isarId = Isar.autoIncrement;
  late String domainId;
  late String bookId;
  late String selectedText;
  late String noteText;
  late String type;
  late String colorId;
  late bool isFavorite;
  late DateTime createdAt;
  late DateTime updatedAt;
  late String locationRef;
}
