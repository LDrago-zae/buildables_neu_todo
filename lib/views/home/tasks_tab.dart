import 'package:flutter/material.dart';
import 'package:buildables_neu_todo/core/app_colors.dart';
import 'package:buildables_neu_todo/models/task.dart';
import 'package:buildables_neu_todo/views/widgets/category_chip_selector.dart';

class TasksTab extends StatelessWidget {
  final List<Task> tasks;
  final List<String> categories;
  final VoidCallback onAddTaskTap;
  final void Function(int index) onToggle;
  final void Function(int index) onDelete;
  final void Function(int index, String title, String? category) onEdit;

  const TasksTab({
    super.key,
    required this.tasks,
    required this.categories,
    required this.onAddTaskTap,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentYellow,
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'YOUR TASKS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ALL TASKS',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentYellow,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      side: const BorderSide(color: Colors.black, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: onAddTaskTap,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(
                      'ADD TASK',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: tasks.isEmpty
                  ? const Center(
                      child: Text(
                        'No tasks yet. Add your first one!',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    )
                  : ListView.separated(
                      itemCount: tasks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        final Color tileColor = task.done
                            ? AppColors.accentGreen
                            : AppColors.surface;
                        return Container(
                          decoration: BoxDecoration(
                            color: tileColor,
                            border: Border.all(color: Colors.black, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: Checkbox(
                              value: task.done,
                              onChanged: (_) => onToggle(index),
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
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Edit',
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) {
                                        final textController =
                                            TextEditingController(
                                              text: task.title,
                                            );
                                        String? selected = task.category;
                                        return AlertDialog(
                                          title: const Text('Update Task'),
                                          content: SingleChildScrollView(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                TextField(
                                                  controller: textController,
                                                  decoration:
                                                      const InputDecoration(
                                                        hintText: 'Title',
                                                      ),
                                                ),
                                                const SizedBox(height: 12),
                                                CategoryChipSelector(
                                                  categories: categories,
                                                  selectedCategory: selected,
                                                  onCategorySelected: (c) {
                                                    selected = c;
                                                  },
                                                ),
                                                const SizedBox(height: 8),
                                              ],
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx),
                                              child: const Text('CANCEL'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(ctx);
                                                onEdit(
                                                  index,
                                                  textController.text.trim(),
                                                  selected,
                                                );
                                              },
                                              child: const Text('SAVE'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.black,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Delete',
                                  onPressed: () => onDelete(index),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
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
