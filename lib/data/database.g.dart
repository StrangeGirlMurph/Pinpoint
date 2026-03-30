// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $EntryListsTable extends EntryLists
    with TableInfo<$EntryListsTable, EntryList> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntryListsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _listIdMeta = const VerificationMeta('listId');
  @override
  late final GeneratedColumn<int> listId = GeneratedColumn<int>(
      'list_id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
      'display_order', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<dynamic, int> color =
      GeneratedColumn<int>('color', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<dynamic>($EntryListsTable.$convertercolor);
  @override
  List<GeneratedColumn> get $columns => [listId, order, name, color];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lists';
  @override
  VerificationContext validateIntegrity(Insertable<EntryList> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('list_id')) {
      context.handle(_listIdMeta,
          listId.isAcceptableOrUnknown(data['list_id']!, _listIdMeta));
    }
    if (data.containsKey('display_order')) {
      context.handle(_orderMeta,
          order.isAcceptableOrUnknown(data['display_order']!, _orderMeta));
    } else if (isInserting) {
      context.missing(_orderMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {listId};
  @override
  EntryList map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntryList(
      listId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}list_id'])!,
      order: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}display_order'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      color: $EntryListsTable.$convertercolor.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}color'])!),
    );
  }

  @override
  $EntryListsTable createAlias(String alias) {
    return $EntryListsTable(attachedDatabase, alias);
  }

  static TypeConverter<dynamic, int> $convertercolor = const ColorConverter();
}

class EntryList extends DataClass implements Insertable<EntryList> {
  final int listId;
  final int order;
  final String name;
  final dynamic color;
  const EntryList(
      {required this.listId,
      required this.order,
      required this.name,
      this.color});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['list_id'] = Variable<int>(listId);
    map['display_order'] = Variable<int>(order);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || color != null) {
      map['color'] =
          Variable<int>($EntryListsTable.$convertercolor.toSql(color));
    }
    return map;
  }

  EntryListsCompanion toCompanion(bool nullToAbsent) {
    return EntryListsCompanion(
      listId: Value(listId),
      order: Value(order),
      name: Value(name),
      color:
          color == null && nullToAbsent ? const Value.absent() : Value(color),
    );
  }

  factory EntryList.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntryList(
      listId: serializer.fromJson<int>(json['listId']),
      order: serializer.fromJson<int>(json['order']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<dynamic>(json['color']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'listId': serializer.toJson<int>(listId),
      'order': serializer.toJson<int>(order),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<dynamic>(color),
    };
  }

  EntryList copyWith(
          {int? listId,
          int? order,
          String? name,
          Value<dynamic> color = const Value.absent()}) =>
      EntryList(
        listId: listId ?? this.listId,
        order: order ?? this.order,
        name: name ?? this.name,
        color: color.present ? color.value : this.color,
      );
  EntryList copyWithCompanion(EntryListsCompanion data) {
    return EntryList(
      listId: data.listId.present ? data.listId.value : this.listId,
      order: data.order.present ? data.order.value : this.order,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntryList(')
          ..write('listId: $listId, ')
          ..write('order: $order, ')
          ..write('name: $name, ')
          ..write('color: $color')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(listId, order, name, color);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntryList &&
          other.listId == this.listId &&
          other.order == this.order &&
          other.name == this.name &&
          other.color == this.color);
}

class EntryListsCompanion extends UpdateCompanion<EntryList> {
  final Value<int> listId;
  final Value<int> order;
  final Value<String> name;
  final Value<dynamic> color;
  const EntryListsCompanion({
    this.listId = const Value.absent(),
    this.order = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
  });
  EntryListsCompanion.insert({
    this.listId = const Value.absent(),
    required int order,
    required String name,
    required dynamic color,
  })  : order = Value(order),
        name = Value(name),
        color = Value(color);
  static Insertable<EntryList> custom({
    Expression<int>? listId,
    Expression<int>? order,
    Expression<String>? name,
    Expression<int>? color,
  }) {
    return RawValuesInsertable({
      if (listId != null) 'list_id': listId,
      if (order != null) 'display_order': order,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
    });
  }

  EntryListsCompanion copyWith(
      {Value<int>? listId,
      Value<int>? order,
      Value<String>? name,
      Value<dynamic>? color}) {
    return EntryListsCompanion(
      listId: listId ?? this.listId,
      order: order ?? this.order,
      name: name ?? this.name,
      color: color ?? this.color,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (listId.present) {
      map['list_id'] = Variable<int>(listId.value);
    }
    if (order.present) {
      map['display_order'] = Variable<int>(order.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] =
          Variable<int>($EntryListsTable.$convertercolor.toSql(color.value));
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntryListsCompanion(')
          ..write('listId: $listId, ')
          ..write('order: $order, ')
          ..write('name: $name, ')
          ..write('color: $color')
          ..write(')'))
        .toString();
  }
}

class $EntriesTable extends Entries with TableInfo<$EntriesTable, Entry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entryIdMeta =
      const VerificationMeta('entryId');
  @override
  late final GeneratedColumn<int> entryId = GeneratedColumn<int>(
      'entry_id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _listIdMeta = const VerificationMeta('listId');
  @override
  late final GeneratedColumn<int> listId = GeneratedColumn<int>(
      'list_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES lists (list_id) ON DELETE CASCADE'));
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _latitudeMeta =
      const VerificationMeta('latitude');
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
      'latitude', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _longitudeMeta =
      const VerificationMeta('longitude');
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
      'longitude', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _imageMeta = const VerificationMeta('image');
  @override
  late final GeneratedColumn<String> image = GeneratedColumn<String>(
      'image', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [entryId, listId, description, latitude, longitude, image, date];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entries';
  @override
  VerificationContext validateIntegrity(Insertable<Entry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entry_id')) {
      context.handle(_entryIdMeta,
          entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta));
    }
    if (data.containsKey('list_id')) {
      context.handle(_listIdMeta,
          listId.isAcceptableOrUnknown(data['list_id']!, _listIdMeta));
    } else if (isInserting) {
      context.missing(_listIdMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('latitude')) {
      context.handle(_latitudeMeta,
          latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta));
    }
    if (data.containsKey('longitude')) {
      context.handle(_longitudeMeta,
          longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta));
    }
    if (data.containsKey('image')) {
      context.handle(
          _imageMeta, image.isAcceptableOrUnknown(data['image']!, _imageMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entryId};
  @override
  Entry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Entry(
      entryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}entry_id'])!,
      listId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}list_id'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      latitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}latitude']),
      longitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}longitude']),
      image: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image']),
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date']),
    );
  }

  @override
  $EntriesTable createAlias(String alias) {
    return $EntriesTable(attachedDatabase, alias);
  }
}

class Entry extends DataClass implements Insertable<Entry> {
  final int entryId;
  final int listId;
  final String? description;
  final double? latitude;
  final double? longitude;
  final String? image;
  final DateTime? date;
  const Entry(
      {required this.entryId,
      required this.listId,
      this.description,
      this.latitude,
      this.longitude,
      this.image,
      this.date});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entry_id'] = Variable<int>(entryId);
    map['list_id'] = Variable<int>(listId);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    if (!nullToAbsent || image != null) {
      map['image'] = Variable<String>(image);
    }
    if (!nullToAbsent || date != null) {
      map['date'] = Variable<DateTime>(date);
    }
    return map;
  }

  EntriesCompanion toCompanion(bool nullToAbsent) {
    return EntriesCompanion(
      entryId: Value(entryId),
      listId: Value(listId),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      image:
          image == null && nullToAbsent ? const Value.absent() : Value(image),
      date: date == null && nullToAbsent ? const Value.absent() : Value(date),
    );
  }

  factory Entry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Entry(
      entryId: serializer.fromJson<int>(json['entryId']),
      listId: serializer.fromJson<int>(json['listId']),
      description: serializer.fromJson<String?>(json['description']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      image: serializer.fromJson<String?>(json['image']),
      date: serializer.fromJson<DateTime?>(json['date']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entryId': serializer.toJson<int>(entryId),
      'listId': serializer.toJson<int>(listId),
      'description': serializer.toJson<String?>(description),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'image': serializer.toJson<String?>(image),
      'date': serializer.toJson<DateTime?>(date),
    };
  }

  Entry copyWith(
          {int? entryId,
          int? listId,
          Value<String?> description = const Value.absent(),
          Value<double?> latitude = const Value.absent(),
          Value<double?> longitude = const Value.absent(),
          Value<String?> image = const Value.absent(),
          Value<DateTime?> date = const Value.absent()}) =>
      Entry(
        entryId: entryId ?? this.entryId,
        listId: listId ?? this.listId,
        description: description.present ? description.value : this.description,
        latitude: latitude.present ? latitude.value : this.latitude,
        longitude: longitude.present ? longitude.value : this.longitude,
        image: image.present ? image.value : this.image,
        date: date.present ? date.value : this.date,
      );
  Entry copyWithCompanion(EntriesCompanion data) {
    return Entry(
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      listId: data.listId.present ? data.listId.value : this.listId,
      description:
          data.description.present ? data.description.value : this.description,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      image: data.image.present ? data.image.value : this.image,
      date: data.date.present ? data.date.value : this.date,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Entry(')
          ..write('entryId: $entryId, ')
          ..write('listId: $listId, ')
          ..write('description: $description, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('image: $image, ')
          ..write('date: $date')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      entryId, listId, description, latitude, longitude, image, date);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Entry &&
          other.entryId == this.entryId &&
          other.listId == this.listId &&
          other.description == this.description &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.image == this.image &&
          other.date == this.date);
}

class EntriesCompanion extends UpdateCompanion<Entry> {
  final Value<int> entryId;
  final Value<int> listId;
  final Value<String?> description;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<String?> image;
  final Value<DateTime?> date;
  const EntriesCompanion({
    this.entryId = const Value.absent(),
    this.listId = const Value.absent(),
    this.description = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.image = const Value.absent(),
    this.date = const Value.absent(),
  });
  EntriesCompanion.insert({
    this.entryId = const Value.absent(),
    required int listId,
    this.description = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.image = const Value.absent(),
    this.date = const Value.absent(),
  }) : listId = Value(listId);
  static Insertable<Entry> custom({
    Expression<int>? entryId,
    Expression<int>? listId,
    Expression<String>? description,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<String>? image,
    Expression<DateTime>? date,
  }) {
    return RawValuesInsertable({
      if (entryId != null) 'entry_id': entryId,
      if (listId != null) 'list_id': listId,
      if (description != null) 'description': description,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (image != null) 'image': image,
      if (date != null) 'date': date,
    });
  }

  EntriesCompanion copyWith(
      {Value<int>? entryId,
      Value<int>? listId,
      Value<String?>? description,
      Value<double?>? latitude,
      Value<double?>? longitude,
      Value<String?>? image,
      Value<DateTime?>? date}) {
    return EntriesCompanion(
      entryId: entryId ?? this.entryId,
      listId: listId ?? this.listId,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      image: image ?? this.image,
      date: date ?? this.date,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entryId.present) {
      map['entry_id'] = Variable<int>(entryId.value);
    }
    if (listId.present) {
      map['list_id'] = Variable<int>(listId.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (image.present) {
      map['image'] = Variable<String>(image.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntriesCompanion(')
          ..write('entryId: $entryId, ')
          ..write('listId: $listId, ')
          ..write('description: $description, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('image: $image, ')
          ..write('date: $date')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $EntryListsTable entryLists = $EntryListsTable(this);
  late final $EntriesTable entries = $EntriesTable(this);
  late final Index entriesByList = Index(
      'entries_by_list', 'CREATE INDEX entries_by_list ON entries (list_id)');
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [entryLists, entries, entriesByList];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('lists',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('entries', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$EntryListsTableCreateCompanionBuilder = EntryListsCompanion Function({
  Value<int> listId,
  required int order,
  required String name,
  required dynamic color,
});
typedef $$EntryListsTableUpdateCompanionBuilder = EntryListsCompanion Function({
  Value<int> listId,
  Value<int> order,
  Value<String> name,
  Value<dynamic> color,
});

final class $$EntryListsTableReferences
    extends BaseReferences<_$AppDatabase, $EntryListsTable, EntryList> {
  $$EntryListsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$EntriesTable, List<Entry>> _entriesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.entries,
          aliasName:
              $_aliasNameGenerator(db.entryLists.listId, db.entries.listId));

  $$EntriesTableProcessedTableManager get entriesRefs {
    final manager = $$EntriesTableTableManager($_db, $_db.entries).filter(
        (f) => f.listId.listId.sqlEquals($_itemColumn<int>('list_id')!));

    final cache = $_typedResult.readTableOrNull(_entriesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$EntryListsTableFilterComposer
    extends Composer<_$AppDatabase, $EntryListsTable> {
  $$EntryListsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get listId => $composableBuilder(
      column: $table.listId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get order => $composableBuilder(
      column: $table.order, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<dynamic, dynamic, int> get color =>
      $composableBuilder(
          column: $table.color,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  Expression<bool> entriesRefs(
      Expression<bool> Function($$EntriesTableFilterComposer f) f) {
    final $$EntriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.listId,
        referencedTable: $db.entries,
        getReferencedColumn: (t) => t.listId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EntriesTableFilterComposer(
              $db: $db,
              $table: $db.entries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$EntryListsTableOrderingComposer
    extends Composer<_$AppDatabase, $EntryListsTable> {
  $$EntryListsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get listId => $composableBuilder(
      column: $table.listId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get order => $composableBuilder(
      column: $table.order, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));
}

class $$EntryListsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntryListsTable> {
  $$EntryListsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get listId =>
      $composableBuilder(column: $table.listId, builder: (column) => column);

  GeneratedColumn<int> get order =>
      $composableBuilder(column: $table.order, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<dynamic, int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  Expression<T> entriesRefs<T extends Object>(
      Expression<T> Function($$EntriesTableAnnotationComposer a) f) {
    final $$EntriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.listId,
        referencedTable: $db.entries,
        getReferencedColumn: (t) => t.listId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EntriesTableAnnotationComposer(
              $db: $db,
              $table: $db.entries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$EntryListsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EntryListsTable,
    EntryList,
    $$EntryListsTableFilterComposer,
    $$EntryListsTableOrderingComposer,
    $$EntryListsTableAnnotationComposer,
    $$EntryListsTableCreateCompanionBuilder,
    $$EntryListsTableUpdateCompanionBuilder,
    (EntryList, $$EntryListsTableReferences),
    EntryList,
    PrefetchHooks Function({bool entriesRefs})> {
  $$EntryListsTableTableManager(_$AppDatabase db, $EntryListsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntryListsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntryListsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntryListsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> listId = const Value.absent(),
            Value<int> order = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<dynamic> color = const Value.absent(),
          }) =>
              EntryListsCompanion(
            listId: listId,
            order: order,
            name: name,
            color: color,
          ),
          createCompanionCallback: ({
            Value<int> listId = const Value.absent(),
            required int order,
            required String name,
            required dynamic color,
          }) =>
              EntryListsCompanion.insert(
            listId: listId,
            order: order,
            name: name,
            color: color,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$EntryListsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({entriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (entriesRefs) db.entries],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (entriesRefs)
                    await $_getPrefetchedData<EntryList, $EntryListsTable,
                            Entry>(
                        currentTable: table,
                        referencedTable:
                            $$EntryListsTableReferences._entriesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$EntryListsTableReferences(db, table, p0)
                                .entriesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.listId == item.listId),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$EntryListsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EntryListsTable,
    EntryList,
    $$EntryListsTableFilterComposer,
    $$EntryListsTableOrderingComposer,
    $$EntryListsTableAnnotationComposer,
    $$EntryListsTableCreateCompanionBuilder,
    $$EntryListsTableUpdateCompanionBuilder,
    (EntryList, $$EntryListsTableReferences),
    EntryList,
    PrefetchHooks Function({bool entriesRefs})>;
typedef $$EntriesTableCreateCompanionBuilder = EntriesCompanion Function({
  Value<int> entryId,
  required int listId,
  Value<String?> description,
  Value<double?> latitude,
  Value<double?> longitude,
  Value<String?> image,
  Value<DateTime?> date,
});
typedef $$EntriesTableUpdateCompanionBuilder = EntriesCompanion Function({
  Value<int> entryId,
  Value<int> listId,
  Value<String?> description,
  Value<double?> latitude,
  Value<double?> longitude,
  Value<String?> image,
  Value<DateTime?> date,
});

final class $$EntriesTableReferences
    extends BaseReferences<_$AppDatabase, $EntriesTable, Entry> {
  $$EntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EntryListsTable _listIdTable(_$AppDatabase db) =>
      db.entryLists.createAlias(
          $_aliasNameGenerator(db.entries.listId, db.entryLists.listId));

  $$EntryListsTableProcessedTableManager get listId {
    final $_column = $_itemColumn<int>('list_id')!;

    final manager = $$EntryListsTableTableManager($_db, $_db.entryLists)
        .filter((f) => f.listId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_listIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$EntriesTableFilterComposer
    extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get entryId => $composableBuilder(
      column: $table.entryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get image => $composableBuilder(
      column: $table.image, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  $$EntryListsTableFilterComposer get listId {
    final $$EntryListsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.listId,
        referencedTable: $db.entryLists,
        getReferencedColumn: (t) => t.listId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EntryListsTableFilterComposer(
              $db: $db,
              $table: $db.entryLists,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get entryId => $composableBuilder(
      column: $table.entryId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get image => $composableBuilder(
      column: $table.image, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  $$EntryListsTableOrderingComposer get listId {
    final $$EntryListsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.listId,
        referencedTable: $db.entryLists,
        getReferencedColumn: (t) => t.listId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EntryListsTableOrderingComposer(
              $db: $db,
              $table: $db.entryLists,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get entryId =>
      $composableBuilder(column: $table.entryId, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<String> get image =>
      $composableBuilder(column: $table.image, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  $$EntryListsTableAnnotationComposer get listId {
    final $$EntryListsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.listId,
        referencedTable: $db.entryLists,
        getReferencedColumn: (t) => t.listId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EntryListsTableAnnotationComposer(
              $db: $db,
              $table: $db.entryLists,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EntriesTable,
    Entry,
    $$EntriesTableFilterComposer,
    $$EntriesTableOrderingComposer,
    $$EntriesTableAnnotationComposer,
    $$EntriesTableCreateCompanionBuilder,
    $$EntriesTableUpdateCompanionBuilder,
    (Entry, $$EntriesTableReferences),
    Entry,
    PrefetchHooks Function({bool listId})> {
  $$EntriesTableTableManager(_$AppDatabase db, $EntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> entryId = const Value.absent(),
            Value<int> listId = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<double?> latitude = const Value.absent(),
            Value<double?> longitude = const Value.absent(),
            Value<String?> image = const Value.absent(),
            Value<DateTime?> date = const Value.absent(),
          }) =>
              EntriesCompanion(
            entryId: entryId,
            listId: listId,
            description: description,
            latitude: latitude,
            longitude: longitude,
            image: image,
            date: date,
          ),
          createCompanionCallback: ({
            Value<int> entryId = const Value.absent(),
            required int listId,
            Value<String?> description = const Value.absent(),
            Value<double?> latitude = const Value.absent(),
            Value<double?> longitude = const Value.absent(),
            Value<String?> image = const Value.absent(),
            Value<DateTime?> date = const Value.absent(),
          }) =>
              EntriesCompanion.insert(
            entryId: entryId,
            listId: listId,
            description: description,
            latitude: latitude,
            longitude: longitude,
            image: image,
            date: date,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$EntriesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({listId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (listId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.listId,
                    referencedTable: $$EntriesTableReferences._listIdTable(db),
                    referencedColumn:
                        $$EntriesTableReferences._listIdTable(db).listId,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$EntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EntriesTable,
    Entry,
    $$EntriesTableFilterComposer,
    $$EntriesTableOrderingComposer,
    $$EntriesTableAnnotationComposer,
    $$EntriesTableCreateCompanionBuilder,
    $$EntriesTableUpdateCompanionBuilder,
    (Entry, $$EntriesTableReferences),
    Entry,
    PrefetchHooks Function({bool listId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$EntryListsTableTableManager get entryLists =>
      $$EntryListsTableTableManager(_db, _db.entryLists);
  $$EntriesTableTableManager get entries =>
      $$EntriesTableTableManager(_db, _db.entries);
}
