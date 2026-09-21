import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart'
    show LocationMarkerPosition;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:pinpoint/util/snackbar.dart';

LatLng locationFromPosition(Position position) {
  return LatLng(position.latitude, position.longitude);
}

enum LocationResultStatus {
  success,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  error,
}

/// Typed result of a location fetch operation, decoupled from UI.
class LocationResult {
  final LocationResultStatus status;
  final LatLng? location;
  final double? accuracy;
  final String? errorMessage;
  final bool isFallback;

  const LocationResult({
    required this.status,
    this.location,
    this.accuracy,
    this.errorMessage,
    this.isFallback = false,
  });

  bool get isSuccess =>
      status == LocationResultStatus.success && location != null;

  String get userFriendlyMessage {
    switch (status) {
      case LocationResultStatus.serviceDisabled:
        return 'Location services are disabled.';
      case LocationResultStatus.permissionDenied:
        return 'Location permissions are denied.';
      case LocationResultStatus.permissionDeniedForever:
        return 'Location permissions are permanently denied.';
      case LocationResultStatus.timeout:
        return 'Could not determine location in time. Check GPS signal.';
      case LocationResultStatus.error:
        return errorMessage ??
            'Could not determine location. Check GPS signal.';
      case LocationResultStatus.success:
        if (accuracy != null && accuracy! > 100.0) {
          return 'GPS accuracy is low (${accuracy!.toStringAsFixed(0)}m), location may be imprecise.';
        }
        return '';
    }
  }
}

/// Pure device location fetcher without any BuildContext dependency.
///
/// Handles checking and requesting permissions and verifying whether location
/// services are enabled. If GPS is weak or times out, it falls back to recent
/// last known coordinates (< 5 minutes).
Future<LocationResult> fetchCurrentLocation({
  Duration timeout = const Duration(seconds: 8),
}) async {
  // Check whether location services (GPS) are enabled
  final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!isServiceEnabled) {
    return const LocationResult(status: LocationResultStatus.serviceDisabled);
  }

  // Check and request location permission
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.unableToDetermine) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return const LocationResult(
        status: LocationResultStatus.permissionDenied,
      );
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return const LocationResult(
      status: LocationResultStatus.permissionDeniedForever,
    );
  }

  if (permission != LocationPermission.always &&
      permission != LocationPermission.whileInUse) {
    return const LocationResult(
      status: LocationResultStatus.permissionDenied,
    );
  }

  // Check if OS has a genuinely fresh, accurate last known position (< 15 seconds, < 50m)
  try {
    final lastPos = await Geolocator.getLastKnownPosition();
    if (lastPos != null) {
      final age = DateTime.now().difference(lastPos.timestamp);
      if (!age.isNegative && age.inSeconds < 15 && lastPos.accuracy < 50.0) {
        return LocationResult(
          status: LocationResultStatus.success,
          location: locationFromPosition(lastPos),
          accuracy: lastPos.accuracy,
        );
      }
    }
  } catch (_) {}

  try {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.best,
        timeLimit: timeout,
      ),
    );

    return LocationResult(
      status: LocationResultStatus.success,
      location: locationFromPosition(position),
      accuracy: position.accuracy,
    );
  } catch (e) {
    if (e is LocationServiceDisabledException) {
      return const LocationResult(status: LocationResultStatus.serviceDisabled);
    }

    if (e is PermissionDeniedException) {
      return const LocationResult(
        status: LocationResultStatus.permissionDenied,
      );
    }

    // Fallback to last known position of the OS if within 5 minutes
    try {
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null) {
        final lastPosAge = DateTime.now().difference(lastPos.timestamp);
        if (!lastPosAge.isNegative && lastPosAge.inMinutes < 5) {
          return LocationResult(
            status: LocationResultStatus.success,
            location: locationFromPosition(lastPos),
            accuracy: lastPos.accuracy,
            isFallback: true,
          );
        }
      }
    } catch (_) {}

    if (e is TimeoutException) {
      return const LocationResult(status: LocationResultStatus.timeout);
    }

    return LocationResult(
      status: LocationResultStatus.error,
      errorMessage: e.toString(),
    );
  }
}

/// Fetches the current device location as a one-shot query with contextual SnackBar feedback.
///
/// Wraps [fetchCurrentLocation] and presents standard UI notifications.
Future<LatLng?> getCurrentLocation(
  BuildContext context, {
  bool showSnackbars = true,
  Duration timeout = const Duration(seconds: 8),
}) async {
  Timer? loadingSnackTimer;
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? loadingSnack;

  if (showSnackbars && context.mounted) {
    loadingSnackTimer = Timer(const Duration(milliseconds: 600), () {
      if (context.mounted) {
        final messenger = ScaffoldMessenger.maybeOf(context);
        messenger?.hideCurrentSnackBar();
        loadingSnack = messenger?.showSnackBar(
          SnackBar(
            content: const Text('Updating current location...'),
            duration: timeout,
          ),
        );
      }
    });
  }

  LocationResult result;
  try {
    result = await fetchCurrentLocation(timeout: timeout);
  } finally {
    loadingSnackTimer?.cancel();
    loadingSnack?.close();
  }

  if (!context.mounted) return result.location;

  if (result.isSuccess) {
    if (showSnackbars) {
      if (result.isFallback) {
        showSnackBar(context, 'Used last known location (GPS signal weak).');
      } else if (result.accuracy != null && result.accuracy! > 100.0) {
        showSnackBar(context, result.userFriendlyMessage);
      }
    }
    return result.location;
  }

  if (showSnackbars) {
    switch (result.status) {
      case LocationResultStatus.serviceDisabled:
        showSnackBar(
          context,
          'Location services are disabled.',
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () {
              Geolocator.openLocationSettings().catchError((_) => false);
            },
          ),
        );
        break;
      case LocationResultStatus.permissionDenied:
        showSnackBar(context, 'Location permissions are denied.');
        break;
      case LocationResultStatus.permissionDeniedForever:
        showSnackBar(
          context,
          'Location permissions are permanently denied, we cannot request permissions.',
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () {
              Geolocator.openAppSettings().catchError((_) => false);
            },
          ),
        );
        break;
      case LocationResultStatus.timeout:
      case LocationResultStatus.error:
        showSnackBar(
          context,
          'Could not determine location. Check your GPS signal.',
        );
        break;
      case LocationResultStatus.success:
        break;
    }
  }

  return null;
}

enum LocationServiceState {
  initializing,
  serviceDisabled,
  permissionDenied,
  searching,
  ready,
}

/// Service dedicated to managing live location streaming and tracking state
/// for the map view.
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

    // Listen to real-time updates
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

  /// Requests permission or enables location services when the user clicks
  /// the map location button while in a disabled or denied state.
  Future<void> requestPermissionAndEnable(BuildContext context) async {
    if (_isDisposed) return;
    isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (_isDisposed) return;

    if (!isLocationServiceEnabled) {
      _notifyStateChanged();
      if (context.mounted) {
        showSnackBar(
          context,
          'Location services are disabled.',
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () {
              Geolocator.openLocationSettings().catchError((_) => false);
            },
          ),
        );
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
        showSnackBar(
          context,
          'Location permissions are permanently denied, we cannot request permissions.',
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () {
              Geolocator.openAppSettings().catchError((_) => false);
            },
          ),
        );
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
