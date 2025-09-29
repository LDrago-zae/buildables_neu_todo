import 'package:flutter/material.dart';
import 'package:buildables_neu_todo/views/widgets/mapbox_widget.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapboxTestScreen extends StatefulWidget {
  const MapboxTestScreen({super.key});

  @override
  State<MapboxTestScreen> createState() => _MapboxTestScreenState();
}

class _MapboxTestScreenState extends State<MapboxTestScreen> {
  MapboxMap? mapboxMap;
  LatLng? selectedLocation;
  final GlobalKey<State<MapboxWidget>> _mapboxWidgetKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapbox Map Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Map
          Expanded(
            flex: 3,
            child: MapboxWidget(
              key: _mapboxWidgetKey,
              initialLatitude: 37.7749, // San Francisco
              initialLongitude: -122.4194,
              showMarker: true,
              styleUrl: MapboxStyles.MAPBOX_STREETS,
              onMapCreated: (MapboxMap map) {
                mapboxMap = map;
                debugPrint('✅ Map created successfully');
              },
              onStyleLoaded: (MapboxMap map) {
                debugPrint('✅ Map style loaded');
              },
              onMapTap: (position, latLng) {
                setState(() {
                  selectedLocation = latLng;
                });
                debugPrint(
                  '📍 Tapped at: ${latLng.latitude}, ${latLng.longitude}',
                );
              },
            ),
          ),

          // Controls
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Map Controls',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                if (selectedLocation != null) ...[
                  Text('Selected Location:'),
                  Text(
                    'Lat: ${selectedLocation!.latitude.toStringAsFixed(6)}\n'
                    'Lng: ${selectedLocation!.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 12),
                ],

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _animateToLocation(37.7749, -122.4194),
                      icon: const Icon(Icons.location_city),
                      label: const Text('San Francisco'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _animateToLocation(40.7128, -74.0060),
                      icon: const Icon(Icons.location_city),
                      label: const Text('New York'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _animateToLocation(51.5074, -0.1278),
                      icon: const Icon(Icons.location_city),
                      label: const Text('London'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _animateToLocation(double lat, double lng) async {
    await MapboxWidget.animateToFromKey(_mapboxWidgetKey, lat, lng, zoom: 12.0);
    await MapboxWidget.updateMarkerFromKey(_mapboxWidgetKey, lat, lng);

    setState(() {
      selectedLocation = LatLng(latitude: lat, longitude: lng);
    });
  }
}
