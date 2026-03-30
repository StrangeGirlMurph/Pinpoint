import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' show Value;
import 'package:latlong2/latlong.dart';

import 'package:pinpoint/data/database.dart';
import 'package:pinpoint/data/images.dart';
import 'package:pinpoint/pages/pick_location.dart';
import 'package:pinpoint/util/snackbar.dart';

class EditBottomSheet extends StatefulWidget {
  final Entry entry;
  final VoidCallback? onSaved;
  final VoidCallback? onDeleted;

  const EditBottomSheet({
    super.key,
    required this.entry,
    this.onSaved,
    this.onDeleted,
  });

  @override
  State<EditBottomSheet> createState() => _EditBottomSheetState();
}

class _EditBottomSheetState extends State<EditBottomSheet> {
  late TextEditingController _descriptionController;
  late TextEditingController _latLngController;
  DateTime? _selectedDate;
  String? _image;
  late int _currentListId;
  late AppDatabase _db;
  late ImageStorage _imageStorage;
  bool _isDeleted = false;
  String? _latLngErrorText;
  late bool _isLatLngEmpty;

  final _dateFormatter = DateFormat('dd.MM.yyyy HH:mm:ss');

  @override
  void initState() {
    super.initState();
    _db = context.read<AppDatabase>();
    _imageStorage = context.read<ImageStorage>();

    _descriptionController =
        TextEditingController(text: widget.entry.description ?? '');

    final lat = widget.entry.latitude;
    final lng = widget.entry.longitude;
    final latLngText = (lat != null && lng != null) ? '$lat, $lng' : '';
    _latLngController = TextEditingController(text: latLngText);
    _latLngErrorText = _getLatLngValidationError(latLngText);
    _isLatLngEmpty = latLngText.trim().isEmpty;

    _selectedDate = widget.entry.date;
    _image = widget.entry.image;
    _currentListId = widget.entry.listId;
  }

  @override
  void dispose() {
    if (!_isDeleted) {
      _saveEntryImplicitly();
    }
    _descriptionController.dispose();
    _latLngController.dispose();
    super.dispose();
  }

  void _saveEntryImplicitly() {
    double? parsedLat = widget.entry.latitude;
    double? parsedLng = widget.entry.longitude;

    final latLngText = _latLngController.text.trim();
    final latLngError = _getLatLngValidationError(latLngText);
    if (latLngText.isEmpty) {
      parsedLat = null;
      parsedLng = null;
    } else if (latLngError == null) {
      final parts = latLngText.split(',');
      parsedLat = double.tryParse(parts[0].trim());
      parsedLng = double.tryParse(parts[1].trim());
    }

    final updatedEntry = widget.entry.copyWith(
      listId: _currentListId,
      description: Value(_descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim()),
      latitude: Value(parsedLat),
      longitude: Value(parsedLng),
      image: Value(_image),
      date: Value(_selectedDate),
    );

    _db.updateEntry(updatedEntry).then((_) {
      widget.onSaved?.call();
    });
  }

  String? _getLatLngValidationError(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    final parts = trimmed.split(',');
    if (parts.length != 2) {
      return 'Use format: Latitude, Longitude';
    }

    final lat = double.tryParse(parts[0].trim());
    final lng = double.tryParse(parts[1].trim());

    if (lat == null || lng == null) {
      return 'Latitude and longitude must be numbers';
    }

    if (lat < -90 || lat > 90) {
      return 'Latitude must be between -90 and 90';
    }

    if (lng < -180 || lng > 180) {
      return 'Longitude must be between -180 and 180';
    }

    return null;
  }

  Future<void> _pickLocationOnMap() async {
    final listColor = (await _db.getList(_currentListId))!.color;

    if (!mounted) return;

    final picked = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(builder: (context) => PickLocationPage(listColor)),
    );

    if (picked == null) return;

    final text =
        '${picked.latitude.toStringAsFixed(6)}, ${picked.longitude.toStringAsFixed(6)}';

    setState(() {
      _latLngController.text = text;
      _latLngErrorText = _getLatLngValidationError(text);
      _isLatLngEmpty = text.trim().isEmpty;
    });
  }

  Future<void> _pickImage(bool fromCamera) async {
    final storage = context.read<ImageStorage>();
    final image = fromCamera
        ? await storage.takePhoto(widget.entry.entryId)
        : await storage.pickMedia(widget.entry.entryId);

    if (image != null) {
      // If we had a previous image, delete it from storage to avoid orphan files
      if (_image != null && _image != image) {
        await storage.deleteImage(_image!, widget.entry.entryId);
      }
      setState(() {
        _image = image;
      });
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Picture'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pick from Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(false);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openImageInGallery() async {
    OpenFile.open(_imageStorage.getImagePath(_image!));
  }

  Future<void> _downloadImage() async {
    final success = await _imageStorage.downloadImage(_image!);

    if (!success && mounted) {
      showSnackBar(context, 'Image download failed.');
    }
  }

  Future<void> _pickDateTime() async {
    final initial = _selectedDate ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(0),
      lastDate: DateTime(DateTime.now().year + 10),
      locale: const Locale('en', 'GB'),
    );
    if (date != null) {
      if (!mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initial),
      );
      if (time != null) {
        setState(() {
          _selectedDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _deleteEntry() async {
    _isDeleted = true;
    await _db.deleteEntry(widget.entry.entryId, _imageStorage);

    if (mounted) {
      widget.onDeleted?.call();
      Navigator.of(context).pop();
    }
  }

  Future<void> _moveEntry() async {
    final lists = await _db.getLists();

    if (!mounted) return;

    final selectedList = await showDialog<EntryList>(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: lists
                  .map(
                    (list) => ListTile(
                      leading: Icon(Icons.circle, color: list.color),
                      title: Text(list.name),
                      selected: list.listId == _currentListId,
                      onTap: () {
                        Navigator.of(context).pop(list);
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
    );

    if (selectedList != null && selectedList.listId != _currentListId) {
      _currentListId = selectedList.listId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: SingleChildScrollView(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image Display
                  if (_image != null) ...[
                    GestureDetector(
                      onTap: _openImageInGallery,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.6,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_imageStorage.getImagePath(_image!)),
                            width: double.infinity,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(
                                    child: Text("Could not load image")),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (_image != null) ...[
                        TextButton.icon(
                          onPressed: () {
                            if (!kIsWeb &&
                                (Platform.isAndroid || Platform.isIOS)) {
                              _showImageSourceDialog();
                            } else {
                              _pickImage(false);
                            }
                          },
                          icon: const Icon(Icons.image),
                          label: const Text('Change'),
                        ),
                        TextButton.icon(
                          onPressed: _downloadImage,
                          icon: const Icon(Icons.download),
                          label: const Text('Download'),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final storage = context.read<ImageStorage>();
                            await storage.deleteImage(
                                _image!, widget.entry.entryId);
                            setState(() {
                              _image = null;
                            });
                          },
                          icon: const Icon(Icons.delete),
                          label: const Text("Remove"),
                        ),
                      ] else ...[
                        TextButton.icon(
                          onPressed: () {
                            _pickImage(false);
                          },
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Pick from Gallery'),
                        ),
                        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
                          TextButton.icon(
                            onPressed: () {
                              _pickImage(true);
                            },
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Take a Picture'),
                          ),
                      ]
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    minLines: 1,
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _pickDateTime,
                    borderRadius: BorderRadius.circular(4),
                    child: InputDecorator(
                      isEmpty: _selectedDate == null,
                      decoration: InputDecoration(
                        labelText: 'Date & Time',
                        border: const OutlineInputBorder(),
                        suffixIcon: _selectedDate != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _selectedDate = null;
                                  });
                                },
                              )
                            : null,
                      ),
                      child: Text(
                        _selectedDate != null
                            ? _dateFormatter.format(_selectedDate!)
                            : '',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _latLngController,
                    onChanged: (value) {
                      final newError = _getLatLngValidationError(value);
                      final isEmpty = value.trim().isEmpty;
                      if (newError != _latLngErrorText ||
                          isEmpty != _isLatLngEmpty) {
                        setState(() {
                          _latLngErrorText = newError;
                          _isLatLngEmpty = isEmpty;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Coordinates',
                      border: const OutlineInputBorder(),
                      hintText: 'e.g. 52.5200, 13.4050',
                      errorText: _latLngErrorText,
                      suffixIcon: IconButton(
                        onPressed: _pickLocationOnMap,
                        icon: const Icon(Icons.map),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: _deleteEntry,
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: const Text('Delete',
                              style: TextStyle(color: Colors.red)),
                        ),
                        TextButton.icon(
                          onPressed: _moveEntry,
                          icon: const Icon(Icons.format_list_bulleted),
                          label: const Text('Change list'),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.save),
                          label: const Text('Close'),
                        ),
                      ]),
                ],
              ),
            ),
          ),
        ));
  }
}

Future<void> showEntryEditBottomSheet(
  BuildContext context,
  Entry entry, {
  VoidCallback? onSaved,
  VoidCallback? onDeleted,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    enableDrag: true,
    builder: (context) => EditBottomSheet(
      entry: entry,
      onSaved: onSaved,
      onDeleted: onDeleted,
    ),
  );
}
