import 'dart:convert';
import 'package:http/http.dart' as http;

class FCMService {
  static const String serverKey = 'YOUR_FCM_SERVER_KEY'; // ⚠️ For testing only
  static const String fcmUrl = 'https://fcm.googleapis.com/fcm/send';

  static Future<bool> sendNotification({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(fcmUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode({
          'to': fcmToken,
          'notification': {
            'title': title,
            'body': body,
            'sound': 'default',
          },
          'data': data ?? {},
          'priority': 'high',
        }),
      );

      if (response.statusCode == 200) {
        print('✅ FCM sent successfully');
        return true;
      } else {
        print('❌ FCM failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('💥 FCM error: $e');
      return false;
    }
  }
}