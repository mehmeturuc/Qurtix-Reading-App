import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import '../../../core/persistence/isar_collections.dart';
import '../domain/annotation_repository.dart';
import '../domain/reader_annotation.dart';

class IsarAnnotationRepository implements AnnotationRepository {
  IsarAnnotationRepository(this._isar)
      : _annotations = ValueNotifier<List<ReaderAnnotation>>(const []) {
    _subscription = _collection.watchLazy().listen((_) => _scheduleReload());
  }

  final Isar _isar;
  final ValueNotifier<List<ReaderAnnotation>> _annotations;
  List<ReaderAnnotation> _cache = const [];
  late final StreamSubscription<void> _subscription;
  Timer? _reloadTimer;
  Future<void>? _reloadFuture;
  bool _hasLoaded = false;
  bool _reloadRequested = false;
  bool _isDisposed = false;

  IsarCollection<IsarReaderAnnotationEntity> get _collection {
    return _isar.collection<IsarReaderAnnotationEntity>();
  }

  @override
  bool get isLoaded => _hasLoaded;

  @override
  ValueListenable<List<ReaderAnnotation>> watchAnnotations() {
    return _annotations;
  }

  @override
  Future<void> ensureLoaded() {
    if (_hasLoaded) return Future<void>.value();

    return _startReload(deferFirstWork: true);
  }

  @override
  List<ReaderAnnotation> getAnnotations() {
    return _cache;
  }

  @override
  List<ReaderAnnotation> getAnnotationsForBook(String bookId) {
    return _cache
        .where((annotation) => annotation.bookId == bookId)
        .toList(growable: false);
  }

  @override
  void addAnnotation(ReaderAnnotation annotation) {
    final existing = _entityByDomainId(annotation.id);
    final entity = _toEntity(annotation)
      ..isarId = existing?.isarId ?? Isar.autoIncrement;

    _isar.writeTxnSync(() => _collection.putSync(entity));
    _upsertInMemory(annotation);
  }

  @override
  void deleteAnnotation(String id) {
    final entity = _entityByDomainId(id);
    if (entity == null) return;

    _isar.writeTxnSync(() => _collection.deleteSync(entity.isarId));
    _removeInMemory((annotation) => annotation.id == id);
  }

  @override
  void deleteAnnotationsForBook(String bookId) {
    final ids = _collection
        .where()
        .bookIdEqualTo(bookId)
        .findAllSync()
        .map((entity) => entity.isarId)
        .toList(growable: false);
    if (ids.isEmpty) return;

    _isar.writeTxnSync(() => _collection.deleteAllSync(ids));
    _removeInMemory((annotation) => annotation.bookId == bookId);
  }

  void dispose() {
    _isDisposed = true;
    _reloadTimer?.cancel();
    unawaited(_subscription.cancel());
    _annotations.dispose();
  }

  void _scheduleReload() {
    if (_isDisposed) return;
    if (!_hasLoaded) {
      _reloadRequested = true;
      return;
    }
    if (_reloadFuture != null) {
      _reloadRequested = true;
      return;
    }
    if (_reloadTimer?.isActive ?? false) return;

    _reloadTimer = Timer(
      const Duration(milliseconds: 120),
      () => unawaited(
        _startReload(deferFirstWork: false).catchError((_) {}),
      ),
    );
  }

  Future<void> _startReload({required bool deferFirstWork}) {
    final existing = _reloadFuture;
    if (existing != null) {
      _reloadRequested = true;
      return existing;
    }

    final future = _reload(deferFirstWork: deferFirstWork);
    _reloadFuture = future;

    unawaited(
      future.then<void>((_) {}, onError: (_) {}).whenComplete(() {
        if (_reloadFuture == future) _reloadFuture = null;
        if (_isDisposed) return;

        if (_reloadRequested) {
          _reloadRequested = false;
          _scheduleReload();
        }
      }),
    );

    return future;
  }

  Future<void> _reload({required bool deferFirstWork}) async {
    if (_isDisposed) return;
    if (deferFirstWork) await Future<void>.delayed(Duration.zero);
    if (_isDisposed) return;

    final entities = await _collection.where().findAll();
    if (_isDisposed) return;

    final annotations = entities.map(_toDomain).toList(growable: false);
    final sortedAnnotations = annotations.length < 80
        ? (List<ReaderAnnotation>.of(annotations)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)))
        : await compute(_sortAnnotationsByCreatedAtDesc, annotations);
    if (_isDisposed) return;

    _hasLoaded = true;
    _setAnnotations(sortedAnnotations);
  }

  void _upsertInMemory(ReaderAnnotation annotation) {
    final next = List<ReaderAnnotation>.of(_cache);
    final index = next.indexWhere((item) => item.id == annotation.id);
    if (index == -1) {
      next.add(annotation);
    } else {
      next[index] = annotation;
    }
    next.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final value = List<ReaderAnnotation>.unmodifiable(next);
    _setAnnotations(value);
  }

  void _removeInMemory(bool Function(ReaderAnnotation annotation) test) {
    final next = _cache
        .where((annotation) => !test(annotation))
        .toList(growable: false);
    _setAnnotations(next);
  }

  void _setAnnotations(List<ReaderAnnotation> annotations) {
    final value = List<ReaderAnnotation>.unmodifiable(annotations);
    final shouldNotify = _hasUserAnnotationChanges(_annotations.value, value);
    _cache = value;
    if (shouldNotify) {
      _annotations.value = value;
    }
  }

  bool _hasUserAnnotationChanges(
    List<ReaderAnnotation> previous,
    List<ReaderAnnotation> next,
  ) {
    final previousUserAnnotations = previous
        .where((annotation) => annotation.isUserAnnotation)
        .toList(growable: false);
    final nextUserAnnotations = next
        .where((annotation) => annotation.isUserAnnotation)
        .toList(growable: false);

    if (previousUserAnnotations.length != nextUserAnnotations.length) {
      return true;
    }

    for (var index = 0; index < nextUserAnnotations.length; index++) {
      if (!_sameAnnotation(
        previousUserAnnotations[index],
        nextUserAnnotations[index],
      )) {
        return true;
      }
    }

    return false;
  }

  bool _sameAnnotation(ReaderAnnotation a, ReaderAnnotation b) {
    return a.id == b.id &&
        a.bookId == b.bookId &&
        a.selectedText == b.selectedText &&
        a.noteText == b.noteText &&
        a.type == b.type &&
        a.colorId == b.colorId &&
        a.isFavorite == b.isFavorite &&
        a.createdAt == b.createdAt &&
        a.updatedAt == b.updatedAt &&
        a.locationRef == b.locationRef;
  }

  IsarReaderAnnotationEntity? _entityByDomainId(String id) {
    return _collection.getByDomainIdSync(id);
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

List<ReaderAnnotation> _sortAnnotationsByCreatedAtDesc(
  List<ReaderAnnotation> annotations,
) {
  return List<ReaderAnnotation>.of(annotations)
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}
