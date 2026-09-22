import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:pinpoint/util/location.dart';
import 'package:pinpoint/util/snackbar.dart';

enum LocationServiceState {
  initializing,
  serviceDisabled,
  permissionDenied,
  searching,
  ready,
}

class LocationService with WidgetsBindingObserver {
  bool isInitializing = true;
  bool isLocationServiceEnabled = false;
  LocationPermission locationPermission = LocationPermission.denied;
  bool hasLocationFix = false;
  Position? currentPosition;

  bool _isCheckingPermissions = false;
  bool _isStartingPositionStream = false;
  bool _isDisposed = false;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;

  LocationServiceState get state {
    if (isInitializing) return LocationServiceState.initializing;
    if (!isLocationServiceEnabled) return LocationServiceState.serviceDisabled;
    if (locationPermission != LocationPermission.always &&
        locationPermission != LocationPermission.whileInUse) {
      return LocationServiceState.permissionDenied;
    }
    if (!hasLocationFix) return LocationServiceState.searching;
    return LocationServiceState.ready;
  }

  /// Returns the current position as [LatLng] if it has been updated within the last 15 seconds.
  LatLng? get freshPosition {
    if (currentPosition != null && hasLocationFix) {
      final age = DateTime.now().difference(currentPosition!.timestamp);
      if (!age.isNegative && age.inSeconds < 15) {
        return locationFromPosition(currentPosition!);
      }
    }
    return null;
  }

  StreamSubscription<ServiceStatus>? _serviceStatusSubscription;
  StreamSubscription<Position>? _positionSubscription;

  final StreamController<LocationMarkerPosition?> _positionStreamController =
      StreamController<LocationMarkerPosition?>.broadcast();

  Stream<LocationMarkerPosition?> get positionStream =>
      _positionStreamController.stream;

  final VoidCallback onStateChanged;

  LocationService({required this.onStateChanged}) {
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  void _notifyStateChanged() {
    if (!_isDisposed) {
      onStateChanged();
    }
  }

  void _addPositionEvent(LocationMarkerPosition? position) {
    if (!_isDisposed && !_positionStreamController.isClosed) {
      _positionStreamController.add(position);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    if (state == AppLifecycleState.resumed) {
      _checkPermissionsOnResume();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _onAppPaused();
    }
  }

  void _onAppPaused() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    hasLocationFix = false;
  }

  Future<void> _checkPermissionsOnResume() async {
    if (_isCheckingPermissions || _isDisposed) return;
    _isCheckingPermissions = true;
    try {
      final newPermission = await Geolocator.checkPermission();
      if (_isDisposed) return;
      final newServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (_isDisposed) return;

      locationPermission = newPermission;
      isLocationServiceEnabled = newServiceEnabled;

      if (isLocationServiceEnabled &&
          (locationPermission == LocationPermission.always ||
              locationPermission == LocationPermission.whileInUse)) {
        if (_positionSubscription == null) {
          await _startPositionStream();
        }
      } else {
        _positionSubscription?.cancel();
        _positionSubscription = null;
        hasLocationFix = false;
        currentPosition = null;
        _addPositionEvent(null);
      }
      _notifyStateChanged();
    } finally {
      _isCheckingPermissions = false;
    }
  }

  Future<void> _init() async {
    _isCheckingPermissions = true;
    try {
      isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (_isDisposed) return;
      locationPermission = await Geolocator.checkPermission();
      if (_isDisposed) return;

      _listenToServiceStatus();
      if (_lifecycleState == AppLifecycleState.resumed &&
          isLocationServiceEnabled &&
          (locationPermission == LocationPermission.always ||
              locationPermission == LocationPermission.whileInUse)) {
        await _startPositionStream();
      }

      isInitializing = false;
      _notifyStateChanged();
    } finally {
      _isCheckingPermissions = false;
    }
  }

  void _listenToServiceStatus() {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      // The getServiceStatusStream is currently not implemented on these platforms
      return;
    }

    _serviceStatusSubscription?.cancel();
    _serviceStatusSubscription =
        Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      if (_isDisposed) return;
      final wasEnabled = isLocationServiceEnabled;
      isLocationServiceEnabled = status == ServiceStatus.enabled;

      if (!isLocationServiceEnabled) {
        hasLocationFix = false;
        currentPosition = null;
        _positionSubscription?.cancel();
        _positionSubscription = null;
        _addPositionEvent(null);
      } else if (!wasEnabled && isLocationServiceEnabled) {
        if (_lifecycleState == AppLifecycleState.resumed &&
            (locationPermission == LocationPermission.always ||
                locationPermission == LocationPermission.whileInUse)) {
          _startPositionStream();
        }
      }

      _notifyStateChanged();
    }, onError: (_) {});
  }

  Future<void> _startPositionStream() async {
    if (_isDisposed || _isStartingPositionStream) return;
    _isStartingPositionStream = true;

    _positionSubscription?.cancel();
    _positionSubscription = null;

    try {
      final lastPos = await Geolocator.getLastKnownPosition();
      if (_isDisposed) return;
      if (lastPos != null) {
        final age = DateTime.now().difference(lastPos.timestamp);
        if (!age.isNegative && age.inMinutes < 5) {
          currentPosition = lastPos;
          _addPositionEvent(LocationMarkerPosition(
            latitude: lastPos.latitude,
            longitude: lastPos.longitude,
            accuracy: lastPos.accuracy,
          ));

          if (!hasLocationFix) {
            hasLocationFix = true;
            _notifyStateChanged();
          }
        }
      }
    } catch (_) {}

    if (_isDisposed) {
      _isStartingPositionStream = false;
      return;
    }

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
      ),
    ).listen(
      (Position position) {
        if (_isDisposed) return;
        currentPosition = position;

        if (!hasLocationFix) {
          hasLocationFix = true;
          _notifyStateChanged();
        }

        _addPositionEvent(LocationMarkerPosition(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
        ));
      },
      onError: (error) async {
        if (_isDisposed) return;
        if (hasLocationFix) {
          hasLocationFix = false;
          _notifyStateChanged();
        }
        final newPerm = await Geolocator.checkPermission();
        if (_isDisposed) return;
        if (newPerm != locationPermission) {
          locationPermission = newPerm;
          _notifyStateChanged();
        }
      },
      onDone: () {
        _positionSubscription = null;
        if (!_isDisposed && hasLocationFix) {
          hasLocationFix = false;
          _notifyStateChanged();
        }
      },
    );
    _isStartingPositionStream = false;
  }

  Future<void> requestPermissionAndEnable(BuildContext context) async {
    if (_isDisposed) return;
    isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (_isDisposed) return;

    if (!isLocationServiceEnabled) {
      _notifyStateChanged();
      if (context.mounted) {
        showLocationServicesDisabledSnackBar(context);
      }
      return;
    }

    locationPermission = await Geolocator.checkPermission();
    if (_isDisposed) return;

    if (locationPermission == LocationPermission.denied ||
        locationPermission == LocationPermission.unableToDetermine) {
      locationPermission = await Geolocator.requestPermission();
      if (_isDisposed) return;
      _notifyStateChanged();
      if (locationPermission == LocationPermission.denied) {
        if (context.mounted) {
          showSnackBar(context, 'Location permissions are denied.');
        }
        return;
      }
    }

    if (locationPermission == LocationPermission.deniedForever) {
      if (context.mounted) {
        showPermissionDeniedForeverSnackBar(context);
      }
      return;
    }

    if (_positionSubscription == null) {
      await _startPositionStream();
    }
    _notifyStateChanged();
  }

  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _serviceStatusSubscription?.cancel();
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _positionStreamController.close();
  }
}
