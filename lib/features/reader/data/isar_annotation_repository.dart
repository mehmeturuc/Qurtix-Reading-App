import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import '../../../core/persistence/isar_collections.dart';
import '../domain/annotation_repository.dart';
import '../domain/reader_annotation.dart';

class IsarAnnotationRepository implements AnnotationRepository {
  IsarAnnotationRepository(this._isar)
      : _annotations = ValueNotifier<List<ReaderAnnotation>>(const []) {
    _reload();
    _subscription = _collection.watchLazy().listen((_) => _reload());
  }

  final Isar _isar;
  final ValueNotifier<List<ReaderAnnotation>> _annotations;
  late final StreamSubscription<void> _subscription;

  IsarCollection<IsarReaderAnnotationEntity> get _collection {
    return _isar.collection<IsarReaderAnnotationEntity>();
  }

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
    final existing = _entityByDomainId(annotation.id);
    final entity = _toEntity(annotation)..isarId = existing?.isarId ?? Isar.autoIncrement;

    _isar.writeTxnSync(() => _collection.putSync(entity));
    _reload();
  }

  @override
  void deleteAnnotation(String id) {
    final entity = _entityByDomainId(id);
    if (entity == null) return;

    _isar.writeTxnSync(() => _collection.deleteSync(entity.isarId));
    _reload();
  }

  @override
  void deleteAnnotationsForBook(String bookId) {
    final ids = _collection
        .where()
        .findAllSync()
        .where((entity) => entity.bookId == bookId)
        .map((entity) => entity.isarId)
        .toList(growable: false);
    if (ids.isEmpty) return;

    _isar.writeTxnSync(() => _collection.deleteAllSync(ids));
    _reload();
  }

  void dispose() {
    _subscription.cancel();
    _annotations.dispose();
  }

  void _reload() {
    final annotations = _collection
        .where()
        .findAllSync()
        .map(_toDomain)
        .toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    _annotations.value = List<ReaderAnnotation>.unmodifiable(annotations);
  }

  IsarReaderAnnotationEntity? _entityByDomainId(String id) {
    for (final entity in _collection.where().findAllSync()) {
      if (entity.domainId == id) return entity;
    }

    return null;
  }

  IsarReaderAnnotationEntity _toEntity(ReaderAnnotation annotation) {
    return IsarReaderAnnotationEntity()
      ..domainId = annotation.id
      ..bookId = annotation.bookId
      ..selectedText = annotation.selectedText
      ..noteText = annotation.noteText
      ..type = annotation.type.name
      ..colorId = annotation.colorId
      ..isFavorite = annotation.isFavorite
      ..createdAt = annotation.createdAt
      ..updatedAt = annotation.updatedAt
      ..locationRef = annotation.locationRef;
  }

  ReaderAnnotation _toDomain(IsarReaderAnnotationEntity entity) {
    return ReaderAnnotation(
      id: entity.domainId,
      bookId: entity.bookId,
      selectedText: entity.selectedText,
      noteText: entity.noteText,
      type: _annotationTypeFromName(entity.type),
      colorId: entity.colorId,
      isFavorite: entity.isFavorite,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      locationRef: entity.locationRef,
    );
  }

  ReaderAnnotationType _annotationTypeFromName(String name) {
    for (final type in ReaderAnnotationType.values) {
      if (type.name == name) return type;
    }

    return ReaderAnnotationType.highlight;
  }
}
