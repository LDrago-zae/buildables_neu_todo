import 'package:buildables_neu_todo/models/task.dart';
import 'package:buildables_neu_todo/repository/task_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();
  static GlobalKey<NavigatorState>? navigatorKey;

  static Future<void> initialize(GlobalKey<NavigatorState> navKey) async {
    navigatorKey = navKey;

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _createNotificationChannel();
  }

  static Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'task_notifications',
      'Task Notifications',
      description: 'Notifications for new tasks and updates',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Show a notification from FCM message
  static Future<void> showNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'task_notifications',
      'Task Notifications',
      channelDescription: 'Notifications for new tasks and updates',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      message.hashCode,
      message.notification?.title ?? 'New Task',
      message.notification?.body ?? 'You have a new task',
      platformDetails,
      payload: message.data['todo_id']?.toString(),
    );
  }

  /// Show a notification from Supabase realtime
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'task_notifications',
      'Task Notifications',
      channelDescription: 'Notifications for new tasks and updates',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformDetails,
      payload: data?['todo_id']?.toString(),
    );
  }

  static Future<void> _onNotificationTapped(
      NotificationResponse response,
      ) async {
    if (response.payload != null && navigatorKey?.currentState != null) {
      final task = await _fetchTask(response.payload!);
      if (task != null) {
        navigatorKey!.currentState!.pushNamed(
          '/task_details',
          arguments: {
            'task': task,
            'categories': await _fetchCategories(),
            'onTaskUpdated': (Task updatedTask) {
              TaskRepository().updateTask(updatedTask);
            },
          },
        );
      }
    }
  }

  static Future<Task?> _fetchTask(String todoId) async {
    try {
      final response = await Supabase.instance.client
          .from('todos')
          .select()
          .eq('id', todoId)
          .single();
      return Task.fromMap(response);
    } catch (e) {
      print('Error fetching task: $e');
      return null;
    }
  }

  static Future<List<String>> _fetchCategories() async {
    // Replace with your actual category-fetching logic
    return ['Work', 'Personal', 'Others'];
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }
}
