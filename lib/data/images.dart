import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import 'package:pinpoint/data/database.dart';
import 'package:pinpoint/data/settings.dart';

class ImageStorage {
  final ImagePicker picker = ImagePicker();
  Settings settings;
  AppDatabase db;
  Directory appDocDir;

  ImageStorage(this.appDocDir, this.settings, this.db) {
    _getLostData();
  }

  Future<List<File>> getAllImages() async {
    final docDir = appDocDir;
    if (!await docDir.exists()) return [];

    final List<File> imageFiles = [];
    final files = docDir.listSync();
    for (var item in files) {
      if (item is File &&
          (item.path.toLowerCase().endsWith('.jpg') ||
              item.path.toLowerCase().endsWith('.jpeg') ||
              item.path.toLowerCase().endsWith('.png'))) {
        imageFiles.add(item);
      }
    }
    return imageFiles;
  }

  Future<String?> pickMedia(int entryId) async {
    settings.set(Settings.lastEntryId, entryId);
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      settings.remove(Settings.lastEntryId);
      return await saveImage(image);
    }
    return null;
  }

  Future<String?> takePhoto(int entryId) async {
    settings.set(Settings.lastEntryId, entryId);

    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      settings.remove(Settings.lastEntryId);
      return await saveImage(photo);
    }
    return null;
  }

  Future<String> saveImage(XFile imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final hash = md5.convert(bytes).toString();
    final extension = p.extension(imageFile.name);

    final String fileName = '$hash$extension';
    final String filePath = p.join(appDocDir.path, fileName);

    final File savedImage = File(filePath);
    if (!await savedImage.exists()) {
      await savedImage.writeAsBytes(bytes);
    }

    try {
      final tempFile = File(imageFile.path);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    } catch (e) {
      debugPrint('Warning: Could not delete temporary image file: $e');
    }

    return fileName;
  }

  String getImagePath(String imageName) {
    return p.join(appDocDir.path, imageName);
  }

  Future<bool> deleteImage(String image, [int? excludeEntryId]) async {
    final isUsed = await db.isImageUsed(image, excludeEntryId);
    if (isUsed) return false;

    final fullPath = getImagePath(image);
    final file = File(fullPath);

    try {
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting image: $e');
      return false;
    }
  }

  Future<bool> downloadImage(String image) async {
    try {
      final fullPath = getImagePath(image);
      final sourceFile = File(fullPath);
      if (!await sourceFile.exists()) {
        return false;
      }

      final bytes = await sourceFile.readAsBytes();

      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save image as',
        fileName: p.basename(fullPath),
        bytes: bytes,
      );

      if (kIsWeb) {
        return true;
      }

      return outputPath != null && outputPath.isNotEmpty;
    } catch (e) {
      debugPrint('Error downloading image: $e');
      return false;
    }
  }

  Future<void> _getLostData() async {
    // retrieveLostData() is only supported on Android and iOS
    if (kIsWeb || Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      return;
    }

    try {
      final ImagePicker picker = ImagePicker();
      final LostDataResponse response = await picker.retrieveLostData();
      if (response.isEmpty) {
        return;
      }
      final XFile? file = response.file;
      if (file != null) {
        _handleLostFile(file);
      } else {
        debugPrint(
            'Error: ${response.exception?.toString() ?? "Unknown error while retrieving lost data."}');
      }
    } catch (e) {
      debugPrint('Error retrieving lost data: $e');
    }
  }

  void _handleLostFile(XFile files) async {
    int? intendedEntryId = settings.get(Settings.lastEntryId);

    if (intendedEntryId != null) {
      String image = await saveImage(files);
      debugPrint('Lost file saved to: $image');
      final entry = await db.getEntry(intendedEntryId);
      if (entry != null) {
        final updated = entry.copyWith(
          image: drift.Value(image),
        );
        await db.updateEntry(updated);
      }
    } else {
      debugPrint('No entry ID found for lost file.');
    }
  }
}
