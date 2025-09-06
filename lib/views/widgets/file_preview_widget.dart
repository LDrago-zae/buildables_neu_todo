import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:buildables_neu_todo/core/app_colors.dart';

class FilePreviewWidget extends StatefulWidget {
  final String? attachmentUrl;
  final String taskId;
  final double? width;
  final double? height;
  final bool showActions;

  const FilePreviewWidget({
    super.key,
    this.attachmentUrl,
    required this.taskId,
    this.width,
    this.height,
    this.showActions = true,
  });

  @override
  State<FilePreviewWidget> createState() => _FilePreviewWidgetState();
}

class _FilePreviewWidgetState extends State<FilePreviewWidget> {
  bool _isLoading = false;
  Uint8List? _fileBytes;
  String? _filePath;
  bool _isImage = false;

  @override
  void initState() {
    super.initState();
    _loadFileData();
  }

  Future<void> _loadFileData() async {
    if (widget.attachmentUrl == null) return;

    setState(() => _isLoading = true);

    try {
      if (widget.attachmentUrl!.startsWith('http')) {
        // Supabase URL - download file
        final response = await _downloadFileFromUrl(widget.attachmentUrl!);
        if (response != null) {
          setState(() {
            _fileBytes = response;
            _isImage = _isImageFile(_getFileExtension());
            _isLoading = false;
          });
        }
      } else if (widget.attachmentUrl!.startsWith('/') ||
          widget.attachmentUrl!.startsWith('file://')) {
        // Local file path
        final file = File(widget.attachmentUrl!);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          setState(() {
            _fileBytes = bytes;
            _filePath = widget.attachmentUrl;
            _isImage = _isImageFile(_getFileExtension());
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading file data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<Uint8List?> _downloadFileFromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      print('Error downloading file: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.attachmentUrl == null) {
      return _buildNoAttachment();
    }

    // Debug: Show file info immediately without loading
    print('FilePreviewWidget: Building with URL: ${widget.attachmentUrl}');
    print('FilePreviewWidget: File extension: ${_getFileExtension()}');
    print('FilePreviewWidget: Is image: ${_isImageFile(_getFileExtension())}');

    // TEST MODE: Skip loading for now to see if widget works
    if (true) {
      // Change to false to enable real loading
      return _buildDebugFallback();
    }

    // TEST: Try with a hardcoded test URL
    if (widget.attachmentUrl == 'test') {
      return _buildTestImage();
    }

    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_fileBytes == null) {
      return _buildDebugFallback();
    }

    return _buildFilePreview();
  }

  Widget _buildNoAttachment() {
    return Container(
      width: widget.width ?? 120,
      height: widget.height ?? 120,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(Icons.add_photo_alternate, size: 48, color: Colors.black54),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      width: widget.width ?? 120,
      height: widget.height ?? 120,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: widget.width ?? 120,
      height: widget.height ?? 120,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 32, color: Colors.red),
            SizedBox(height: 8),
            Text(
              'Error loading file',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugFallback() {
    // Show file info even when file can't be loaded
    final extension = _getFileExtension();
    final isImage = _isImageFile(extension);

    return Container(
      width: widget.width ?? 120,
      height: widget.height ?? 120,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isImage)
              const Icon(Icons.image, size: 48, color: Colors.blue)
            else
              Text(
                _getFileIcon(extension),
                style: const TextStyle(fontSize: 48),
              ),
            const SizedBox(height: 8),
            Text(
              extension.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Preview not available',
              style: const TextStyle(fontSize: 10, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestImage() {
    // Show a test image to verify the widget works
    return Container(
      width: widget.width ?? 120,
      height: widget.height ?? 120,
      decoration: BoxDecoration(
        color: AppColors.accentGreen,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 48, color: Colors.white),
            SizedBox(height: 8),
            Text(
              'TEST IMAGE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePreview() {
    if (_isImage) {
      return _buildImagePreview();
    } else {
      return _buildDocumentPreview(_getFileExtension());
    }
  }

  Widget _buildImagePreview() {
    return Container(
      width: widget.width ?? 120,
      height: widget.height ?? 120,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(2, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            // Image
            Image.memory(
              _fileBytes!,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildErrorState();
              },
            ),
            // File type indicator
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getFileExtension().toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Actions overlay
            if (widget.showActions)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.zoom_in,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: _openFullScreen,
                        tooltip: 'View Full Screen',
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.download,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: _downloadFile,
                        tooltip: 'Download',
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentPreview(String fileExtension) {
    final icon = _getFileIcon(fileExtension);
    final color = _getFileColor(fileExtension);

    return Container(
      width: widget.width ?? 120,
      height: widget.height ?? 120,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // File icon
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(icon, style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 8),
                Text(
                  fileExtension.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          // Actions
          if (widget.showActions)
            Positioned(
              bottom: 8,
              right: 8,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.open_in_new,
                      color: Colors.black,
                      size: 20,
                    ),
                    onPressed: _openFile,
                    tooltip: 'Open File',
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.download,
                      color: Colors.black,
                      size: 20,
                    ),
                    onPressed: _downloadFile,
                    tooltip: 'Download',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _getFileExtension() {
    if (widget.attachmentUrl == null) return '';

    if (widget.attachmentUrl!.startsWith('http')) {
      final uri = Uri.parse(widget.attachmentUrl!);
      return uri.pathSegments.last.split('.').last.toLowerCase();
    } else {
      return widget.attachmentUrl!.split('.').last.toLowerCase();
    }
  }

  bool _isImageFile(String extension) {
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }

  String _getFileIcon(String extension) {
    switch (extension) {
      case 'pdf':
        return '📄';
      case 'doc':
      case 'docx':
        return '📝';
      case 'txt':
        return '📄';
      case 'xls':
      case 'xlsx':
        return '📊';
      case 'ppt':
      case 'pptx':
        return '📊';
      default:
        return '📎';
    }
  }

  Color _getFileColor(String extension) {
    switch (extension) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'txt':
        return Colors.grey;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      default:
        return Colors.black;
    }
  }

  void _openFullScreen() {
    if (_fileBytes != null && _isImage) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              title: const Text('Image Preview'),
            ),
            body: Center(
              child: InteractiveViewer(child: Image.memory(_fileBytes!)),
            ),
          ),
        ),
      );
    }
  }

  void _openFile() {
    if (widget.attachmentUrl != null &&
        widget.attachmentUrl!.startsWith('http')) {
      _launchUrl(widget.attachmentUrl!);
    }
  }

  void _downloadFile() {
    // Implement file download logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Download functionality coming soon!'),
        backgroundColor: AppColors.accentGreen,
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      // For now, just show a message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Opening: ${url.split('/').last}'),
          backgroundColor: AppColors.accentGreen,
        ),
      );
    } catch (e) {
      print('Error launching URL: $e');
    }
  }
}
