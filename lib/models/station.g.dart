// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'station.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetStationModelCollection on Isar {
  IsarCollection<StationModel> get stationModels => this.collection();
}

const StationModelSchema = CollectionSchema(
  name: r'StationModel',
  id: 8818857602217503579,
  properties: {
    r'adresse': PropertySchema(
      id: 0,
      name: r'adresse',
      type: IsarType.string,
    ),
    r'caisse': PropertySchema(
      id: 1,
      name: r'caisse',
      type: IsarType.string,
    ),
    r'cuives': PropertySchema(
      id: 2,
      name: r'cuives',
      type: IsarType.long,
    ),
    r'mail': PropertySchema(
      id: 3,
      name: r'mail',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 4,
      name: r'name',
      type: IsarType.string,
    ),
    r'phone': PropertySchema(
      id: 5,
      name: r'phone',
      type: IsarType.string,
    ),
    r'pompes': PropertySchema(
      id: 6,
      name: r'pompes',
      type: IsarType.long,
    ),
    r'uuid': PropertySchema(
      id: 7,
      name: r'uuid',
      type: IsarType.string,
    )
  },
  estimateSize: _stationModelEstimateSize,
  serialize: _stationModelSerialize,
  deserialize: _stationModelDeserialize,
  deserializeProp: _stationModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'uuid': IndexSchema(
      id: 2134397340427724972,
      name: r'uuid',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'uuid',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _stationModelGetId,
  getLinks: _stationModelGetLinks,
  attach: _stationModelAttach,
  version: '3.1.0+1',
);

int _stationModelEstimateSize(
  StationModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.adresse;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.caisse;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.mail;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.name.length * 3;
  {
    final value = object.phone;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.uuid.length * 3;
  return bytesCount;
}

void _stationModelSerialize(
  StationModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.adresse);
  writer.writeString(offsets[1], object.caisse);
  writer.writeLong(offsets[2], object.cuives);
  writer.writeString(offsets[3], object.mail);
  writer.writeString(offsets[4], object.name);
  writer.writeString(offsets[5], object.phone);
  writer.writeLong(offsets[6], object.pompes);
  writer.writeString(offsets[7], object.uuid);
}

StationModel _stationModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = StationModel();
  object.adresse = reader.readStringOrNull(offsets[0]);
  object.caisse = reader.readStringOrNull(offsets[1]);
  object.cuives = reader.readLongOrNull(offsets[2]);
  object.id = id;
  object.mail = reader.readStringOrNull(offsets[3]);
  object.name = reader.readString(offsets[4]);
  object.phone = reader.readStringOrNull(offsets[5]);
  object.pompes = reader.readLongOrNull(offsets[6]);
  object.uuid = reader.readString(offsets[7]);
  return object;
}

P _stationModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readLongOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readLongOrNull(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _stationModelGetId(StationModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _stationModelGetLinks(StationModel object) {
  return [];
}

void _stationModelAttach(
    IsarCollection<dynamic> col, Id id, StationModel object) {
  object.id = id;
}

extension StationModelByIndex on IsarCollection<StationModel> {
  Future<StationModel?> getByUuid(String uuid) {
    return getByIndex(r'uuid', [uuid]);
  }

  StationModel? getByUuidSync(String uuid) {
    return getByIndexSync(r'uuid', [uuid]);
  }

  Future<bool> deleteByUuid(String uuid) {
    return deleteByIndex(r'uuid', [uuid]);
  }

  bool deleteByUuidSync(String uuid) {
    return deleteByIndexSync(r'uuid', [uuid]);
  }

  Future<List<StationModel?>> getAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uuid', values);
  }

  List<StationModel?> getAllByUuidSync(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'uuid', values);
  }

  Future<int> deleteAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'uuid', values);
  }

  int deleteAllByUuidSync(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'uuid', values);
  }

  Future<Id> putByUuid(StationModel object) {
    return putByIndex(r'uuid', object);
  }

  Id putByUuidSync(StationModel object, {bool saveLinks = true}) {
    return putByIndexSync(r'uuid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUuid(List<StationModel> objects) {
    return putAllByIndex(r'uuid', objects);
  }

  List<Id> putAllByUuidSync(List<StationModel> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'uuid', objects, saveLinks: saveLinks);
  }
}

extension StationModelQueryWhereSort
    on QueryBuilder<StationModel, StationModel, QWhere> {
  QueryBuilder<StationModel, StationModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension StationModelQueryWhere
    on QueryBuilder<StationModel, StationModel, QWhereClause> {
  QueryBuilder<StationModel, StationModel, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterWhereClause> uuidEqualTo(
      String uuid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uuid',
        value: [uuid],
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterWhereClause> uuidNotEqualTo(
      String uuid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [],
              upper: [uuid],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [uuid],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [uuid],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [],
              upper: [uuid],
              includeUpper: false,
            ));
      }
    });
  }
}

extension StationModelQueryFilter
    on QueryBuilder<StationModel, StationModel, QFilterCondition> {
  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      adresseIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'adresse',
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      adresseIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'adresse',
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      adresseEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'adresse',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      adresseGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'adresse',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      adresseLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'adresse',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      adresseBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'adresse',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      adresseStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'adresse',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      adresseEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'adresse',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      adresseContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'adresse',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      adresseMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'adresse',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      adresseIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'adresse',
        value: '',
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      adresseIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'adresse',
        value: '',
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      caisseIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'caisse',
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      caisseIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'caisse',
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition> caisseEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'caisse',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      caisseGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'caisse',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      caisseLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'caisse',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition> caisseBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'caisse',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      caisseStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'caisse',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      caisseEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'caisse',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      caisseContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'caisse',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition> caisseMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'caisse',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      caisseIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'caisse',
        value: '',
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      caisseIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'caisse',
        value: '',
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      cuivesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'cuives',
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      cuivesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'cuives',
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition> cuivesEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cuives',
        value: value,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      cuivesGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cuives',
        value: value,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      cuivesLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cuives',
        value: value,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition> cuivesBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cuives',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition> mailIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'mail',
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      mailIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'mail',
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition> mailEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      mailGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition> mailLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition> mailBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mail',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      mailStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition> mailEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition> mailContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition> mailMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mail',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      mailIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mail',
        value: '',
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      mailIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mail',
        value: '',
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition> nameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      phoneIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'phone',
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      phoneIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'phone',
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition> phoneEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'phone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      phoneGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'phone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition> phoneLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'phone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition> phoneBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'phone',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      phoneStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'phone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition> phoneEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'phone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition> phoneContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'phone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition> phoneMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'phone',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      phoneIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'phone',
        value: '',
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      phoneIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'phone',
        value: '',
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      pompesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'pompes',
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      pompesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'pompes',
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition> pompesEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pompes',
        value: value,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      pompesGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pompes',
        value: value,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      pompesLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pompes',
        value: value,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition> pompesBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pompes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition> uuidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      uuidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition> uuidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition> uuidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'uuid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      uuidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition> uuidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition> uuidContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition> uuidMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'uuid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      uuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uuid',
        value: '',
      ));
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterFilterCondition>
      uuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uuid',
        value: '',
      ));
    });
  }
}

extension StationModelQueryObject
    on QueryBuilder<StationModel, StationModel, QFilterCondition> {}

extension StationModelQueryLinks
    on QueryBuilder<StationModel, StationModel, QFilterCondition> {}

extension StationModelQuerySortBy
    on QueryBuilder<StationModel, StationModel, QSortBy> {
  QueryBuilder<StationModel, StationModel, QAfterSortBy> sortByAdresse() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'adresse', Sort.asc);
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterSortBy> sortByAdresseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'adresse', Sort.desc);
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterSortBy> sortByCaisse() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'caisse', Sort.asc);
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterSortBy> sortByCaisseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'caisse', Sort.desc);
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterSortBy> sortByCuives() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cuives', Sort.asc);
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterSortBy> sortByCuivesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cuives', Sort.desc);
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterSortBy> sortByMail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mail', Sort.asc);
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterSortBy> sortByMailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mail', Sort.desc);
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterSortBy> sortByPhone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'phone', Sort.asc);
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterSortBy> sortByPhoneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'phone', Sort.desc);
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterSortBy> sortByPompes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pompes', Sort.asc);
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterSortBy> sortByPompesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pompes', Sort.desc);
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterSortBy> sortByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterSortBy> sortByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension StationModelQuerySortThenBy
    on QueryBuilder<StationModel, StationModel, QSortThenBy> {
  QueryBuilder<StationModel, StationModel, QAfterSortBy> thenByAdresse() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'adresse', Sort.asc);
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterSortBy> thenByAdresseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'adresse', Sort.desc);
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterSortBy> thenByCaisse() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'caisse', Sort.asc);
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterSortBy> thenByCaisseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'caisse', Sort.desc);
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterSortBy> thenByCuives() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cuives', Sort.asc);
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterSortBy> thenByCuivesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cuives', Sort.desc);
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterSortBy> thenByMail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mail', Sort.asc);
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterSortBy> thenByMailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mail', Sort.desc);
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterSortBy> thenByPhone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'phone', Sort.asc);
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterSortBy> thenByPhoneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'phone', Sort.desc);
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterSortBy> thenByPompes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pompes', Sort.asc);
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterSortBy> thenByPompesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pompes', Sort.desc);
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterSortBy> thenByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<StationModel, StationModel, QAfterSortBy> thenByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension StationModelQueryWhereDistinct
    on QueryBuilder<StationModel, StationModel, QDistinct> {
  QueryBuilder<StationModel, StationModel, QDistinct> distinctByAdresse(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'adresse', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StationModel, StationModel, QDistinct> distinctByCaisse(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'caisse', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StationModel, StationModel, QDistinct> distinctByCuives() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cuives');
    });
  }

  QueryBuilder<StationModel, StationModel, QDistinct> distinctByMail(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mail', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StationModel, StationModel, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StationModel, StationModel, QDistinct> distinctByPhone(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'phone', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StationModel, StationModel, QDistinct> distinctByPompes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pompes');
    });
  }

  QueryBuilder<StationModel, StationModel, QDistinct> distinctByUuid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uuid', caseSensitive: caseSensitive);
    });
  }
}

extension StationModelQueryProperty
    on QueryBuilder<StationModel, StationModel, QQueryProperty> {
  QueryBuilder<StationModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<StationModel, String?, QQueryOperations> adresseProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'adresse');
    });
  }

  QueryBuilder<StationModel, String?, QQueryOperations> caisseProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'caisse');
    });
  }

  QueryBuilder<StationModel, int?, QQueryOperations> cuivesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cuives');
    });
  }

  QueryBuilder<StationModel, String?, QQueryOperations> mailProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mail');
    });
  }

  QueryBuilder<StationModel, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<StationModel, String?, QQueryOperations> phoneProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'phone');
    });
  }

  QueryBuilder<StationModel, int?, QQueryOperations> pompesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pompes');
    });
  }

  QueryBuilder<StationModel, String, QQueryOperations> uuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uuid');
    });
  }
}
