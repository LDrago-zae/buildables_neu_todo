import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class LocationInfoWidget extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final bool isCompact;
  final VoidCallback? onTap;

  const LocationInfoWidget({
    super.key,
    this.latitude,
    this.longitude,
    this.locationName,
    this.isCompact = true,
    this.onTap,
  });

  bool get hasLocation => latitude != null && longitude != null;

  @override
  Widget build(BuildContext context) {
    if (!hasLocation) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 8 : 12,
          vertical: isCompact ? 4 : 8,
        ),
        decoration: BoxDecoration(
          color: AppColors.accentGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(isCompact ? 6 : 8),
          border: Border.all(
            color: AppColors.accentGreen.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on,
              color: AppColors.accentGreen,
              size: isCompact ? 14 : 16,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                _getDisplayText(),
                style: TextStyle(
                  color: AppColors.accentGreen,
                  fontSize: isCompact ? 11 : 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDisplayText() {
    if (locationName?.isNotEmpty == true) {
      return locationName!;
    }
    return '${latitude!.toStringAsFixed(3)}, ${longitude!.toStringAsFixed(3)}';
  }
}
