import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../core/app_colors.dart';
import 'mapbox_widget.dart';

class LocationDetailScreen extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String? locationName;

  const LocationDetailScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    this.locationName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Location Details'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: Column(
        children: [
          // Full Map View
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: MapboxWidget(
                  initialLatitude: latitude,
                  initialLongitude: longitude,
                  showMarker: true,
                  onMapCreated: (map) async {
                    // Set appropriate zoom level for detail view
                    try {
                      await map.flyTo(
                        CameraOptions(
                          center: Point(
                            coordinates: Position(longitude, latitude),
                          ),
                          zoom: 15.0,
                        ),
                        MapAnimationOptions(duration: 1000),
                      );
                    } catch (e) {
                      debugPrint('Error setting initial zoom: $e');
                    }
                  },
                ),
              ),
            ),
          ),

          // Location Info Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Location Name Section
                if (locationName?.isNotEmpty == true) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.location_city,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Address',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              locationName!,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                // Coordinates Section
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.my_location,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Coordinates',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Copy coordinates button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _copyCoordinates(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.copy,
                            color: AppColors.textMuted,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openInMaps(context),
                        icon: Icon(
                          Icons.open_in_new,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        label: Text(
                          'Open in Maps',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _shareLocation(context),
                        icon: const Icon(
                          Icons.share,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Share Location',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                      ),
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

  void _copyCoordinates(BuildContext context) {
    // Copy coordinates to clipboard
    final coordinates =
        '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
    // Note: You'll need to add clipboard functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Coordinates copied: $coordinates'),
        backgroundColor: AppColors.accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _openInMaps(BuildContext context) {
    // Open location in external maps app
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Opening in maps app...'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _shareLocation(BuildContext context) {
    // Share location
    final locationText = locationName?.isNotEmpty == true
        ? '$locationName\n${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}'
        : '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing: $locationText'),
        backgroundColor: AppColors.accentCyan,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
