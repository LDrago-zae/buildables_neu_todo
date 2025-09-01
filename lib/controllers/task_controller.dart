import 'dart:io';
import 'package:buildables_neu_todo/models/task.dart';
import 'package:buildables_neu_todo/services/enhanced_file_service.dart';
import 'package:buildables_neu_todo/repository/task_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';

class TaskController extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;
  final TaskRepository _repository = TaskRepository();
  final EnhancedFileService _fileService = EnhancedFileService();
  final List<Task> _tasks;
  RealtimeChannel? _channel;

  TaskController({List<Task>? initial})
    : _tasks = List<Task>.from(initial ?? const <Task>[]) {
    _fetchAll();
    _initRealtimeAsync();
  }

  void _initRealtimeAsync() async {
    await _initRealtime();
  }

  List<Task> get tasks => List.unmodifiable(_tasks);
  int get completedCount => _tasks.where((t) => t.done).length;
  int get pendingCount => _tasks.length - completedCount;

  // Check if app is online and Supabase is reachable
  Future<bool> get isOnline async => await _repository.isSupabaseReachable;

  // Refresh data from both Supabase and local database
  Future<void> refreshData() async {
    try {
      await _fetchAll();
    } catch (e) {
      debugPrint('Failed to refresh data: $e');
      rethrow;
    }
  }

  Future<void> _fetchAll() async {
    try {
      final fetched = await _repository.getAllTasks();
      _tasks
        ..clear()
        ..addAll(fetched);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to fetch tasks: $e');
    }
  }

  Future<void> _initRealtime() async {
    _channel?.unsubscribe();

    // Only set up realtime subscriptions if Supabase is reachable
    final isReachable = await _repository.isSupabaseReachable;
    if (!isReachable) {
      print('Supabase not reachable, skipping realtime subscriptions');
      return;
    }

    _channel = _client.channel('public:todos')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'todos',
        callback: (payload) async {
          await _repository.syncPendingChanges();
          await _fetchAll();
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'todos',
        callback: (payload) async {
          await _repository.syncPendingChanges();
          await _fetchAll();
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'todos',
        callback: (payload) async {
          await _repository.syncPendingChanges();
          await _fetchAll();
        },
      )
      ..subscribe();
  }

  Future<void> addTask(String title, {String? category}) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final taskId = const Uuid().v4();
      final newTask = Task(
        id: taskId,
        title: title,
        category: category,
        createdBy: user.id,
        done: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final addedTask = await _repository.addTask(newTask);

      final existingIndex = _tasks.indexWhere((t) => t.id == addedTask.id);
      if (existingIndex == -1) {
        _tasks.insert(0, addedTask);
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addTaskWithAttachment({
    required String title,
    String? category,
    File? attachmentFile,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final taskId = const Uuid().v4();
      String? attachmentUrl;

      // Store file using enhanced file service (handles offline/online automatically)
      if (attachmentFile != null) {
        attachmentUrl = await _fileService.storeFile(attachmentFile, taskId);
        print('File stored: $attachmentUrl');
      }

      // Create task with repository
      final newTask = Task(
        id: taskId,
        title: title,
        category: category,
        createdBy: user.id,
        done: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final addedTask = await _repository.addTask(newTask);

      // Update attachment if stored
      if (attachmentUrl != null) {
        final updatedTask = addedTask.copyWith(attachmentUrl: attachmentUrl);
        await _repository.updateTask(updatedTask);

        final index = _tasks.indexWhere((t) => t.id == addedTask.id);
        if (index != -1) {
          _tasks[index] = updatedTask;
          notifyListeners();
        }
      } else {
        final existingIndex = _tasks.indexWhere((t) => t.id == addedTask.id);
        if (existingIndex == -1) {
          _tasks.insert(0, addedTask);
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error adding task with attachment: $e');
      rethrow;
    }
  }

  Future<void> toggleTask(int index) async {
    final task = _tasks[index];
    try {
      final updatedTask = task.copyWith(done: !task.done);
      await _repository.updateTask(updatedTask);

      _tasks[index] = updatedTask;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateTask(int index, {String? title, String? category}) async {
    final task = _tasks[index];
    try {
      final updatedTask = task.copyWith(
        title: title ?? task.title,
        category: category ?? task.category,
      );

      await _repository.updateTask(updatedTask);
      _tasks[index] = updatedTask;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTask(int index) async {
    final task = _tasks[index];
    try {
      // Delete associated file if exists
      if (task.hasAttachment) {
        await _fileService.deleteFile(task.attachmentUrl!);
      }

      await _repository.deleteTask(task.id);
      _tasks.removeAt(index);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Upload pending files when coming back online
  Future<void> uploadPendingFiles() async {
    try {
      await _fileService.uploadPendingFiles();
      print('Pending files upload completed');
    } catch (e) {
      print('Error uploading pending files: $e');
    }
  }

  // Get user email by ID
  Future<String> getUserEmail(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select('email')
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        return response['email'] as String;
      }
      return 'Unknown User';
    } catch (e) {
      print('Error fetching user email: $e');
      return 'Unknown User';
    }
  }

  // Collaboration features
  Future<String?> shareTask(String taskId, String email) async {
    try {
      // First, get the user by email
      final userQuery = await _client
          .from('profiles')
          .select('id')
          .eq('email', email.trim().toLowerCase())
          .maybeSingle();

      if (userQuery == null) {
        debugPrint(
          'Share failed: User with email $email not found in profiles table.',
        );
        return 'User with email $email not found. Please ensure they have an account and the email is correct.';
      }

      final userId = userQuery['id'] as String;

      // Get current task
      final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
      if (taskIndex == -1) return 'Task not found';

      final task = _tasks[taskIndex];
      final currentSharedWith = task.sharedWith ?? [];

      if (!currentSharedWith.contains(userId)) {
        final updatedSharedWith = [...currentSharedWith, userId];

        await _client
            .from('todos')
            .update({
              'shared_with': updatedSharedWith,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', taskId);

        // Update local state
        _tasks[taskIndex] = task.copyWith(sharedWith: updatedSharedWith);
        notifyListeners();
      } else {
        return 'Task is already shared with this user';
      }

      return null; // Success
    } catch (e) {
      // Log detailed error for debugging in terminal
      debugPrint('Failed to share task for taskId=$taskId to email=$email: $e');
      return 'Failed to share task: ${e.toString()}';
    }
  }

  Future<void> unshareTask(String taskId, String userId) async {
    try {
      final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
      if (taskIndex == -1) throw Exception('Task not found');

      final task = _tasks[taskIndex];
      final currentSharedWith = task.sharedWith ?? [];
      final updatedSharedWith = currentSharedWith
          .where((id) => id != userId)
          .toList();

      await _client
          .from('todos')
          .update({
            'shared_with': updatedSharedWith,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', taskId);

      // Update local state
      _tasks[taskIndex] = task.copyWith(sharedWith: updatedSharedWith);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateTaskAttachment(
    String taskId,
    String? attachmentUrl,
  ) async {
    try {
      await _client
          .from('todos')
          .update({
            'attachment_url': attachmentUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', taskId);

      // Update local state
      final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
      if (taskIndex != -1) {
        _tasks[taskIndex] = _tasks[taskIndex].copyWith(
          attachmentUrl: attachmentUrl,
        );
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get shared tasks
  List<Task> get sharedTasks {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return [];

    return _tasks
        .where(
          (task) =>
              task.sharedWith?.contains(currentUserId) == true &&
              task.createdBy != currentUserId,
        )
        .toList();
  }

  // Get owned tasks
  List<Task> get ownedTasks {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return [];

    return _tasks.where((task) => task.createdBy == currentUserId).toList();
  }

  void handleConnectivityChange(ConnectivityResult result) {
    if (result != ConnectivityResult.none) {
      // Coming back online - upload pending files
      uploadPendingFiles();
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
