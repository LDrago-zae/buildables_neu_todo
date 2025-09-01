import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';
import 'package:uuid/uuid.dart';

class EnhancedFileService {
  static final EnhancedFileService _instance = EnhancedFileService._internal();
  factory EnhancedFileService() => _instance;
  EnhancedFileService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Check connectivity status
  Future<bool> get _isOnline async {
    final connectivity = Connectivity();
    final result = await connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // Get local storage directory
  Future<String> get _localStorageDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/task_attachments');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  // Get pending uploads directory
  Future<String> get _pendingUploadsDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/pending_uploads');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  // Main method to handle file storage (offline-first)
  Future<String?> storeFile(File file, String taskId) async {
    try {
      final isOnline = await _isOnline;
      final fileName =
          '${taskId}_${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';

      // Always store locally first
      final localPath = await _storeLocally(file, fileName);
      print('File stored locally: $localPath');

      if (isOnline) {
        // Online: upload to Supabase immediately
        try {
          final supabaseUrl = await _uploadToSupabase(file, fileName);
          print('File uploaded to Supabase: $supabaseUrl');

          // Update local metadata to mark as synced
          await _updateLocalMetadata(localPath, supabaseUrl, true);

          return supabaseUrl;
        } catch (e) {
          print('Supabase upload failed, will retry later: $e');
          // Mark for later upload
          await _markForPendingUpload(localPath, fileName);
          return localPath; // Return local path for now
        }
      } else {
        // Offline: mark for later upload
        await _markForPendingUpload(localPath, fileName);
        return localPath; // Return local path
      }
    } catch (e) {
      print('Error storing file: $e');
      return null;
    }
  }

  // Store file locally
  Future<String> _storeLocally(File file, String fileName) async {
    final storageDir = await _localStorageDir;
    final localPath = '$storageDir/$fileName';

    // Copy file to local storage
    await file.copy(localPath);

    // Create metadata file
    final metadata = {
      'originalPath': file.path,
      'fileName': fileName,
      'size': await file.length(),
      'mimeType': lookupMimeType(file.path) ?? 'application/octet-stream',
      'createdAt': DateTime.now().toIso8601String(),
      'isSynced': false,
      'supabaseUrl': null,
    };

    final metadataFile = File('$localPath.meta');
    await metadataFile.writeAsString(metadata.toString());

    return localPath;
  }

  // Upload to Supabase
  Future<String> _uploadToSupabase(File file, String fileName) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final filePath = 'task-attachments/$fileName';

    await _supabase.storage
        .from('task-files')
        .upload(
          filePath,
          file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    final publicUrl = _supabase.storage
        .from('task-files')
        .getPublicUrl(filePath);

    return publicUrl;
  }

  // Mark file for pending upload
  Future<void> _markForPendingUpload(String localPath, String fileName) async {
    final pendingDir = await _pendingUploadsDir;
    final pendingFile = File('$pendingDir/$fileName');

    // Create a reference to the local file
    final localFile = File(localPath);
    if (await localFile.exists()) {
      await localFile.copy(pendingFile.path);
      print('File marked for pending upload: $fileName');
    }
  }

  // Update local metadata
  Future<void> _updateLocalMetadata(
    String localPath,
    String? supabaseUrl,
    bool isSynced,
  ) async {
    final metadataFile = File('$localPath.meta');
    if (await metadataFile.exists()) {
      final metadata = {
        'originalPath': localPath,
        'fileName': path.basename(localPath),
        'size': await File(localPath).length(),
        'mimeType': lookupMimeType(localPath) ?? 'application/octet-stream',
        'createdAt': DateTime.now().toIso8601String(),
        'isSynced': isSynced,
        'supabaseUrl': supabaseUrl,
      };

      await metadataFile.writeAsString(metadata.toString());
    }
  }

  // Upload all pending files when coming back online
  Future<void> uploadPendingFiles() async {
    final isOnline = await _isOnline;
    if (!isOnline) return;

    final pendingDir = await _pendingUploadsDir;
    final pendingDirFile = Directory(pendingDir);

    if (!await pendingDirFile.exists()) return;

    final pendingFiles = await pendingDirFile.list().toList();
    final files = pendingFiles.whereType<File>().toList();
    print('Found ${files.length} pending files to upload');

    for (final pendingFile in files) {
      try {
        final fileName = path.basename(pendingFile.path);
        final supabaseUrl = await _uploadToSupabase(pendingFile, fileName);

        // Update local metadata
        final localPath = await _getLocalPathFromPending(fileName);
        if (localPath != null) {
          await _updateLocalMetadata(localPath, supabaseUrl, true);
        }

        // Remove from pending uploads
        await pendingFile.delete();
        print('Successfully uploaded pending file: $fileName');
      } catch (e) {
        print('Failed to upload pending file ${pendingFile.path}: $e');
        // Keep the file for retry later
      }
    }
  }

  // Get local path from pending file name
  Future<String?> _getLocalPathFromPending(String fileName) async {
    final storageDir = await _localStorageDir;
    final localPath = '$storageDir/$fileName';

    if (await File(localPath).exists()) {
      return localPath;
    }
    return null;
  }

  // Get file URL (local or remote)
  Future<String?> getFileUrl(String filePath) async {
    // Check if it's a local path
    if (filePath.startsWith('/')) {
      final file = File(filePath);
      if (await file.exists()) {
        return filePath;
      }
    }

    // Check if it's a Supabase URL
    if (filePath.startsWith('http')) {
      return filePath;
    }

    // Try to find in local storage
    final storageDir = await _localStorageDir;
    final localPath = '$storageDir/$filePath';
    final file = File(localPath);
    if (await file.exists()) {
      return localPath;
    }

    return null;
  }

  // Delete file from both local and remote storage
  Future<void> deleteFile(String filePath) async {
    try {
      // Delete from local storage
      final storageDir = await _localStorageDir;
      final localPath = '$storageDir/${path.basename(filePath)}';
      final localFile = File(localPath);
      final metadataFile = File('$localPath.meta');

      if (await localFile.exists()) {
        await localFile.delete();
      }
      if (await metadataFile.exists()) {
        await metadataFile.delete();
      }

      // Delete from pending uploads
      final pendingDir = await _pendingUploadsDir;
      final pendingPath = '$pendingDir/${path.basename(filePath)}';
      final pendingFile = File(pendingPath);
      if (await pendingFile.exists()) {
        await pendingFile.delete();
      }

      // Delete from Supabase if it's a remote URL
      if (filePath.startsWith('http')) {
        await _deleteFromSupabase(filePath);
      }
    } catch (e) {
      print('Error deleting file: $e');
    }
  }

  // Delete from Supabase
  Future<void> _deleteFromSupabase(String fileUrl) async {
    try {
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;
      final filePathIndex = pathSegments.indexOf('task-files');

      if (filePathIndex != -1 && filePathIndex < pathSegments.length - 1) {
        final filePath = pathSegments.sublist(filePathIndex + 1).join('/');
        await _supabase.storage.from('task-files').remove([filePath]);
        print('Deleted from Supabase: $filePath');
      }
    } catch (e) {
      print('Error deleting from Supabase: $e');
    }
  }

  // Get file info
  Future<Map<String, dynamic>?> getFileInfo(String filePath) async {
    try {
      final storageDir = await _localStorageDir;
      final localPath = '$storageDir/${path.basename(filePath)}';
      final metadataFile = File('$localPath.meta');

      if (await metadataFile.exists()) {
        final metadataContent = await metadataFile.readAsString();
        // Parse the metadata string (you might want to use JSON instead)
        return _parseMetadata(metadataContent);
      }

      return null;
    } catch (e) {
      print('Error getting file info: $e');
      return null;
    }
  }

  // Parse metadata string (simple implementation)
  Map<String, dynamic> _parseMetadata(String metadataString) {
    // This is a simple parser - you might want to use JSON instead
    final metadata = <String, dynamic>{};
    final lines = metadataString.split(',');

    for (final line in lines) {
      if (line.contains(':')) {
        final parts = line.split(':');
        if (parts.length >= 2) {
          final key = parts[0].trim().replaceAll('{', '').replaceAll('}', '');
          final value = parts[1].trim().replaceAll('{', '').replaceAll('}', '');
          metadata[key] = value;
        }
      }
    }

    return metadata;
  }

  // Check if file is synced
  Future<bool> isFileSynced(String filePath) async {
    final info = await getFileInfo(filePath);
    return info?['isSynced'] == 'true';
  }

  // Get all pending uploads
  Future<List<File>> getPendingUploads() async {
    final pendingDir = await _pendingUploadsDir;
    final pendingDirFile = Directory(pendingDir);

    if (!await pendingDirFile.exists()) return [];

    return (await pendingDirFile.list().toList()).whereType<File>().toList();
  }

  // Clear all pending uploads (for testing)
  Future<void> clearPendingUploads() async {
    final pendingFiles = await getPendingUploads();
    for (final file in pendingFiles) {
      await file.delete();
    }
    print('Cleared ${pendingFiles.length} pending uploads');
  }
}
