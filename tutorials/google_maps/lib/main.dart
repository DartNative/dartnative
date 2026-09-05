/// DartNative tutorial — a native map.
///
/// dartnative_google_maps puts the platform's real Google Maps SDK view —
/// GMSMapView (iOS) / MapView (Android) — directly in the widget tree:
///   • GoogleMaps(initialCameraPosition:) — the map widget
///   • markers: [Marker(id:, latitude:, longitude:)] + onMarkerTap
///   • mapType — normal / satellite / terrain / hybrid
///   • camera moves — pass a new CameraPosition, the map animates
///
/// Pan/zoom gestures are handled INSIDE the native map view; your Dart
/// overlays (the chips and cards below) float above it in the same
/// hierarchy. API keys are provided natively — see README.
import 'package:dartnative/dartnative.dart';
import 'package:dartnative_google_maps/dartnative_google_maps.dart';

import 'dartnative_plugin_registrant.dart';

void main() {
  DartNativePluginRegistrant.registerAll();
  runApp(const MapScreen());
}

const _cities = [
  (name: 'San Francisco', lat: 37.7749, lng: -122.4194),
  (name: 'London', lat: 51.5074, lng: -0.1278),
  (name: 'Tokyo', lat: 35.6762, lng: 139.6503),
];

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapType _mapType = MapType.normal;
  List<Marker> _markers = const [];
  String? _tappedMarker;

  // A tiny nonce nudges the coordinates so re-selecting the same city
  // still re-animates the camera (identical positions are deduped).
  int _nonce = 0;
  CameraPosition _camera = const CameraPosition(
    latitude: 37.7749,
    longitude: -122.4194,
    zoom: 12,
  );

  // #region actions
  void _goTo(({String name, double lat, double lng}) city) {
    setState(() {
      _camera = CameraPosition(
        latitude: city.lat + (_nonce * 1e-10),
        longitude: city.lng + (_nonce * 1e-10),
        zoom: 12,
      );
      _nonce++;
      _markers = [
        Marker(id: city.name, latitude: city.lat, longitude: city.lng),
      ];
    });
  }
  // #endregion actions

  @override
  Widget build(BuildContext context) {
    final padTop = MediaQuery.paddingOf(context).top;
    final padBottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // #region map
          Positioned.fill(
            child: GoogleMaps(
              initialCameraPosition: _camera,
              mapType: _mapType,
              markers: _markers,
              zoomGesturesEnabled: true,
              scrollGesturesEnabled: true,
              onMarkerTap: (id) => setState(() => _tappedMarker = id),
            ),
          ),
          // #endregion map
          // Dart overlays float over the native map.
          Positioned(
            top: padTop + 12,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final city in _cities)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _Chip(
                      label: city.name,
                      active: _markers.isNotEmpty &&
                          _markers.first.id == city.name,
                      onTap: () => _goTo(city),
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: padBottom + 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_tappedMarker != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xF2FFFFFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Marker tapped: $_tappedMarker',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF111111),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                // #region maptype
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // MapType.none renders no tiles at all — valid for apps
                    // that draw their own base layer, pointless in a demo.
                    for (final t in MapType.values.where((t) => t != MapType.none))
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _Chip(
                          label: t.name,
                          active: _mapType == t,
                          onTap: () => setState(() => _mapType = t),
                        ),
                      ),
                  ],
                ),
                // #endregion maptype
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.onTap, this.active = false});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0A84FF) : const Color(0xF2FFFFFF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
                active ? const Color(0xFFFFFFFF) : const Color(0xFF111111),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
