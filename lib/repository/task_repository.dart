import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../models/task.dart';

class TaskRepository {
  static final TaskRepository _instance = TaskRepository._internal();
  factory TaskRepository() => _instance;
  TaskRepository._internal();

  late AppDatabase _localDb;
  late SupabaseClient _supabase;
  late Connectivity _connectivity;

  void initialize({
    required SupabaseClient supabase,
    required Connectivity connectivity,
  }) {
    _localDb = AppDatabase();
    _supabase = supabase;
    _connectivity = connectivity;
  }

  // Check connectivity status
  Future<bool> get isOnline async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // Get all tasks with offline support
  Future<List<Task>> getAllTasks() async {
    if (await isOnline) {
      try {
        // Online: sync with Supabase
        final response = await _supabase
            .from('todos')
            .select()
            .order('created_at', ascending: false);

        final tasks = (response as List)
            .map((row) => Task.fromMap(row as Map<String, dynamic>))
            .toList();

        // Update local database
        await _syncToLocal(tasks);
        return tasks;
      } catch (e) {
        // Fall back to local data on error
        return await _getLocalTasks();
      }
    } else {
      // Offline: use local database
      return await _getLocalTasks();
    }
  }

  // Get local tasks
  Future<List<Task>> _getLocalTasks() async {
    final query = await _localDb.select(_localDb.todos).get();
    return query
        .map(
          (row) => Task(
            id: row.id,
            title: row.title,
            done: row.done,
            category: row.category,
            createdAt: row.createdAt,
            updatedAt: row.updatedAt,
            createdBy: row.createdBy,
            sharedWith: row.sharedWith,
            attachmentUrl: row.attachmentUrl,
          ),
        )
        .toList();
  }

  // Sync Supabase data to local database
  Future<void> _syncToLocal(List<Task> tasks) async {
    await _localDb.transaction(() async {
      // Clear existing data
      await _localDb.delete(_localDb.todos).go();

      // Insert new data
      for (final task in tasks) {
        await _localDb
            .into(_localDb.todos)
            .insert(
              TodosCompanion.insert(
                id: Value(task.id),
                title: task.title,
                category: task.category ?? '',
                createdBy: task.createdBy ?? '',
                done: Value(task.done),
                createdAt: Value(task.createdAt ?? DateTime.now()),
                updatedAt: Value(task.updatedAt ?? DateTime.now()),
                sharedWith: Value(task.sharedWith),
                attachmentUrl: Value(task.attachmentUrl),
                color: Value(task.category),
                icon: const Value('task'),
                isSynced: const Value(true),
              ),
            );
      }
    });
  }

  // Add task with offline support
  Future<Task> addTask({
    required String title,
    String? category,
    String? createdBy,
  }) async {
    final taskId = const Uuid().v4();
    final task = Task(
      id: taskId,
      title: title,
      category: category,
      createdBy: createdBy,
    );

    if (await isOnline) {
      try {
        // Online: add to Supabase
        final response = await _supabase
            .from('todos')
            .insert({
              'id': taskId,
              'title': title,
              'category': category,
              'created_by': createdBy,
              'done': false,
              'created_at': task.createdAt!.toIso8601String(),
              'updated_at': task.updatedAt!.toIso8601String(),
            })
            .select()
            .single();

        final createdTask = Task.fromMap(response);
        await _addToLocal(createdTask, isSynced: true);
        return createdTask;
      } catch (e) {
        // Offline: add to local only
        await _addToLocal(task, isSynced: false);
        return task;
      }
    } else {
      // Offline: add to local only
      await _addToLocal(task, isSynced: false);
      return task;
    }
  }

  // Add task to local database
  Future<void> _addToLocal(Task task, {required bool isSynced}) async {
    await _localDb
        .into(_localDb.todos)
        .insert(
          TodosCompanion.insert(
            id: Value(task.id),
            title: task.title,
            category: task.category ?? '',
            createdBy: task.createdBy ?? '',
            done: Value(task.done),
            createdAt: Value(task.createdAt ?? DateTime.now()),
            updatedAt: Value(task.updatedAt ?? DateTime.now()),
            sharedWith: Value(task.sharedWith),
            attachmentUrl: Value(task.attachmentUrl),
            color: Value(task.category),
            icon: const Value('task'),
            isSynced: Value(isSynced),
          ),
        );
  }

  // Update task with offline support
  Future<Task> updateTask(Task task) async {
    final updatedTask = task.copyWith(updatedAt: DateTime.now());

    if (await isOnline) {
      try {
        // Online: update in Supabase
        await _supabase
            .from('todos')
            .update({
              'title': updatedTask.title,
              'done': updatedTask.done,
              'category': updatedTask.category,
              'updated_at': updatedTask.updatedAt!.toIso8601String(),
              'shared_with': updatedTask.sharedWith,
              'attachment_url': updatedTask.attachmentUrl,
            })
            .eq('id', task.id);

        await _updateLocal(updatedTask, isSynced: true);
        return updatedTask;
      } catch (e) {
        // Offline: update local only
        await _updateLocal(updatedTask, isSynced: false);
        return updatedTask;
      }
    } else {
      // Offline: update local only
      await _updateLocal(updatedTask, isSynced: false);
      return updatedTask;
    }
  }

  // Update task in local database
  Future<void> _updateLocal(Task task, {required bool isSynced}) async {
    await (_localDb.update(
      _localDb.todos,
    )..where((t) => t.id.equals(task.id))).write(
      TodosCompanion(
        title: Value(task.title),
        done: Value(task.done),
        category: Value(task.category ?? ''),
        updatedAt: Value(task.updatedAt ?? DateTime.now()),
        sharedWith: Value(task.sharedWith),
        attachmentUrl: Value(task.attachmentUrl),
        isSynced: Value(isSynced),
      ),
    );
  }

  // Delete task with offline support
  Future<void> deleteTask(String taskId) async {
    if (await isOnline) {
      try {
        // Online: delete from Supabase
        await _supabase.from('todos').delete().eq('id', taskId);
        await _deleteLocal(taskId);
      } catch (e) {
        // Offline: mark for deletion
        await _markForDeletion(taskId);
      }
    } else {
      // Offline: mark for deletion
      await _markForDeletion(taskId);
    }
  }

  // Delete from local database
  Future<void> _deleteLocal(String taskId) async {
    await (_localDb.delete(
      _localDb.todos,
    )..where((t) => t.id.equals(taskId))).go();
  }

  // Mark task for deletion (when offline)
  Future<void> _markForDeletion(String taskId) async {
    // For now, just delete locally
    // In a more robust implementation, you might add a 'deleted' flag
    await _deleteLocal(taskId);
  }

  // Sync unsynced local changes when coming back online
  Future<void> syncPendingChanges() async {
    if (!await isOnline) return;

    try {
      // Get unsynced tasks
      final unsyncedQuery = await (_localDb.select(
        _localDb.todos,
      )..where((t) => t.isSynced.equals(false))).get();

      for (final localTask in unsyncedQuery) {
        try {
          // Try to sync each task
          await _supabase.from('todos').upsert({
            'id': localTask.id,
            'title': localTask.title,
            'category': localTask.category,
            'done': localTask.done,
            'created_by': localTask.createdBy,
            'created_at': localTask.createdAt.toIso8601String(),
            'updated_at': localTask.updatedAt.toIso8601String(),
            'shared_with': localTask.sharedWith,
            'attachment_url': localTask.attachmentUrl,
          });

          // Mark as synced
          await (_localDb.update(_localDb.todos)
                ..where((t) => t.id.equals(localTask.id)))
              .write(const TodosCompanion(isSynced: Value(true)));
        } catch (e) {
          // Skip this task and continue with others
          continue;
        }
      }
    } catch (e) {
      // Sync failed, will retry later
    }
  }

  // Dispose resources
  Future<void> dispose() async {
    await _localDb.close();
  }
}
