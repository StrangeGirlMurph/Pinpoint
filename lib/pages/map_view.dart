import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_dragmarker/flutter_map_dragmarker.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:pinpoint/data/database.dart';
import 'package:pinpoint/data/images.dart';
import 'package:pinpoint/data/settings.dart';
import 'package:pinpoint/util/exif.dart';
import 'package:pinpoint/util/links.dart';
import 'package:pinpoint/util/location.dart';
import 'package:pinpoint/util/snackbar.dart';
import 'package:pinpoint/util/tile_layer.dart';
import 'package:pinpoint/widgets/appbar.dart';
import 'package:pinpoint/widgets/drawer.dart';
import 'package:pinpoint/widgets/bottom_sheet.dart';
import 'package:pinpoint/widgets/map_buttons.dart';
import 'package:pinpoint/widgets/scaffold.dart';
import 'package:pinpoint/util/list.dart';
import 'package:pinpoint/util/quick_actions.dart';
import 'package:pinpoint/widgets/dropdown.dart';

const double _markerSize = 40.0;
const double _iconPaddingOffset = _markerSize * (2.0 / 24.0);

enum MapTrackingState { none, position, positionAndBearing }

class MapViewPage extends StatefulWidget {
  const MapViewPage({super.key});

  @override
  State<MapViewPage> createState() => _MapViewPageState();
}

class _MapViewPageState extends State<MapViewPage> {
  final MapController _mapController = MapController();
  EntryList? _selectedList;
  List<EntryList> _lists = [];
  List<Entry> _entries = [];
  MapTrackingState _mapTrackingState = MapTrackingState.none;
  late final StreamController<double?> _alignPositionStreamController;
  late final StreamController<void> _alignDirectionStreamController;

  bool _isRotationLocked = false;
  late final LocationService _locationService;

  late final AppDatabase _db;
  late final Settings _settings;
  late final ImageStorage _imageStorage;
  late final QuickActionsService _quickActionsService;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _dataLoaded = false;
  bool _isHandlingQuickAction = false;

  Timer? _saveMapTimer;

  @override
  void initState() {
    super.initState();
    _db = context.read<AppDatabase>();
    _settings = context.read<Settings>();
    _imageStorage = context.read<ImageStorage>();
    _quickActionsService = context.read<QuickActionsService>();
    _quickActionsService.addListener(_handleQuickAction);
    _alignPositionStreamController = StreamController<double?>.broadcast();
    _alignDirectionStreamController = StreamController<void>.broadcast();

    _locationService = LocationService(
      onStateChanged: () {
        if (mounted) {
          if ((_locationService.state == LocationServiceState.serviceDisabled ||
                  _locationService.state ==
                      LocationServiceState.permissionDenied) &&
              _mapTrackingState != MapTrackingState.none) {
            setState(() {
              _mapTrackingState = MapTrackingState.none;
            });
          } else {
            setState(() {});
          }
        }
      },
    );

    _isRotationLocked = _settings.get(Settings.lastMapRotationLocked) ?? false;

    _loadData();
  }

  @override
  void dispose() {
    _quickActionsService.removeListener(_handleQuickAction);
    _saveMapTimer?.cancel();
    _locationService.dispose();
    _alignPositionStreamController.close();
    _alignDirectionStreamController.close();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final lists = await _db.getLists();

    if (mounted) {
      final newSelectedList = determineSelectedList(
        lists: lists,
        currentSelectedList: _selectedList,
        lastListId: _settings.get(Settings.lastListId),
      );

      setState(() {
        _lists = lists;
        _selectedList = newSelectedList;
        if (_selectedList == null) {
          _entries = [];
        }
      });
      if (_selectedList != null) {
        await _loadEntries(_selectedList!.listId);
      }
      _dataLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _handleQuickAction();
        }
      });
    }
  }

  Future<void> _handleQuickAction() async {
    if (!_dataLoaded || _isHandlingQuickAction || !mounted) return;

    final action = _quickActionsService.consumePendingAction();
    if (action == null) return;

    // Ensure the drawer is dismissed if left open from a previous screen or pause.
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      _scaffoldKey.currentState?.closeDrawer();
    }

    _isHandlingQuickAction = true;
    try {
      if (_lists.isEmpty) {
        showSnackBar(context, 'Please create a list first');
        return;
      }

      // Check if a valid default list is configured in Settings.
      EntryList? targetList;
      final defaultListId =
          _settings.get(Settings.quickActionDefaultListId) as int;
      if (defaultListId != -1) {
        targetList = _lists.where((l) => l.listId == defaultListId).firstOrNull;
        if (targetList == null) {
          // Stale ID (e.g. list was deleted), reset setting to "always ask"
          _settings.set(Settings.quickActionDefaultListId, -1);
        }
      }

      // If no default list is set, prompt user if multiple lists exist, or auto-pick the single list.
      if (targetList == null) {
        if (_lists.length == 1) {
          targetList = _lists.first;
        } else {
          targetList = await showSelectListDialog(
            context,
            _lists,
            currentListId:
                _selectedList?.listId != -1 ? _selectedList?.listId : null,
            title: 'Select list for new entry',
          );
        }
      }

      if (targetList == null || !mounted) return;

      if (_selectedList?.listId != targetList.listId) {
        setState(() {
          _selectedList = targetList;
        });
        _settings.set(Settings.lastListId, targetList.listId);
        await _loadEntries(targetList.listId);
      }

      if (!mounted) return;

      switch (action) {
        case QuickActionType.location:
          await _addEntryAtCurrentLocation();
          break;
        case QuickActionType.picture:
          await _addEntryWithPicture();
          break;
        case QuickActionType.blank:
          await _addEntryWithoutLocation();
          break;
      }
    } catch (e, stack) {
      debugPrint('Error handling quick action: $e\n$stack');
    } finally {
      _isHandlingQuickAction = false;
    }
  }

  Future<void> _loadEntries(int listId) async {
    final entries = listId == -1
        ? await _db.getAllEntries()
        : await _db.getListEntries(listId);

    if (mounted) {
      setState(() {
        _entries = entries;
      });
    }
  }

  Future<void> _handleMapLongPress(LatLng location) async {
    if (!mounted || !canAddEntryToSelectedList(context, _selectedList)) return;
    await _addEntryAtLocation(location);
  }

  void _focusMapOnLocation(LatLng location) {
    final targetZoom = math.max(_mapController.camera.zoom, 18.0);
    _mapController.move(location, targetZoom);
  }

  Future<void> _createAndShowEntry({LatLng? location}) async {
    final entryId = await _db.addEntry(
      listId: _selectedList!.listId,
      location: location,
      date: DateTime.now(),
    );
    final newEntry = await _db.getEntry(entryId);

    if (newEntry != null && mounted) {
      if (location != null) {
        _focusMapOnLocation(location);
      }
      _showBottomSheet(newEntry);
    }

    _loadEntries(_selectedList!.listId);
  }

  Future<void> _addEntryAtLocation(LatLng location) async {
    await _createAndShowEntry(location: location);
  }

  Future<void> _addEntryWithoutLocation() async {
    if (!mounted || !canAddEntryToSelectedList(context, _selectedList)) return;
    await _createAndShowEntry();
  }

  Future<void> _addEntryAtCurrentLocation() async {
    if (!mounted || !canAddEntryToSelectedList(context, _selectedList)) return;

    final location =
        _locationService.freshPosition ?? await getCurrentLocation(context);
    if (location != null && mounted) {
      final roundedLocation = LatLng(
        round(location.latitude),
        round(location.longitude),
      );
      await _createAndShowEntry(location: roundedLocation);
    }
  }

  Future<void> _addEntryWithPicture() async {
    if (!mounted || !canAddEntryToSelectedList(context, _selectedList)) return;

    final preCameraLocation = _locationService.freshPosition ??
        (_locationService.currentPosition != null
            ? locationFromPosition(_locationService.currentPosition!)
            : null);

    final entryId = await _db.addEntry(
      listId: _selectedList!.listId,
      location: null,
      date: DateTime.now(),
    );

    final image = await _imageStorage.takePhoto(entryId);

    if (image != null) {
      final entry = (await _db.getEntry(entryId))!;
      if (!mounted) return;

      final imagePath = _imageStorage.getImagePath(image);
      final metadata = await readImageMetadata(imagePath);

      final location = metadata.location ??
          _locationService.freshPosition ??
          preCameraLocation;

      final roundedLocation = location != null
          ? LatLng(round(location.latitude), round(location.longitude))
          : null;

      final entryDate = metadata.dateTime ?? DateTime.now();

      final updatedEntry = entry.copyWith(
        image: drift.Value(image),
        latitude: drift.Value(roundedLocation?.latitude),
        longitude: drift.Value(roundedLocation?.longitude),
        date: drift.Value(entryDate),
      );
      await _db.updateEntry(updatedEntry);

      await _loadEntries(_selectedList!.listId);

      if (roundedLocation != null) {
        _focusMapOnLocation(roundedLocation);
      }

      if (!mounted) return;
      _showBottomSheet(
        updatedEntry,
        autoFetchLocation: roundedLocation == null,
      );
    } else {
      await _db.deleteEntry(entryId, _imageStorage);
    }
  }

  Future<void> _viewLocation() async {
    if (_locationService.state == LocationServiceState.serviceDisabled ||
        _locationService.state == LocationServiceState.permissionDenied) {
      await _locationService.requestPermissionAndEnable(context);
      return;
    }

    if (_locationService.state != LocationServiceState.ready) {
      return; // Still searching or initializing
    }

    setState(() {
      if (_mapTrackingState == MapTrackingState.none) {
        _mapTrackingState = MapTrackingState.position;
        final targetZoom = math.max(_mapController.camera.zoom, 18.0);
        _alignPositionStreamController.add(targetZoom);
      } else if (_mapTrackingState == MapTrackingState.position) {
        _mapTrackingState = MapTrackingState.positionAndBearing;
        _alignDirectionStreamController.add(null);
      } else {
        _mapTrackingState = MapTrackingState.none;
        _mapController.rotate(0.0);
      }
    });
  }

  void _handleCompassPress() {
    if (_mapController.camera.rotation != 0.0) {
      _mapController.rotate(0.0);

      if (_mapTrackingState == MapTrackingState.positionAndBearing) {
        setState(() {
          _mapTrackingState = MapTrackingState.position;
        });
      }
    } else {
      setState(() {
        _isRotationLocked = !_isRotationLocked;
      });
      _settings.set(Settings.lastMapRotationLocked, _isRotationLocked);
    }
  }

  void _showBottomSheet(Entry entry, {bool autoFetchLocation = false}) {
    showEntryEditBottomSheet(
      context,
      entry,
      onSaved: () => _loadEntries(_selectedList!.listId),
      onDeleted: () => _loadEntries(_selectedList!.listId),
      onLocationChanged: (location) {
        _focusMapOnLocation(location);
      },
      autoFetchLocation: autoFetchLocation,
    );
  }

  Future<void> _handleMarkerTap(Entry entry) async {
    _showBottomSheet(entry);
  }

  Future<void> _handleMarkerDragEnd(Entry entry, LatLng point) async {
    final updatedEntry = entry.copyWith(
      latitude: drift.Value(round(point.latitude)),
      longitude: drift.Value(round(point.longitude)),
    );
    await _db.updateEntry(updatedEntry);
    if (_selectedList != null) {
      _loadEntries(_selectedList!.listId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<Settings>();
    final isDefaultOsm = isDefaultOsmProvider(settings);
    final isLocating =
        _locationService.state == LocationServiceState.initializing ||
            _locationService.state == LocationServiceState.searching;

    IconData locationIcon;
    String locationTooltip;
    switch (_locationService.state) {
      case LocationServiceState.initializing:
        locationIcon = Icons.my_location;
        locationTooltip = 'Loading location...';
        break;
      case LocationServiceState.serviceDisabled:
        locationIcon = Icons.location_disabled;
        locationTooltip = 'Enable location services first';
        break;
      case LocationServiceState.permissionDenied:
        locationIcon = Icons.location_disabled;
        locationTooltip = 'Grant location permissions first';
        break;
      case LocationServiceState.searching:
        locationIcon = Icons.location_searching;
        locationTooltip = 'Searching for location...';
        break;
      case LocationServiceState.ready:
        if (_mapTrackingState == MapTrackingState.none) {
          locationIcon = Icons.my_location;
          locationTooltip = 'View and follow my current location';
        } else if (_mapTrackingState == MapTrackingState.position) {
          locationIcon = Symbols.assistant_navigation;
          locationTooltip = 'Follow bearing';
        } else {
          locationIcon = Icons.assistant_navigation;
          locationTooltip = 'Stop following';
        }
        break;
    }

    return AnnotatedScaffold(
      scaffoldKey: _scaffoldKey,
      drawer: CDrawer(),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          StreamBuilder<MapEvent>(
            stream: _mapController.mapEventStream,
            builder: (context, snapshot) {
              // Rotate icon backward to point north relative to screen
              final rotation = _mapController.camera.rotation;
              return MapFloatingActionButtonSmall(
                heroTag: 'toggleCompass',
                tooltip: _mapController.camera.rotation != 0.0
                    ? 'Reset map rotation to True North'
                    : (_isRotationLocked
                        ? 'Enable map rotation'
                        : 'Lock map rotation'),
                onPressed: _handleCompassPress,
                child: Transform.rotate(
                  angle: (rotation * (math.pi / 180.0)),
                  child: Icon(
                    _isRotationLocked
                        ? Icons.navigation_outlined
                        : Icons.navigation,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          MapFloatingActionButtonSmall(
            heroTag: 'addEntry',
            tooltip: 'Add an entry without a location',
            onPressed: _addEntryWithoutLocation,
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          MapFloatingActionButton(
            heroTag: 'addAtLocation',
            tooltip: 'Add an entry at my current location',
            onPressed: _addEntryAtCurrentLocation,
            child: const Icon(Icons.add_location),
          ),
          if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) ...[
            const SizedBox(height: 8),
            MapFloatingActionButton(
              heroTag: 'addFromPicture',
              tooltip: 'Add an entry at your location by taking a picture',
              onPressed: _addEntryWithPicture,
              child: const Icon(Icons.camera_alt),
            ),
          ],
          const SizedBox(height: 8),
          MapFloatingActionButton(
            heroTag: 'viewLocation',
            tooltip: locationTooltip,
            onPressed: _viewLocation,
            child: isLocating
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        locationIcon,
                        size: 18,
                      ),
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  )
                : Icon(
                    locationIcon,
                    fill:
                        _mapTrackingState != MapTrackingState.positionAndBearing
                            ? 0
                            : 1,
                  ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              keepAlive: true,
              interactionOptions: InteractionOptions(
                enableMultiFingerGestureRace: true,
                cursorKeyboardRotationOptions: _isRotationLocked
                    ? CursorKeyboardRotationOptions.disabled()
                    : const CursorKeyboardRotationOptions(),
                flags: _isRotationLocked
                    ? InteractiveFlag.all & ~InteractiveFlag.rotate
                    : InteractiveFlag.all,
              ),
              initialCenter: LatLng(
                _settings.get(Settings.lastMapLatitude) as double,
                _settings.get(Settings.lastMapLongitude) as double,
              ),
              initialZoom: _settings.get(Settings.lastMapZoom) as double,
              minZoom: 1.5,
              maxZoom: 22,
              onPositionChanged: (MapCamera position, bool hasGesture) {
                _saveMapTimer?.cancel();
                _saveMapTimer = Timer(const Duration(seconds: 1), () {
                  if (!mounted) return;
                  _settings.set(
                      Settings.lastMapLatitude, position.center.latitude);
                  _settings.set(
                      Settings.lastMapLongitude, position.center.longitude);
                  _settings.set(Settings.lastMapZoom, position.zoom);
                });

                if (hasGesture &&
                    (_mapTrackingState != MapTrackingState.none)) {
                  setState(() {
                    _mapTrackingState = MapTrackingState.none;
                  });
                }
              },
              onLongPress: (tapPosition, point) => _handleMapLongPress(point),
            ),
            children: [
              buildAppTileLayer(settings),
              CurrentLocationLayer(
                positionStream: _locationService.positionStream,
                alignPositionStream: _alignPositionStreamController.stream,
                alignDirectionStream: _alignDirectionStreamController.stream,
                alignPositionOnUpdate:
                    _mapTrackingState != MapTrackingState.none
                        ? AlignOnUpdate.always
                        : AlignOnUpdate.never,
                alignDirectionOnUpdate:
                    _mapTrackingState == MapTrackingState.positionAndBearing
                        ? AlignOnUpdate.always
                        : AlignOnUpdate.never,
              ),
              DragMarkers(
                markers: _entries
                    .where((e) => e.latitude != null && e.longitude != null)
                    .map(
                      (e) => DragMarker(
                        key: ValueKey(e.entryId),
                        point: LatLng(e.latitude!, e.longitude!),
                        size: const Size.square(_markerSize),
                        alignment: Alignment.topCenter,
                        builder: (_, __, ___) => Transform.translate(
                          offset: const Offset(0, _iconPaddingOffset),
                          child: Icon(
                            Icons.location_on,
                            size: _markerSize,
                            color: _selectedList!.listId == -1
                                ? _lists
                                    .singleWhere((l) => l.listId == e.listId)
                                    .color
                                : _selectedList!.color,
                            shadows: const [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 3.0,
                              ),
                            ],
                          ),
                        ),
                        useLongPress: true,
                        onTap: (point) => _handleMarkerTap(e),
                        onLongDragEnd: (details, pt) =>
                            _handleMarkerDragEnd(e, pt),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          // OSM Attribution
          if (isDefaultOsm) const OsmAttributionBadge(),
          // App bar
          Positioned(
            top: 0,
            left: 0,
            child: CoreAppbar([
              Expanded(
                child: ListDropdown(
                  selectedList: _selectedList,
                  lists: _lists,
                  onSelected: (newList) {
                    if (newList != null) {
                      setState(() {
                        _selectedList = newList;
                      });
                      _loadEntries(newList.listId);
                    }
                  },
                ),
              ),
              if (isDefaultOsm)
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('OpenStreetMap Attribution'),
                        content: const Text(
                          "© OpenStreetMap contributors\nThis app uses the OpenStreetMap tiles kindly provided by the OpenStreetMap Foundation. The maps data is licensed under the Open Database License (ODbL). Their servers run on donations from people like you. Please consider supporting them and please report any errors you may find in the map by following the link below!",
                        ),
                        actionsAlignment: MainAxisAlignment.start,
                        actions: [
                          Wrap(
                            children: [
                              TextButton(
                                onPressed: () => openURL(context,
                                    "https://www.openstreetmap.org/copyright"),
                                child: const Text("See License"),
                              ),
                              TextButton(
                                onPressed: () => openURL(context,
                                    "https://supporting.openstreetmap.org/"),
                                child: const Text("Support OSM"),
                              ),
                              TextButton(
                                onPressed: () => openURL(context,
                                    "https://www.openstreetmap.org/fixthemap"),
                                child: const Text("Fix the Map"),
                              ),
                              TextButton(
                                child: const Text('Okay!'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
            ]),
          ),
        ],
      ),
    );
  }
}
