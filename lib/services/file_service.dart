import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FileService {
  final _supabase = Supabase.instance.client;
  final _imagePicker = ImagePicker();

  // Check if user is authenticated
  bool get isAuthenticated => _supabase.auth.currentUser != null;

  Future<String?> uploadFile(File file, String taskId) async {
    try {
      // Check authentication first
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final user = _supabase.auth.currentUser!;

      // Debug info
      debugAuth();

      final fileName =
          '${user.id}_${taskId}_${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final filePath = 'task-attachments/$fileName';

      print('=== UPLOAD DEBUG INFO ===');
      print('Uploading file to: $filePath');
      print('User ID: ${user.id}');
      print('User Email: ${user.email}');
      print('File path: ${file.path}');
      print('File exists: ${await file.exists()}');
      print('File size: ${await file.length()} bytes');
      print('Bucket: task-files');
      print('========================');

      // Test bucket access first
      try {
        print('Testing bucket access...');
        final bucketFiles = await _supabase.storage.from('task-files').list();
        print('Bucket access successful: ${bucketFiles.length} files found');
      } catch (bucketError) {
        print('Bucket access error: $bucketError');
        throw Exception('Cannot access bucket: $bucketError');
      }

      // Try the upload
      print('Starting upload...');
      final uploadResult = await _supabase.storage
          .from('task-files')
          .upload(
            filePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      print('Upload result: $uploadResult');

      final publicUrl = _supabase.storage
          .from('task-files')
          .getPublicUrl(filePath);
      print('Public URL generated: $publicUrl');

      return publicUrl;
    } catch (e) {
      print('=== UPLOAD ERROR ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      if (e is StorageException) {
        print('Storage error details:');
        print('- Message: ${e.message}');
        print('- Status Code: ${e.statusCode}');
        print('- Error: ${e.error}');
      }
      print('===================');
      rethrow;
    }
  }

  Future<bool> deleteFile(String fileUrl) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      // Extract file path from URL
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;
      final filePathIndex = pathSegments.indexOf('task-files');

      if (filePathIndex != -1 && filePathIndex < pathSegments.length - 1) {
        final filePath = pathSegments
            .sublist(filePathIndex + 1)
            .join('/'); // Skip 'task-files'
        print('Deleting file: $filePath');

        await _supabase.storage.from('task-files').remove([filePath]);
        print('Delete successful');
        return true;
      }
      throw Exception('Invalid file URL format');
    } catch (e) {
      print('Delete error: $e');
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
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.first;

        if (pickedFile.path != null) {
          return File(pickedFile.path!);
        } else if (pickedFile.bytes != null) {
          final tempFile = File(
            '${Directory.systemTemp.path}/${pickedFile.name}',
          );
          await tempFile.writeAsBytes(pickedFile.bytes!);
          return tempFile;
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

  String getFileIcon(String filePath) {
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

  // Debug method to check authentication
  void debugAuth() {
    final user = _supabase.auth.currentUser;
    final session = _supabase.auth.currentSession;

    print('=== AUTH DEBUG ===');
    print('- User ID: ${user?.id}');
    print('- Email: ${user?.email}');
    print('- Authenticated: $isAuthenticated');
    print('- Session valid: ${session != null}');
    print('- Access token exists: ${session?.accessToken != null}');
    print('- Token expires: ${session?.expiresAt}');
    print('==================');
  }

  // Test bucket connectivity
  Future<void> testBucketAccess() async {
    try {
      debugAuth();

      print('Testing bucket access...');
      final files = await _supabase.storage.from('task-files').list();
      print('✅ Bucket access successful: ${files.length} files found');

      // Try to get bucket info
      final buckets = await _supabase.storage.listBuckets();
      final taskFilesBucket = buckets.firstWhere(
        (b) => b.id == 'task-files',
        orElse: () => throw Exception('task-files bucket not found'),
      );
      print(
        '✅ Bucket found: ${taskFilesBucket.name}, Public: ${taskFilesBucket.public}',
      );
    } catch (e) {
      print('❌ Bucket test failed: $e');
      rethrow;
    }
  }

  Future<void> debugDatabaseSchema() async {
    try {
      print('=== DATABASE SCHEMA DEBUG ===');

      // Check if the attachment_url column exists
      final result = await _supabase
          .from('todos')
          .select('id, title, attachment_url, created_by, updated_at')
          .limit(1);

      print('Database columns available: ${result.first.keys.toList()}');
      print('Sample task data: ${result.first}');

      // Check if there are any tasks with attachments
      final tasksWithAttachments = await _supabase
          .from('todos')
          .select('id, title, attachment_url')
          .not('attachment_url', 'is', null);

      print('Tasks with attachments: ${tasksWithAttachments.length}');
      for (final task in tasksWithAttachments) {
        print(
          '- Task: ${task['title']}, Attachment: ${task['attachment_url']}',
        );
      }

      print('============================');
    } catch (e) {
      print('Database schema debug error: $e');
    }
  }
}
