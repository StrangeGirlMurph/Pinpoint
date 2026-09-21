import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';

Future<void> clearTileCache() async {
  if (kIsWeb) return;
  try {
    await BuiltInMapCachingProvider.getOrCreateInstance()
        .destroy(deleteCache: true);
  } catch (_) {}
}

Future<void> reconfigureTileCache() async {
  if (kIsWeb) return;
  // destroy(deleteCache: false) resets the singleton without deleting files,
  // allowing BuiltInMapCachingProvider.getOrCreateInstance to take new parameters.
  try {
    await BuiltInMapCachingProvider.getOrCreateInstance()
        .destroy(deleteCache: false);
  } catch (_) {}
}
