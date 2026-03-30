import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:pinpoint/widgets/appbar.dart';
import 'package:pinpoint/widgets/scaffold.dart';
import 'package:provider/provider.dart';
import 'package:pinpoint/data/settings.dart';

class PickLocationPage extends StatefulWidget {
  final LatLng? initialLocation;
  final Color color;

  const PickLocationPage(
    this.color, {
    super.key,
    this.initialLocation,
  });

  @override
  State<PickLocationPage> createState() => _PickLocationPageState();
}

class _PickLocationPageState extends State<PickLocationPage> {
  LatLng? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.read<Settings>();
    final initialCenter = _selectedLocation ??
        LatLng(
          settings.get(Settings.lastMapLatitude) as double,
          settings.get(Settings.lastMapLongitude) as double,
        );
    final initialZoom = _selectedLocation != null
        ? 17.0
        : settings.get(Settings.lastMapZoom) as double;

    return AnnotatedScaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              interactionOptions:
                  InteractionOptions(enableMultiFingerGestureRace: true),
              initialCenter: initialCenter,
              initialZoom: initialZoom,
              minZoom: 2.5,
              maxZoom: 18,
              onTap: (_, point) {
                setState(() {
                  _selectedLocation = point;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'pinpoint',
              ),
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      width: 40,
                      height: 40,
                      alignment: Alignment.topCenter,
                      child: Icon(
                        Icons.location_on,
                        size: 40,
                        color: widget.color,
                        shadows: const [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 3.0,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          BareAppbar(
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close),
                  tooltip: "Discard and go back",
                ),
                Text(
                  "Tap to select a location",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  onPressed: _selectedLocation == null
                      ? null
                      : () {
                          Navigator.of(context).pop(_selectedLocation);
                        },
                  icon: Icon(Icons.check),
                  tooltip: "Save location to entry",
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
