import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:pinpoint/util/snackbar.dart';

enum LocationServiceState {
  initializing,
  serviceDisabled,
  permissionDenied,
  searching,
  ready,
}

class LocationService with WidgetsBindingObserver {
  static const Duration _freshLocationTimeout = Duration(seconds: 8);

  bool isInitializing = true;
  bool isLocationServiceEnabled = false;
  LocationPermission locationPermission = LocationPermission.denied;
  bool hasLocationFix = false;
  Position? currentPosition;

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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionsOnResume();
    }
  }

  Future<void> _checkPermissionsOnResume() async {
    final newPermission = await Geolocator.checkPermission();
    final newServiceEnabled = await Geolocator.isLocationServiceEnabled();
    bool stateChanged = false;

    if (locationPermission != newPermission) {
      locationPermission = newPermission;
      stateChanged = true;
    }

    if (isLocationServiceEnabled != newServiceEnabled) {
      isLocationServiceEnabled = newServiceEnabled;
      stateChanged = true;
    }

    if (stateChanged) {
      if (isLocationServiceEnabled &&
          (locationPermission == LocationPermission.always ||
              locationPermission == LocationPermission.whileInUse)) {
        if (_positionSubscription == null) {
          _startPositionStream();
        }
      } else {
        _positionSubscription?.cancel();
        _positionSubscription = null;
        hasLocationFix = false;
        currentPosition = null;
        _positionStreamController.add(null);
      }
      onStateChanged();
    }
  }

  Future<void> _init() async {
    isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    locationPermission = await Geolocator.checkPermission();

    if (locationPermission == LocationPermission.denied) {
      locationPermission = await Geolocator.requestPermission();
    }

    _listenToServiceStatus();
    if (isLocationServiceEnabled &&
        (locationPermission == LocationPermission.always ||
            locationPermission == LocationPermission.whileInUse)) {
      await _startPositionStream();
    }

    isInitializing = false;
    onStateChanged();
  }

  void _listenToServiceStatus() {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      // The getServiceStatusStream is currently not implemented on these platforms
      return;
    }

    _serviceStatusSubscription =
        Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      final wasEnabled = isLocationServiceEnabled;
      isLocationServiceEnabled = status == ServiceStatus.enabled;

      if (!isLocationServiceEnabled) {
        hasLocationFix = false;
        currentPosition = null;
        _positionSubscription?.cancel();
        _positionSubscription = null;
        _positionStreamController.add(null);
      } else if (!wasEnabled && isLocationServiceEnabled) {
        if (locationPermission == LocationPermission.always ||
            locationPermission == LocationPermission.whileInUse) {
          _startPositionStream();
        }
      }

      onStateChanged();
    });
  }

  Future<void> _startPositionStream() async {
    _positionSubscription?.cancel();

    try {
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null) {
        final age = DateTime.now().difference(lastPos.timestamp);
        if (age.inMinutes < 5) {
          currentPosition = lastPos;
          _positionStreamController.add(LocationMarkerPosition(
            latitude: lastPos.latitude,
            longitude: lastPos.longitude,
            accuracy: lastPos.accuracy,
          ));

          if (!hasLocationFix) {
            hasLocationFix = true;
            onStateChanged();
          }
        }
      }
    } catch (_) {}

    // Listen to real-time updates
    _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 0,
    )).listen((Position position) {
      currentPosition = position;

      if (!hasLocationFix) {
        hasLocationFix = true;
        onStateChanged();
      }

      _positionStreamController.add(LocationMarkerPosition(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      ));
    }, onError: (error) async {
      if (hasLocationFix) {
        hasLocationFix = false;
        onStateChanged();
      }
      final newPerm = await Geolocator.checkPermission();
      if (newPerm != locationPermission) {
        locationPermission = newPerm;
        onStateChanged();
      }
    }, onDone: () {
      _positionSubscription = null;
    });
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _serviceStatusSubscription?.cancel();
    _positionSubscription?.cancel();
    _positionStreamController.close();
  }

  Future<LatLng?> getFreshLocation(BuildContext context,
      {bool showSnackbars = true}) async {
    // Check for location service
    isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocationServiceEnabled) {
      onStateChanged();
      if (showSnackbars && context.mounted) {
        showSnackBar(context, 'Location services are disabled.');
      }
      return null;
    }

    // Check for location permission
    locationPermission = await Geolocator.checkPermission();
    if (locationPermission == LocationPermission.denied) {
      locationPermission = await Geolocator.requestPermission();
      onStateChanged();
      if (locationPermission == LocationPermission.denied) {
        if (showSnackbars && context.mounted) {
          showSnackBar(context, 'Location permissions are denied.');
        }
        return null;
      }
    }

    if (locationPermission == LocationPermission.deniedForever) {
      if (showSnackbars && context.mounted) {
        showSnackBar(context,
            'Location permissions are permanently denied, we cannot request permissions.');
      }
      return null;
    }

    // Got permission and service enabled
    if (_positionSubscription == null) {
      _startPositionStream();
      onStateChanged();
    }

    // Check if current location is fresh and accurate enough
    if (currentPosition != null) {
      final age = DateTime.now().difference(currentPosition!.timestamp);

      final isVeryRecent =
          age.inSeconds < 15 && currentPosition!.accuracy < 50.0;
      final isStandingStill =
          age.inMinutes < 2 && currentPosition!.accuracy < 25.0;

      if (isVeryRecent || isStandingStill) {
        return locationFromPosition(currentPosition!);
      }
    }

    // Otherwise dynamically fetch a new one
    try {
      ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? loadingSnack;
      if (showSnackbars && context.mounted) {
        final messenger = ScaffoldMessenger.of(context);
        loadingSnack = messenger.showSnackBar(
          const SnackBar(
            content: Text('Updating current location...'),
            duration: _freshLocationTimeout,
          ),
        );
      }

      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(timeLimit: _freshLocationTimeout),
        );
      } finally {
        loadingSnack?.close();
      }

      if (position.accuracy > 100.0 && showSnackbars && context.mounted) {
        showSnackBar(context,
            'GPS accuracy is low (${position.accuracy.toStringAsFixed(0)}m), location may be imprecise.');
      }

      return locationFromPosition(position);
    } catch (e) {
      // Fallback to slightly stale tracker position no matter the accuracy
      if (currentPosition != null) {
        final age = DateTime.now().difference(currentPosition!.timestamp);
        if (age.inMinutes < 2) {
          if (showSnackbars && context.mounted) {
            showSnackBar(context, 'Used recent location (GPS signal weak).');
          }
          return locationFromPosition(currentPosition!);
        }
      }

      // Fallback to last known position of the OS
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null) {
        final lastPosAge = DateTime.now().difference(lastPos.timestamp);

        if (lastPosAge.inMinutes < 5) {
          if (showSnackbars && context.mounted) {
            showSnackBar(
                context, 'Used last known location (GPS signal weak).');
          }
          return locationFromPosition(lastPos);
        }
      }

      // Complete Failure
      if (showSnackbars && context.mounted) {
        showSnackBar(
            context, 'Could not determine location. Check your GPS signal.');
      }
      return null;
    }
  }

  LatLng locationFromPosition(Position position) {
    return LatLng(position.latitude, position.longitude);
  }
}
