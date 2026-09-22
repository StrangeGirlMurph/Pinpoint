import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' show Value;
import 'package:latlong2/latlong.dart';
import 'package:pinpoint/util/exif.dart';

import 'package:pinpoint/data/database.dart';
import 'package:pinpoint/data/images.dart';
import 'package:pinpoint/pages/pick_location.dart';
import 'package:pinpoint/util/location.dart';
import 'package:pinpoint/util/list.dart';
import 'package:pinpoint/util/snackbar.dart';
import 'package:share_plus/share_plus.dart';

class EditBottomSheet extends StatefulWidget {
  final Entry entry;
  final VoidCallback? onSaved;
  final VoidCallback? onDeleted;
  final void Function(LatLng location)? onLocationChanged;
  final bool autoFetchLocation;

  const EditBottomSheet({
    super.key,
    required this.entry,
    this.onSaved,
    this.onDeleted,
    this.onLocationChanged,
    this.autoFetchLocation = false,
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
  bool _isFetchingLocation = false;
  final GlobalKey _shareButtonKey = GlobalKey();

  final _dateFormatter = DateFormat('HH:mm:ss dd.MM.yyyy');
  final _shareDateFormatter = DateFormat("HH:mm:ss 'on the' dd.MM.yyyy");

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

    if (widget.autoFetchLocation && lat == null && lng == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _pasteCurrentLocation();
        }
      });
    }
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

  void _saveEntryImplicitly({double? overrideLat, double? overrideLng}) {
    double? parsedLat = overrideLat ?? widget.entry.latitude;
    double? parsedLng = overrideLng ?? widget.entry.longitude;

    if (overrideLat == null && overrideLng == null) {
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

    _saveEntryImplicitly(
      overrideLat: picked.latitude,
      overrideLng: picked.longitude,
    );
    widget.onLocationChanged?.call(picked);
  }

  Future<void> _pasteCurrentLocation() async {
    if (_isFetchingLocation) return;
    setState(() {
      _isFetchingLocation = true;
    });

    try {
      final result = await fetchCurrentLocation();
      if (!mounted) return;

      if (result.isSuccess && result.location != null) {
        final location = result.location!;
        final text =
            '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
        setState(() {
          _latLngController.text = text;
          _latLngErrorText = null;
          _isLatLngEmpty = false;
        });

        _saveEntryImplicitly(
          overrideLat: location.latitude,
          overrideLng: location.longitude,
        );
        widget.onLocationChanged?.call(location);
      }

      showLocationResultFeedback(context, result,
          position: SnackBarPosition.top);
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingLocation = false;
        });
      }
    }
  }

  Future<void> _pickImage(bool fromCamera) async {
    final storage = context.read<ImageStorage>();
    try {
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

        final imagePath = storage.getImagePath(image);
        final metadata = await readImageMetadata(imagePath);

        if (metadata.location != null && mounted) {
          final latLngText = _latLngController.text.trim();
          final error = _getLatLngValidationError(latLngText);
          final entryHasLocation = latLngText.isNotEmpty && error == null;

          LatLng? locationToUse;
          if (entryHasLocation) {
            locationToUse = await _showLocationConflictDialog(
              latLngText,
              metadata.location!,
            );
          } else {
            locationToUse = metadata.location;
          }

          if (locationToUse != null && mounted) {
            final text =
                '${locationToUse.latitude.toStringAsFixed(6)}, ${locationToUse.longitude.toStringAsFixed(6)}';
            setState(() {
              _latLngController.text = text;
              _latLngErrorText = _getLatLngValidationError(text);
              _isLatLngEmpty = text.trim().isEmpty;
            });
            _saveEntryImplicitly(
              overrideLat: locationToUse.latitude,
              overrideLng: locationToUse.longitude,
            );
            widget.onLocationChanged?.call(locationToUse);
          }
        }

        if (metadata.dateTime != null && mounted) {
          DateTime? dateToUse;
          if (_selectedDate != null) {
            dateToUse = await _showDateTimeConflictDialog(
              _selectedDate!,
              metadata.dateTime!,
            );
          } else {
            dateToUse = metadata.dateTime;
          }

          if (dateToUse != null && mounted) {
            setState(() {
              _selectedDate = dateToUse;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(
          context,
          'Failed to pick image: $e',
          position: SnackBarPosition.top,
        );
      }
    }
  }

  Future<LatLng?> _showLocationConflictDialog(
      String currentText, LatLng imageLocation) {
    return showDialog<LatLng>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Keep current'),
              subtitle: Text(currentText),
              onTap: () => Navigator.of(context).pop(null),
            ),
            ListTile(
              title: const Text('Use image metadata'),
              subtitle: Text(
                '${imageLocation.latitude.toStringAsFixed(6)}, ${imageLocation.longitude.toStringAsFixed(6)}',
              ),
              onTap: () => Navigator.of(context).pop(imageLocation),
            ),
          ],
        ),
      ),
    );
  }

  Future<DateTime?> _showDateTimeConflictDialog(
      DateTime currentDate, DateTime imageDate) {
    return showDialog<DateTime>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a Date & Time'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Keep current'),
              subtitle: Text(_dateFormatter.format(currentDate)),
              onTap: () => Navigator.of(context).pop(null),
            ),
            ListTile(
              title: const Text('Use image metadata'),
              subtitle: Text(_dateFormatter.format(imageDate)),
              onTap: () => Navigator.of(context).pop(imageDate),
            ),
          ],
        ),
      ),
    );
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
    final result = await OpenFile.open(_imageStorage.getImagePath(_image!));
    if (result.type != ResultType.done && mounted) {
      showSnackBar(
        context,
        result.message.isNotEmpty
            ? result.message
            : 'Could not open image in gallery.',
        position: SnackBarPosition.top,
      );
    }
  }

  Future<void> _downloadImage() async {
    final success = await _imageStorage.downloadImage(_image!);

    if (success == false && mounted) {
      showSnackBar(
        context,
        'Image download failed.',
        position: SnackBarPosition.top,
      );
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

    final selectedList = await showSelectListDialog(
      context,
      lists,
      currentListId: _currentListId,
    );

    if (selectedList != null && selectedList.listId != _currentListId) {
      setState(() {
        _currentListId = selectedList.listId;
      });
      _saveEntryImplicitly();
    }
  }

  String? _buildShareText() {
    final description = _descriptionController.text.trim();
    final hasDesc = description.isNotEmpty;
    final dateTime = _selectedDate != null
        ? _shareDateFormatter.format(_selectedDate!)
        : null;
    final hasDateTime = dateTime != null;

    String? coordinates;
    final latLngText = _latLngController.text.trim();
    if (latLngText.isNotEmpty &&
        _getLatLngValidationError(latLngText) == null) {
      final parts = latLngText.split(',');
      coordinates = '${parts[0].trim()}, ${parts[1].trim()}';
    }
    final hasCoords = coordinates != null;

    if (hasDesc && hasDateTime && hasCoords) {
      return '$description at $dateTime and $coordinates';
    } else if (hasDesc && hasCoords) {
      return '$description at $coordinates';
    } else if (hasDesc && hasDateTime) {
      return '$description at $dateTime';
    } else if (hasDateTime && hasCoords) {
      return '$dateTime at $coordinates';
    } else if (hasCoords) {
      return coordinates;
    } else if (hasDesc) {
      return description;
    } else if (hasDateTime) {
      return dateTime;
    }
    return null;
  }

  Rect? _sharePositionOrigin() {
    final box =
        _shareButtonKey.currentContext?.findRenderObject() as RenderBox? ??
            context.findRenderObject() as RenderBox?;
    if (box == null) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> _shareEntry() async {
    _saveEntryImplicitly();

    final shareText = _buildShareText();
    List<XFile>? files;

    if (_image != null && _image!.isNotEmpty) {
      final imagePath = _imageStorage.getImagePath(_image!);
      final file = File(imagePath);
      if (file.existsSync()) {
        files = [XFile(imagePath)];
      }
    }

    if (shareText == null && (files == null || files.isEmpty)) {
      if (mounted) {
        showSnackBar(
          context,
          'Nothing to share.',
          position: SnackBarPosition.top,
        );
      }
      return;
    }

    try {
      await SharePlus.instance.share(
        ShareParams(
          files: (files != null && files.isNotEmpty) ? files : null,
          text: shareText,
          sharePositionOrigin: _sharePositionOrigin(),
        ),
      );
    } catch (e) {
      if (mounted) {
        showSnackBar(
          context,
          'Failed to share: $e',
          position: SnackBarPosition.top,
        );
      }
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
                        TextButton.icon(
                          onPressed: _downloadImage,
                          icon: const Icon(Icons.download),
                          label: const Text('Download'),
                        ),
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
                        suffixIconConstraints:
                            const BoxConstraints(minWidth: 0, minHeight: 0),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints.tightFor(
                                  width: 40,
                                  height: 40,
                                ),
                                style: IconButton.styleFrom(
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                tooltip: 'Use current date & time',
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                onPressed: () {
                                  setState(() {
                                    _selectedDate = DateTime.now();
                                  });
                                },
                                icon: const Icon(Icons.today),
                              ),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints.tightFor(
                                  width: 40,
                                  height: 40,
                                ),
                                style: IconButton.styleFrom(
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                tooltip: "Clear date & time",
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                onPressed: _selectedDate != null
                                    ? () {
                                        setState(() {
                                          _selectedDate = null;
                                        });
                                      }
                                    : null,
                                icon: const Icon(Icons.clear),
                              ),
                            ],
                          ),
                        ),
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
                      suffixIconConstraints:
                          const BoxConstraints(minWidth: 0, minHeight: 0),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(
                                width: 40,
                                height: 40,
                              ),
                              style: IconButton.styleFrom(
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              tooltip: 'Pick on map',
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              onPressed: _pickLocationOnMap,
                              icon: const Icon(Icons.map),
                            ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(
                                width: 40,
                                height: 40,
                              ),
                              style: IconButton.styleFrom(
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              tooltip: 'Use current location',
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              onPressed: _isFetchingLocation
                                  ? null
                                  : _pasteCurrentLocation,
                              icon: _isFetchingLocation
                                  ? SizedBox.square(
                                      dimension: 24,
                                      child: Center(
                                        child: SizedBox.square(
                                          dimension: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    )
                                  : const Icon(Icons.my_location),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        tooltip: "Delete the entry",
                        onPressed: _deleteEntry,
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 18,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _moveEntry,
                        icon: const Icon(Icons.format_list_bulleted),
                        label: const Text('Change list'),
                      ),
                      TextButton.icon(
                        key: _shareButtonKey,
                        onPressed: _shareEntry,
                        icon: const Icon(Icons.share),
                        label: const Text('Share'),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Close'),
                      ),
                    ],
                  ),
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
  void Function(LatLng location)? onLocationChanged,
  bool autoFetchLocation = false,
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
      onLocationChanged: onLocationChanged,
      autoFetchLocation: autoFetchLocation,
    ),
  );
}
