import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter/material.dart';

/// MapboxWidget - A comprehensive Mapbox Maps Flutter widget
///
/// Usage Example:
/// ```dart
/// MapboxWidget(
///   accessToken: 'your_mapbox_access_token', // Optional if set in .env
///   initialLatitude: 37.7749,
///   initialLongitude: -122.4194,
///   showMarker: true,
///   styleUrl: MapboxStyles.MAPBOX_STREETS, // Optional
///   onMapCreated: (MapboxMap map) {
///     print('Map created successfully');
///   },
///   onMapTap: (position, latLng) {
///     print('Tapped at: ${latLng.latitude}, ${latLng.longitude}');
///   },
/// )
/// ```
///
/// Setup Requirements:
/// 1. Add MAPBOX_ACCESS_TOKEN to your .env file
/// 2. Or pass accessToken directly to the widget
/// 3. Ensure mapbox_maps_flutter dependency is added to pubspec.yaml

class MapboxWidget extends StatefulWidget {
  final String? accessToken;
  final CameraOptions? initialCameraOptions;
  final void Function(MapboxMap)? onMapCreated;
  final void Function(Position, LatLng)? onMapTap;
  final void Function(MapboxMap)? onStyleLoaded;
  final double? initialLatitude;
  final double? initialLongitude;
  final String? styleUrl;
  final bool showMarker;

  const MapboxWidget({
    super.key,
    this.accessToken,
    this.initialCameraOptions,
    this.onMapCreated,
    this.onMapTap,
    this.onStyleLoaded,
    this.initialLatitude,
    this.initialLongitude,
    this.styleUrl,
    this.showMarker = true,
  });

  @override
  State<MapboxWidget> createState() => _MapboxWidgetState();

  // Static method to animate to location from outside the widget
  static Future<void> animateToFromKey(
    GlobalKey<State<MapboxWidget>> key,
    double lat,
    double lng, {
    double? zoom,
  }) async {
    final state = key.currentState as _MapboxWidgetState?;
    if (state != null) {
      await state.animateTo(lat, lng, zoom: zoom);
    }
  }

  // Static method to update marker from outside the widget
  static Future<void> updateMarkerFromKey(
    GlobalKey<State<MapboxWidget>> key,
    double lat,
    double lng,
  ) async {
    final state = key.currentState as _MapboxWidgetState?;
    if (state != null) {
      await state.updateMarker(lat, lng);
    }
  }
}

class _MapboxWidgetState extends State<MapboxWidget> {
  MapboxMap? mapboxMap;
  PointAnnotationManager? pointAnnotationManager;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeMapbox();
  }

  Future<void> _initializeMapbox() async {
    try {
      // Initialize Mapbox access token
      final accessToken =
          widget.accessToken ??
          dotenv.env['MAPBOX_API_KEY'] ??
          const String.fromEnvironment('MAPBOX_API_KEY');

      if (accessToken.isEmpty) {
        throw Exception('Mapbox access token is required');
      }

      // Set the access token for Mapbox SDK
      MapboxOptions.setAccessToken(accessToken);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Map Error: $_errorMessage',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                  _isLoading = true;
                });
                _initializeMapbox();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return MapWidget(
      key: const ValueKey("mapWidget"),
      styleUri: widget.styleUrl ?? MapboxStyles.MAPBOX_STREETS,
      cameraOptions:
          widget.initialCameraOptions ??
          CameraOptions(
            center: Point(
              coordinates: Position(
                widget.initialLongitude ?? -74.0060,
                widget.initialLatitude ?? 40.7128,
              ),
            ),
            zoom: 12.0,
          ),
      onMapCreated: _onMapCreated,
      onTapListener: _onMapTap,
    );
  }

  Future<void> _onMapCreated(MapboxMap map) async {
    try {
      mapboxMap = map;

      // Create point annotation manager
      pointAnnotationManager = await map.annotations
          .createPointAnnotationManager();

      // Add initial marker if coordinates provided
      if (widget.showMarker &&
          widget.initialLatitude != null &&
          widget.initialLongitude != null) {
        await _addMarker(widget.initialLatitude!, widget.initialLongitude!);
      }

      widget.onMapCreated?.call(map);
      widget.onStyleLoaded?.call(map);
    } catch (e) {
      debugPrint('Error in onMapCreated: $e');
    }
  }

  Future<void> _onMapTap(MapContentGestureContext context) async {
    try {
      if (widget.onMapTap != null && mapboxMap != null) {
        final screenCoordinate = context.touchPosition;

        // Convert screen coordinates to geographic coordinates
        final point = await mapboxMap!.coordinateForPixel(screenCoordinate);

        final latLng = LatLng(
          latitude: point.coordinates.lat.toDouble(),
          longitude: point.coordinates.lng.toDouble(),
        );

        widget.onMapTap!(point.coordinates, latLng);

        // Add marker at tapped location if enabled
        if (widget.showMarker) {
          await _addMarker(latLng.latitude, latLng.longitude);
        }
      }
    } catch (e) {
      debugPrint('Error in onMapTap: $e');
    }
  }

  Future<void> _addMarker(double lat, double lng) async {
    if (pointAnnotationManager == null) return;

    try {
      // Clear existing annotations
      await pointAnnotationManager!.deleteAll();

      // Try to load custom marker icon from assets
      Uint8List? iconImage;
      try {
        final ByteData bytes = await DefaultAssetBundle.of(
          context,
        ).load('assets/icons/marker.png');
        iconImage = bytes.buffer.asUint8List();
      } catch (e) {
        // If custom icon fails to load, we'll use default
        debugPrint('Failed to load custom marker icon: $e');
      }

      final pointAnnotationOptions = PointAnnotationOptions(
        geometry: Point(coordinates: Position(lng, lat)),
        image: iconImage,
        iconSize: 1.0,
      );

      await pointAnnotationManager!.create(pointAnnotationOptions);
    } catch (e) {
      debugPrint('Error adding marker: $e');
    }
  }

  // Method to update marker position (useful for external calls)
  Future<void> updateMarker(double lat, double lng) async {
    await _addMarker(lat, lng);
  }

  // Method to animate camera to a new position
  Future<void> animateTo(double lat, double lng, {double? zoom}) async {
    if (mapboxMap == null) return;

    try {
      await mapboxMap!.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(lng, lat)),
          zoom: zoom ?? 14.0,
        ),
        MapAnimationOptions(duration: 1500),
      );
    } catch (e) {
      debugPrint('Error animating camera: $e');
    }
  }

  @override
  void dispose() {
    pointAnnotationManager = null;
    mapboxMap = null;
    super.dispose();
  }
}

class LatLng {
  final double latitude;
  final double longitude;

  const LatLng({required this.latitude, required this.longitude});

  @override
  String toString() => 'LatLng(lat: $latitude, lng: $longitude)';
}
