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
import 'package:pinpoint/util/tile_cache.dart';
import 'package:pinpoint/util/tile_layer.dart';
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
        await SharePlus.instance.share(
          ShareParams(
            files: files,
            text: shareText,
            sharePositionOrigin: _sharePositionOrigin(context),
          ),
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
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result.isEmpty || result.first.path == null) {
        return;
      }

      final String zipPath = result.first.path!;

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

  Future<void> _showTileProviderDialog(
      BuildContext context, Settings settings) async {
    final currentUrl = settings.get(Settings.tileUrlTemplate) as String;
    final currentUserAgent = settings.get(Settings.tileUserAgent) as String;

    await showDialog(
      context: context,
      builder: (ctx) => _TileProviderDialog(
        initialUrl: currentUrl,
        initialUserAgent: currentUserAgent,
        onSave: (url, userAgent) {
          settings.set(Settings.tileUrlTemplate, url);
          settings.set(Settings.tileUserAgent, userAgent);
          reconfigureTileCache();
        },
      ),
    );
  }

  Future<void> _confirmClearCache(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Map Cache?'),
        content: const Text(
          'This will delete all locally cached map tiles. With an internet connection they will be re-downloaded when needed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await clearTileCache();
      if (context.mounted) {
        showSnackBar(context, 'Map tile cache cleared');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<Settings>();
    final currentTheme = settings.get(Settings.theme) as String;
    final currentStartPage = settings.get(Settings.startPage) as String;
    final isDefaultOsm = isDefaultOsmProvider(settings);
    final cacheEnabled = settings.get(Settings.tileCacheEnabled) as bool;
    final cacheMaxSizeMB = settings.get(Settings.tileCacheMaxSizeMB) as int;
    final cacheFreshnessDays =
        settings.get(Settings.tileCacheFreshnessDays) as int;
    final topPadding = MediaQuery.of(context).padding.top + appbarHeight;

    return DefaultPage(
      name: "Settings",
      body: ListView(
        padding: EdgeInsets.only(top: topPadding, bottom: 10),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'General',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Theme'),
            subtitle: const Text('Pick a default'),
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
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Startup Page'),
            subtitle: const Text('Choose a homepage'),
            trailing: DropdownButton<String>(
              value: currentStartPage,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  settings.set(Settings.startPage, newValue);
                }
              },
              items: const [
                DropdownMenuItem(
                  value: '/map',
                  child: Text('Map View'),
                ),
                DropdownMenuItem(
                  value: '/list',
                  child: Text('List View'),
                ),
              ],
            ),
          ),
          StreamBuilder<List<EntryList>>(
            stream: context.read<AppDatabase>().watchLists(),
            builder: (context, snapshot) {
              final lists = snapshot.data ?? [];
              final currentDefaultListId =
                  settings.get(Settings.quickActionDefaultListId) as int;
              final listExists =
                  lists.any((l) => l.listId == currentDefaultListId);
              final effectiveValue = listExists ? currentDefaultListId : -1;

              if (snapshot.hasData &&
                  currentDefaultListId != -1 &&
                  !listExists) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  settings.set(Settings.quickActionDefaultListId, -1);
                });
              }

              return ListTile(
                titleAlignment: ListTileTitleAlignment.top,
                isThreeLine: true,
                leading: const Icon(Icons.shortcut_outlined),
                title: const Text('Quick Action default list'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Target list for app shortcuts'),
                    const SizedBox(height: 8),
                    DropdownButton<int>(
                      value: effectiveValue,
                      onChanged: (int? newValue) {
                        if (newValue != null) {
                          settings.set(
                              Settings.quickActionDefaultListId, newValue);
                        }
                      },
                      items: [
                        const DropdownMenuItem<int>(
                          value: -1,
                          child: Text('None (always ask me)'),
                        ),
                        ...lists.map(
                          (list) => DropdownMenuItem<int>(
                            value: list.listId,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle, color: list.color, size: 14),
                                const SizedBox(width: 8),
                                Text(
                                  list.name,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.system_update),
            title: const Text('Updates'),
            subtitle: const Text('Check for updates on startup'),
            value: settings.get(Settings.checkForUpdates) as bool,
            onChanged: (bool value) {
              settings.set(Settings.checkForUpdates, value);
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Map',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.layers_outlined),
            title: const Text('Tile Provider'),
            subtitle: Text(
              isDefaultOsm ? 'OpenStreetMap (Default)' : 'Custom Provider',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showTileProviderDialog(context, settings),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: isDefaultOsm
                ? () => showSnackBar(context,
                    'Tile caching is mandatory for the default OSM tiles')
                : null,
            child: IgnorePointer(
              ignoring: isDefaultOsm,
              child: SwitchListTile(
                secondary: const Icon(Icons.cached),
                title: const Text('Tile Caching'),
                subtitle: const Text('Highly recommended!'),
                value: isDefaultOsm ? true : cacheEnabled,
                onChanged: isDefaultOsm
                    ? null
                    : (bool value) {
                        settings.set(Settings.tileCacheEnabled, value);
                        reconfigureTileCache();
                      },
              ),
            ),
          ),
          if (isDefaultOsm || cacheEnabled) ...[
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: isDefaultOsm
                  ? () => showSnackBar(context,
                      'Following the HTTP Headers for tile freshness is mandatory for the default OSM tiles')
                  : null,
              child: IgnorePointer(
                ignoring: isDefaultOsm,
                child: ListTile(
                  enabled: !isDefaultOsm,
                  leading: const Icon(Icons.history),
                  title: const Text('Tile Freshness'),
                  subtitle: const Text('Expiry duration for cached tiles'),
                  trailing: DropdownButton<int>(
                    value: isDefaultOsm
                        ? 0
                        : ([0, 7, 30, 90].contains(cacheFreshnessDays)
                            ? cacheFreshnessDays
                            : 0),
                    onChanged: isDefaultOsm
                        ? null
                        : (int? newValue) {
                            if (newValue != null) {
                              settings.set(
                                  Settings.tileCacheFreshnessDays, newValue);
                              reconfigureTileCache();
                            }
                          },
                    items: const [
                      DropdownMenuItem(
                        value: 0,
                        child: Text('HTTP Headers'),
                      ),
                      DropdownMenuItem(
                        value: 7,
                        child: Text('7 Days'),
                      ),
                      DropdownMenuItem(
                        value: 30,
                        child: Text('30 Days'),
                      ),
                      DropdownMenuItem(
                        value: 90,
                        child: Text('90 Days'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.storage),
              title: const Text('Max Cache Size'),
              subtitle: const Text('Oldest tiles are pruned first if exceeded'),
              trailing: DropdownButton<int>(
                value: [250, 500, 1000, 2000, 5000, 0].contains(cacheMaxSizeMB)
                    ? cacheMaxSizeMB
                    : 1000,
                onChanged: (int? newValue) {
                  if (newValue != null) {
                    settings.set(Settings.tileCacheMaxSizeMB, newValue);
                    reconfigureTileCache();
                  }
                },
                items: const [
                  DropdownMenuItem(value: 250, child: Text('250 MB')),
                  DropdownMenuItem(value: 500, child: Text('500 MB')),
                  DropdownMenuItem(value: 1000, child: Text('1 GB')),
                  DropdownMenuItem(value: 2000, child: Text('2 GB')),
                  DropdownMenuItem(value: 5000, child: Text('5 GB')),
                  DropdownMenuItem(value: 0, child: Text('Unlimited')),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Clear Tile Cache'),
              subtitle: const Text('Delete all locale map tiles'),
              onTap: () => _confirmClearCache(context),
            ),
          ],
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

class _TileProviderDialog extends StatefulWidget {
  final String initialUrl;
  final String initialUserAgent;
  final void Function(String url, String userAgent) onSave;

  const _TileProviderDialog({
    required this.initialUrl,
    required this.initialUserAgent,
    required this.onSave,
  });

  @override
  State<_TileProviderDialog> createState() => _TileProviderDialogState();
}

class _TileProviderDialogState extends State<_TileProviderDialog> {
  late final TextEditingController _urlController;
  late final TextEditingController _userAgentController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.initialUrl);
    _userAgentController = TextEditingController(text: widget.initialUserAgent);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _userAgentController.dispose();
    super.dispose();
  }

  void _resetToDefault() {
    setState(() {
      _urlController.text = Settings.defaultTileUrlTemplate;
      _userAgentController.text = Settings.defaultTileUserAgent;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tile Provider'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL Template',
                hintText: Settings.defaultTileUrlTemplate,
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              autocorrect: false,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Supported Formats: Standard XYZ raster tiles (PNG, JPG, WebP) with {z}, {x}, {y} placeholders. Vector tiles and WMS services are not supported.',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Terms of Service: You are solely responsible for ensuring you comply with all usage policies, terms of service, attribution requirements, and rate limits of your chosen tile provider!',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _userAgentController,
              decoration: const InputDecoration(
                labelText: 'User-Agent',
                hintText: Settings.defaultTileUserAgent,
                border: OutlineInputBorder(),
              ),
              autocorrect: false,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'User-Agent: A unique name/identifier that identifies this client in HTTP requests. Many tile servers (including OpenStreetMap) require a valid and specific identifier to prevent abuse and blocks.',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        Wrap(
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: _resetToDefault,
              child: const Text('Reset to Default'),
            ),
            TextButton(
              onPressed: () {
                final url = _urlController.text.trim();
                final userAgent = _userAgentController.text.trim();
                widget.onSave(
                  url.isEmpty ? Settings.defaultTileUrlTemplate : url,
                  userAgent.isEmpty ? Settings.defaultTileUserAgent : userAgent,
                );
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        )
      ],
    );
  }
}
