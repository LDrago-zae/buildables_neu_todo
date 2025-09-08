import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  // Check if Supabase is actually reachable
  Future<bool> get isSupabaseReachable async {
    if (!await isOnline) return false;

    try {
      // Try a simple query to test connectivity
      await _supabase.from('todos').select('id').limit(1);
      return true;
    } catch (e) {
      print('Supabase not reachable: $e');
      return false;
    }
  }

  // Get all tasks with offline support
  Future<List<Task>> getAllTasks() async {
    final connectivity = await _connectivity.checkConnectivity();
    final isOnline = connectivity != ConnectivityResult.none;
    final supabaseReachable = await isSupabaseReachable;

    print('=== GETTING TASKS ===');
    print('Online: $isOnline, Supabase reachable: $supabaseReachable');

    if (supabaseReachable) {
      try {
        // Online: sync with Supabase and return merged data
        await _syncWithSupabase();
        final remoteTasks = await _getRemoteTasks();
        await _syncToLocal(remoteTasks);
        return remoteTasks;
      } catch (e) {
        print('Online sync failed, falling back to local: $e');
        return await _getLocalTasks();
      }
    } else {
      // Offline or Supabase not reachable: return local tasks only
      print('Offline mode or Supabase not reachable: returning local tasks');
      return await _getLocalTasks();
    }
  }

  // Get local tasks
  Future<List<Task>> _getLocalTasks() async {
    final query = await (_localDb.select(
      _localDb.todos,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
    return query
        .map(
          (row) => Task(
            id: row.id,
            title: row.title,
            done: row.done,
            category: row.category,
            color: row.color,
            icon: row.icon,
            createdAt: row.createdAt,
            updatedAt: row.updatedAt,
            createdBy: row.createdBy,
            sharedWith: row.sharedWith,
            attachmentUrl: row.attachmentUrl,
          ),
        )
        .toList();
  }

  // Get remote tasks from Supabase
  Future<List<Task>> _getRemoteTasks() async {
    final response = await _supabase
        .from('todos')
        .select()
        .order('created_at', ascending: false);
    return (response as List)
        .map((row) => Task.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  // Sync local changes to Supabase
  Future<void> _syncWithSupabase() async {
    try {
      // Get local tasks that need syncing
      final localTasks = await _localDb.select(_localDb.todos).get();
      final unsyncedTasks = localTasks.where((task) => !task.isSynced).toList();

      print('Found ${unsyncedTasks.length} unsynced tasks');

      for (final localTask in unsyncedTasks) {
        try {
          // Check if task exists remotely
          final remoteTask = await _supabase
              .from('todos')
              .select()
              .eq('id', localTask.id)
              .maybeSingle();

          if (remoteTask == null) {
            // Task doesn't exist remotely, create it
            await _supabase.from('todos').insert({
              'id': localTask.id,
              'title': localTask.title,
              'done': localTask.done,
              'category': localTask.category,
              'color': localTask.color,
              'icon': localTask.icon,
              'created_by': localTask.createdBy,
              'attachment_url': localTask.attachmentUrl,
              'created_at': localTask.createdAt.toIso8601String(),
              'updated_at': localTask.updatedAt.toIso8601String(),
            });
          } else {
            // Task exists, update it
            await _supabase
                .from('todos')
                .update({
                  'title': localTask.title,
                  'done': localTask.done,
                  'category': localTask.category,
                  'color': localTask.color,
                  'icon': localTask.icon,
                  'attachment_url': localTask.attachmentUrl,
                  'updated_at': localTask.updatedAt.toIso8601String(),
                })
                .eq('id', localTask.id);
          }

          // Mark as synced
          await (_localDb.update(_localDb.todos)
                ..where((t) => t.id.equals(localTask.id)))
              .write(TodosCompanion(isSynced: Value(true)));
        } catch (e) {
          print('Error syncing task ${localTask.id}: $e');
        }
      }

      print('Supabase sync completed');
    } catch (e) {
      print('Error during Supabase sync: $e');
      rethrow;
    }
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
                color: Value(task.color),
                icon: Value(task.icon),
                done: Value(task.done),
                createdAt: Value(task.createdAt ?? DateTime.now()),
                updatedAt: Value(task.updatedAt ?? DateTime.now()),
                createdBy: task.createdBy ?? '',
                sharedWith: Value(task.sharedWith),
                attachmentUrl: Value(task.attachmentUrl),
                isSynced: const Value(true),
              ),
            );
      }
    });
  }

  // Add task with offline support
  Future<Task> addTask(Task task) async {
    final connectivity = await _connectivity.checkConnectivity();
    final isOnline = connectivity != ConnectivityResult.none;
    final supabaseReachable = await isSupabaseReachable;

    print(
      'Adding task: ${task.title}, Online: $isOnline, Supabase reachable: $supabaseReachable',
    );

    // Always save to local database first
    await _localDb
        .into(_localDb.todos)
        .insert(
          TodosCompanion.insert(
            id: Value(task.id),
            title: task.title,
            category: task.category ?? '',
            color: Value(task.color),
            icon: Value(task.icon),
            done: Value(task.done),
            createdAt: Value(task.createdAt ?? DateTime.now()),
            updatedAt: Value(task.updatedAt ?? DateTime.now()),
            createdBy: task.createdBy ?? '',
            sharedWith: Value(task.sharedWith),
            attachmentUrl: Value(task.attachmentUrl),
            isSynced: Value(
              supabaseReachable,
            ), // Mark as synced only if Supabase is reachable
          ),
        );

    if (supabaseReachable) {
      try {
        // Also save to Supabase
        await _supabase.from('todos').insert({
          'id': task.id,
          'title': task.title,
          'done': task.done,
          'category': task.category,
          'color': task.color,
          'icon': task.icon,
          'created_by': task.createdBy,
          'attachment_url': task.attachmentUrl,
          'created_at': task.createdAt?.toIso8601String(),
          'updated_at': task.updatedAt?.toIso8601String(),
        });
        print('Task saved to Supabase');
      } catch (e) {
        print('Failed to save to Supabase: $e');
        // Task is still saved locally, will sync later
      }
    }

    return task;
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
    if (!await isSupabaseReachable) {
      print('Supabase not reachable, skipping sync');
      return;
    }

    try {
      // Get unsynced tasks
      final unsyncedQuery = await (_localDb.select(
        _localDb.todos,
      )..where((t) => t.isSynced.equals(false))).get();

      print('Found ${unsyncedQuery.length} unsynced tasks to sync');

      for (final localTask in unsyncedQuery) {
        try {
          // Check if task already exists in Supabase
          final existingTask = await _supabase
              .from('todos')
              .select('id')
              .eq('id', localTask.id)
              .maybeSingle();

          final taskData = {
            'id': localTask.id,
            'title': localTask.title,
            'category': localTask.category,
            'color': localTask.color,
            'icon': localTask.icon,
            'done': localTask.done,
            'created_by': localTask.createdBy,
            'created_at': localTask.createdAt.toIso8601String(),
            'updated_at': localTask.updatedAt.toIso8601String(),
            'shared_with': localTask.sharedWith,
            'attachment_url': localTask.attachmentUrl,
          };

          if (existingTask != null) {
            // Update existing task
            await _supabase
                .from('todos')
                .update(taskData)
                .eq('id', localTask.id);
          } else {
            // Insert new task
            await _supabase.from('todos').insert(taskData);
          }

          // Mark as synced
          await (_localDb.update(_localDb.todos)
                ..where((t) => t.id.equals(localTask.id)))
              .write(const TodosCompanion(isSynced: Value(true)));

          print('Successfully synced task: ${localTask.title}');
        } catch (e) {
          print('Error syncing task ${localTask.id}: $e');
          // Skip this task and continue with others
          continue;
        }
      }

      print('Sync completed successfully');
    } catch (e) {
      print('Error during sync: $e');
      // Sync failed, will retry later
    }
  }

  // Dispose resources
  Future<void> dispose() async {
    await _localDb.close();
  }
}
