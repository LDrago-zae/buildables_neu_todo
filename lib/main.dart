import 'package:buildables_neu_todo/repository/task_repository.dart';
import 'package:buildables_neu_todo/services/fcm_token_storage.dart';
import 'package:buildables_neu_todo/services/notification_service.dart';
import 'package:buildables_neu_todo/views/auth/login_screen.dart';
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

  // Initialize local notifications
  await NotificationService.initialize();

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
      // Note: TaskController will handle file uploads when it's instantiated
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

  // Set up message handlers
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
      // Show local notification when app is in foreground
      NotificationService.showNotification(message);
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('A new onMessageOpenedApp event was published!');
    print('Message data: ${message.data}');
    // Handle notification tap when app is in background
    // You can navigate to specific screens based on message data
  });

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      home: LoginScreen(),
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
