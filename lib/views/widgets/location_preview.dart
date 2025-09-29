import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../core/app_colors.dart';
import 'mapbox_widget.dart';

class LocationPreview extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final VoidCallback? onTap;
  final double height;
  final bool showEditButton;

  const LocationPreview({
    super.key,
    this.latitude,
    this.longitude,
    this.locationName,
    this.onTap,
    this.height = 120,
    this.showEditButton = true,
  });

  @override
  Widget build(BuildContext context) {
    if (latitude == null || longitude == null) {
      return _buildEmptyState(context);
    }

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Mini Map
            MapboxWidget(
              initialLatitude: latitude!,
              initialLongitude: longitude!,
              showMarker: true,
              onMapCreated: (map) async {
                // Disable map interactions for preview
                try {
                  await map.gestures.updateSettings(
                    GesturesSettings(
                      rotateEnabled: false,
                      pitchEnabled: false,
                      scrollEnabled: false,
                      simultaneousRotateAndPinchToZoomEnabled: false,
                      quickZoomEnabled: false,
                    ),
                  );
                } catch (e) {
                  debugPrint('Error disabling gestures: $e');
                }
              },
            ),

            // Overlay with location info and edit button
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (locationName?.isNotEmpty == true) ...[
                            Text(
                              locationName!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                          ],
                          Text(
                            '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (showEditButton && onTap != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onTap,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Tap overlay for interaction
            if (onTap != null)
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border.withOpacity(0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_on_outlined,
              color: AppColors.textMuted,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to select location',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
