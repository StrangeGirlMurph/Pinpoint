import 'dart:io';
import 'dart:isolate';
import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';
import 'package:pinpoint/data/database.dart';
import 'package:pinpoint/data/images.dart';
import 'package:pinpoint/util/snackbar.dart';

Rect? getSharePositionOrigin(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  if (box == null) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}

Future<void> handleExport(
  BuildContext context, {
  required Future<dynamic> Function() exportAction,
  required String shareText,
  required String errorMessage,
  Rect? sharePositionOrigin,
}) async {
  try {
    if (context.mounted) {
      showSnackBar(
        context,
        'Exporting... Please be patient!',
        duration: const Duration(minutes: 20),
      );
    }

    final result = await exportAction();

    if (context.mounted) {
      hideCurrentSnackBar(context);
    }

    if (result == null) {
      if (context.mounted) {
        showSnackBar(context, 'Nothing to export.');
      }
      return;
    }

    final files = result is List<String>
        ? result.map((p) => XFile(p)).toList()
        : [XFile(result as String)];

    if (context.mounted && files.isNotEmpty) {
      await SharePlus.instance.share(
        ShareParams(
          files: files,
          text: shareText,
          sharePositionOrigin:
              sharePositionOrigin ?? getSharePositionOrigin(context),
        ),
      );
    }
  } catch (e, stackTrace) {
    debugPrint('Export failed: $e\n$stackTrace');
    if (context.mounted) {
      hideCurrentSnackBar(context);
      showSnackBar(context, '$errorMessage: $e');
    }
  }
}

class Exporter {
  static Future<void> writeListsCsv(File file, List<EntryList> lists) async {
    final sink = file.openWrite();
    try {
      sink.writeln('listId,order,name,color');
      for (final list in lists) {
        final name = list.name.replaceAll('"', '""');
        final colorHex = list.color is Color
            ? (list.color as Color).toHexString(includeHashSign: true)
            : '';
        sink.writeln('${list.listId},${list.order},"$name",$colorHex');
      }
    } finally {
      await sink.flush();
      await sink.close();
    }
  }

  static Future<void> writeEntriesCsv(
    File file,
    List<Entry> entries, {
    bool includeIds = false,
  }) async {
    final sink = file.openWrite();
    try {
      sink.writeln(includeIds
          ? 'entryId,listId,description,latitude,longitude,image,date'
          : 'description,latitude,longitude,image,date');
      for (final entry in entries) {
        final description = entry.description?.replaceAll('"', '""') ?? '';
        final date = entry.date?.toIso8601String() ?? '';
        final data =
            '"$description",${entry.latitude ?? ''},${entry.longitude ?? ''},${entry.image ?? ''},$date';
        sink.writeln(
            includeIds ? '${entry.entryId},${entry.listId},$data' : data);
      }
    } finally {
      await sink.flush();
      await sink.close();
    }
  }

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
    await writeListsCsv(listsFile, lists);

    final entries = await db.getAllEntries();
    final entriesFile = File(path.join(tempDir.path, 'entries.csv'));
    await writeEntriesCsv(entriesFile, entries, includeIds: true);

    return [listsFile.path, entriesFile.path];
  }

  static Future<String?> exportList({
    required AppDatabase db,
    required ImageStorage storage,
    required EntryList list,
  }) async {
    final entries = list.listId == -1
        ? await db.getAllEntries()
        : await db.getListEntries(list.listId);

    if (entries.isEmpty) return null;

    final tempDir = await getTemporaryDirectory();
    final sanitizedName =
        list.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    final baseName = sanitizedName.isEmpty ? 'list' : sanitizedName;

    final imagePaths = <String>{};
    for (final entry in entries) {
      if (entry.image != null && entry.image!.isNotEmpty) {
        final imageFile = File(storage.getImagePath(entry.image!));
        if (imageFile.existsSync()) {
          imagePaths.add(imageFile.path);
        }
      }
    }

    if (imagePaths.isEmpty) {
      final csvFile = File(path.join(tempDir.path, '$baseName.csv'));
      await writeEntriesCsv(csvFile, entries);
      return csvFile.path;
    }

    final tempCsvFile = File(
      path.join(tempDir.path,
          'temp_${DateTime.now().millisecondsSinceEpoch}_entries.csv'),
    );
    await writeEntriesCsv(tempCsvFile, entries);

    final zipPath = path.join(tempDir.path, '$baseName.zip');
    final csvPath = tempCsvFile.path;
    final imagePathsList = imagePaths.toList();

    return await Isolate.run(() async {
      final zipFile = File(zipPath);
      if (zipFile.existsSync()) {
        zipFile.deleteSync();
      }

      final encoder = ZipFileEncoder();
      encoder.create(zipPath);

      try {
        await encoder.addFile(File(csvPath), 'entries.csv');

        for (final imagePath in imagePathsList) {
          await encoder.addFile(
            File(imagePath),
            'images/${path.basename(imagePath)}',
          );
        }

        return zipPath;
      } finally {
        await encoder.close();
        try {
          final tempCsv = File(csvPath);
          if (tempCsv.existsSync()) {
            tempCsv.deleteSync();
          }
        } catch (_) {
          // Ignore deletion errors on temp file
        }
      }
    });
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
          await encoder.addFile(File(imagePath));
        }
        return zipPath;
      } finally {
        await encoder.close();
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
        if (backupFile.existsSync()) {
          await encoder.addFile(backupFile, 'pinpoint_database_backup.sqlite');
        }

        for (var imagePath in imagePaths) {
          await encoder.addFile(
              File(imagePath), 'images/${path.basename(imagePath)}');
        }

        return zipPath;
      } finally {
        await encoder.close();
        try {
          if (backupFile.existsSync()) {
            backupFile.deleteSync();
          }
        } catch (_) {
          // Ignore deletion errors on temp file
        }
      }
    });
  }
}
