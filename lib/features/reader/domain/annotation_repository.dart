import 'package:flutter/foundation.dart';

import 'reader_annotation.dart';

abstract class AnnotationRepository {
  bool get isLoaded;

  ValueListenable<List<ReaderAnnotation>> watchAnnotations();

  Future<void> ensureLoaded();

  List<ReaderAnnotation> getAnnotations();

  List<ReaderAnnotation> getAnnotationsForBook(String bookId);

  void addAnnotation(ReaderAnnotation annotation);

  void deleteAnnotation(String id);

  void deleteAnnotationsForBook(String bookId);
}
