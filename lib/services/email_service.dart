import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EmailService {
  final String apiToken = dotenv.env['MAILTRAP_API_TOKEN'] ?? '';
  final String inboxId = dotenv.env['MAILTRAP_INBOX_ID'] ?? '';
  final String fromEmail = dotenv.env['MAILTRAP_FROM_EMAIL'] ?? '';
  final String fromName = dotenv.env['MAILTRAP_FROM_NAME'] ?? 'Neu Todo';

  bool get isConfigured =>
      apiToken.isNotEmpty && inboxId.isNotEmpty && fromEmail.isNotEmpty;

  bool isValidEmail(String email) {
    final regex = RegExp(r'^[\w\.-]+@[\w\.-]+\.[A-Za-z]{2,}$');
    return regex.hasMatch(email.trim());
  }

  Future<bool> sendEmail({
    required String toEmail,
    required String toName,
    required String subject,
    required String text,
  }) async {
    final url = Uri.parse('https://send.api.mailtrap.io/api/send');

    final body = {
      "from": {"email": fromEmail, "name": fromName},
      "to": [
        {"email": toEmail, "name": toName},
      ],
      "subject": subject,
      "text": text,
      "category": "Flutter Integration Test",
    };

    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $apiToken",
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        print("✅ Email sent successfully: ${response.body}");
        return true;
      } else {
        print("❌ Failed to send email: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Exception while sending email: $e");
      return false;
    }
  }
}
