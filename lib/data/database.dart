import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart' hide Table, Column, Row, Container;
import 'package:latlong2/latlong.dart';
import 'package:pinpoint/util/random.dart';
import 'package:pinpoint/data/images.dart';

part 'database.g.dart';

extension EntryLocationExtension on Entry {
  LatLng? get location {
    if (latitude != null && longitude != null) {
      return LatLng(latitude!, longitude!);
    }
    return null;
  }

  // Create a copy with a new location
  Entry copyWithLocation(LatLng? location) {
    return copyWith(
      latitude: Value(location?.latitude),
      longitude: Value(location?.longitude),
    );
  }
}

extension EntriesCompanionExtension on EntriesCompanion {
  static EntriesCompanion createWithLocation({
    Value<int> entryId = const Value.absent(),
    required int listId,
    Value<String?> description = const Value.absent(),
    LatLng? location,
    Value<String?> image = const Value.absent(),
    Value<DateTime?> date = const Value.absent(),
  }) {
    return EntriesCompanion.insert(
      entryId: entryId,
      listId: listId,
      description: description,
      latitude: Value(location?.latitude),
      longitude: Value(location?.longitude),
      image: image,
      date: date,
    );
  }
}

class ColorConverter extends TypeConverter<Color, int> {
  const ColorConverter();

  @override
  Color fromSql(int fromDb) {
    return Color(fromDb);
  }

  @override
  int toSql(Color value) {
    return value.toARGB32();
  }
}

class EntryLists extends Table {
  IntColumn get listId => integer().autoIncrement()();
  IntColumn get order => integer().named('display_order')();
  TextColumn get name => text()();
  IntColumn get color => integer().map(const ColorConverter())();

  @override
  String get tableName => 'lists';
}

@TableIndex(name: 'entries_by_list', columns: {#listId})
class Entries extends Table {
  IntColumn get entryId => integer().autoIncrement()();
  IntColumn get listId =>
      integer().references(EntryLists, #listId, onDelete: KeyAction.cascade)();
  TextColumn get description => text().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  TextColumn get image => text().nullable()();
  DateTimeColumn get date => dateTime().nullable()();

  @override
  String get tableName => 'entries';
}

@DriftDatabase(tables: [EntryLists, Entries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.fromFile(File file) : super(NativeDatabase(file));

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'pinpoint',
    );
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      beforeOpen: (details) async {
        // Enable foreign key constraints
        await customStatement('PRAGMA foreign_keys = ON');

        // Insert default list if database was just created
        if (details.wasCreated) {
          await into(entryLists).insert(
            EntryListsCompanion.insert(
              order: 0,
              name: 'Default',
              color: getRandomMaterialColor(),
            ),
          );
        }
      },
    );
  }

  Future<void> exportInto(File file) async {
    // Make sure the directory of the target file exists
    await file.parent.create(recursive: true);

    // Override an existing backup, sqlite expects the target file to be empty
    if (file.existsSync()) {
      file.deleteSync();
    }

    await customStatement('VACUUM INTO ?', [file.absolute.path]);
  }

  Future<List<Entry>> getAllEntries() async {
    return await select(entries).get();
  }

  Future<List<Entry>> getListEntries(int listId) async {
    return await (select(entries)..where((e) => e.listId.equals(listId))).get();
  }

  Future<Entry?> getEntry(int entryId) async {
    return await (select(entries)..where((e) => e.entryId.equals(entryId)))
        .getSingleOrNull();
  }

  Future<int> addEntry({
    required int listId,
    String? description,
    LatLng? location,
    String? image,
    DateTime? date,
  }) async {
    return await into(entries).insert(
      EntriesCompanion.insert(
        entryId: const Value.absent(),
        listId: listId,
        description: Value(description),
        latitude: Value(location?.latitude),
        longitude: Value(location?.longitude),
        image: Value(image),
        date: Value(date),
      ),
    );
  }

  Future<bool> isImageUsed(String image, [int? excludedEntryId]) async {
    final query = select(entries)..where((e) => e.image.equals(image));
    if (excludedEntryId != null) {
      query.where((e) => e.entryId.isNotValue(excludedEntryId));
    }
    final results = await query.get();
    return results.isNotEmpty;
  }

  Future<void> updateEntry(Entry entry) async {
    await update(entries).replace(entry);
  }

  Future<void> deleteEntry(int entryId, ImageStorage storage) async {
    final entry = await getEntry(entryId);
    await (delete(entries)..where((e) => e.entryId.equals(entryId))).go();
    if (entry != null && entry.image != null) {
      await storage.deleteImage(entry.image!);
    }
  }

  Future<List<EntryList>> getLists() async {
    return await (select(entryLists)
          ..orderBy([(e) => OrderingTerm(expression: e.order)]))
        .get();
  }

  Future<EntryList?> getList(int listId) async {
    return await (select(entryLists)..where((l) => l.listId.equals(listId)))
        .getSingleOrNull();
  }

  Future<int> addList({
    int? listId,
    int? order,
    required String name,
    Color? color,
  }) async {
    color ??= getRandomMaterialColor();

    // If order not provided, get the count of existing lists
    if (order == null) {
      final count = await (selectOnly(entryLists)
            ..addColumns([entryLists.listId.count()]))
          .getSingle();
      order = count.read(entryLists.listId.count()) ?? 0;
    }

    return await into(entryLists).insert(
      EntryListsCompanion.insert(
        listId: listId != null ? Value(listId) : const Value.absent(),
        order: order,
        name: name,
        color: color,
      ),
    );
  }

  Future<void> updateList(EntryList list) async {
    await update(entryLists).replace(list);
  }

  Future<void> deleteList(int listId, ImageStorage storage) async {
    final list = await getList(listId);
    if (list == null) return;

    final listEntries = await getListEntries(listId);

    await transaction(() async {
      // Delete the list (entries will be cascade deleted due to foreign key)
      await (delete(entryLists)..where((l) => l.listId.equals(listId))).go();

      // Renumber remaining lists to maintain sequential order
      final remainingLists = await getLists();
      for (int i = 0; i < remainingLists.length; i++) {
        await (update(entryLists)
              ..where((l) => l.listId.equals(remainingLists[i].listId)))
            .write(EntryListsCompanion(order: Value(i)));
      }
    });

    for (final entry in listEntries) {
      if (entry.image != null) {
        await storage.deleteImage(entry.image!);
      }
    }
  }

  Future<void> reorderLists(int oldIndex, int newIndex) async {
    // Get all lists in current order
    final lists = await getLists();

    // Reorder in memory
    final item = lists.removeAt(oldIndex);
    lists.insert(newIndex, item);

    // Update all orders in database
    await transaction(() async {
      for (int i = 0; i < lists.length; i++) {
        await (update(entryLists)
              ..where((l) => l.listId.equals(lists[i].listId)))
            .write(EntryListsCompanion(order: Value(i)));
      }
    });
  }
}
