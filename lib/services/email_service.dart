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

  Future<bool> sendTaskInviteEmail({
    required String toEmail,
    required String toName,
    required String taskTitle,
    required String taskId,
    required String inviterName,
    required String inviterEmail,
    String? customMessage,
  }) async {
    if (!isConfigured) {
      print('❌ Email service not properly configured');
      return false;
    }

    if (!isValidEmail(toEmail)) {
      print('❌ Invalid email address: $toEmail');
      return false;
    }

    try {
      print('📧 Sending task invite email to: $toEmail');

      final emailContent = _buildInviteEmailContent(
        toName: toName,
        taskTitle: taskTitle,
        inviterName: inviterName,
        inviterEmail: inviterEmail,
        customMessage: customMessage,
        taskId: taskId,
        inviteeEmail: toEmail,
      );

      final url = Uri.parse('https://send.api.mailtrap.io/api/send');

      final body = {
        "from": {"email": fromEmail, "name": fromName},
        "to": [
          {"email": toEmail, "name": toName},
        ],
        "subject": "🤝 You've been invited to collaborate on a task!",
        "html": emailContent,
        "category": "Task Invitation",
      };

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $apiToken",
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        print('✅ Task invite email sent successfully to: $toEmail');
        return true;
      } else {
        print(
          '❌ Failed to send invite email: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('❌ Error sending task invite email: $e');
      return false;
    }
  }

  // Build email content with accept invite button
  String _buildInviteEmailContent({
    required String toName,
    required String taskTitle,
    required String inviterName,
    required String inviterEmail,
    required String taskId,
    required String inviteeEmail,
    String? customMessage,
  }) {
    // Simple confirmation URL that just shows success message
    final confirmUrl =
        'https://buildablestodo.com/invite-confirmed?taskId=$taskId&email=${Uri.encodeComponent(inviteeEmail)}';

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Task Invitation</title>
    <style>
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
            line-height: 1.6; 
            color: #333; 
            max-width: 600px; 
            margin: 0 auto; 
            padding: 20px; 
            background-color: #f5f5f5;
        }
        .container { 
            background: white; 
            border-radius: 12px; 
            padding: 40px; 
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        .header { 
            text-align: center; 
            margin-bottom: 30px; 
        }
        .app-icon { 
            width: 64px; 
            height: 64px; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
            border-radius: 12px; 
            margin: 0 auto 16px; 
            display: flex; 
            align-items: center; 
            justify-content: center; 
            font-size: 32px; 
            color: white;
        }
        .title { 
            color: #1a1a1a; 
            margin: 0; 
            font-size: 24px; 
            font-weight: 600;
        }
        .subtitle { 
            color: #666; 
            margin: 8px 0 0 0; 
            font-size: 16px;
        }
        .task-card {
            background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
            color: white;
            padding: 24px;
            margin: 24px 0;
            border-radius: 12px;
            text-align: center;
        }
        .task-title {
            font-size: 20px;
            font-weight: 600;
            margin: 0 0 8px 0;
        }
        .task-meta {
            opacity: 0.9;
            font-size: 14px;
        }
        .message-box {
            background: #e3f2fd;
            border-radius: 8px;
            padding: 16px;
            margin: 20px 0;
            border-left: 4px solid #2196f3;
        }
        .accept-button {
            display: inline-block;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white !important;
            padding: 18px 36px;
            text-decoration: none;
            border-radius: 50px;
            font-weight: 600;
            font-size: 16px;
            text-align: center;
            margin: 24px 0;
            box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
            transition: all 0.3s ease;
        }
        .accept-button:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(102, 126, 234, 0.6);
        }
        .instruction-box {
            background: #f8f9fa;
            border: 2px solid #e9ecef;
            border-radius: 8px;
            padding: 20px;
            margin: 24px 0;
            text-align: center;
        }
        .step {
            display: flex;
            align-items: center;
            margin: 12px 0;
            padding: 8px;
            background: white;
            border-radius: 6px;
        }
        .step-number {
            background: #667eea;
            color: white;
            width: 24px;
            height: 24px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 600;
            font-size: 12px;
            margin-right: 12px;
            flex-shrink: 0;
        }
        .footer {
            text-align: center;
            margin-top: 40px;
            padding-top: 30px;
            border-top: 1px solid #eee;
            color: #666;
            font-size: 14px;
        }
        @media (max-width: 480px) {
            .container { padding: 24px; }
            .step { flex-direction: column; text-align: center; }
            .step-number { margin-right: 0; margin-bottom: 8px; }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="app-icon">📋</div>
            <h1 class="title">You're Invited!</h1>
            <p class="subtitle">$inviterName wants to collaborate with you on a task</p>
        </div>

        <div class="task-card">
            <div class="task-title">"$taskTitle"</div>
            <div class="task-meta">Shared by $inviterName</div>
        </div>

        ${customMessage != null ? '''
        <div class="message-box">
            <strong>💌 Personal message:</strong><br>
            "$customMessage"
        </div>
        ''' : ''}

        <div style="text-align: center;">
            <a href="$confirmUrl" class="accept-button">
                ✅ Accept Invite
            </a>
        </div>

        <div class="instruction-box">
            <h3 style="margin: 0 0 16px 0; color: #1a1a1a;">📱 How to access your shared task:</h3>
            
            <div class="step">
                <div class="step-number">1</div>
                <div>Click "Accept Invite" button above to confirm</div>
            </div>
            
            <div class="step">
                <div class="step-number">2</div>
                <div>Open the <strong>Neu Todo</strong> app on your device</div>
            </div>
            
            <div class="step">
                <div class="step-number">3</div>
                <div>Login with this email: <strong>$inviteeEmail</strong></div>
            </div>
            
            <div class="step">
                <div class="step-number">4</div>
                <div>Find your shared task in the "Shared with Me" tab</div>
            </div>
        </div>

        <div style="text-align: center; background: #fff3cd; border: 1px solid #ffeaa7; border-radius: 8px; padding: 16px; margin: 20px 0;">
            <strong>📧 Important:</strong> Make sure to login with the email address <strong>$inviteeEmail</strong> to see the shared task.
        </div>

        <div class="footer">
            <p>
                This invitation was sent by <strong>$inviterName</strong> ($inviterEmail).<br>
                If you don't want to receive these emails, you can safely ignore this message.
            </p>
            <p style="margin-top: 16px; font-weight: 600;">
                📋 <strong>Neu Todo</strong> - Collaborative Task Management Made Simple
            </p>
        </div>
    </div>
</body>
</html>
''';
  }
}
