import 'package:flutter/material.dart';
import 'package:buildables_neu_todo/core/app_colors.dart';
import 'package:buildables_neu_todo/views/widgets/file_picker_test_widget.dart';
import 'package:buildables_neu_todo/controllers/task_controller.dart';

class ProfileTab extends StatelessWidget {
  final int completed;
  final int pending;
  final VoidCallback onLogout;
  final TaskController? taskController;

  const ProfileTab({
    super.key,
    required this.completed,
    required this.pending,
    required this.onLogout,
    this.taskController,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Profile',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              ),
              subtitle: const Text(
                'Account and stats',
                style: TextStyle(color: AppColors.textMuted),
              ),
              trailing: CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.accentPink,
                child: const Icon(Icons.person, color: Colors.black),
              ),
            ),
            const SizedBox(height: 50),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.person, size: 72, color: Colors.black),
                    const SizedBox(height: 20),
                    const Text(
                      'Hello User!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'user@example.com',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _StatPill(
                            label: 'Completed',
                            color: AppColors.accentGreen,
                            value: completed,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatPill(
                            label: 'Pending',
                            color: AppColors.accentOrange,
                            value: pending,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentCyan,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          side: const BorderSide(color: Colors.black, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const FilePickerTestWidget(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.bug_report),
                        label: const Text(
                          'Test File Picker',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Edge Function Test Button
                    if (taskController != null) ...[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.accentCyan,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            _showLoadingSnackBar(
                              context,
                              'Testing Edge Function...',
                            );

                            try {
                              final result = await taskController!
                                  .testEdgeFunction();
                              _hideLoadingSnackBar(context);

                              if (result['success']) {
                                _showSuccessSnackBar(
                                  context,
                                  'Edge Function Test Successful!',
                                  'Duration: ${result['duration_ms']}ms\nStatus: ${result['status']}',
                                );
                              } else {
                                _showErrorSnackBar(
                                  context,
                                  'Edge Function Test Failed',
                                  result['error'] ?? 'Unknown error',
                                );
                              }
                            } catch (e) {
                              _hideLoadingSnackBar(context);
                              _showErrorSnackBar(
                                context,
                                'Test Failed',
                                e.toString(),
                              );
                            }
                          },
                          icon: const Icon(Icons.cloud_sync),
                          label: const Text(
                            'Test Edge Function',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Email Test Button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.accentOrange,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            _showLoadingSnackBar(
                              context,
                              'Testing Email Configuration...',
                            );

                            try {
                              await taskController!.testEmailConfiguration();
                              _hideLoadingSnackBar(context);
                              _showSuccessSnackBar(
                                context,
                                'Email Test Completed!',
                                'Check console/logs for detailed results',
                              );
                            } catch (e) {
                              _hideLoadingSnackBar(context);
                              _showErrorSnackBar(
                                context,
                                'Email Test Failed',
                                e.toString(),
                              );
                            }
                          },
                          icon: const Icon(Icons.email),
                          label: const Text(
                            'Test Email Config',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Process Pending Notifications Button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accentPink,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          _showLoadingSnackBar(
                            context,
                            'Processing pending notifications...',
                          );

                          try {
                            final result = await taskController!
                                .processPendingNotifications();
                            _hideLoadingSnackBar(context);

                            if (result['success']) {
                              _showSuccessSnackBar(
                                context,
                                'Notifications Processed!',
                                'Status: ${result['status']}\nData: ${result['data']}',
                              );
                            } else {
                              _showErrorSnackBar(
                                context,
                                'Failed to Process Notifications',
                                result['error'] ?? 'Unknown error',
                              );
                            }
                          } catch (e) {
                            _hideLoadingSnackBar(context);
                            _showErrorSnackBar(
                              context,
                              'Processing Failed',
                              e.toString(),
                            );
                          }
                        },
                        icon: const Icon(Icons.notifications_active),
                        label: const Text(
                          'Process Pending Notifications',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: onLogout,
                        icon: const Icon(Icons.logout),
                        label: const Text('Log out'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLoadingSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 30), // Long duration for loading
      ),
    );
  }

  void _hideLoadingSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  void _showSuccessSnackBar(
    BuildContext context,
    String title,
    String subtitle,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  child: const Icon(Icons.check, size: 12, color: Colors.black),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ],
        ),
        backgroundColor: AppColors.accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.black, width: 1),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String title, String subtitle) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: const Icon(Icons.error, size: 12, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.white, width: 1),
        ),
        duration: const Duration(seconds: 6),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final Color color;
  final int value;

  const _StatPill({
    required this.label,
    required this.color,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$value',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(width: 8),
            Text(
              label.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}
