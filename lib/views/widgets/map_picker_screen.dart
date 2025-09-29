import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'mapbox_widget.dart';
import '../../core/app_colors.dart';

class MapPickerScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialLocationName;

  const MapPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialLocationName,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  double? _selectedLat;
  double? _selectedLng;
  String? _selectedLocationName;
  bool _isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    _selectedLat = widget.initialLatitude;
    _selectedLng = widget.initialLongitude;
    _selectedLocationName = widget.initialLocationName;
  }

  Future<void> _getAddressFromCoordinates(double lat, double lng) async {
    setState(() {
      _isLoadingAddress = true;
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address = [
          placemark.street,
          placemark.locality,
          placemark.administrativeArea,
          placemark.country,
        ].where((element) => element != null && element.isNotEmpty).join(', ');

        setState(() {
          _selectedLocationName = address.isEmpty
              ? 'Unknown Location'
              : address;
        });
      } else {
        setState(() {
          _selectedLocationName = 'Unknown Location';
        });
      }
    } catch (e) {
      setState(() {
        _selectedLocationName =
            'Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}';
      });
    } finally {
      setState(() {
        _isLoadingAddress = false;
      });
    }
  }

  void _onMapTapped(Position position, LatLng latLng) {
    setState(() {
      _selectedLat = latLng.latitude;
      _selectedLng = latLng.longitude;
    });
    _getAddressFromCoordinates(latLng.latitude, latLng.longitude);
  }

  void _confirmSelection() {
    if (_selectedLat != null && _selectedLng != null) {
      Navigator.pop(context, {
        'latitude': _selectedLat!,
        'longitude': _selectedLng!,
        'locationName': _selectedLocationName ?? 'Selected Location',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Pick Location',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.textMuted),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _selectedLat != null && _selectedLng != null
                ? _confirmSelection
                : null,
            child: Text(
              'Done',
              style: TextStyle(
                color: _selectedLat != null && _selectedLng != null
                    ? AppColors.accentGreen
                    : AppColors.textMuted,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Map Area
          Expanded(
            child: MapboxWidget(
              initialLatitude: _selectedLat ?? 40.7128,
              initialLongitude: _selectedLng ?? -74.0060,
              showMarker: true,
              onMapTap: _onMapTapped,
              onMapCreated: (MapboxMap map) {
                print('✅ Map picker ready');
              },
            ),
          ),
          // Selected Location Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: AppColors.accentGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Selected Location',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_isLoadingAddress)
                  Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.accentGreen,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Getting address...',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  )
                else if (_selectedLocationName != null)
                  Text(
                    _selectedLocationName!,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  Text(
                    'Tap on the map to select a location',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                if (_selectedLat != null && _selectedLng != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Coordinates: ${_selectedLat!.toStringAsFixed(6)}, ${_selectedLng!.toStringAsFixed(6)}',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedLat != null && _selectedLng != null
                        ? _confirmSelection
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _selectedLat != null && _selectedLng != null
                          ? 'Confirm Location'
                          : 'Select a Location',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
