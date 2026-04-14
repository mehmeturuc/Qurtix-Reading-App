import 'package:flutter/foundation.dart';

import '../domain/annotation_repository.dart';
import '../domain/reader_annotation.dart';

class InMemoryAnnotationRepository implements AnnotationRepository {
  InMemoryAnnotationRepository({List<ReaderAnnotation>? initialAnnotations})
      : _annotations = ValueNotifier<List<ReaderAnnotation>>(
          List<ReaderAnnotation>.unmodifiable(initialAnnotations ?? const []),
        );

  final ValueNotifier<List<ReaderAnnotation>> _annotations;

  @override
  ValueListenable<List<ReaderAnnotation>> watchAnnotations() {
    return _annotations;
  }

  @override
  List<ReaderAnnotation> getAnnotations() {
    return _annotations.value;
  }

  @override
  List<ReaderAnnotation> getAnnotationsForBook(String bookId) {
    return _annotations.value
        .where((annotation) => annotation.bookId == bookId)
        .toList(growable: false);
  }

  @override
  void addAnnotation(ReaderAnnotation annotation) {
    final existingIndex = _annotations.value.indexWhere(
      (item) => item.id == annotation.id,
    );
    if (existingIndex != -1) {
      final updated = List<ReaderAnnotation>.of(_annotations.value);
      updated[existingIndex] = annotation;
      _annotations.value = List<ReaderAnnotation>.unmodifiable(updated);
      return;
    }

    _annotations.value = List<ReaderAnnotation>.unmodifiable([
      annotation,
      ..._annotations.value,
    ]);
  }

  @override
  void deleteAnnotation(String id) {
    _annotations.value = List<ReaderAnnotation>.unmodifiable(
      _annotations.value.where((annotation) => annotation.id != id),
    );
  }

  @override
  void deleteAnnotationsForBook(String bookId) {
    _annotations.value = List<ReaderAnnotation>.unmodifiable(
      _annotations.value.where((annotation) => annotation.bookId != bookId),
    );
  }
}
