import 'dart:async';
import 'package:flutter/material.dart';
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

}

/// Handles checking and requesting permissions and verifying whether location
/// services are enabled.
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

void showLocationResultFeedback(
  BuildContext context,
  LocationResult result, {
  SnackBarPosition position = SnackBarPosition.bottom,
}) {
  if (result.isSuccess) {
    if (result.isFallback) {
      showSnackBar(
        context,
        'Used last known location (GPS signal weak).',
        position: position,
      );
    } else if (result.accuracy != null && result.accuracy! > 100.0) {
      showSnackBar(
        context,
        'GPS accuracy is low (${result.accuracy!.toStringAsFixed(0)}m), location may be imprecise.',
        position: position,
      );
    }
    return;
  }

  switch (result.status) {
    case LocationResultStatus.serviceDisabled:
      showLocationServicesDisabledSnackBar(context, position: position);
      break;
    case LocationResultStatus.permissionDenied:
      showSnackBar(
        context,
        'Location permissions are denied.',
        position: position,
      );
      break;
    case LocationResultStatus.permissionDeniedForever:
      showPermissionDeniedForeverSnackBar(context, position: position);
      break;
    case LocationResultStatus.timeout:
      showSnackBar(
        context,
        'Could not determine location in time. Check GPS signal.',
        position: position,
      );
      break;
    case LocationResultStatus.error:
      showSnackBar(
        context,
        result.errorMessage ??
            'Could not determine location. Check GPS signal.',
        position: position,
      );
      break;
    case LocationResultStatus.success:
      break;
  }
}

void showLocationServicesDisabledSnackBar(
  BuildContext context, {
  SnackBarPosition position = SnackBarPosition.bottom,
}) {
  showSnackBar(
    context,
    'Location services are disabled.',
    position: position,
    action: SnackBarAction(
      label: 'Settings',
      onPressed: () {
        Geolocator.openLocationSettings().catchError((_) => false);
      },
    ),
  );
}

void showPermissionDeniedForeverSnackBar(
  BuildContext context, {
  SnackBarPosition position = SnackBarPosition.bottom,
}) {
  showSnackBar(
    context,
    'Location permissions are permanently denied, we cannot request permissions.',
    position: position,
    action: SnackBarAction(
      label: 'Settings',
      onPressed: () {
        Geolocator.openAppSettings().catchError((_) => false);
      },
    ),
  );
}

/// Wraps [fetchCurrentLocation] and presents standard UI notifications.
Future<LatLng?> getCurrentLocation(
  BuildContext context, {
  bool showSnackbars = true,
  Duration timeout = const Duration(seconds: 8),
  SnackBarPosition snackBarPosition = SnackBarPosition.bottom,
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

  if (showSnackbars) {
    showLocationResultFeedback(context, result, position: snackBarPosition);
  }

  return result.location;
}
