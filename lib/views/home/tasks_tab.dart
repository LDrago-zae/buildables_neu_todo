import 'package:flutter/material.dart';
import 'package:buildables_neu_todo/core/app_colors.dart';
import 'package:buildables_neu_todo/models/task.dart';
import 'package:buildables_neu_todo/views/widgets/category_chip_selector.dart';
import 'package:buildables_neu_todo/views/widgets/share_task_dialog.dart';
import 'package:buildables_neu_todo/views/home/task_detail_screen.dart';
import 'package:buildables_neu_todo/views/widgets/file_thumbnail_widget.dart';

class TasksTab extends StatelessWidget {
  final List<Task> tasks;
  final List<String> categories;
  final VoidCallback onAddTaskTap;
  final void Function(int index) onToggle;
  final void Function(int index) onDelete;
  final void Function(int index, String title, String? category) onEdit;
  final Future<String?> Function(Task task, String email) onShare;
  final void Function(Task updatedTask) onTaskUpdated;

  const TasksTab({
    super.key,
    required this.tasks,
    required this.categories,
    required this.onAddTaskTap,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
    required this.onShare,
    required this.onTaskUpdated,
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
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      offset: const Offset(4, 4),
                      blurRadius: 8,
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.2),
                      offset: const Offset(-4, -4),
                      blurRadius: 8,
                    ),
                  ],
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
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentYellow,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      shadowColor: Colors.black.withOpacity(0.2),
                    ),
                    onPressed: onAddTaskTap,
                    icon: Transform.scale(
                      scale: 1.2,
                      child: const Icon(Icons.add, size: 20),
                    ),
                    label: const Text(
                      'ADD TASK',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: tasks.isEmpty
                  ? Center(
                      child: Text(
                        'No tasks yet. Add your first one!',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black.withOpacity(0.6),
                        ),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final double width = constraints.maxWidth;
                        int crossAxisCount = 1;
                        if (width >= 1200) {
                          crossAxisCount = 4;
                        } else if (width >= 900) {
                          crossAxisCount = 3;
                        } else if (width >= 600) {
                          crossAxisCount = 2;
                        }

                        return GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 4 / 2.2,
                              ),
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            return _buildTaskCard(context, task, index);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, Task task, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailScreen(
              task: task,
              categories: categories,
              onTaskUpdated: onTaskUpdated,
            ),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: task.done
              ? LinearGradient(
                  colors: [
                    AppColors.accentGreen.withOpacity(0.8),
                    AppColors.accentGreen.withOpacity(0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    AppColors.surface,
                    AppColors.surface.withOpacity(0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(4, 4),
              blurRadius: 8,
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.2),
              offset: const Offset(-4, -4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskDetailScreen(
                    task: task,
                    categories: categories,
                    onTaskUpdated: onTaskUpdated,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Transform.scale(
                        scale: 1.2,
                        child: Checkbox(
                          value: task.done,
                          onChanged: (_) => onToggle(index),
                          activeColor: Colors.black,
                          checkColor: AppColors.accentGreen,
                          side: BorderSide(
                            color: Colors.black.withOpacity(0.6),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    task.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      decoration: task.done
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                      color: Colors.black.withOpacity(0.9),
                                    ),
                                  ),
                                ),
                                if (task.hasAttachment) ...[
                                  const SizedBox(width: 8),
                                  FileThumbnailWidget(
                                    attachmentUrl: task.attachmentUrl,
                                    size: 24,
                                    showBorder: false,
                                  ),
                                ],
                              ],
                            ),
                            if (task.category != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    task.category!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black.withOpacity(0.7),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildActionButton(
                        icon: Icons.share,
                        tooltip: 'Share',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => ShareTaskDialog(
                              taskTitle: task.title,
                              onShare:
                                  (identifier, name, shareType, message) async {
                                    try {
                                      final result = await onShare(
                                        task,
                                        identifier,
                                      );
                                      if (result != null) {
                                        if (ctx.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(result),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                        throw Exception(result);
                                      }
                                    } catch (e) {
                                      rethrow;
                                    }
                                  },
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.edit,
                        tooltip: 'Edit',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) {
                              final textController = TextEditingController(
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
                                        decoration: const InputDecoration(
                                          hintText: 'Title',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(12),
                                            ),
                                          ),
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
                                    onPressed: () => Navigator.pop(ctx),
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
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.delete_outline,
                        tooltip: 'Delete',
                        onPressed: () => onDelete(index),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(2, 2),
                blurRadius: 4,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.1),
                offset: const Offset(-2, -2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Icon(icon, size: 20, color: Colors.black.withOpacity(0.8)),
        ),
      ),
    );
  }
}
