import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:pinpoint/data/settings.dart';

TileLayer buildAppTileLayer(Settings settings) {
  final url = (settings.get(Settings.tileUrlTemplate) as String?)?.trim();
  final userAgent = (settings.get(Settings.tileUserAgent) as String?)?.trim();

  final effectiveUrl =
      (url != null && url.isNotEmpty) ? url : Settings.defaultTileUrlTemplate;
  final effectiveUserAgent = (userAgent != null && userAgent.isNotEmpty)
      ? userAgent
      : Settings.defaultTileUserAgent;

  return TileLayer(
    urlTemplate: effectiveUrl,
    userAgentPackageName: effectiveUserAgent,
  );
}

bool isDefaultOsmProvider(Settings settings) {
  final url = (settings.get(Settings.tileUrlTemplate) as String?)?.trim();
  if (url == null || url.isEmpty) return true;
  return url == Settings.defaultTileUrlTemplate;
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
