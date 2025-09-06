import 'package:flutter/material.dart';
import 'package:buildables_neu_todo/core/app_colors.dart';
import 'package:buildables_neu_todo/services/email_service.dart';

class EmailConfigWidget extends StatefulWidget {
  const EmailConfigWidget({super.key});

  @override
  State<EmailConfigWidget> createState() => _EmailConfigWidgetState();
}

class _EmailConfigWidgetState extends State<EmailConfigWidget> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailService = EmailService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _sendTestEmail() async {
    if (_emailController.text.isEmpty || _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both email and name'),
          backgroundColor: AppColors.accentPink,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (!_emailService.isConfigured) {
        throw Exception('Email service not configured. Check .env file.');
      }

      final success = await _emailService.sendWelcomeEmail(
        recipientEmail: _emailController.text.trim(),
        recipientName: _nameController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Test email sent successfully! Check your Mailtrap inbox.'
                  : 'Failed to send test email. Verify Mailtrap credentials.',
            ),
            backgroundColor: success
                ? AppColors.accentGreen
                : AppColors.accentPink,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.accentPink,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.email, color: AppColors.textPrimary),
                const SizedBox(width: 8),
                Text(
                  'Email Configuration Test',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'Configured: ${_emailService.isConfigured ? "✅ Yes" : "❌ No"}',
              style: TextStyle(
                color: _emailService.isConfigured
                    ? AppColors.accentGreen
                    : AppColors.accentPink,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            if (!_emailService.isConfigured) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accentPink.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.accentPink.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email service not configured',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentPink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please add the following to your .env file:\n'
                      'MAILTRAP_API_TOKEN=your_smtp_username\n'
                      'MAILTRAP_FROM_EMAIL=your_email@domain.com\n'
                      'MAILTRAP_FROM_NAME=Buildables Todo',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Recipient Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Recipient Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendTestEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGreen,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text('Send Test Email'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
