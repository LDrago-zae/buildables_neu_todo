import 'dart:io';
import 'package:flutter/material.dart';
import 'package:buildables_neu_todo/core/app_colors.dart';
import 'package:buildables_neu_todo/services/file_service.dart';
import 'package:buildables_neu_todo/views/widgets/file_preview_widget.dart';
import 'package:buildables_neu_todo/views/widgets/file_thumbnail_widget.dart';

class TaskAttachmentWidget extends StatefulWidget {
  final String? attachmentUrl;
  final String taskId;
  final Function(String?) onAttachmentChanged;

  const TaskAttachmentWidget({
    super.key,
    this.attachmentUrl,
    required this.taskId,
    required this.onAttachmentChanged,
  });

  @override
  State<TaskAttachmentWidget> createState() => _TaskAttachmentWidgetState();
}

class _TaskAttachmentWidgetState extends State<TaskAttachmentWidget> {
  final FileService _fileService = FileService();
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // File Preview Section
          if (widget.attachmentUrl != null) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CURRENT ATTACHMENT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // File Preview
                  Center(
                    child: FilePreviewWidget(
                      attachmentUrl: widget.attachmentUrl,
                      taskId: widget.taskId,
                      width: 200,
                      height: 150,
                      showActions: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // File Info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accentCyan.withOpacity(0.1),
                      border: Border.all(color: AppColors.accentCyan, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        FileThumbnailWidget(
                          attachmentUrl: widget.attachmentUrl,
                          size: 40,
                          showBorder: false,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getFileTypeDisplay(widget.attachmentUrl!),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Tap to manage attachment',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: _showAttachmentOptions,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // No Attachment Section
            ListTile(
              leading: const Icon(
                Icons.add_photo_alternate,
                color: Colors.black,
              ),
              title: const Text(
                'Add Attachment',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              subtitle: const Text(
                'Tap to attach a photo or file',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.black,
              ),
              onTap: _isUploading ? null : _showAttachmentOptions,
            ),
          ],
        ],
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: Colors.black, width: 2),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.attachmentUrl != null) ...[
              _buildOptionTile(
                icon: Icons.visibility,
                title: 'View Attachment',
                onTap: _viewAttachment,
              ),
              const SizedBox(height: 8),
              _buildOptionTile(
                icon: Icons.delete,
                title: 'Remove Attachment',
                onTap: _removeAttachment,
                isDestructive: true,
              ),
              const SizedBox(height: 8),
            ],
            _buildOptionTile(
              icon: Icons.photo_library,
              title: 'Choose from Gallery',
              onTap: () => _attachFile('gallery'),
            ),
            const SizedBox(height: 8),
            _buildOptionTile(
              icon: Icons.camera_alt,
              title: 'Take Photo',
              onTap: () => _attachFile('camera'),
            ),
            const SizedBox(height: 8),
            _buildOptionTile(
              icon: Icons.attach_file,
              title: 'Choose File',
              onTap: () => _attachFile('file'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDestructive ? AppColors.danger : AppColors.surface,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.black),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.black,
        ),
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
      ),
    );
  }

  Future<void> _attachFile(String type) async {
    setState(() => _isUploading = true);

    try {
      File? file;

      switch (type) {
        case 'gallery':
          file = await _fileService.pickImageFromGallery();
          break;
        case 'camera':
          file = await _fileService.pickImageFromCamera();
          break;
        case 'file':
          file = await _fileService.pickFile();
          break;
      }

      if (file != null) {
        final url = await _fileService.uploadFile(file, widget.taskId);
        widget.onAttachmentChanged(url);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Attachment added successfully!'),
              backgroundColor: AppColors.accentGreen,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to attach file: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _removeAttachment() async {
    if (widget.attachmentUrl == null) return;

    setState(() => _isUploading = true);

    try {
      await _fileService.deleteFile(widget.attachmentUrl!);
      widget.onAttachmentChanged(null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attachment removed successfully!'),
            backgroundColor: AppColors.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove attachment: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _viewAttachment() {
    if (widget.attachmentUrl == null) return;

    // Handle local files
    if (widget.attachmentUrl!.startsWith('/') ||
        widget.attachmentUrl!.startsWith('file://')) {
      // For local files, we could show a file viewer or download dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Local file - will be uploaded to cloud when online'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Handle Supabase URLs - open in browser or show file viewer
    if (widget.attachmentUrl!.startsWith('http')) {
      // You can implement file viewing here
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Opening: ${widget.attachmentUrl!.split('/').last}'),
          backgroundColor: AppColors.accentGreen,
        ),
      );
      return;
    }
  }

  String _getFileTypeDisplay(String url) {
    try {
      // Handle local file paths
      if (url.startsWith('/') || url.startsWith('file://')) {
        final fileName = url.split('/').last;
        return _getFileTypeFromName(fileName);
      }

      // Handle Supabase URLs
      if (url.startsWith('http')) {
        final uri = Uri.parse(url);
        final fileName = uri.pathSegments.last;
        return _getFileTypeFromName(fileName);
      }

      // Handle other cases
      return 'File • ${url.split('/').last}';
    } catch (e) {
      print('Error parsing file URL: $e');
      return 'File • Unknown';
    }
  }

  String _getFileTypeFromName(String fileName) {
    if (fileName.toLowerCase().contains(
      RegExp(r'\.(jpg|jpeg|png|gif|bmp|webp)$'),
    )) {
      return 'Image • ${fileName.split('_').last}';
    } else if (fileName.toLowerCase().contains(
      RegExp(r'\.(pdf|doc|docx|txt)$'),
    )) {
      return 'Document • ${fileName.split('_').last}';
    } else {
      return 'File • ${fileName.split('_').last}';
    }
  }
}
