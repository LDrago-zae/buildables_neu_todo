import 'dart:io';
import 'package:flutter/material.dart';
import 'package:buildables_neu_todo/core/app_colors.dart';
import 'package:buildables_neu_todo/services/file_service.dart';

class FilePickerTestWidget extends StatefulWidget {
  const FilePickerTestWidget({super.key});

  @override
  State<FilePickerTestWidget> createState() => _FilePickerTestWidgetState();
}

class _FilePickerTestWidgetState extends State<FilePickerTestWidget> {
  final FileService _fileService = FileService();
  String _status = 'Ready to test';
  bool _isLoading = false;
  File? _selectedFile;
  String? _uploadedUrl;

  void _updateStatus(String message) {
    setState(() {
      _status = message;
    });
  }

  Future<void> _testCamera() async {
    setState(() {
      _isLoading = true;
      _status = 'Opening camera...';
    });

    try {
      final file = await _fileService.pickImageFromCamera();
      if (file != null) {
        setState(() {
          _selectedFile = file;
          _status = '✅ Camera photo captured: ${file.path.split('/').last}';
        });
      } else {
        _updateStatus('❌ Camera cancelled or failed');
      }
    } catch (e) {
      _updateStatus('❌ Camera error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testGallery() async {
    setState(() {
      _isLoading = true;
      _status = 'Opening gallery...';
    });

    try {
      final file = await _fileService.pickImageFromGallery();
      if (file != null) {
        setState(() {
          _selectedFile = file;
          _status = '✅ Gallery image selected: ${file.path.split('/').last}';
        });
      } else {
        _updateStatus('❌ Gallery cancelled or failed');
      }
    } catch (e) {
      _updateStatus('❌ Gallery error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testFilePicker() async {
    setState(() {
      _isLoading = true;
      _status = 'Opening file picker...';
    });

    try {
      final file = await _fileService.pickFile();
      if (file != null) {
        setState(() {
          _selectedFile = file;
          _status = '✅ File selected: ${file.path.split('/').last}';
        });
      } else {
        _updateStatus('❌ File picker cancelled or failed');
      }
    } catch (e) {
      _updateStatus('❌ File picker error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testUpload() async {
    if (_selectedFile == null) {
      _updateStatus('❌ No file selected for upload');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Uploading file...';
    });

    try {
      final url = await _fileService.uploadFile(_selectedFile!, 'test-task-id');
      setState(() {
        _uploadedUrl = url;
        _status =
            '✅ File uploaded successfully!\nURL: ${url?.substring(0, 50)}...';
      });
    } catch (e) {
      _updateStatus('❌ Upload failed: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearResults() {
    setState(() {
      _selectedFile = null;
      _uploadedUrl = null;
      _status = 'Ready to test';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'File Picker Test',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        shape: const Border(bottom: BorderSide(color: Colors.black, width: 2)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'STATUS',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _status,
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Test Buttons
            Expanded(
              child: Column(
                children: [
                  _buildTestButton(
                    icon: Icons.camera_alt,
                    title: 'Test Camera',
                    onPressed: _isLoading ? null : _testCamera,
                  ),
                  const SizedBox(height: 12),
                  _buildTestButton(
                    icon: Icons.photo_library,
                    title: 'Test Gallery',
                    onPressed: _isLoading ? null : _testGallery,
                  ),
                  const SizedBox(height: 12),
                  _buildTestButton(
                    icon: Icons.insert_drive_file,
                    title: 'Test File Picker',
                    onPressed: _isLoading ? null : _testFilePicker,
                  ),
                  const SizedBox(height: 12),
                  _buildTestButton(
                    icon: Icons.cloud_upload,
                    title: 'Test Upload',
                    onPressed: _isLoading || _selectedFile == null
                        ? null
                        : _testUpload,
                    color: _selectedFile == null
                        ? Colors.grey
                        : AppColors.accentGreen,
                  ),
                  const SizedBox(height: 12),
                  _buildTestButton(
                    icon: Icons.clear,
                    title: 'Clear Results',
                    onPressed: _isLoading ? null : _clearResults,
                    color: AppColors.danger,
                  ),
                ],
              ),
            ),

            // File Info Display
            if (_selectedFile != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentYellow,
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SELECTED FILE',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Name: ${_selectedFile!.path.split('/').last}',
                      style: const TextStyle(color: Colors.black),
                    ),
                    Text(
                      'Path: ${_selectedFile!.path}',
                      style: const TextStyle(color: Colors.black, fontSize: 12),
                    ),
                    Text(
                      'Size: ${_selectedFile!.lengthSync()} bytes',
                      style: const TextStyle(color: Colors.black),
                    ),
                    Text(
                      'Type: ${_fileService.getFileExtension(_selectedFile!.path)}',
                      style: const TextStyle(color: Colors.black),
                    ),
                  ],
                ),
              ),
            ],

            // Upload URL Display
            if (_uploadedUrl != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen,
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'UPLOADED URL',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      _uploadedUrl!,
                      style: const TextStyle(color: Colors.black, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton({
    required IconData icon,
    required String title,
    required VoidCallback? onPressed,
    Color? color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.accentCyan,
          foregroundColor: Colors.black,
          elevation: 0,
          side: const BorderSide(color: Colors.black, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }
}
