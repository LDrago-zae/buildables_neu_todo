import 'dart:io';
import 'package:flutter/material.dart';
import 'package:buildables_neu_todo/core/app_colors.dart';
import 'package:buildables_neu_todo/services/file_service.dart';

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
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.accentYellow,
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'ADD ATTACHMENT',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildOptionTile(
              icon: Icons.photo_library,
              title: 'Choose from Gallery',
              onTap: () => _attachFile('gallery'),
            ),
            const SizedBox(height: 12),
            _buildOptionTile(
              icon: Icons.camera_alt,
              title: 'Take Photo',
              onTap: () => _attachFile('camera'),
            ),
            const SizedBox(height: 12),
            _buildOptionTile(
              icon: Icons.insert_drive_file,
              title: 'Choose File',
              onTap: () => _attachFile('file'),
            ),
            if (widget.attachmentUrl != null) ...[
              const SizedBox(height: 12),
              _buildOptionTile(
                icon: Icons.delete,
                title: 'Remove Attachment',
                onTap: _removeAttachment,
                isDestructive: true,
              ),
            ],
            const SizedBox(height: 20),
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
            SnackBar(
              content: const Text('Attachment added successfully!'),
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
          SnackBar(
            content: const Text('Attachment removed successfully!'),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          widget.attachmentUrl != null
              ? Icons.attach_file
              : Icons.add_photo_alternate,
          color: Colors.black,
        ),
        title: Text(
          widget.attachmentUrl != null ? 'View Attachment' : 'Add Attachment',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        subtitle: widget.attachmentUrl != null
            ? Text(
                _getFileTypeDisplay(widget.attachmentUrl!),
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              )
            : const Text(
                'Tap to attach a photo or file',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
        trailing: _isUploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
            : const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.black,
              ),
        onTap: _isUploading ? null : _showAttachmentOptions,
      ),
    );
  }

  String _getFileTypeDisplay(String url) {
    final uri = Uri.parse(url);
    final fileName = uri.pathSegments.last;

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
