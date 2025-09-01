import 'dart:io';
import 'package:flutter/material.dart';
import 'package:buildables_neu_todo/services/file_service.dart';
import 'package:buildables_neu_todo/core/app_colors.dart';

class FilePickerTestWidget extends StatefulWidget {
  const FilePickerTestWidget({super.key});

  @override
  State<FilePickerTestWidget> createState() => _FilePickerTestWidgetState();
}

class _FilePickerTestWidgetState extends State<FilePickerTestWidget> {
  final FileService _fileService = FileService();
  String? _selectedFilePath;
  String _status = 'Ready to test file picker';
  bool _isLoading = false;

  void _testCamera() async {
    setState(() {
      _isLoading = true;
      _status = 'Opening camera...';
    });

    try {
      final file = await _fileService.pickImageFromCamera();
      if (file != null) {
        setState(() {
          _selectedFilePath = file.path;
          _status = 'Camera photo selected: ${file.path.split('/').last}';
        });
      } else {
        setState(() => _status = 'Camera cancelled');
      }
    } catch (e) {
      setState(() => _status = 'Camera error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _testGallery() async {
    setState(() {
      _isLoading = true;
      _status = 'Opening gallery...';
    });

    try {
      final file = await _fileService.pickImageFromGallery();
      if (file != null) {
        setState(() {
          _selectedFilePath = file.path;
          _status = 'Gallery image selected: ${file.path.split('/').last}';
        });
      } else {
        setState(() => _status = 'Gallery cancelled');
      }
    } catch (e) {
      setState(() => _status = 'Gallery error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _testFilePicker() async {
    setState(() {
      _isLoading = true;
      _status = 'Opening file picker...';
    });

    try {
      final file = await _fileService.pickFile();
      if (file != null) {
        setState(() {
          _selectedFilePath = file.path;
          _status = 'File selected: ${file.path.split('/').last}';
        });
      } else {
        setState(() => _status = 'File picker cancelled');
      }
    } catch (e) {
      setState(() => _status = 'File picker error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _testUpload() async {
    if (_selectedFilePath == null) {
      setState(() => _status = 'No file selected for upload');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Uploading file...';
    });

    try {
      final file = File(_selectedFilePath!);
      final url = await _fileService.uploadFile(
        file,
        'test_task_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (url != null) {
        setState(() => _status = 'Upload successful! URL: $url');
      } else {
        setState(() => _status = 'Upload failed - no URL returned');
      }
    } catch (e) {
      setState(() => _status = 'Upload error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _debugDatabase() async {
    setState(() {
      _isLoading = true;
      _status = 'Checking database schema...';
    });

    try {
      final fileService = FileService();
      await fileService.debugDatabaseSchema();
      setState(
        () => _status = 'Database schema check completed - check console',
      );
    } catch (e) {
      setState(() => _status = 'Database debug error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Picker Test'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Test File Sharing Features',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _status,
                    style: const TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Test Buttons
            _TestButton(
              icon: Icons.camera_alt,
              label: 'Test Camera',
              onPressed: _isLoading ? null : _testCamera,
              color: AppColors.accentGreen,
            ),
            const SizedBox(height: 12),

            _TestButton(
              icon: Icons.photo_library,
              label: 'Test Gallery',
              onPressed: _isLoading ? null : _testGallery,
              color: AppColors.accentCyan,
            ),
            const SizedBox(height: 12),

            _TestButton(
              icon: Icons.insert_drive_file,
              label: 'Test File Picker',
              onPressed: _isLoading ? null : _testFilePicker,
              color: AppColors.accentYellow,
            ),
            const SizedBox(height: 20),

            if (_selectedFilePath != null) ...[
              _TestButton(
                icon: Icons.cloud_upload,
                label: 'Test Upload to Supabase',
                onPressed: _isLoading ? null : _testUpload,
                color: AppColors.accentPink,
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(color: Colors.black, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selected File:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedFilePath!.split('/').last,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Extension: ${_fileService.getFileExtension(_selectedFilePath!)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            _TestButton(
              icon: Icons.storage,
              label: 'Debug Database',
              onPressed: _isLoading ? null : _debugDatabase,
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }
}

class _TestButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color color;

  const _TestButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          elevation: 0,
          side: const BorderSide(color: Colors.black, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
