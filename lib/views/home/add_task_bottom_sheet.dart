import 'dart:io';
import 'package:buildables_neu_todo/views/widgets/map_picker_screen.dart';
import 'package:buildables_neu_todo/views/widgets/location_preview.dart';
import 'package:buildables_neu_todo/views/widgets/location_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:buildables_neu_todo/core/app_colors.dart';
import 'package:buildables_neu_todo/controllers/task_controller.dart';
import 'package:buildables_neu_todo/services/file_service.dart';
import 'package:buildables_neu_todo/views/widgets/category_chip_selector.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart' as geo;

class AddTaskBottomSheet extends StatefulWidget {
  final List<String> categories;
  final TaskController taskController;
  final void Function() onTaskAdded;
  final void Function(Object error)? onError;

  const AddTaskBottomSheet({
    super.key,
    required this.categories,
    required this.taskController,
    required this.onTaskAdded,
    this.onError,
  });

  @override
  State<AddTaskBottomSheet> createState() => _AddTaskBottomSheetState();
}

class _AddTaskBottomSheetState extends State<AddTaskBottomSheet> {
  final TextEditingController _titleController = TextEditingController();
  final FileService _fileService = FileService();
  String? _selectedCategory;
  File? _selectedFile;
  bool _isLoading = false;
  bool _includeLocation = false;
  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _selectedLocationName;
  bool _isGettingLocation = false;

  // Helper getter
  bool get _hasLocationSelected =>
      _selectedLatitude != null && _selectedLongitude != null;

  // Helper methods for location handling
  Future<void> _pickLocationFromMap() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(
          initialLatitude: _selectedLatitude,
          initialLongitude: _selectedLongitude,
          initialLocationName: _selectedLocationName,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLatitude = result['latitude'] as double;
        _selectedLongitude = result['longitude'] as double;
        _selectedLocationName = result['locationName'] as String;
      });
    }
  }

  void _openLocationDetail() {
    if (_selectedLatitude != null && _selectedLongitude != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LocationDetailScreen(
            latitude: _selectedLatitude!,
            longitude: _selectedLongitude!,
            locationName: _selectedLocationName,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      geo.LocationPermission permission =
          await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      geo.Position position = await geo.Geolocator.getCurrentPosition();

      // Get address from coordinates
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        String address = 'Unknown location';
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          address =
              '${place.street ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}';
        }

        setState(() {
          _selectedLatitude = position.latitude;
          _selectedLongitude = position.longitude;
          _selectedLocationName = address;
        });
      } catch (e) {
        setState(() {
          _selectedLatitude = position.latitude;
          _selectedLongitude = position.longitude;
          _selectedLocationName =
              'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}';
        });
      }
    } catch (e) {
      // Use the onError callback instead of local SnackBar
      widget.onError?.call('Failed to get location: $e');
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  void _addTask() async {
    if (_titleController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.taskController.addTaskWithAttachment(
        title: _titleController.text.trim(),
        category: _selectedCategory,
        attachmentFile: _selectedFile,
        latitude: _includeLocation ? _selectedLatitude : null,
        longitude: _includeLocation ? _selectedLongitude : null,
        locationName: _includeLocation ? _selectedLocationName : null,
      );

      widget.onTaskAdded();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error adding task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add task: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _pickFile() async {
    try {
      final file = await _fileService.pickFile();
      setState(() {
        _selectedFile = file;
      });
    } catch (e) {
      widget.onError?.call('Failed to pick file: $e');
    }
  }

  void _pickImageFromGallery() async {
    try {
      final file = await _fileService.pickImageFromGallery();
      setState(() {
        _selectedFile = file;
      });
    } catch (e) {
      widget.onError?.call('Failed to pick image: $e');
    }
  }

  void _pickImageFromCamera() async {
    try {
      final file = await _fileService.pickImageFromCamera();
      setState(() {
        _selectedFile = file;
      });
    } catch (e) {
      widget.onError?.call('Failed to take photo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Add New Task',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Task title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Colors.black,
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Colors.black,
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                CategoryChipSelector(
                  categories: widget.categories,
                  selectedCategory: _selectedCategory,
                  onCategorySelected: (category) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Add this after the attachment section and before the Row with buttons
                // Location section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LOCATION',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),

                    SwitchListTile(
                      value: _includeLocation,
                      onChanged: (value) {
                        setState(() => _includeLocation = value);
                        if (value && _selectedLatitude == null) {
                          _getCurrentLocation();
                        }
                      },
                      title: const Text(
                        'Include Location',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Add location info to this task',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),

                    if (_includeLocation) ...[
                      const SizedBox(height: 16),

                      // Location Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Location',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black.withOpacity(0.8),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _pickLocationFromMap,
                            icon: Icon(
                              Icons.map_outlined,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            label: Text(
                              _hasLocationSelected ? 'Change' : 'Pick Map',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Location Preview or Empty State
                      LocationPreview(
                        latitude: _selectedLatitude,
                        longitude: _selectedLongitude,
                        locationName: _selectedLocationName,
                        onTap: _hasLocationSelected
                            ? _openLocationDetail
                            : _pickLocationFromMap,
                        height: 140,
                      ),

                      // Current Location Button (if no location selected)
                      if (!_hasLocationSelected) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isGettingLocation
                                ? null
                                : _getCurrentLocation,
                            icon: _isGettingLocation
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.primary,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.my_location,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                            label: Text(
                              _isGettingLocation
                                  ? 'Getting Location...'
                                  : 'Use Current Location',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.primary),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ] else ...[
                        // Location actions for selected location
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _getCurrentLocation,
                                icon: Icon(
                                  Icons.my_location,
                                  size: 16,
                                  color: AppColors.textMuted,
                                ),
                                label: Text(
                                  'Use Current',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 14,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: AppColors.border),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _selectedLatitude = null;
                                    _selectedLongitude = null;
                                    _selectedLocationName = null;
                                  });
                                },
                                icon: Icon(
                                  Icons.clear,
                                  size: 16,
                                  color: AppColors.danger,
                                ),
                                label: Text(
                                  'Remove',
                                  style: TextStyle(
                                    color: AppColors.danger,
                                    fontSize: 14,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: AppColors.danger),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                // Attachment section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ATTACHMENT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Show selected file
                    if (_selectedFile != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.accentCyan,
                          border: Border.all(color: Colors.black, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _fileService.getFileIcon(_selectedFile!.path),
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedFile!.path.split('/').last,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Ready to upload',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _selectedFile = null;
                                });
                              },
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Attachment buttons
                    if (_selectedFile == null)
                      Row(
                        children: [
                          Expanded(
                            child: _AttachmentButton(
                              icon: Icons.photo_library,
                              label: 'Gallery',
                              onTap: _pickImageFromGallery,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _AttachmentButton(
                              icon: Icons.camera_alt,
                              label: 'Camera',
                              onTap: _pickImageFromCamera,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _AttachmentButton(
                              icon: Icons.attach_file,
                              label: 'File',
                              onTap: _pickFile,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.black, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _addTask,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          side: const BorderSide(color: Colors.black, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.black,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.save, size: 16),
                                  SizedBox(width: 4),
                                  Text('Save Task'),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AttachmentButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AttachmentButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: Colors.black, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
