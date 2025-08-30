import 'package:buildables_neu_todo/models/task.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TaskController extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;
  final List<Task> _tasks;
  RealtimeChannel? _channel;

  TaskController({List<Task>? initial})
    : _tasks = List<Task>.from(initial ?? const <Task>[]) {
    _initRealtime();
    _fetchAll();
  }

  List<Task> get tasks => List.unmodifiable(_tasks);

  int get completedCount => _tasks.where((t) => t.done).length;
  int get pendingCount => _tasks.length - completedCount;

  Future<void> _fetchAll() async {
    try {
      final response = await _client
          .from('todos')
          .select()
          .order('created_at', ascending: false);
      final fetched = (response as List)
          .map((row) => Task.fromMap(row as Map<String, dynamic>))
          .toList();
      _tasks
        ..clear()
        ..addAll(fetched);
      notifyListeners();
    } catch (e) {
      try {
        final response = await _client.from('todos').select();
        final fetched = (response as List)
            .map((row) => Task.fromMap(row as Map<String, dynamic>))
            .toList();
        _tasks
          ..clear()
          ..addAll(fetched);
        notifyListeners();
      } catch (e2) {
        debugPrint('Failed to fetch tasks: $e2');
      }
    }
  }

  void _initRealtime() {
    _channel?.unsubscribe();
    _channel = _client.channel('public:todos')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'todos',
        callback: (payload) {
          final newRow = payload.newRecord;
          _tasks.insert(0, Task.fromMap(newRow));
          notifyListeners();
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'todos',
        callback: (payload) {
          final newRow = payload.newRecord;
          final updated = Task.fromMap(newRow);
          final idx = _tasks.indexWhere((t) => t.id == updated.id);
          if (idx != -1) {
            _tasks[idx] = updated;
            notifyListeners();
          }
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'todos',
        callback: (payload) {
          final oldRow = payload.oldRecord;
          final id = oldRow['id']?.toString();
          _tasks.removeWhere((t) => t.id == id);
          notifyListeners();
        },
      )
      ..subscribe();
  }

  Future<void> addTask(String title, {String? category}) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');
      final insertedList = await _client.from('todos').insert({
        'title': title,
        'done': false,
        'category': category,
        'created_by': user.id, // Add this line
      }).select();
      if (insertedList.isNotEmpty) {
        final inserted = Task.fromMap(insertedList.first);
        final existingIndex = _tasks.indexWhere((t) => t.id == inserted.id);
        if (existingIndex == -1) {
          _tasks.insert(0, inserted);
          notifyListeners();
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleTask(int index) async {
    final task = _tasks[index];
    try {
      await _client
          .from('todos')
          .update({'done': !task.done})
          .eq('id', task.id);
      _tasks[index] = task.copyWith(done: !task.done);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateTask(int index, {String? title, String? category}) async {
    final task = _tasks[index];
    try {
      await _client
          .from('todos')
          .update({
            if (title != null) 'title': title,
            if (category != null) 'category': category,
          })
          .eq('id', task.id);
      _tasks[index] = task.copyWith(
        title: title ?? task.title,
        category: category ?? task.category,
      );
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTask(int index) async {
    final task = _tasks[index];
    try {
      await _client.from('todos').delete().eq('id', task.id);
      _tasks.removeAt(index);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Collaboration features
  Future<void> shareTask(String taskId, String email) async {
    try {
      // First, get the user by email
      final userQuery = await _client
          .from('profiles')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      if (userQuery == null) {
        throw Exception('User with email $email not found');
      }

      final userId = userQuery['id'] as String;

      // Get current task
      final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
      if (taskIndex == -1) throw Exception('Task not found');

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
      }
    } catch (e) {
      rethrow;
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

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
