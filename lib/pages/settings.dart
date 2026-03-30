import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pinpoint/data/database.dart';
import 'package:pinpoint/data/images.dart';
import 'package:pinpoint/data/import.dart';
import 'package:pinpoint/data/export.dart';
import 'package:pinpoint/data/settings.dart';
import 'package:pinpoint/util/snackbar.dart';
import 'package:pinpoint/widgets/appbar.dart';
import 'package:pinpoint/widgets/default_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Rect? _sharePositionOrigin(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> _handleExport(
    BuildContext context, {
    required Future<dynamic> Function() exportAction,
    required String shareText,
    required String errorMessage,
  }) async {
    ScaffoldFeatureController<SnackBar, SnackBarClosedReason>?
        snackbarController;
    try {
      if (context.mounted) {
        snackbarController = ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exporting... Please be patient!'),
            duration: Duration(minutes: 20),
          ),
        );
      }

      final result = await exportAction();

      if (snackbarController != null) {
        snackbarController.close();
      }

      if (result == null) {
        if (context.mounted) {
          showSnackBar(context, 'Nothing to export.');
        }
        return;
      }

      final files = result is List<String>
          ? result.map((path) => XFile(path)).toList()
          : [XFile(result as String)];

      if (context.mounted && files.isNotEmpty) {
        await Share.shareXFiles(
          files,
          text: shareText,
          sharePositionOrigin: _sharePositionOrigin(context),
        );
      }
    } catch (e) {
      if (snackbarController != null) {
        snackbarController.close();
      }
      if (context.mounted) {
        showSnackBar(context, '$errorMessage: $e');
      }
    }
  }

  Future<void> _exportDatabase(BuildContext context) async {
    final db = context.read<AppDatabase>();
    await _handleExport(
      context,
      exportAction: () => Exporter.exportDatabase(db),
      shareText: 'Pinpoint Database Backup',
      errorMessage: 'Failed to export database',
    );
  }

  Future<void> _exportHumanReadableDatabase(BuildContext context) async {
    final db = context.read<AppDatabase>();
    await _handleExport(
      context,
      exportAction: () => Exporter.exportHumanReadableDatabase(db),
      shareText: 'Pinpoint Database CSV Export',
      errorMessage: 'Failed to export CSV',
    );
  }

  Future<void> _exportImages(BuildContext context) async {
    final storage = context.read<ImageStorage>();
    await _handleExport(
      context,
      exportAction: () => Exporter.exportImages(storage),
      shareText: 'Pinpoint Images Backup',
      errorMessage: 'Error exporting images',
    );
  }

  Future<void> _exportFullBackup(BuildContext context) async {
    final db = context.read<AppDatabase>();
    final storage = context.read<ImageStorage>();
    await _handleExport(
      context,
      exportAction: () => Exporter.exportFullBackup(db, storage),
      shareText: 'Pinpoint Full Backup',
      errorMessage: 'Failed to create full backup',
    );
  }

  Future<void> _importFullBackup(BuildContext context) async {
    final db = context.read<AppDatabase>();
    final storage = context.read<ImageStorage>();
    bool isLoadingShown = false;

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result == null || result.files.single.path == null) {
        return;
      }

      final String zipPath = result.files.single.path!;

      if (!context.mounted) return;
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Import Backup'),
          content: const Text(
              'This will merge lists and entries from the backup with your current data. '
              'Exact duplicates will be skipped. Do you want to proceed?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Import'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      if (!context.mounted) return;
      isLoadingShown = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const PopScope(
          canPop: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      );

      await Importer.importFullBackupFromZip(zipPath, db, storage);

      if (context.mounted) {
        if (isLoadingShown) Navigator.of(context).pop(); // Dismiss loading
        showSnackBar(context, 'Import completed successfully.');
      }
    } catch (e) {
      if (context.mounted) {
        if (isLoadingShown) Navigator.of(context).pop();
        showSnackBar(context, 'Failed to import backup: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<Settings>();
    final currentTheme = settings.get(Settings.theme) as String;
    final topPadding = MediaQuery.of(context).padding.top + appbarHeight;

    return DefaultPage(
      name: "Settings",
      body: ListView(
        padding: EdgeInsets.only(top: topPadding, bottom: 10),
        children: [
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Theme'),
            subtitle: const Text('Choose application theme'),
            trailing: DropdownButton<String>(
              value: currentTheme,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  settings.set(Settings.theme, newValue);
                }
              },
              items: const [
                DropdownMenuItem(
                  value: 'system',
                  child: Text('System'),
                ),
                DropdownMenuItem(
                  value: 'light',
                  child: Text('Light'),
                ),
                DropdownMenuItem(
                  value: 'dark',
                  child: Text('Dark'),
                ),
              ],
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Data & Storage',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Symbols.database),
            title: const Text('Export Database'),
            subtitle: const Text('Export your sqlite database'),
            onTap: () => _exportDatabase(context),
          ),
          ListTile(
            leading: const Icon(Symbols.table),
            title: const Text('Export Human-readable Database'),
            subtitle: const Text('Export your database as csv files'),
            onTap: () => _exportHumanReadableDatabase(context),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Export Images'),
            subtitle: const Text('Export all your images'),
            onTap: () => _exportImages(context),
          ),
          ListTile(
            leading: const Icon(Icons.upload),
            title: const Text('Export Full Backup'),
            subtitle: const Text('Export database and images together'),
            onTap: () => _exportFullBackup(context),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Import Full Backup'),
            subtitle: const Text('Import a previous full backup'),
            onTap: () => _importFullBackup(context),
          ),
          // Room for future settings
        ],
      ),
    );
  }
}
