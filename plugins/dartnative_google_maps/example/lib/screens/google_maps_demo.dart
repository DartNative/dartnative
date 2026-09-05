/// Google Maps demo — standalone example for dartnative_google_maps.
///
/// Tests basic map functionality:
///   - Display a native Google Map
///   - Toggle map type (normal, satellite, terrain, hybrid)
///   - Animate camera to different locations
///   - Add/clear markers
///   - Toggle gesture settings
///
/// Requires a valid Google Maps API key. Set it in each platform's config:
///
///   iOS:   example/ios/Runner/Info.plist       → GoogleMapsAPIKey
///   Android: example/android/app/src/main/AndroidManifest.xml → com.google.android.geo.API_KEY

import 'dart:io';

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_google_maps/dartnative_google_maps.dart';

class GoogleMapsDemo extends StatefulWidget {
  const GoogleMapsDemo({super.key});

  @override
  State<GoogleMapsDemo> createState() => _GoogleMapsDemoState();
}

class _GoogleMapsDemoState extends State<GoogleMapsDemo> {
  // ── Map state ──────────────────────────────────────────────────────────
  MapType _currentMapType = MapType.normal;
  bool _zoomGesturesEnabled = true;
  bool _scrollGesturesEnabled = true;
  List<Marker> _markers = [];
  int _markerCounter = 0;
  int _cameraNonce = 0;
  String _statusText = '';

  CameraPosition _currentPosition = const CameraPosition(
    latitude: 37.7749,
    longitude: -122.4194,
    zoom: 12,
  );

  // ── Collapsible section state ──────────────────────────────────────────
  /// Which section is expanded, or null if none.
  _ControlSection? _expandedSection;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    dnLog('[GoogleMapsDemo] build() — _currentMapType=$_currentMapType');
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Google Maps Demo',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 17,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black54,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          // Map fills the entire screen
          Positioned.fill(
            child: GoogleMaps(
              initialCameraPosition: _currentPosition,
              mapType: _currentMapType,
              zoomGesturesEnabled: _zoomGesturesEnabled,
              scrollGesturesEnabled: _scrollGesturesEnabled,
              markers: _markers,
              onMapReady: () {
                dnLog('Map is ready');
              },
            ),
          ),
          // Tap-to-dismiss barrier (zero-size when panel is collapsed)
          _buildDismissBarrier(),
          // Expanded content overlay (above the bottom controls)
          _buildOverlay(),
          // Bottom control bar — floats over the map, 30px from bottom
          _buildBottomControls(),
        ],
      ),
    );
  }

  // ── Tap-to-dismiss barrier (covers the map when panel is open) ────────────

  Widget _buildDismissBarrier() {
    if (_expandedSection == null) return const SizedBox.shrink();
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          dnLog('[Dismiss] barrier tapped — closing expanded section');
          setState(() => _expandedSection = null);
        },
        behavior: HitTestBehavior.translucent,
        child: Container(color: const Color(0x01000000)),
      ),
    );
  }

  // ── Overlay (floats above the bottom controls when a section is expanded) ──

  Widget _buildOverlay() {
    if (_expandedSection == null) return const SizedBox.shrink();
    return Positioned(
      left: 12,
      right: 12,
      bottom: Platform.isAndroid ? 72 : 82,
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.all(10),
        child: _buildExpandedContent(),
      ),
    );
  }

  // ── Bottom controls (always visible, floats over the map) ────────────────

  Widget _buildBottomControls() {
    return Positioned(
      left: 12,
      right: 12,
      bottom: Platform.isAndroid ? 35 : 45,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _SectionHeader(
            label: 'View',
            active: _currentMapType != MapType.normal,
            expanded: _expandedSection == _ControlSection.mapType,
            onTap: () => _toggleSection(_ControlSection.mapType),
          ),
          const SizedBox(width: 8),
          _SectionHeader(
            label: 'Cities',
            expanded: _expandedSection == _ControlSection.cities,
            onTap: () => _toggleSection(_ControlSection.cities),
          ),
          const SizedBox(width: 8),
          _SectionHeader(
            label: 'Markers',
            expanded: _expandedSection == _ControlSection.markers,
            onTap: () => _toggleSection(_ControlSection.markers),
          ),
          const SizedBox(width: 8),
          _SectionHeader(
            label: 'Options',
            expanded: _expandedSection == _ControlSection.options,
            onTap: () => _toggleSection(_ControlSection.options),
          ),
        ],
      ),
    );
  }

  void _toggleSection(_ControlSection section) {
    setState(() {
      _expandedSection = _expandedSection == section ? null : section;
    });
  }

  Widget _buildExpandedContent() {
    switch (_expandedSection) {
      case _ControlSection.mapType:
        return _ExpandedColumn(
          children: [
            _PillButton(
              label: 'View',
              active: _currentMapType == MapType.normal,
              onTap: () => setState(() {
                _currentMapType = MapType.normal;
                _statusText = 'Map type: Normal';
                _expandedSection = null;
              }),
            ),
            _PillButton(
              label: 'Satellite',
              active: _currentMapType == MapType.satellite,
              onTap: () => setState(() {
                _currentMapType = MapType.satellite;
                _statusText = 'Map type: Satellite';
                _expandedSection = null;
              }),
            ),
            _PillButton(
              label: 'Terrain',
              active: _currentMapType == MapType.terrain,
              onTap: () => setState(() {
                _currentMapType = MapType.terrain;
                _statusText = 'Map type: Terrain';
                _expandedSection = null;
              }),
            ),
            _PillButton(
              label: 'Hybrid',
              active: _currentMapType == MapType.hybrid,
              onTap: () => setState(() {
                _currentMapType = MapType.hybrid;
                _statusText = 'Map type: Hybrid';
                _expandedSection = null;
              }),
            ),
          ],
        );

      case _ControlSection.cities:
        return _ExpandedColumn(
          children: [
            _PillButton(
              label: 'San Francisco',
              onTap: () => setState(() {
                _currentPosition = CameraPosition(
                  latitude: 37.7749 + (_cameraNonce * 1e-10),
                  longitude: -122.4194 + (_cameraNonce * 1e-10),
                  zoom: 12,
                );
                _cameraNonce++;
                _statusText = 'Moving to San Francisco…';
                _expandedSection = null;
              }),
            ),
            _PillButton(
              label: 'London',
              onTap: () => setState(() {
                _currentPosition = CameraPosition(
                  latitude: 51.5074 + (_cameraNonce * 1e-10),
                  longitude: -0.1278 + (_cameraNonce * 1e-10),
                  zoom: 12,
                );
                _cameraNonce++;
                _statusText = 'Moving to London…';
                _expandedSection = null;
              }),
            ),
            _PillButton(
              label: 'Tokyo',
              onTap: () => setState(() {
                _currentPosition = CameraPosition(
                  latitude: 35.6762 + (_cameraNonce * 1e-10),
                  longitude: 139.6503 + (_cameraNonce * 1e-10),
                  zoom: 12,
                );
                _cameraNonce++;
                _statusText = 'Moving to Tokyo…';
                _expandedSection = null;
              }),
            ),
          ],
        );

      case _ControlSection.markers:
        return _ExpandedColumn(
          children: [
            _PillButton(
              label: 'Add Marker',
              onTap: () => setState(() {
                _markerCounter++;
                final marker = Marker(
                  id: 'marker_$_markerCounter',
                  latitude: _currentPosition.latitude + (0.01 * _markerCounter),
                  longitude:
                      _currentPosition.longitude + (0.01 * _markerCounter),
                );
                _markers = [..._markers, marker];
                _statusText =
                    'Marker $_markerCounter added at'
                    ' (${marker.latitude.toStringAsFixed(4)},'
                    ' ${marker.longitude.toStringAsFixed(4)})';
                _expandedSection = null;
              }),
            ),
            _PillButton(
              label: 'Clear Markers',
              onTap: () => setState(() {
                _markers = [];
                _statusText = 'All markers cleared';
                _expandedSection = null;
              }),
            ),
          ],
        );

      case _ControlSection.options:
        return _ExpandedColumn(
          children: [
            _PillButton(
              label: 'Zoom: ${_zoomGesturesEnabled ? "ON" : "OFF"}',
              active: _zoomGesturesEnabled,
              onTap: () => setState(() {
                _zoomGesturesEnabled = !_zoomGesturesEnabled;
              }),
            ),
            _PillButton(
              label: 'Scroll: ${_scrollGesturesEnabled ? "ON" : "OFF"}',
              active: _scrollGesturesEnabled,
              onTap: () => setState(() {
                _scrollGesturesEnabled = !_scrollGesturesEnabled;
              }),
            ),
          ],
        );

      case null:
        return const SizedBox.shrink();
    }
  }
}

// ── Section identifier ───────────────────────────────────────────────────────

enum _ControlSection { mapType, cities, markers, options }

// ── Bottom bar widgets ───────────────────────────────────────────────────────

/// A header button in the floating bottom controls.
class _SectionHeader extends StatelessWidget {
  final String label;
  final bool active;
  final bool expanded;
  final VoidCallback onTap;

  const _SectionHeader({
    required this.label,
    this.active = false,
    this.expanded = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Flexible(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF000000),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}

/// A vertical column of pill buttons in the expanded section.
class _ExpandedColumn extends StatelessWidget {
  final List<Widget> children;
  const _ExpandedColumn({required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          children[i],
        ],
      ],
    );
  }
}

/// A single selectable pill button in the expanded section.
class _PillButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _PillButton({
    required this.label,
    this.active = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF007AFF) : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? const Color(0xFFFFFFFF) : const Color(0xFF000000),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
