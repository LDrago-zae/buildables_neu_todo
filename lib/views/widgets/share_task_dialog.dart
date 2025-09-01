import 'package:flutter/material.dart';
import 'package:buildables_neu_todo/core/app_colors.dart';

class ShareTaskDialog extends StatefulWidget {
  final Future<String?> Function(String email) onShare;

  const ShareTaskDialog({super.key, required this.onShare});

  @override
  State<ShareTaskDialog> createState() => _ShareTaskDialogState();
}

class _ShareTaskDialogState extends State<ShareTaskDialog> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleShare() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final error = await widget.onShare(_emailController.text.trim());

    if (mounted) {
      if (error == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task shared with ${_emailController.text.trim()}'),
            backgroundColor: AppColors.accentGreen,
          ),
        );
      } else {
        // Log the error to the terminal for debugging
        // ignore: avoid_print
        print('Share failed: ' + error);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.accentPink),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Row(
        children: [
          Icon(Icons.share, color: AppColors.textPrimary),
          const SizedBox(width: 8),
          Text(
            'SHARE TASK',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter email address:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                hintText: 'user@example.com',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter an email address';
                }
                if (!value!.contains('@') || !value.contains('.')) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(
            'CANCEL',
            style: TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _handleShare,
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('SHARE'),
        ),
      ],
    );
  }
}
