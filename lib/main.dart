import 'package:buildables_neu_todo/repository/task_repository.dart';
import 'package:buildables_neu_todo/services/fcm_token_storage.dart';
import 'package:buildables_neu_todo/services/notification_service.dart';
import 'package:buildables_neu_todo/views/auth/login_screen.dart';
import 'package:buildables_neu_todo/views/home/task_detail_screen.dart';
import 'package:buildables_neu_todo/models/task.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Background message handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Initialize repository
  TaskRepository().initialize(
    supabase: Supabase.instance.client,
    connectivity: Connectivity(),
  );

  // Initialize local notifications with navigator key
  await NotificationService.initialize(navigatorKey);

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Request notification permissions
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Set up connectivity monitoring
  Connectivity().onConnectivityChanged.listen((
    List<ConnectivityResult> results,
  ) async {
    // Check if any result indicates connectivity
    final hasConnectivity = results.any(
      (result) => result != ConnectivityResult.none,
    );

    if (hasConnectivity) {
      // Coming back online - sync pending changes and uploads
      await TaskRepository().syncPendingChanges();
    }
  });

  await saveFcmToken();

  // Handle token refresh
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user != null) {
      try {
        // Check if user already has a token
        final existingTokens = await supabase
            .from('device_tokens')
            .select('id')
            .eq('user_id', user.id);

        if (existingTokens.isNotEmpty) {
          // Update existing token
          await supabase
              .from('device_tokens')
              .update({
                'fcm_token': newToken,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('user_id', user.id);
        } else {
          // Insert new token
          await supabase.from('device_tokens').insert({
            'user_id': user.id,
            'fcm_token': newToken,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        }

        print('FCM token refreshed successfully for user: ${user.id}');
      } catch (e) {
        print('Error refreshing FCM token: $e');
      }
    }
  });

  runApp(const MyApp());
}

final navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupRealtimeSubscription();
    _setupFcmHandlers();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    Supabase.instance.client.channel('notifications').unsubscribe();
    super.dispose();
  }

  void _setupRealtimeSubscription() {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    print('Setting up Realtime subscription for user_id: $userId');

    if (userId == null) {
      print('No user logged in, skipping Realtime subscription');
      return;
    }

    supabase
        .channel('public:notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          callback: (payload) async {
            print('Received Realtime notification: $payload');
            final notification = payload.newRecord;
            if (notification == null) return;
            if (notification['user_id']?.toString() != userId) return;
            await NotificationService.showLocalNotification(
              title: notification['title'] as String,
              body: notification['body'] as String,
              data: notification['data'] as Map<String, dynamic>,
            );

            // Update notification state to 'displayed'
            try {
              await supabase
                  .from('notifications')
                  .update({
                    'state': 'displayed',
                    'updated_at': DateTime.now().toIso8601String(),
                  })
                  .eq('id', notification['id']);
              print('Updated notification ${notification['id']} to displayed');
            } catch (e) {
              print('Error updating notification state: $e');
            }
          },
        )
        .subscribe((status, [error]) {
          print('Realtime subscription status: $status');
          if (error != null) print('Realtime subscription error: $error');
        });
  }

  void _setupFcmHandlers() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');
      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        NotificationService.showNotification(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      print('Message data: ${message.data}');
      if (message.data['todo_id'] != null) {
        _navigateToTaskDetail(message.data['todo_id']);
      }
    });

    FirebaseMessaging.instance.getInitialMessage().then((
      RemoteMessage? message,
    ) {
      if (message != null && message.data['todo_id'] != null) {
        _navigateToTaskDetail(message.data['todo_id']);
      }
    });
  }

  Future<void> _navigateToTaskDetail(String todoId) async {
    final task = await _fetchTask(todoId);
    if (task != null && navigatorKey.currentState != null) {
      navigatorKey.currentState!.pushNamed(
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

  Future<Task?> _fetchTask(String todoId) async {
    try {
      final response = await Supabase.instance.client
          .from('todos')
          .select()
          .eq('id', todoId)
          .single();
      return Task.fromMap(response as Map<String, dynamic>);
    } catch (e) {
      print('Error fetching task: $e');
      return null;
    }
  }

  Future<List<String>> _fetchCategories() async {
    // Replace with your actual category-fetching logic
    return ['Work', 'Personal', 'Others'];
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/task_details': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return TaskDetailScreen(
            task: args['task'] as Task,
            categories: args['categories'] as List<String>,
            onTaskUpdated: args['onTaskUpdated'] as Function(Task),
          );
        },
      },
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          surface: AppColors.background,
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
          titleLarge: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
          bodyLarge: TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          bodyMedium: TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          labelLarge: TextStyle(fontWeight: FontWeight.w700),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.textPrimary,
        ),
      ),
    );
  }
}
