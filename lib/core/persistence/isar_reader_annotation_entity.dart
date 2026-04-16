import 'package:isar/isar.dart';

part 'isar_reader_annotation_entity.g.dart';

@collection
class IsarReaderAnnotationEntity {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  String domainId = '';

  @Index()
  String bookId = '';

  String selectedText = '';
  String noteText = '';
  String type = '';
  String colorId = '';
  bool isFavorite = false;
  DateTime createdAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime updatedAt = DateTime.fromMillisecondsSinceEpoch(0);
  String locationRef = '';
}
