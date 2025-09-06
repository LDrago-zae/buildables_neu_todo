import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EmailService {
  // Mailtrap configuration from environment
  static String get _mailtrapApiToken => dotenv.env['MAILTRAP_API_TOKEN'] ?? '';
  static String get _fromEmail =>
      dotenv.env['MAILTRAP_FROM_EMAIL'] ?? 'hello@example.com';
  static String get _fromName =>
      dotenv.env['MAILTRAP_FROM_NAME'] ?? 'Neu Todo App';
  static const String _mailtrapApiUrl = 'https://send.api.mailtrap.io/api/send';

  // Check if email service is properly configured
  bool get isConfigured {
    return _mailtrapApiToken.isNotEmpty &&
        _fromEmail.isNotEmpty &&
        _fromEmail != 'noreply@example.com';
  }

  static Future<bool> sendTaskShareEmail({
    required String recipientEmail,
    required String recipientName,
    required String senderName,
    required String senderEmail,
    required String taskTitle,
    required String taskCategory,
    required String shareMessage,
    bool hasAttachment = false,
  }) async {
    try {
      // Check if we're in testing mode (default/invalid API token)
      if (_mailtrapApiToken.isEmpty ||
          _mailtrapApiToken == 'd4178623a02c22392d55b665f7cf9f0d') {
        print('EmailService: Running in TEST MODE - simulating email send');
        print('EmailService: Would send email to: $recipientEmail');
        print('EmailService: Task: $taskTitle');
        print('EmailService: From: $senderName ($senderEmail)');
        print('EmailService: Message: $shareMessage');

        // Simulate network delay
        await Future.delayed(const Duration(seconds: 1));

        print('EmailService: ✅ TEST EMAIL SENT SUCCESSFULLY (simulated)');
        return true; // Return success for testing
      }

      if (_mailtrapApiToken.isEmpty) {
        print('EmailService: Mailtrap API token not configured');
        return false;
      }

      print('EmailService: Sending task share email to $recipientEmail');
      print(
        'EmailService: Using API token: ${_mailtrapApiToken.substring(0, 8)}...',
      );
      print('EmailService: From email: $_fromEmail');

      final requestBody = {
        'from': {'email': _fromEmail, 'name': _fromName},
        'to': [
          {
            'email': recipientEmail,
            'name': recipientName.isNotEmpty
                ? recipientName
                : recipientEmail.split('@')[0],
          },
        ],
        'subject': '📋 $senderName shared a task with you: $taskTitle',
        'html': _buildShareEmailTemplate(
          recipientName: recipientName.isNotEmpty
              ? recipientName
              : recipientEmail.split('@')[0],
          senderName: senderName,
          senderEmail: senderEmail,
          taskTitle: taskTitle,
          taskCategory: taskCategory,
          shareMessage: shareMessage,
          hasAttachment: hasAttachment,
        ),
        'category': 'task_sharing',
      };

      print('EmailService: Request URL: $_mailtrapApiUrl');

      final response = await http.post(
        Uri.parse(_mailtrapApiUrl),
        headers: {
          'Authorization': 'Bearer $_mailtrapApiToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('EmailService: Response status: ${response.statusCode}');
      print('EmailService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('EmailService: Email sent successfully');
        final responseData = jsonDecode(response.body);
        print('EmailService: Response: $responseData');
        return true;
      } else {
        print(
          'EmailService: Failed to send email. Status: ${response.statusCode}',
        );
        print('EmailService: Response: ${response.body}');

        // Provide more specific error messages
        if (response.statusCode == 401) {
          print(
            'EmailService: Authentication failed. Please check your API token and permissions.',
          );
        } else if (response.statusCode == 422) {
          print(
            'EmailService: Invalid request data. Please check email addresses and content.',
          );
        } else if (response.statusCode == 429) {
          print(
            'EmailService: Rate limit exceeded. Please wait before sending more emails.',
          );
        }

        return false;
      }
    } catch (e) {
      print('EmailService: Error sending email: $e');
      return false;
    }
  }

  // For backward compatibility
  Future<bool> sendTaskShareNotification({
    required String recipientEmail,
    required String recipientName,
    required String senderName,
    required String senderEmail,
    required String taskTitle,
    required String taskCategory,
    String shareMessage = '',
    bool hasAttachment = false,
  }) async {
    return await sendTaskShareEmail(
      recipientEmail: recipientEmail,
      recipientName: recipientName,
      senderName: senderName,
      senderEmail: senderEmail,
      taskTitle: taskTitle,
      taskCategory: taskCategory,
      shareMessage: shareMessage,
      hasAttachment: hasAttachment,
    );
  }

  // For backward compatibility
  Future<bool> sendTaskCompletionNotification({
    required String recipientEmail,
    required String recipientName,
    required String senderName,
    required String taskTitle,
  }) async {
    return await sendTaskShareEmail(
      recipientEmail: recipientEmail,
      recipientName: recipientName,
      senderName: senderName,
      senderEmail: 'system@neutodo.com',
      taskTitle: taskTitle,
      taskCategory: 'General',
      shareMessage: 'Task has been completed!',
      hasAttachment: false,
    );
  }

  static String _buildShareEmailTemplate({
    required String recipientName,
    required String senderName,
    required String senderEmail,
    required String taskTitle,
    required String taskCategory,
    required String shareMessage,
    required bool hasAttachment,
  }) {
    final currentDate = DateTime.now();
    final formattedDate =
        '${currentDate.day}/${currentDate.month}/${currentDate.year}';

    return '''
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Task Shared - Neu Todo</title>
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body { 
                font-family: 'Arial', sans-serif; 
                background-color: #F7F7FB; 
                padding: 20px;
                line-height: 1.6;
            }
            .email-container { 
                max-width: 600px; 
                margin: 0 auto; 
                background-color: #FFFFFF;
                border: 3px solid #000000;
                border-radius: 16px;
                box-shadow: 8px 8px 0px #000000;
                overflow: hidden;
            }
            .header { 
                background: linear-gradient(135deg, #9CC5FF 0%, #B2F0EE 50%, #FFF3B0 100%); 
                padding: 32px 24px; 
                text-align: center; 
                border-bottom: 3px solid #000000; 
            }
            .header h1 { 
                font-size: 28px; 
                font-weight: 900; 
                color: #000000; 
                margin-bottom: 8px;
                text-shadow: 2px 2px 0px rgba(255,255,255,0.5);
            }
            .header p { 
                font-size: 14px; 
                color: #000000; 
                font-weight: 600;
            }
            .content { 
                padding: 32px 24px; 
            }
            .greeting { 
                font-size: 18px; 
                font-weight: 700; 
                color: #000000; 
                margin-bottom: 16px; 
            }
            .message { 
                font-size: 16px; 
                color: #374151; 
                margin-bottom: 24px; 
                line-height: 1.5;
            }
            .task-card { 
                background-color: #FFF3B0; 
                border: 3px solid #000000; 
                border-radius: 12px; 
                padding: 24px; 
                margin: 24px 0; 
                box-shadow: 4px 4px 0px #000000; 
                position: relative;
            }
            .task-icon {
                position: absolute;
                top: -15px;
                right: 20px;
                background-color: #9CC5FF;
                border: 3px solid #000000;
                border-radius: 50%;
                width: 40px;
                height: 40px;
                display: flex;
                align-items: center;
                justify-content: center;
                font-size: 18px;
                box-shadow: 3px 3px 0px #000000;
            }
            .task-title { 
                font-size: 22px; 
                font-weight: 900; 
                color: #000000; 
                margin-bottom: 12px; 
                padding-right: 50px;
            }
            .task-meta { 
                display: flex; 
                align-items: center; 
                font-size: 14px; 
                color: #6B7280; 
                margin-bottom: 8px; 
                font-weight: 600;
            }
            .meta-icon { 
                margin-right: 8px; 
                font-size: 16px; 
            }
            .share-message {
                background-color: #E0F2FE;
                border: 2px solid #0369A1;
                border-radius: 8px;
                padding: 16px;
                margin: 20px 0;
                font-style: italic;
                color: #0369A1;
                font-weight: 600;
            }
            .attachment-badge { 
                display: inline-flex;
                align-items: center;
                background-color: #FFE0B2; 
                border: 2px solid #000000; 
                border-radius: 20px; 
                padding: 6px 12px; 
                font-size: 12px; 
                font-weight: 700; 
                margin-top: 12px; 
                color: #000000;
                box-shadow: 2px 2px 0px #000000;
            }
            .cta-button { 
                display: inline-block; 
                background-color: #C6F6D5; 
                color: #000000; 
                padding: 16px 32px; 
                text-decoration: none; 
                border: 3px solid #000000; 
                border-radius: 12px; 
                font-weight: 900; 
                font-size: 16px;
                margin: 24px 0; 
                box-shadow: 4px 4px 0px #000000; 
                transition: all 0.1s ease;
                text-align: center;
                display: block;
                max-width: 200px;
            }
            .features { 
                background-color: #F9FAFB; 
                border: 2px solid #E5E7EB; 
                border-radius: 8px; 
                padding: 20px; 
                margin: 24px 0; 
            }
            .features h3 { 
                font-size: 16px; 
                font-weight: 700; 
                color: #000000; 
                margin-bottom: 12px; 
            }
            .features ul { 
                list-style: none; 
                padding: 0; 
            }
            .features li { 
                font-size: 14px; 
                color: #374151; 
                margin-bottom: 8px; 
                padding-left: 24px; 
                position: relative;
                font-weight: 500;
            }
            .features li:before { 
                content: '✅'; 
                position: absolute; 
                left: 0; 
                font-size: 14px; 
            }
            .footer { 
                background-color: #6B7280; 
                color: #FFFFFF; 
                padding: 24px; 
                text-align: center; 
                font-size: 12px; 
                border-top: 3px solid #000000;
            }
            .footer a { 
                color: #FFFFFF; 
                text-decoration: underline; 
            }
            .signature {
                margin-top: 24px;
                padding-top: 20px;
                border-top: 2px solid #E5E7EB;
                font-size: 14px;
                color: #6B7280;
                font-style: italic;
            }
            @media (max-width: 600px) {
                .email-container { margin: 10px; }
                .header, .content { padding: 20px 16px; }
                .task-card { padding: 16px; }
                .task-title { font-size: 18px; }
            }
        </style>
    </head>
    <body>
        <div class="email-container">
            <div class="header">
                <h1>📋 Task Shared!</h1>
                <p>Someone wants to collaborate with you</p>
            </div>
            
            <div class="content">
                <div class="greeting">
                    Hello $recipientName! 👋
                </div>
                
                <div class="message">
                    <strong>$senderName</strong> has shared a task with you on <strong>Neu Todo</strong> and would like you to collaborate.
                </div>
                
                <div class="task-card">
                    <div class="task-icon">📌</div>
                    <div class="task-title">$taskTitle</div>
                    <div class="task-meta">
                        <span class="meta-icon">📂</span>
                        Category: $taskCategory
                    </div>
                    <div class="task-meta">
                        <span class="meta-icon">👤</span>
                        Shared by: $senderName ($senderEmail)
                    </div>
                    <div class="task-meta">
                        <span class="meta-icon">📅</span>
                        Shared on: $formattedDate
                    </div>
                    ${hasAttachment ? '<div class="attachment-badge">📎 Has Attachment</div>' : ''}
                </div>
                
                ${shareMessage.isNotEmpty ? '''
                <div class="share-message">
                    💬 <strong>Message from $senderName:</strong><br>
                    "$shareMessage"
                </div>
                ''' : ''}
                
                <a href="#" class="cta-button">
                    🚀 Open Neu Todo
                </a>
                
                <div class="features">
                    <h3>🤝 What you can do:</h3>
                    <ul>
                        <li>View and update the shared task</li>
                        <li>Add comments and collaborate in real-time</li>
                        <li>Access any attached files or documents</li>
                        <li>Track progress together with $senderName</li>
                        <li>Get notifications on task updates</li>
                    </ul>
                </div>
                
                <div class="signature">
                    <strong>Happy collaborating!</strong><br>
                    The Neu Todo Team 🎉
                </div>
            </div>
            
            <div class="footer">
                <p><strong>Neu Todo - Beautiful Task Management</strong></p>
                <p>This email was sent because $senderName shared a task with you.</p>
                <p>If you didn't expect this email, you can safely ignore it.</p>
            </div>
        </div>
    </body>
    </html>
    ''';
  }

  // Send welcome email to new users
  Future<bool> sendWelcomeEmail({
    required String recipientEmail,
    required String recipientName,
  }) async {
    try {
      if (_mailtrapApiToken.isEmpty) {
        print('EmailService: Mailtrap API token not configured');
        return false;
      }

      final response = await http.post(
        Uri.parse(_mailtrapApiUrl),
        headers: {
          'Authorization': 'Bearer $_mailtrapApiToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'from': {'email': _fromEmail, 'name': _fromName},
          'to': [
            {'email': recipientEmail, 'name': recipientName},
          ],
          'subject': '🎉 Welcome to Neu Todo!',
          'html': _buildWelcomeEmailTemplate(recipientName),
          'category': 'welcome',
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('EmailService: Welcome email error: $e');
      return false;
    }
  }

  static String _buildWelcomeEmailTemplate(String recipientName) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <style>
            body { font-family: Arial, sans-serif; background-color: #F7F7FB; margin: 0; padding: 20px; }
            .container { max-width: 500px; margin: 0 auto; background-color: white; border: 3px solid #000; box-shadow: 8px 8px 0px #000; }
            .header { background: linear-gradient(135deg, #9CC5FF 0%, #FFF3B0 100%); padding: 30px; text-align: center; border-bottom: 3px solid #000; }
            .content { padding: 30px; }
            .button { display: inline-block; background-color: #C6F6D5; color: #000; padding: 12px 24px; text-decoration: none; border: 3px solid #000; border-radius: 8px; font-weight: 900; box-shadow: 4px 4px 0px #000; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🎉 Welcome to Neu Todo!</h1>
            </div>
            <div class="content">
                <h2>Hello $recipientName!</h2>
                <p>Welcome to the most beautiful and productive todo app! 🚀</p>
                <p>Start organizing your tasks with style and collaborate with others seamlessly.</p>
                <a href="#" class="button">Get Started</a>
            </div>
        </div>
    </body>
    </html>
    ''';
  }

  // Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Test Mailtrap connection and configuration
  static Future<Map<String, dynamic>> testConfiguration() async {
    try {
      print('EmailService: Testing Mailtrap configuration...');
      print(
        'EmailService: API Token configured: ${_mailtrapApiToken.isNotEmpty}',
      );
      print('EmailService: From email: $_fromEmail');
      print('EmailService: From name: $_fromName');

      if (_mailtrapApiToken.isEmpty) {
        return {
          'success': false,
          'error': 'MAILTRAP_API_TOKEN not configured in .env file',
          'suggestions': [
            '1. Get your API token from Mailtrap.io → Email Sending → Integration',
            '2. Add MAILTRAP_API_TOKEN=your_token_here to your .env file',
            '3. Restart your app',
          ],
        };
      }

      if (_fromEmail == 'your_verified_domain_email@yourdomain.com') {
        return {
          'success': false,
          'error': 'MAILTRAP_FROM_EMAIL not properly configured',
          'suggestions': [
            '1. Verify a domain in Mailtrap.io → Email Sending → Domains',
            '2. Update MAILTRAP_FROM_EMAIL=yourname@yourdomain.com in .env file',
            '3. Make sure the domain is verified in Mailtrap',
          ],
        };
      }

      // Test with a simple request to Mailtrap API
      final response = await http.get(
        Uri.parse('https://mailtrap.io/api/v1/inboxes'),
        headers: {
          'Authorization': 'Bearer $_mailtrapApiToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Mailtrap configuration is valid',
          'details': {
            'api_access': 'OK',
            'from_email': _fromEmail,
            'from_name': _fromName,
          },
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Invalid API token or insufficient permissions',
          'suggestions': [
            '1. Check your API token in Mailtrap.io → Email Sending → Integration',
            '2. Make sure the token has "Email Sending" permissions',
            '3. Try regenerating the API token if needed',
          ],
        };
      } else {
        return {
          'success': false,
          'error': 'Unexpected response from Mailtrap API',
          'details': {
            'status_code': response.statusCode,
            'response': response.body,
          },
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to connect to Mailtrap API',
        'exception': e.toString(),
        'suggestions': [
          '1. Check your internet connection',
          '2. Verify Mailtrap API endpoint is accessible',
          '3. Check if there are any firewall restrictions',
        ],
      };
    }
  }

  // Test Mailtrap connection
  static Future<bool> testMailtrapConnection() async {
    try {
      if (_mailtrapApiToken.isEmpty) {
        print('EmailService: Mailtrap API token not configured');
        return false;
      }

      final response = await http.get(
        Uri.parse('https://mailtrap.io/api/accounts'),
        headers: {'Authorization': 'Bearer $_mailtrapApiToken'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('EmailService: Mailtrap connection test failed: $e');
      return false;
    }
  }
}
