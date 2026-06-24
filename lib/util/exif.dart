import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:exif/exif.dart';

class ImageMetadata {
  final LatLng? location;
  final DateTime? dateTime;

  const ImageMetadata({this.location, this.dateTime});
}

Future<ImageMetadata> readImageMetadata(String filePath) async {
  try {
    final file = File(filePath);
    if (!await file.exists()) return const ImageMetadata();
    final tags = await readExifFromFile(file);

    if (tags.isEmpty) return const ImageMetadata();

    LatLng? location;
    final latTag = tags['GPS GPSLatitude'];
    final latRefTag = tags['GPS GPSLatitudeRef'];
    final lngTag = tags['GPS GPSLongitude'];
    final lngRefTag = tags['GPS GPSLongitudeRef'];

    if (latTag != null &&
        latRefTag != null &&
        lngTag != null &&
        lngRefTag != null) {
      final lat = _parseGpsCoordinate(latTag, latRefTag);
      final lng = _parseGpsCoordinate(lngTag, lngRefTag);
      if (lat != null && lng != null) {
        if (lat >= -90.0 && lat <= 90.0 && lng >= -180.0 && lng <= 180.0) {
          location = LatLng(lat, lng);
        } else {
          debugPrint('Invalid EXIF GPS bounds: lat=$lat, lng=$lng');
        }
      }
    }

    DateTime? dateTime;
    // Common tags for creation time
    final dateTimeTag = tags['EXIF DateTimeOriginal'] ??
        tags['Image DateTime'] ??
        tags['EXIF DateTimeDigitized'];
    if (dateTimeTag != null) {
      dateTime = _parseExifDateTime(dateTimeTag);
    }

    return ImageMetadata(location: location, dateTime: dateTime);
  } catch (e) {
    debugPrint('Error reading EXIF data: $e');
  }
  return const ImageMetadata();
}

double? _parseGpsCoordinate(IfdTag tag, IfdTag refTag) {
  final values = tag.values.toList();
  if (values.length < 3) return null;

  double? parseValue(dynamic val) {
    if (val == null) return null;
    if (val is Ratio) {
      if (val.denominator == 0) return null;
      final d = val.toDouble();
      return (d.isNaN || !d.isFinite) ? null : d;
    } else if (val is num) {
      final d = val.toDouble();
      return (d.isNaN || !d.isFinite) ? null : d;
    }
    final parsed = double.tryParse(val.toString());
    if (parsed == null || parsed.isNaN || !parsed.isFinite) return null;
    return parsed;
  }

  final degrees = parseValue(values[0]);
  final minutes = parseValue(values[1]);
  final seconds = parseValue(values[2]);

  if (degrees == null || minutes == null || seconds == null) {
    return null;
  }

  double coordinate = degrees + (minutes / 60.0) + (seconds / 3600.0);
  final ref = refTag.printable.trim().toUpperCase();
  if (ref == 'S' || ref == 'W') {
    coordinate = -coordinate;
  }

  if (coordinate.isNaN || !coordinate.isFinite) {
    return null;
  }

  return coordinate;
}

DateTime? _parseExifDateTime(IfdTag tag) {
  final str = tag.printable.trim();
  if (str.isEmpty) return null;

  try {
    final parts = str.split(' ');
    if (parts.length >= 2) {
      final datePart = parts[0].replaceAll(':', '-');
      final timePart = parts[1];
      final isoStr = '$datePart $timePart';
      return DateTime.tryParse(isoStr);
    } else {
      final normalized = str.replaceFirst(':', '-').replaceFirst(':', '-');
      return DateTime.tryParse(normalized);
    }
  } catch (e) {
    debugPrint('Error parsing EXIF DateTime: $e');
  }
  return null;
}
