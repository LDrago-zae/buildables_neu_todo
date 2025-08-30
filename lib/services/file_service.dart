import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FileService {
  final _supabase = Supabase.instance.client;
  final _imagePicker = ImagePicker();

  Future<String?> uploadFile(File file, String taskId) async {
    try {
      final fileName =
          '${taskId}_${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final filePath = 'task-attachments/$fileName';

      await _supabase.storage.from('task-files').upload(filePath, file);
      return _supabase.storage.from('task-files').getPublicUrl(filePath);
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  Future<bool> deleteFile(String fileUrl) async {
    try {
      // Extract file path from URL
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;
      final filePathIndex = pathSegments.indexOf('task-files');

      if (filePathIndex != -1 && filePathIndex < pathSegments.length - 1) {
        final filePath = pathSegments.sublist(filePathIndex).join('/');
        await _supabase.storage.from('task-files').remove([filePath]);
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to take photo: $e');
    }
  }

  Future<File?> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          return File(file.path!);
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick file: $e');
    }
  }

  String getFileExtension(String filePath) {
    return filePath.split('.').last.toLowerCase();
  }

  bool isImageFile(String filePath) {
    final extension = getFileExtension(filePath);
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }

  String getFileTypeIcon(String filePath) {
    final extension = getFileExtension(filePath);

    switch (extension) {
      case 'pdf':
        return '📄';
      case 'doc':
      case 'docx':
        return '📝';
      case 'txt':
        return '📄';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return '🖼️';
      default:
        return '📎';
    }
  }

  String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
