import 'package:flutter/material.dart';
import 'package:buildables_neu_todo/core/app_colors.dart';
import 'package:buildables_neu_todo/models/task.dart';

class HomeTab extends StatelessWidget {
  final List<Task> tasks;
  final int completedCount;
  final int pendingCount;
  final VoidCallback onViewAll;
  final void Function(int index) onToggle;

  const HomeTab({
    super.key,
    required this.tasks,
    required this.completedCount,
    required this.pendingCount,
    required this.onViewAll,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Welcome back',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                '${completedCount + pendingCount} total tasks',
                style: const TextStyle(color: AppColors.textMuted),
              ),
              trailing: CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.accentCyan,
                child: const Icon(Icons.person, color: Colors.black),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    value: completedCount.toString(),
                    label: 'Completed',
                    color: AppColors.accentGreen,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _StatCard(
                    value: pendingCount.toString(),
                    label: 'Pending',
                    color: AppColors.accentOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'All tasks',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                TextButton.icon(
                  onPressed: onViewAll,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('View all'),
                  style: TextButton.styleFrom(foregroundColor: Colors.black),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Expanded(
              child: tasks.isEmpty
                  ? const Center(
                      child: Text(
                        'No tasks yet. Add your first one!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, i) {
                        final task = tasks[i];
                        final tileColor = task.done
                            ? AppColors.accentGreen
                            : AppColors.surface;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: tileColor,
                              border: Border.all(color: Colors.black, width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              dense: false,
                              leading: Checkbox(
                                value: task.done,
                                onChanged: (_) => onToggle(i),
                                activeColor: Colors.black,
                                checkColor: tileColor,
                                side: const BorderSide(
                                  color: Colors.black,
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              title: Text(
                                task.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  decoration: task.done
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                              ),
                              subtitle: task.category != null
                                  ? Text(
                                      task.category!,
                                      style: const TextStyle(fontSize: 12),
                                    )
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      height: 100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
