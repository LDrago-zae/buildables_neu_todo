import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';

class SupabaseRealtimeListener {
  final supabase = Supabase.instance.client;

  void listenToUserNotifications(String userId) {
    supabase
        .channel('public:notifications')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'notifications',
      callback: (payload) {
        final newNotif = payload.newRecord;

        if (newNotif['user_id'] == userId) {
          NotificationService.showLocalNotification(
            title: newNotif['title'] ?? 'Notification',
            body: newNotif['body'] ?? '',
            data: newNotif['data'],
          );
        }
      },
    )
        .subscribe();
  }
}
