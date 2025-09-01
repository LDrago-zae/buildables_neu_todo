import 'package:flutter/material.dart';
import 'package:buildables_neu_todo/core/app_colors.dart';
import 'package:buildables_neu_todo/views/widgets/file_picker_test_widget.dart';

class ProfileTab extends StatelessWidget {
  final int completed;
  final int pending;
  final VoidCallback onLogout;

  const ProfileTab({
    super.key,
    required this.completed,
    required this.pending,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
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
