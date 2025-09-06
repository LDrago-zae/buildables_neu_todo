import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:buildables_neu_todo/core/app_colors.dart';

class FileThumbnailWidget extends StatefulWidget {
  final String? attachmentUrl;
  final double size;
  final bool showBorder;

  const FileThumbnailWidget({
    super.key,
    this.attachmentUrl,
    this.size = 60,
    this.showBorder = true,
  });

  @override
  State<FileThumbnailWidget> createState() => _FileThumbnailWidgetState();
}

class _FileThumbnailWidgetState extends State<FileThumbnailWidget> {
  bool _isLoading = false;
  Uint8List? _fileBytes;
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
        final response = await http.get(Uri.parse(widget.attachmentUrl!));
        if (response.statusCode == 200) {
          setState(() {
            _fileBytes = response.bodyBytes;
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

  @override
  Widget build(BuildContext context) {
    if (widget.attachmentUrl == null) {
      return _buildNoAttachment();
    }

    // Debug: Show file info immediately without loading
    print('FileThumbnailWidget: Building with URL: ${widget.attachmentUrl}');
    print('FileThumbnailWidget: File extension: ${_getFileExtension()}');
    print(
      'FileThumbnailWidget: Is image: ${_isImageFile(_getFileExtension())}',
    );

    // TEST MODE: Skip loading for now to see if widget works
    if (true) {
      // Change to false to enable real loading
      return _buildTestThumbnail();
    }

    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_fileBytes == null) {
      return _buildTestThumbnail();
    }

    return _buildThumbnail();
  }

  Widget _buildNoAttachment() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: widget.showBorder
            ? Border.all(color: Colors.black, width: 2)
            : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(Icons.add_photo_alternate, size: 24, color: Colors.black54),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: widget.showBorder
            ? Border.all(color: Colors.black, width: 2)
            : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: widget.showBorder
            ? Border.all(color: Colors.black, width: 2)
            : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(Icons.error_outline, size: 20, color: Colors.red),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (_isImage) {
      return _buildImageThumbnail();
    } else {
      return _buildDocumentThumbnail();
    }
  }

  Widget _buildImageThumbnail() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: widget.showBorder
            ? Border.all(color: Colors.black, width: 2)
            : null,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(1, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
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
              top: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getFileExtension().toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentThumbnail() {
    final icon = _getFileIcon(_getFileExtension());
    final color = _getFileColor(_getFileExtension());

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: widget.showBorder
            ? Border.all(color: Colors.black, width: 2)
            : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: TextStyle(fontSize: widget.size * 0.4)),
            const SizedBox(height: 2),
            Text(
              _getFileExtension().toUpperCase(),
              style: TextStyle(
                fontSize: widget.size * 0.15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestThumbnail() {
    // Show file info even when file can't be loaded
    final extension = _getFileExtension();
    final isImage = _isImageFile(extension);

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: widget.showBorder
            ? Border.all(color: Colors.black, width: 2)
            : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isImage)
              const Icon(Icons.image, size: 20, color: Colors.blue)
            else
              Text(
                _getFileIcon(extension),
                style: TextStyle(fontSize: widget.size * 0.3),
              ),
            const SizedBox(height: 2),
            Text(
              extension.toUpperCase(),
              style: TextStyle(
                fontSize: widget.size * 0.12,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
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
}
