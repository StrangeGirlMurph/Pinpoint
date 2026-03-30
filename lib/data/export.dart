import 'dart:io';
import 'dart:isolate';
import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:pinpoint/data/database.dart';
import 'package:pinpoint/data/images.dart';

class Exporter {
  static Future<String> exportDatabase(AppDatabase db) async {
    final tempDir = await getTemporaryDirectory();
    final backupPath =
        path.join(tempDir.path, 'pinpoint_database_backup.sqlite');
    final backupFile = File(backupPath);
    await db.exportInto(backupFile);
    return backupPath;
  }

  static Future<List<String>> exportHumanReadableDatabase(
      AppDatabase db) async {
    final tempDir = await getTemporaryDirectory();

    final lists = await db.getLists();
    final listsFile = File(path.join(tempDir.path, 'lists.csv'));
    final listsSink = listsFile.openWrite();

    try {
      listsSink.writeln('listId,order,name,color');
      for (final list in lists) {
        final name = list.name.replaceAll('"', '""');
        listsSink.writeln(
            '${list.listId},${list.order},"$name",${(list.color as Color).toHexString(includeHashSign: true)}');
      }
    } finally {
      await listsSink.flush();
      await listsSink.close();
    }

    final entries = await db.getAllEntries();
    final entriesFile = File(path.join(tempDir.path, 'entries.csv'));
    final entriesSink = entriesFile.openWrite();

    try {
      entriesSink
          .writeln('entryId,listId,description,latitude,longitude,image,date');
      for (final entry in entries) {
        final description = entry.description?.replaceAll('"', '""') ?? '';
        final date = entry.date?.toIso8601String() ?? '';
        entriesSink.writeln(
            '${entry.entryId},${entry.listId},"$description",${entry.latitude ?? ''},${entry.longitude ?? ''},${entry.image ?? ''},$date');
      }
    } finally {
      await entriesSink.flush();
      await entriesSink.close();
    }

    return [listsFile.path, entriesFile.path];
  }

  static Future<String?> exportImages(ImageStorage storage) async {
    final images = await storage.getAllImages();
    if (images.isEmpty) return null;

    final tempDir = await getTemporaryDirectory();
    final zipPath = path.join(tempDir.path, 'pinpoint_images.zip');
    final imagePaths = images.map((f) => f.path).toList();

    return await Isolate.run(() async {
      final zipFile = File(zipPath);

      if (zipFile.existsSync()) {
        zipFile.deleteSync();
      }

      final encoder = ZipFileEncoder();
      encoder.create(zipPath);

      try {
        for (var imagePath in imagePaths) {
          encoder.addFile(File(imagePath));
        }
        encoder.close();
        return zipPath;
      } catch (e) {
        encoder.close();
        rethrow;
      }
    });
  }

  static Future<String?> exportFullBackup(
      AppDatabase db, ImageStorage storage) async {
    final tempDir = await getTemporaryDirectory();

    final backupPath =
        path.join(tempDir.path, 'temp_pinpoint_database_backup.sqlite');
    final backupFile = File(backupPath);
    await db.exportInto(backupFile);

    final zipPath = path.join(tempDir.path, 'pinpoint_full_backup.zip');

    final images = await storage.getAllImages();
    final imagePaths = images.map((f) => f.path).toList();

    return await Isolate.run(() async {
      final zipFile = File(zipPath);
      if (zipFile.existsSync()) {
        zipFile.deleteSync();
      }

      final encoder = ZipFileEncoder();
      encoder.create(zipPath);

      try {
        final backupFileToArchive = File(backupPath);
        if (backupFileToArchive.existsSync()) {
          encoder.addFile(
              backupFileToArchive, 'pinpoint_database_backup.sqlite');
        }

        for (var imagePath in imagePaths) {
          encoder.addFile(
              File(imagePath), 'images/${path.basename(imagePath)}');
        }

        encoder.close();
        return zipPath;
      } catch (e) {
        encoder.close();
        rethrow;
      } finally {
        final backupFileToArchive = File(backupPath);
        if (backupFileToArchive.existsSync()) {
          try {
            backupFileToArchive.deleteSync();
          } catch (_) {
            // Ignore deletion errors on temp file
          }
        }
      }
    });
  }
}
