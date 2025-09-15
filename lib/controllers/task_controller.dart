import 'dart:io';
import 'package:buildables_neu_todo/models/task.dart';
import 'package:buildables_neu_todo/services/enhanced_file_service.dart';
import 'package:buildables_neu_todo/services/email_service.dart';
import 'package:buildables_neu_todo/services/notification_service.dart';
import 'package:buildables_neu_todo/repository/task_repository.dart';
import 'package:buildables_neu_todo/views/widgets/share_task_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TaskController extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;
  final TaskRepository _repository = TaskRepository();
  final EnhancedFileService _fileService = EnhancedFileService();
  final EmailService _emailService = EmailService();
  final Connectivity _connectivity = Connectivity();
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

  // Get all tasks (alias for _tasks getter for backward compatibility)
  Future<List<Task>> getAllTasks() async {
    await _fetchAll();
    return tasks;
  }

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

          try {
            final record = payload.newRecord as Map<String, dynamic>?;
            final title = record?['title'] as String? ?? 'New Task';

            await NotificationService.showLocalNotification(
              title: 'New task',
              body: title,
              data: {
                'event': 'insert',
                'task_id': (record?['id'] ?? '').toString(),
              },
            );
          } catch (_) {}
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'todos',
        callback: (payload) async {
          // Avoid pushing local changes here; just refetch
          await _fetchAll();
          try {
            final currentUserId = _client.auth.currentUser?.id;
            final record = payload.newRecord as Map<String, dynamic>?;
            final updatedBy =
                record?['updated_by'] as String? ??
                record?['created_by'] as String?;
            final title = record?['title'] as String? ?? 'Task updated';
            if (currentUserId != null && updatedBy != currentUserId) {
              await NotificationService.showLocalNotification(
                title: 'Task updated',
                body: title,
                data: {
                  'event': 'update',
                  'task_id': (record?['id'] ?? '').toString(),
                },
              );
            }
          } catch (_) {}
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'todos',
        callback: (payload) async {
          await _repository.syncPendingChanges();
          await _fetchAll();

          try {
            final currentUserId = _client.auth.currentUser?.id;
            final oldRecord = payload.oldRecord as Map<String, dynamic>?;
            final deletedBy =
                oldRecord?['updated_by'] as String? ??
                oldRecord?['created_by'] as String?;
            final title = oldRecord?['title'] as String? ?? 'Task deleted';

            if (currentUserId != null && deletedBy != currentUserId) {
              await NotificationService.showLocalNotification(
                title: 'Task deleted',
                body: title,
                data: {
                  'event': 'delete',
                  'task_id': (oldRecord?['id'] ?? '').toString(),
                },
              );
            }
          } catch (_) {}
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

      // 🚀 Call Edge Function for notification — FIXED PAYLOAD
      await _sendNewTaskNotification(addedTask);
    } catch (e) {
      rethrow;
    }
  }

  // Helper method to create notification record instead of calling Edge Function directly
  Future<void> _sendNewTaskNotification(Task task) async {
    try {
      print('🔔 === SENDING FCM NOTIFICATION ===');
      print('📋 Task: ${task.title}');
      print('🆔 Task ID: ${task.id}');
      print('👤 Created by: ${task.createdBy}');

      // Wait a moment for database trigger to complete
      await Future.delayed(const Duration(milliseconds: 500));

      // Call Edge Function to process pending notifications
      print('📤 Calling Edge Function to process notifications...');

      final response = await _client.functions.invoke(
        'dynamic-processor',
        body: {
          'trigger': 'task_created',
          'task_id': task.id,
          'task_title': task.title,
          'created_by': task.createdBy,
          'category': task.category,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      print('📨 Edge Function Response Status: ${response.status}');
      print('📨 Edge Function Response Data: ${response.data}');

      if (response.status >= 200 && response.status < 300) {
        final data = response.data as Map<String, dynamic>?;
        final success = data?['success'] ?? false;
        final sent = data?['sent'] ?? 0;
        final total = data?['total'] ?? 0;
        final errors = data?['errors'] ?? [];

        if (success && sent > 0) {
          print('✅ FCM notification sent successfully: $sent/$total');
        } else {
          print('⚠️ FCM notification issues: $sent/$total sent');
          if (errors.isNotEmpty) {
            print('❌ Errors: $errors');
          }
        }
      } else {
        print('❌ Edge Function returned error status: ${response.status}');
        print('❌ Error details: ${response.data}');
      }
    } catch (e, stackTrace) {
      print('❌ Error sending FCM notification: $e');
      print('📍 Stack trace: ${stackTrace.toString().substring(0, 500)}...');
      // Don't rethrow - notification failure shouldn't break task creation
    }
  }

  Future<void> reorderTasks(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;

    // Optimistic local reorder
    final moved = _tasks.removeAt(oldIndex);
    _tasks.insert(newIndex, moved);

    // Keep local models consistent (optional but recommended)
    for (var i = 0; i < _tasks.length; i++) {
      _tasks[i] = _tasks[i].copyWith(sortIndex: i);
    }
    notifyListeners();

    try {
      await _repository.persistTaskOrder(tasksInNewOrder: _tasks);
    } catch (e) {
      // Fallback: reload from server to restore order
      await _fetchAll();
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

      print('🚀 === ADDING NEW TASK ===');
      print('📝 Title: $title');
      print('🏷️ Category: ${category ?? 'None'}');
      print('📎 Has attachment: ${attachmentFile != null}');

      final taskId = const Uuid().v4();
      String? attachmentUrl;

      // Store file using enhanced file service (handles offline/online automatically)
      if (attachmentFile != null) {
        print('📎 Uploading attachment...');
        try {
          attachmentUrl = await _fileService.storeFile(attachmentFile, taskId);
          print('✅ Attachment stored: $attachmentUrl');
        } catch (e) {
          print('❌ Attachment upload failed: $e');
          // Continue without attachment rather than failing completely
        }
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
        attachmentUrl:
            attachmentUrl, // Include attachment URL in initial creation
      );

      print('💾 Saving task to repository...');
      final addedTask = await _repository.addTask(newTask);

      // Update local state immediately for UI feedback
      final existingIndex = _tasks.indexWhere((t) => t.id == addedTask.id);
      if (existingIndex == -1) {
        _tasks.insert(0, addedTask); // Add to beginning of list
        notifyListeners();
      }

      print('✅ Task saved successfully: ${addedTask.title}');

      // 🔔 CRITICAL: Trigger FCM notification after task creation
      print('🔔 Triggering FCM notification...');
      await _sendNewTaskNotification(addedTask);

      print('🎉 Task creation process completed!');
    } catch (e) {
      print('❌ Error adding task with attachment: $e');
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

      // Send email notification if task was completed
      if (updatedTask.done && !task.done) {
        await _sendTaskCompletionEmail(task: updatedTask);
      }
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

      // After uploading pending files, sync attachment URLs
      await _syncAttachmentUrls();
    } catch (e) {
      print('Error uploading pending files: $e');
    }
  }

  // Sync attachment URLs after pending files are uploaded
  Future<void> _syncAttachmentUrls() async {
    try {
      for (int i = 0; i < _tasks.length; i++) {
        final task = _tasks[i];
        if (task.hasAttachment &&
            task.attachmentUrl != null &&
            !task.attachmentUrl!.startsWith('http')) {
          // This is a local file path, try to get the Supabase URL
          final supabaseUrl = await _getSupabaseUrlForLocalFile(
            task.attachmentUrl!,
          );
          if (supabaseUrl != null) {
            // Update the task with the Supabase URL
            final updatedTask = task.copyWith(attachmentUrl: supabaseUrl);
            await _repository.updateTask(updatedTask);
            _tasks[i] = updatedTask;
            print('Updated task ${task.id} with Supabase URL: $supabaseUrl');
          }
        }
      }
      notifyListeners();
    } catch (e) {
      print('Error syncing attachment URLs: $e');
    }
  }

  // Get Supabase URL for a local file
  Future<String?> _getSupabaseUrlForLocalFile(String localPath) async {
    try {
      final fileName = localPath.split('/').last;
      final filePath = 'task-attachments/$fileName';

      // Check if file exists in Supabase storage
      final files = await _client.storage
          .from('task-files')
          .list(path: 'task-attachments');

      // Check if our file exists in the list
      final fileExists = files.any((file) => file.name == fileName);

      if (fileExists) {
        return _client.storage.from('task-files').getPublicUrl(filePath);
      }

      return null;
    } catch (e) {
      print('Error getting Supabase URL for local file: $e');
      return null;
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

  // Test email configuration
  Future<void> testEmailConfiguration() async {
    print('\n=== TESTING EMAIL CONFIGURATION ===');
    final emailService = EmailService();
    if (emailService.isConfigured) {
      print('✅ Email service appears configured');
      print(
        'Details: { from_email: ${emailService.fromEmail}, from_name: ${emailService.fromName} }',
      );
    } else {
      print('❌ Email service not fully configured');
      print(
        'Suggestions: Set MAILTRAP_API_TOKEN, MAILTRAP_INBOX_ID, MAILTRAP_FROM_EMAIL/NAME',
      );
    }
    print('=====================================\n');
  }

  // Test notifications workflow — UPDATED APPROACH
  Future<Map<String, dynamic>> testEdgeFunction() async {
    try {
      print('\n🧪 === TESTING NOTIFICATIONS WORKFLOW ===');

      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        print('❌ No authenticated user found');
        return {
          'success': false,
          'error': 'User not authenticated',
          'details': 'Please ensure user is logged in before testing',
        };
      }

      print('👤 Current user ID: ${currentUser.id}');
      print('📧 Current user email: ${currentUser.email}');

      // Check if device_tokens table exists and has data
      try {
        final tokensCheck = await _client
            .from('device_tokens')
            .select('fcm_token')
            .eq('user_id', currentUser.id);

        print('📱 FCM tokens found: ${tokensCheck.length}');
        if (tokensCheck.isEmpty) {
          print('⚠️  Warning: No FCM tokens found for current user');
          print('💡 You may need to register device tokens first');
        }
      } catch (e) {
        print('⚠️  Warning: Could not check device_tokens table: $e');
      }

      // Create a test notification record
      final testTaskId = 'test-task-${DateTime.now().millisecondsSinceEpoch}';
      final testPayload = {
        'user_id': currentUser.id,
        'title': 'Test Notification',
        'body': 'This is a test notification from Flutter App',
        'data': {
          'todo_id': testTaskId,
          'task_title': 'Test Task from Flutter App',
          'test': true,
          'created_at': DateTime.now().toIso8601String(),
        },
        'state': 'pending',
      };

      print('📤 Creating test notification record:');
      print('   - User ID: ${testPayload['user_id']}');
      print('   - Title: ${testPayload['title']}');
      print('   - Body: ${testPayload['body']}');
      print(
        '   - Task ID: ${(testPayload['data'] as Map<String, dynamic>?)?['todo_id']}',
      );

      final startTime = DateTime.now();
      print('⏱️  Creating notification at: ${startTime.toIso8601String()}');

      // Insert notification record
      await _client.from('notifications').insert(testPayload);

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      print('⏱️  Notification created in: ${duration.inMilliseconds}ms');
      print('✅ Test notification record created successfully!');
      print(
        '💡 The Edge Function will process this notification automatically',
      );
      print('=====================================\n');

      return {
        'success': true,
        'message': 'Notification record created successfully',
        'duration_ms': duration.inMilliseconds,
        'payload_created': testPayload,
        'note':
            'Edge Function will process pending notifications automatically',
      };
    } catch (e) {
      print('💥 Error testing notifications workflow: $e');
      print('📍 Stack trace: ${StackTrace.current}');
      print('=====================================\n');

      return {'success': false, 'error': e.toString(), 'type': 'exception'};
    }
  }

  // Debug Edge Function with comprehensive testing
  Future<Map<String, dynamic>> debugEdgeFunction() async {
    final result = <String, dynamic>{
      'success': false,
      'timestamp': DateTime.now().toIso8601String(),
      'tests': <String, dynamic>{},
    };

    try {
      print('🔍 === DEBUGGING EDGE FUNCTION ===');

      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        result['error'] = 'No authenticated user';
        print('❌ No authenticated user');
        return result;
      }

      print('👤 User ID: ${currentUser.id}');
      print('📧 User Email: ${currentUser.email}');
      print('🔑 User Role: ${currentUser.role}');

      // Test 1: Check Supabase connection
      print('\n🧪 Test 1: Supabase Connection');
      try {
        final testQuery = await _client
            .from('profiles')
            .select('id')
            .eq('id', currentUser.id)
            .limit(1);

        result['tests']['supabase_connection'] = {
          'success': true,
          'profile_found': testQuery.isNotEmpty,
        };
        print('✅ Supabase connection working');
      } catch (e) {
        result['tests']['supabase_connection'] = {
          'success': false,
          'error': e.toString(),
        };
        print('❌ Supabase connection failed: $e');
      }

      // Test 2: Check available functions
      print('\n🧪 Test 2: Function Discovery');
      try {
        // Try to call a non-existent function to see the error pattern
        final nonExistentResponse = await _client.functions.invoke(
          'non-existent-function-test',
          body: {'test': true},
        );

        result['tests']['function_discovery'] = {
          'non_existent_status': nonExistentResponse.status,
          'non_existent_data': nonExistentResponse.data,
        };
      } catch (e) {
        result['tests']['function_discovery'] = {
          'non_existent_error': e.toString(),
        };
      }

      // Test 3: Try the actual function with minimal payload
      print('\n🧪 Test 3: Minimal Function Call');
      try {
        final minimalPayload = {'test': true};
        print('📤 Sending minimal payload: $minimalPayload');

        final response = await _client.functions.invoke(
          'dynamic-processor',
          body: minimalPayload,
        );

        final isSuccess = response.status >= 200 && response.status < 300;

        result['tests']['minimal_call'] = {
          'status': response.status,
          'data': response.data,
          'success': isSuccess,
        };

        print('📨 Minimal call response:');
        print('  Status: ${response.status}');
        print('  Data: ${response.data}');
        print('  Success: $isSuccess');
      } catch (e) {
        result['tests']['minimal_call'] = {
          'exception': e.toString(),
          'success': false,
        };
        print('💥 Minimal call exception: $e');
      }

      // Test 4: Try with full payload
      print('\n🧪 Test 4: Full Payload Function Call');
      try {
        final fullPayload = {
          'task_id': 'debug-test-${DateTime.now().millisecondsSinceEpoch}',
          'task_title': 'Debug Test Task',
          'created_by': currentUser.id,
          'debug_mode': true,
        };

        print('📤 Sending full payload: $fullPayload');

        final response = await _client.functions.invoke(
          'dynamic-processor',
          body: fullPayload,
        );

        final isSuccess = response.status >= 200 && response.status < 300;

        result['tests']['full_call'] = {
          'status': response.status,
          'data': response.data,
          'success': isSuccess,
        };

        print('📨 Full call response:');
        print('  Status: ${response.status}');
        print('  Data: ${response.data}');
        print('  Success: $isSuccess');

        if (isSuccess) {
          result['success'] = true;
        }
      } catch (e) {
        result['tests']['full_call'] = {
          'exception': e.toString(),
          'success': false,
        };
        print('💥 Full call exception: $e');
      }

      // Test 5: Check project configuration
      print('\n🧪 Test 5: Project Configuration');
      try {
        // Access environment variables to check configuration
        final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
        final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

        result['tests']['project_config'] = {
          'url_configured': supabaseUrl.isNotEmpty,
          'key_configured': supabaseKey.isNotEmpty,
          'url_format': supabaseUrl.contains('supabase.co'),
          'partial_url': supabaseUrl.length > 30
              ? supabaseUrl.substring(0, 30)
              : supabaseUrl,
        };

        print('🔧 Project config:');
        print('  URL configured: ${supabaseUrl.isNotEmpty}');
        print('  Key configured: ${supabaseKey.isNotEmpty}');
        print(
          '  URL: ${supabaseUrl.length > 30 ? supabaseUrl.substring(0, 30) : supabaseUrl}...',
        );
      } catch (e) {
        result['tests']['project_config'] = {'error': e.toString()};
        print('❌ Project config check failed: $e');
      }
    } catch (e, stackTrace) {
      result['global_error'] = e.toString();
      result['stack_trace'] = stackTrace.toString();
      print('💥 Global exception: $e');
    }

    print('\n🏁 Debug completed');
    print('📊 Final result: $result');
    return result;
  }

  // Manually trigger the Edge Function to process pending notifications
  // Manually trigger the Edge Function to process pending notifications
  Future<Map<String, dynamic>> processPendingNotifications() async {
    try {
      print('🔄 Processing pending notifications...');

      // ✅ CALL dynamic-processor (plural) — your existing function
      final response = await _client.functions.invoke('dynamic-processor');

      print('📨 Edge Function response: ${response.data}');

      if (response.status >= 200 && response.status < 300) {
        final data = response.data as Map<String, dynamic>?;
        final sent = data?['sent'] ?? 0;
        final total = data?['total'] ?? 0;

        print('✅ Processed $sent/$total notifications');

        return {
          'success': true,
          'data': response.data,
          'status': response.status,
          'sent': sent,
          'total': total,
        };
      } else {
        print('❌ Edge Function returned status ${response.status}');
        return {
          'success': false,
          'error': 'HTTP ${response.status}: ${response.data}',
          'status': response.status,
        };
      }
    } catch (e) {
      print('💥 Error processing notifications: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Legacy share method for backward compatibility
  Future<String?> shareTaskLegacy(String taskId, String email) async {
    try {
      // First, check if this is an authenticated user
      final userQuery = await _client
          .from('profiles')
          .select('id, email, full_name')
          .eq('email', email.trim().toLowerCase())
          .maybeSingle();

      if (userQuery != null) {
        // User exists in profiles - share with authenticated user
        final userId = userQuery['id'] as String;
        final recipientEmail = userQuery['email'] as String;
        final recipientName = userQuery['full_name'] as String? ?? 'User';

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

          // Send email notification
          await _sendTaskShareEmail(
            task: task,
            recipientEmail: recipientEmail,
            recipientName: recipientName,
          );

          return null; // Success
        } else {
          return 'Task is already shared with this user';
        }
      } else {
        // User doesn't exist in profiles - share via email (external sharing)
        debugPrint('User not found in profiles, sharing via email: $email');

        try {
          await shareTaskWithEmail(
            taskId: taskId,
            recipientEmail: email.trim(),
            recipientName: email.split('@')[0], // Use email prefix as name
            message: 'You have been invited to collaborate on this task!',
          );
          return null; // Success
        } catch (e) {
          return 'Failed to send email invitation: ${e.toString()}';
        }
      }
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

  // Email notification helper methods
  Future<void> _sendTaskShareEmail({
    required Task task,
    required String recipientEmail,
    required String recipientName,
  }) async {
    try {
      if (!await isOnline) {
        print('Offline: Task share email queued for when online');
        return; // Optionally queue email for later
      }

      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return;

      final currentUserEmail = await getUserEmail(currentUser.id);
      final currentUserName = await _getUserFullName(currentUser.id);

      final subject = 'Task Invitation: ${task.title}';
      final attachmentNote = task.hasAttachment
          ? '\n\nThis task includes an attachment.'
          : '';
      final text =
          'Hello $recipientName,\n\n$currentUserName ($currentUserEmail) invited you to collaborate on a task.'
              '\n\nTask: ${task.title}\nCategory: ${task.category ?? 'General'}' +
          attachmentNote;

      await _emailService.sendEmail(
        toEmail: recipientEmail,
        toName: recipientName,
        subject: subject,
        text: text,
      );

      print('Task share email sent to $recipientEmail');
    } catch (e) {
      print('Failed to send task share email: $e');
    }
  }

  Future<void> _sendTaskCompletionEmail({required Task task}) async {
    try {
      if (!await isOnline) {
        print('Offline: Task completion email queued for when online');
        return; // Optionally queue email for later
      }

      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return;

      final sharedWith = task.sharedWith ?? [];
      if (sharedWith.isEmpty) return;

      for (final userId in sharedWith) {
        if (userId != currentUser.id) {
          final userEmail = await getUserEmail(userId);
          final userName = await _getUserFullName(userId);

          await _emailService.sendEmail(
            toEmail: userEmail,
            toName: userName,
            subject: 'Task Completion Notification',
            text: 'Your task has been completed.',
          );
        }
      }

      print('Task completion emails sent');
    } catch (e) {
      print('Failed to send task completion emails: $e');
    }
  }

  Future<String> _getUserFullName(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select('full_name')
          .eq('id', userId)
          .maybeSingle();

      if (response != null && response['full_name'] != null) {
        return response['full_name'] as String;
      }
      return 'User';
    } catch (e) {
      print('Error fetching user full name: $e');
      return 'User';
    }
  }

  // Add these methods to your existing TaskController

  // Share with authenticated users (internal)
  Future<void> shareTaskWithAuthenticatedUser({
    required String taskId,
    required String userIdentifier,
    required String userName,
    required String message,
  }) async {
    try {
      final connectivity = await _connectivity.checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        throw Exception('Cannot share task while offline');
      }

      // Get current user info
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get the task
      final tasks = await getAllTasks();
      final task = tasks.firstWhere(
        (t) => t.id == taskId,
        orElse: () => throw Exception('Task not found'),
      );

      print(
        'TaskController: Sharing task ${task.title} with authenticated user: $userIdentifier',
      );

      // Find the user in Supabase (by email or username)
      String? recipientUserId;
      try {
        // Try to find user by email first
        if (EmailService().isValidEmail(userIdentifier)) {
          final userResponse = await _client.auth.admin.listUsers();
          final user = userResponse.firstWhere(
            (u) => u.email == userIdentifier,
            orElse: () => throw Exception('User not found'),
          );
          recipientUserId = user.id;
        } else {
          // If not an email, treat as username and try to find in profiles table
          final profileResponse = await _client
              .from('profiles')
              .select('id')
              .eq('username', userIdentifier)
              .maybeSingle();

          if (profileResponse != null) {
            recipientUserId = profileResponse['id'];
          } else {
            throw Exception('User not found');
          }
        }
      } catch (e) {
        throw Exception('User "$userIdentifier" not found in the app');
      }

      // Update task's shared_with array
      final currentSharedWith = task.sharedWith ?? [];
      if (recipientUserId != null &&
          !currentSharedWith.contains(recipientUserId)) {
        currentSharedWith.add(recipientUserId);

        // Update in Supabase
        await _client
            .from('todos')
            .update({
              'shared_with': currentSharedWith,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', taskId);

        // Update local database through repository
        final updatedTask = task.copyWith(
          sharedWith: currentSharedWith,
          updatedAt: DateTime.now(),
        );
        await _repository.updateTask(updatedTask);

        print(
          'TaskController: Task shared successfully with authenticated user: $userIdentifier',
        );

        // 🚀 Notify shared user via Edge Function
        await _client.functions.invoke(
          'dynamic-processor',
          body: {
            'task_id': task.id,
            'task_title': task.title,
            'recipient_id': recipientUserId,
            'is_shared': true,
          },
        );
      } else {
        print('TaskController: Task already shared with user: $userIdentifier');
      }

      // Refresh tasks
      await getAllTasks();
    } catch (e) {
      print('TaskController: Error sharing task with authenticated user: $e');
      rethrow;
    }
  }

  // Share with anyone via email (external)
  Future<void> shareTaskWithEmail({
    required String taskId,
    required String recipientEmail,
    required String recipientName,
    required String message,
  }) async {
    try {
      final connectivity = await _connectivity.checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        throw Exception(
          'Cannot share task while offline - email requires internet connection',
        );
      }

      // Get current user info
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get the task
      final tasks = await getAllTasks();
      final task = tasks.firstWhere(
        (t) => t.id == taskId,
        orElse: () => throw Exception('Task not found'),
      );

      print(
        'TaskController: Sharing task ${task.title} with email: $recipientEmail',
      );

      // Send email notification via Mailtrap
      final emailSent = await EmailService().sendEmail(
        toEmail: recipientEmail,
        toName: recipientName,
        subject: 'Task Share Notification',
        text: 'Your task has been shared.',
      );

      if (!emailSent) {
        throw Exception(
          'Failed to send email invitation. Please check your Mailtrap configuration.',
        );
      }

      print(
        'TaskController: Email invitation sent successfully to: $recipientEmail',
      );

      // Note: Email invitations are not tracked in shared_with field
      // since that field is constrained to UUIDs for authenticated users only

      // Refresh tasks
      await getAllTasks();
    } catch (e) {
      print('TaskController: Error sharing task via email: $e');
      rethrow;
    }
  }

  // Combined share method that routes to appropriate handler
  Future<void> shareTask({
    required String taskId,
    required String identifier,
    required String name,
    required ShareType shareType,
    required String message,
  }) async {
    if (shareType == ShareType.authenticated) {
      await shareTaskWithAuthenticatedUser(
        taskId: taskId,
        userIdentifier: identifier,
        userName: name,
        message: message,
      );
    } else {
      await shareTaskWithEmail(
        taskId: taskId,
        recipientEmail: identifier,
        recipientName: name,
        message: message,
      );
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
