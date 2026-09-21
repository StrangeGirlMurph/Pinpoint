import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:pinpoint/data/settings.dart';

TileLayer buildAppTileLayer(Settings settings) {
  final url = settings.get(Settings.tileUrlTemplate) as String;
  final userAgent = settings.get(Settings.tileUserAgent) as String;

  final isDefaultOsm = isDefaultOsmProvider(settings);
  final cacheEnabled =
      isDefaultOsm || settings.get(Settings.tileCacheEnabled) as bool;
  final maxCacheSizeMB = settings.get(Settings.tileCacheMaxSizeMB) as int;
  final freshnessDays =
      isDefaultOsm ? 0 : (settings.get(Settings.tileCacheFreshnessDays) as int);

  final MapCachingProvider cachingProvider;
  if (!cacheEnabled) {
    cachingProvider = const DisabledMapCachingProvider();
  } else {
    cachingProvider = BuiltInMapCachingProvider.getOrCreateInstance(
      maxCacheSize: maxCacheSizeMB > 0 ? maxCacheSizeMB * 1024 * 1024 : null,
      overrideFreshAge:
          freshnessDays > 0 ? Duration(days: freshnessDays) : null,
    );
  }

  return TileLayer(
    urlTemplate: url,
    userAgentPackageName: userAgent,
    tileProvider: NetworkTileProvider(
      cachingProvider: cachingProvider,
    ),
  );
}

bool isDefaultOsmProvider(Settings settings) {
  return (settings.get(Settings.tileUrlTemplate) as String) ==
      Settings.defaultTileUrlTemplate;
}

class OsmAttributionBadge extends StatelessWidget {
  const OsmAttributionBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 30,
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(150),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
          child: const Text(
            "© OpenStreetMap",
            style: TextStyle(
              fontSize: 11,
              color: Colors.black,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
