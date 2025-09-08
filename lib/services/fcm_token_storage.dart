import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> saveFcmToken() async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  if (user == null) {
    print('No authenticated user found, skipping FCM token save');
    return;
  }

  final fcmToken = await FirebaseMessaging.instance.getToken();
  if (fcmToken != null) {
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
              'fcm_token': fcmToken,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', user.id);
      } else {
        // Insert new token
        await supabase.from('device_tokens').insert({
          'user_id': user.id,
          'fcm_token': fcmToken,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      print('FCM token saved successfully for user: ${user.id}');
    } catch (e) {
      print('Error saving FCM token: $e');
      // Fallback: try simple insert (will fail if user already exists, but that's ok)
      try {
        await supabase.from('device_tokens').insert({
          'user_id': user.id,
          'fcm_token': fcmToken,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (insertError) {
        print('Fallback insert also failed: $insertError');
      }
    }
  }
}
