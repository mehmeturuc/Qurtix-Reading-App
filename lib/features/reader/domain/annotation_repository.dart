import 'package:flutter/foundation.dart';

import 'reader_annotation.dart';

abstract class AnnotationRepository {
  ValueListenable<List<ReaderAnnotation>> watchAnnotations();

  List<ReaderAnnotation> getAnnotations();

  List<ReaderAnnotation> getAnnotationsForBook(String bookId);

  void addAnnotation(ReaderAnnotation annotation);

  void deleteAnnotation(String id);
}
