// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_reader_annotation_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarReaderAnnotationEntityCollection on Isar {
  IsarCollection<IsarReaderAnnotationEntity> get isarReaderAnnotationEntitys =>
      this.collection();
}

const IsarReaderAnnotationEntitySchema = CollectionSchema(
  name: r'IsarReaderAnnotationEntity',
  id: 2556148724275358079,
  properties: {
    r'bookId': PropertySchema(
      id: 0,
      name: r'bookId',
      type: IsarType.string,
    ),
    r'colorId': PropertySchema(
      id: 1,
      name: r'colorId',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'domainId': PropertySchema(
      id: 3,
      name: r'domainId',
      type: IsarType.string,
    ),
    r'isFavorite': PropertySchema(
      id: 4,
      name: r'isFavorite',
      type: IsarType.bool,
    ),
    r'locationRef': PropertySchema(
      id: 5,
      name: r'locationRef',
      type: IsarType.string,
    ),
    r'noteText': PropertySchema(
      id: 6,
      name: r'noteText',
      type: IsarType.string,
    ),
    r'selectedText': PropertySchema(
      id: 7,
      name: r'selectedText',
      type: IsarType.string,
    ),
    r'type': PropertySchema(
      id: 8,
      name: r'type',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 9,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _isarReaderAnnotationEntityEstimateSize,
  serialize: _isarReaderAnnotationEntitySerialize,
  deserialize: _isarReaderAnnotationEntityDeserialize,
  deserializeProp: _isarReaderAnnotationEntityDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'domainId': IndexSchema(
      id: -9138809277110658179,
      name: r'domainId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'domainId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'bookId': IndexSchema(
      id: 3567540928881766442,
      name: r'bookId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'bookId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _isarReaderAnnotationEntityGetId,
  getLinks: _isarReaderAnnotationEntityGetLinks,
  attach: _isarReaderAnnotationEntityAttach,
  version: '3.1.0+1',
);

int _isarReaderAnnotationEntityEstimateSize(
  IsarReaderAnnotationEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.bookId.length * 3;
  bytesCount += 3 + object.colorId.length * 3;
  bytesCount += 3 + object.domainId.length * 3;
  bytesCount += 3 + object.locationRef.length * 3;
  bytesCount += 3 + object.noteText.length * 3;
  bytesCount += 3 + object.selectedText.length * 3;
  bytesCount += 3 + object.type.length * 3;
  return bytesCount;
}

void _isarReaderAnnotationEntitySerialize(
  IsarReaderAnnotationEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.bookId);
  writer.writeString(offsets[1], object.colorId);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeString(offsets[3], object.domainId);
  writer.writeBool(offsets[4], object.isFavorite);
  writer.writeString(offsets[5], object.locationRef);
  writer.writeString(offsets[6], object.noteText);
  writer.writeString(offsets[7], object.selectedText);
  writer.writeString(offsets[8], object.type);
  writer.writeDateTime(offsets[9], object.updatedAt);
}

IsarReaderAnnotationEntity _isarReaderAnnotationEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarReaderAnnotationEntity();
  object.bookId = reader.readString(offsets[0]);
  object.colorId = reader.readString(offsets[1]);
  object.createdAt = reader.readDateTime(offsets[2]);
  object.domainId = reader.readString(offsets[3]);
  object.isFavorite = reader.readBool(offsets[4]);
  object.isarId = id;
  object.locationRef = reader.readString(offsets[5]);
  object.noteText = reader.readString(offsets[6]);
  object.selectedText = reader.readString(offsets[7]);
  object.type = reader.readString(offsets[8]);
  object.updatedAt = reader.readDateTime(offsets[9]);
  return object;
}

P _isarReaderAnnotationEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarReaderAnnotationEntityGetId(IsarReaderAnnotationEntity object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _isarReaderAnnotationEntityGetLinks(
    IsarReaderAnnotationEntity object) {
  return [];
}

void _isarReaderAnnotationEntityAttach(
    IsarCollection<dynamic> col, Id id, IsarReaderAnnotationEntity object) {
  object.isarId = id;
}

extension IsarReaderAnnotationEntityByIndex
    on IsarCollection<IsarReaderAnnotationEntity> {
  Future<IsarReaderAnnotationEntity?> getByDomainId(String domainId) {
    return getByIndex(r'domainId', [domainId]);
  }

  IsarReaderAnnotationEntity? getByDomainIdSync(String domainId) {
    return getByIndexSync(r'domainId', [domainId]);
  }

  Future<bool> deleteByDomainId(String domainId) {
    return deleteByIndex(r'domainId', [domainId]);
  }

  bool deleteByDomainIdSync(String domainId) {
    return deleteByIndexSync(r'domainId', [domainId]);
  }

  Future<List<IsarReaderAnnotationEntity?>> getAllByDomainId(
      List<String> domainIdValues) {
    final values = domainIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'domainId', values);
  }

  List<IsarReaderAnnotationEntity?> getAllByDomainIdSync(
      List<String> domainIdValues) {
    final values = domainIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'domainId', values);
  }

  Future<int> deleteAllByDomainId(List<String> domainIdValues) {
    final values = domainIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'domainId', values);
  }

  int deleteAllByDomainIdSync(List<String> domainIdValues) {
    final values = domainIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'domainId', values);
  }

  Future<Id> putByDomainId(IsarReaderAnnotationEntity object) {
    return putByIndex(r'domainId', object);
  }

  Id putByDomainIdSync(IsarReaderAnnotationEntity object,
      {bool saveLinks = true}) {
    return putByIndexSync(r'domainId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByDomainId(List<IsarReaderAnnotationEntity> objects) {
    return putAllByIndex(r'domainId', objects);
  }

  List<Id> putAllByDomainIdSync(List<IsarReaderAnnotationEntity> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'domainId', objects, saveLinks: saveLinks);
  }
}

extension IsarReaderAnnotationEntityQueryWhereSort on QueryBuilder<
    IsarReaderAnnotationEntity, IsarReaderAnnotationEntity, QWhere> {
  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarReaderAnnotationEntityQueryWhere on QueryBuilder<
    IsarReaderAnnotationEntity, IsarReaderAnnotationEntity, QWhereClause> {
  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterWhereClause> isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterWhereClause> isarIdNotEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterWhereClause> isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterWhereClause> isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterWhereClause> isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerIsarId,
        includeLower: includeLower,
        upper: upperIsarId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterWhereClause> domainIdEqualTo(String domainId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'domainId',
        value: [domainId],
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterWhereClause> domainIdNotEqualTo(String domainId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'domainId',
              lower: [],
              upper: [domainId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'domainId',
              lower: [domainId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'domainId',
              lower: [domainId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'domainId',
              lower: [],
              upper: [domainId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterWhereClause> bookIdEqualTo(String bookId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'bookId',
        value: [bookId],
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterWhereClause> bookIdNotEqualTo(String bookId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'bookId',
              lower: [],
              upper: [bookId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'bookId',
              lower: [bookId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'bookId',
              lower: [bookId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'bookId',
              lower: [],
              upper: [bookId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension IsarReaderAnnotationEntityQueryFilter on QueryBuilder<
    IsarReaderAnnotationEntity, IsarReaderAnnotationEntity, QFilterCondition> {
  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> bookIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bookId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> bookIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bookId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> bookIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bookId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> bookIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bookId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> bookIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'bookId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> bookIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'bookId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
          QAfterFilterCondition>
      bookIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'bookId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
          QAfterFilterCondition>
      bookIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'bookId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> bookIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bookId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> bookIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'bookId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> colorIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'colorId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> colorIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'colorId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> colorIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'colorId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> colorIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'colorId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> colorIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'colorId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> colorIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'colorId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
          QAfterFilterCondition>
      colorIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'colorId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
          QAfterFilterCondition>
      colorIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'colorId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> colorIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'colorId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> colorIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'colorId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> domainIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'domainId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> domainIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'domainId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> domainIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'domainId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> domainIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'domainId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> domainIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'domainId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> domainIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'domainId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
          QAfterFilterCondition>
      domainIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'domainId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
          QAfterFilterCondition>
      domainIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'domainId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> domainIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'domainId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> domainIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'domainId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> isFavoriteEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isFavorite',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> isarIdGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> isarIdLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isarId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> locationRefEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'locationRef',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> locationRefGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'locationRef',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> locationRefLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'locationRef',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> locationRefBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'locationRef',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> locationRefStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'locationRef',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> locationRefEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'locationRef',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
          QAfterFilterCondition>
      locationRefContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'locationRef',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
          QAfterFilterCondition>
      locationRefMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'locationRef',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> locationRefIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'locationRef',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> locationRefIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'locationRef',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> noteTextEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'noteText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> noteTextGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'noteText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> noteTextLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'noteText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> noteTextBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'noteText',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> noteTextStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'noteText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> noteTextEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'noteText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
          QAfterFilterCondition>
      noteTextContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'noteText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
          QAfterFilterCondition>
      noteTextMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'noteText',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> noteTextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'noteText',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> noteTextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'noteText',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> selectedTextEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'selectedText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> selectedTextGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'selectedText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> selectedTextLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'selectedText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> selectedTextBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'selectedText',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> selectedTextStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'selectedText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> selectedTextEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'selectedText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
          QAfterFilterCondition>
      selectedTextContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'selectedText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
          QAfterFilterCondition>
      selectedTextMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'selectedText',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> selectedTextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'selectedText',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> selectedTextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'selectedText',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> typeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> typeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> typeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> typeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'type',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> typeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> typeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
          QAfterFilterCondition>
      typeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
          QAfterFilterCondition>
      typeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'type',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterFilterCondition> updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension IsarReaderAnnotationEntityQueryObject on QueryBuilder<
    IsarReaderAnnotationEntity, IsarReaderAnnotationEntity, QFilterCondition> {}

extension IsarReaderAnnotationEntityQueryLinks on QueryBuilder<
    IsarReaderAnnotationEntity, IsarReaderAnnotationEntity, QFilterCondition> {}

extension IsarReaderAnnotationEntityQuerySortBy on QueryBuilder<
    IsarReaderAnnotationEntity, IsarReaderAnnotationEntity, QSortBy> {
  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterSortBy> sortByBookId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bookId', Sort.asc);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterSortBy> sortByBookIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bookId', Sort.desc);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterSortBy> sortByColorId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorId', Sort.asc);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterSortBy> sortByColorIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorId', Sort.desc);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterSortBy> sortByDomainId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'domainId', Sort.asc);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterSortBy> sortByDomainIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'domainId', Sort.desc);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterSortBy> sortByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.asc);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterSortBy> sortByIsFavoriteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.desc);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterSortBy> sortByLocationRef() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'locationRef', Sort.asc);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterSortBy> sortByLocationRefDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'locationRef', Sort.desc);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterSortBy> sortByNoteText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noteText', Sort.asc);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterSortBy> sortByNoteTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noteText', Sort.desc);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterSortBy> sortBySelectedText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedText', Sort.asc);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterSortBy> sortBySelectedTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedText', Sort.desc);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterSortBy> sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension IsarReaderAnnotationEntityQuerySortThenBy on QueryBuilder<
    IsarReaderAnnotationEntity, IsarReaderAnnotationEntity, QSortThenBy> {
  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterSortBy> thenByBookId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bookId', Sort.asc);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterSortBy> thenByBookIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bookId', Sort.desc);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterSortBy> thenByColorId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorId', Sort.asc);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterSortBy> thenByColorIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorId', Sort.desc);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterSortBy> thenByDomainId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'domainId', Sort.asc);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterSortBy> thenByDomainIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'domainId', Sort.desc);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterSortBy> thenByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.asc);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterSortBy> thenByIsFavoriteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.desc);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterSortBy> thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterSortBy> thenByLocationRef() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'locationRef', Sort.asc);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterSortBy> thenByLocationRefDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'locationRef', Sort.desc);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterSortBy> thenByNoteText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noteText', Sort.asc);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterSortBy> thenByNoteTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noteText', Sort.desc);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterSortBy> thenBySelectedText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedText', Sort.asc);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterSortBy> thenBySelectedTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedText', Sort.desc);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterSortBy> thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension IsarReaderAnnotationEntityQueryWhereDistinct on QueryBuilder<
    IsarReaderAnnotationEntity, IsarReaderAnnotationEntity, QDistinct> {
  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QDistinct> distinctByBookId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bookId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QDistinct> distinctByColorId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'colorId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QDistinct> distinctByDomainId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'domainId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QDistinct> distinctByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isFavorite');
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QDistinct> distinctByLocationRef({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'locationRef', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QDistinct> distinctByNoteText({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'noteText', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QDistinct> distinctBySelectedText({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'selectedText', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QDistinct> distinctByType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, IsarReaderAnnotationEntity,
      QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension IsarReaderAnnotationEntityQueryProperty on QueryBuilder<
    IsarReaderAnnotationEntity, IsarReaderAnnotationEntity, QQueryProperty> {
  QueryBuilder<IsarReaderAnnotationEntity, int, QQueryOperations>
      isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, String, QQueryOperations>
      bookIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bookId');
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, String, QQueryOperations>
      colorIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'colorId');
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, String, QQueryOperations>
      domainIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'domainId');
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, bool, QQueryOperations>
      isFavoriteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isFavorite');
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, String, QQueryOperations>
      locationRefProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'locationRef');
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, String, QQueryOperations>
      noteTextProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'noteText');
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, String, QQueryOperations>
      selectedTextProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'selectedText');
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, String, QQueryOperations>
      typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }

  QueryBuilder<IsarReaderAnnotationEntity, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
