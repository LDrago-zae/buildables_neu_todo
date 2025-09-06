import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  // Mailtrap API configuration
  static const String _baseUrl = 'https://send.api.mailtrap.io/api/send';

  String? get _apiToken => dotenv.env['MAILTRAP_API_TOKEN'];
  String? get _fromEmail => dotenv.env['MAILTRAP_FROM_EMAIL'];
  String? get _fromName => dotenv.env['MAILTRAP_FROM_NAME'];

  // Check if email service is configured
  bool get isConfigured =>
      _apiToken != null && _fromEmail != null && _fromName != null;

  // Send task sharing notification email
  Future<bool> sendTaskShareNotification({
    required String recipientEmail,
    required String recipientName,
    required String taskTitle,
    required String taskCategory,
    required String sharerName,
    required String sharerEmail,
    String? taskDescription,
    String? attachmentUrl,
  }) async {
    if (!isConfigured) {
      print('Email service not configured. Please check your .env file.');
      return false;
    }

    try {
      final subject = 'Task Shared: $taskTitle';

      final htmlContent = _buildTaskShareHtml(
        recipientName: recipientName,
        taskTitle: taskTitle,
        taskCategory: taskCategory,
        sharerName: sharerName,
        sharerEmail: sharerEmail,
        taskDescription: taskDescription,
        attachmentUrl: attachmentUrl,
      );

      final textContent = _buildTaskShareText(
        recipientName: recipientName,
        taskTitle: taskTitle,
        taskCategory: taskCategory,
        sharerName: sharerName,
        sharerEmail: sharerEmail,
        taskDescription: taskDescription,
        attachmentUrl: attachmentUrl,
      );

      final response = await _sendEmail(
        to: recipientEmail,
        toName: recipientName,
        subject: subject,
        htmlContent: htmlContent,
        textContent: textContent,
      );

      return response;
    } catch (e) {
      print('Error sending task share notification: $e');
      return false;
    }
  }

  // Send welcome email for new users
  Future<bool> sendWelcomeEmail({
    required String recipientEmail,
    required String recipientName,
  }) async {
    if (!isConfigured) {
      print('Email service not configured. Please check your .env file.');
      return false;
    }

    try {
      final subject = 'Welcome to Buildables Neu Todo!';

      final htmlContent = _buildWelcomeHtml(recipientName);
      final textContent = _buildWelcomeText(recipientName);

      final response = await _sendEmail(
        to: recipientEmail,
        toName: recipientName,
        subject: subject,
        htmlContent: htmlContent,
        textContent: textContent,
      );

      return response;
    } catch (e) {
      print('Error sending welcome email: $e');
      return false;
    }
  }

  // Send task completion notification
  Future<bool> sendTaskCompletionNotification({
    required String recipientEmail,
    required String recipientName,
    required String taskTitle,
    required String completedByName,
  }) async {
    if (!isConfigured) {
      print('Email service not configured. Please check your .env file.');
      return false;
    }

    try {
      final subject = 'Task Completed: $taskTitle';

      final htmlContent = _buildTaskCompletionHtml(
        recipientName: recipientName,
        taskTitle: taskTitle,
        completedByName: completedByName,
      );

      final textContent = _buildTaskCompletionText(
        recipientName: recipientName,
        taskTitle: taskTitle,
        completedByName: completedByName,
      );

      final response = await _sendEmail(
        to: recipientEmail,
        toName: recipientName,
        subject: subject,
        htmlContent: htmlContent,
        textContent: textContent,
      );

      return response;
    } catch (e) {
      print('Error sending task completion notification: $e');
      return false;
    }
  }

  // Core method to send email via Mailtrap API
  Future<bool> _sendEmail({
    required String to,
    required String toName,
    required String subject,
    required String htmlContent,
    required String textContent,
  }) async {
    try {
      final headers = {
        'Api-Token': _apiToken!,
        'Content-Type': 'application/json',
      };

      final body = {
        'to': [
          {'email': to, 'name': toName},
        ],
        'from': {'email': _fromEmail!, 'name': _fromName!},
        'subject': subject,
        'html': htmlContent,
        'text': textContent,
      };

      print('Sending email to: $to');
      print('Subject: $subject');

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        print('Email sent successfully');
        return true;
      } else {
        print('Failed to send email. Status: ${response.statusCode}');
        print('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending email: $e');
      return false;
    }
  }

  // Build HTML content for task sharing notification
  String _buildTaskShareHtml({
    required String recipientName,
    required String taskTitle,
    required String taskCategory,
    required String sharerName,
    required String sharerEmail,
    String? taskDescription,
    String? attachmentUrl,
  }) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Task Shared with You</title>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 20px; background-color: #f4f4f4; }
            .container { max-width: 600px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
            .header { text-align: center; margin-bottom: 30px; }
            .logo { font-size: 24px; font-weight: bold; color: #2c3e50; margin-bottom: 10px; }
            .task-card { background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #3498db; }
            .task-title { font-size: 20px; font-weight: bold; color: #2c3e50; margin-bottom: 10px; }
            .task-category { background: #3498db; color: white; padding: 4px 12px; border-radius: 20px; font-size: 12px; display: inline-block; margin-bottom: 10px; }
            .task-description { color: #666; margin: 10px 0; }
            .attachment { background: #e8f4fd; padding: 15px; border-radius: 5px; margin: 15px 0; }
            .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
            .button { display: inline-block; background: #3498db; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; margin: 20px 0; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <div class="logo">📋 Buildables Neu Todo</div>
                <p>You have a new shared task!</p>
            </div>
            
            <div class="task-card">
                <div class="task-category">$taskCategory</div>
                <div class="task-title">$taskTitle</div>
                ${taskDescription != null ? '<div class="task-description">$taskDescription</div>' : ''}
                ${attachmentUrl != null ? '<div class="attachment">📎 This task has an attachment</div>' : ''}
            </div>
            
            <p>Hello <strong>$recipientName</strong>,</p>
            <p><strong>$sharerName</strong> ($sharerEmail) has shared a task with you in Buildables Neu Todo.</p>
            
            <p>You can now view and collaborate on this task in your app.</p>
            
            <div style="text-align: center;">
                <a href="#" class="button">Open in App</a>
            </div>
            
            <div class="footer">
                <p>This email was sent from Buildables Neu Todo</p>
                <p>If you didn't expect this email, you can safely ignore it.</p>
            </div>
        </div>
    </body>
    </html>
    ''';
  }

  // Build text content for task sharing notification
  String _buildTaskShareText({
    required String recipientName,
    required String taskTitle,
    required String taskCategory,
    required String sharerName,
    required String sharerEmail,
    String? taskDescription,
    String? attachmentUrl,
  }) {
    return '''
TASK SHARED WITH YOU
===================

Hello $recipientName,

$sharerName ($sharerEmail) has shared a task with you in Buildables Neu Todo.

Task Details:
- Title: $taskTitle
- Category: $taskCategory
${taskDescription != null ? '- Description: $taskDescription' : ''}
${attachmentUrl != null ? '- Has Attachment: Yes' : ''}

You can now view and collaborate on this task in your app.

Best regards,
Buildables Neu Todo Team
    ''';
  }

  // Build HTML content for welcome email
  String _buildWelcomeHtml(String recipientName) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Welcome to Buildables Neu Todo</title>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 20px; background-color: #f4f4f4; }
            .container { max-width: 600px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
            .header { text-align: center; margin-bottom: 30px; }
            .logo { font-size: 24px; font-weight: bold; color: #2c3e50; margin-bottom: 10px; }
            .feature { background: #f8f9fa; padding: 15px; margin: 10px 0; border-radius: 5px; border-left: 4px solid #3498db; }
            .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <div class="logo">📋 Buildables Neu Todo</div>
                <h1>Welcome, $recipientName!</h1>
            </div>
            
            <p>Thank you for joining Buildables Neu Todo! We're excited to help you stay organized and productive.</p>
            
            <h3>What you can do:</h3>
            <div class="feature">
                <strong>📝 Create Tasks</strong><br>
                Add tasks with categories, descriptions, and due dates.
            </div>
            <div class="feature">
                <strong>👥 Collaborate</strong><br>
                Share tasks with team members and work together.
            </div>
            <div class="feature">
                <strong>📎 Attach Files</strong><br>
                Add attachments to your tasks for better organization.
            </div>
            <div class="feature">
                <strong>📱 Sync Everywhere</strong><br>
                Access your tasks from any device, online or offline.
            </div>
            
            <p>Get started by creating your first task in the app!</p>
            
            <div class="footer">
                <p>Happy organizing!</p>
                <p>The Buildables Neu Todo Team</p>
            </div>
        </div>
    </body>
    </html>
    ''';
  }

  // Build text content for welcome email
  String _buildWelcomeText(String recipientName) {
    return '''
WELCOME TO BUILDABLES NEU TODO
==============================

Hello $recipientName,

Thank you for joining Buildables Neu Todo! We're excited to help you stay organized and productive.

WHAT YOU CAN DO:
- Create Tasks: Add tasks with categories, descriptions, and due dates
- Collaborate: Share tasks with team members and work together
- Attach Files: Add attachments to your tasks for better organization
- Sync Everywhere: Access your tasks from any device, online or offline

Get started by creating your first task in the app!

Happy organizing!
The Buildables Neu Todo Team
    ''';
  }

  // Build HTML content for task completion notification
  String _buildTaskCompletionHtml({
    required String recipientName,
    required String taskTitle,
    required String completedByName,
  }) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Task Completed</title>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 20px; background-color: #f4f4f4; }
            .container { max-width: 600px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
            .header { text-align: center; margin-bottom: 30px; }
            .logo { font-size: 24px; font-weight: bold; color: #2c3e50; margin-bottom: 10px; }
            .task-card { background: #d4edda; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #28a745; }
            .task-title { font-size: 20px; font-weight: bold; color: #155724; margin-bottom: 10px; }
            .completed-badge { background: #28a745; color: white; padding: 4px 12px; border-radius: 20px; font-size: 12px; display: inline-block; margin-bottom: 10px; }
            .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <div class="logo">📋 Buildables Neu Todo</div>
                <p>Task Completed! 🎉</p>
            </div>
            
            <div class="task-card">
                <div class="completed-badge">✅ COMPLETED</div>
                <div class="task-title">$taskTitle</div>
            </div>
            
            <p>Hello <strong>$recipientName</strong>,</p>
            <p><strong>$completedByName</strong> has completed the task: <strong>$taskTitle</strong></p>
            
            <p>Great job on the collaboration!</p>
            
            <div class="footer">
                <p>This notification was sent from Buildables Neu Todo</p>
            </div>
        </div>
    </body>
    </html>
    ''';
  }

  // Build text content for task completion notification
  String _buildTaskCompletionText({
    required String recipientName,
    required String taskTitle,
    required String completedByName,
  }) {
    return '''
TASK COMPLETED! 🎉
=================

Hello $recipientName,

$completedByName has completed the task: $taskTitle

Great job on the collaboration!

Best regards,
Buildables Neu Todo Team
    ''';
  }
}
