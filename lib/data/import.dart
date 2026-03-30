import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pinpoint/data/database.dart';
import 'package:pinpoint/data/images.dart';

class Importer {
  static Future<void> importFullBackupFromZip(
    String zipPath,
    AppDatabase db,
    ImageStorage storage,
  ) async {
    final tempDir = await getTemporaryDirectory();
    final extractDir = Directory(p.join(tempDir.path, 'pinpoint_import'));
    if (await extractDir.exists()) {
      try {
        await extractDir.delete(recursive: true);
      } catch (_) {
        // Ignore deletion errors on old temp folders
      }
    }
    await extractDir.create(recursive: true);

    InputFileStream? inputStream;
    AppDatabase? backupDb;

    try {
      inputStream = InputFileStream(zipPath);
      final archive = ZipDecoder().decodeBuffer(inputStream);

      File? backupDbFile;
      Map<String, File> backupImages = {};

      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final outFile = File(p.join(extractDir.path, filename));

          final normalizedPath = p.normalize(outFile.path);
          if (!p.isWithin(extractDir.path, normalizedPath)) {
            throw Exception('Invalid zip file: path traversal detected');
          }
          final safeOutFile = File(normalizedPath);
          await safeOutFile.parent.create(recursive: true);

          final outStream = OutputFileStream(safeOutFile.path);
          try {
            file.writeContent(outStream);
          } finally {
            outStream.close();
          }

          if (p.basename(filename) == 'pinpoint_database_backup.sqlite') {
            backupDbFile = safeOutFile;
          } else if (filename.startsWith('images/') ||
              filename.startsWith('images\\')) {
            backupImages[p.basename(filename)] = safeOutFile;
          }
        }
      }

      if (backupDbFile == null) {
        throw Exception('Not a valid backup file (missing database)');
      }

      backupDb = AppDatabase.fromFile(backupDbFile);
      final backupLists = await backupDb.getLists();
      final backupEntries = await backupDb.getAllEntries();

      final currentLists = (await db.getLists()).toList();
      final currentEntries = (await db.getAllEntries()).toList();

      for (var bList in backupLists) {
        int targetListId;

        // Find duplicate list based on all values (name and color)
        final duplicateLists = currentLists
            .where((l) => l.name == bList.name && l.color == bList.color)
            .toList();

        if (duplicateLists.isNotEmpty) {
          targetListId = duplicateLists.first.listId;
        } else {
          targetListId = await db.addList(
            name: bList.name,
            color: bList.color,
          );
          final newList = await db.getList(targetListId);
          currentLists.add(newList!);
        }

        final entriesForList =
            backupEntries.where((e) => e.listId == bList.listId).toList();

        for (var bEntry in entriesForList) {
          bool isDuplicate = currentEntries.any((cEntry) =>
              cEntry.listId == targetListId &&
              cEntry.description == bEntry.description &&
              cEntry.latitude == bEntry.latitude &&
              cEntry.longitude == bEntry.longitude &&
              cEntry.image == bEntry.image &&
              cEntry.date?.millisecondsSinceEpoch ==
                  bEntry.date?.millisecondsSinceEpoch);

          if (isDuplicate) {
            continue;
          }

          String? image;

          if (bEntry.image != null) {
            final imageInBackup = backupImages[bEntry.image];

            if (imageInBackup != null) {
              image = bEntry.image;
              final destPath = storage.getImagePath(image!);
              final destFile = File(destPath);
              if (!await destFile.exists()) {
                await imageInBackup.copy(destPath);
              }
            }
          }

          await db.addEntry(
            listId: targetListId,
            description: bEntry.description,
            location: bEntry.location,
            image: image,
            date: bEntry.date,
          );

          currentEntries.add(Entry(
            entryId: 0, // placeholder since it's not checked for duplicates
            listId: targetListId,
            description: bEntry.description,
            latitude: bEntry.latitude,
            longitude: bEntry.longitude,
            image: image,
            date: bEntry.date,
          ));
        }
      }
    } finally {
      inputStream?.close();
      if (backupDb != null) {
        await backupDb.close();
      }
      if (await extractDir.exists()) {
        try {
          await extractDir.delete(recursive: true);
        } catch (_) {
          // Ignore failing to clean up temp files (e.g. locked by OS)
          // so we don't accidentally crash a successful import operation.
        }
      }
    }
  }
}
