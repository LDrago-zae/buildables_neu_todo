import 'dart:math';
import 'package:flutter/material.dart';
import 'package:buildables_neu_todo/core/app_colors.dart';
import 'package:buildables_neu_todo/models/task.dart';
import 'package:buildables_neu_todo/controllers/task_controller.dart';
import 'package:buildables_neu_todo/views/home/task_detail_screen.dart';

class SharedTab extends StatefulWidget {
  final TaskController taskController;
  final List<String> categories;

  const SharedTab({
    super.key,
    required this.taskController,
    required this.categories,
  });

  @override
  State<SharedTab> createState() => _SharedTabState();
}

class _SharedTabState extends State<SharedTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<Task> get _sharedTasks {
    return widget.taskController.tasks
        .where((task) => task.sharedWith != null && task.sharedWith!.isNotEmpty)
        .toList();
  }

  List<Task> get _filteredTasks {
    if (_selectedFilter == 'All') return _sharedTasks;
    if (_selectedFilter == 'Completed') {
      return _sharedTasks.where((task) => task.done).toList();
    }
    if (_selectedFilter == 'Pending') {
      return _sharedTasks.where((task) => !task.done).toList();
    }
    return _sharedTasks
        .where((task) => task.category == _selectedFilter)
        .toList();
  }

  Color _getRandomColor(String seed) {
    final colors = [
      AppColors.accentCyan,
      AppColors.accentGreen,
      AppColors.accentOrange,
      AppColors.accentPink,
      AppColors.accentYellow,
    ];
    return colors[seed.hashCode % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterChips(),
            const SizedBox(height: 20),
            Expanded(child: _buildSharedTasksList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accentCyan,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people, color: Colors.black, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${_sharedTasks.length} SHARED',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _animationController.value * 2 * pi,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentYellow,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: const Icon(Icons.sync, color: Colors.black, size: 20),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Completed', 'Pending', ...widget.categories];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accentYellow
                      : AppColors.surface,
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSharedTasksList() {
    if (_filteredTasks.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        itemCount: _filteredTasks.length,
        itemBuilder: (context, index) {
          final task = _filteredTasks[index];
          return _buildSharedTaskCard(task, index);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: const Icon(
              Icons.people_outline,
              size: 50,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No shared tasks yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tasks shared with you will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSharedTaskCard(Task task, int index) {
    final cardColor = task.done
        ? AppColors.accentGreen
        : _getRandomColor(task.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskDetailScreen(
                task: task,
                categories: widget.categories,
                onTaskUpdated: (updatedTask) {
                  // Handle task update
                  final taskIndex = widget.taskController.tasks.indexWhere(
                    (t) => t.id == updatedTask.id,
                  );
                  if (taskIndex != -1) {
                    widget.taskController.updateTask(
                      taskIndex,
                      title: updatedTask.title,
                      category: updatedTask.category,
                    );
                  }
                },
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(4, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: Icon(
                        task.done ? Icons.check : Icons.schedule,
                        size: 16,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              decoration: task.done
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                          if (task.category != null)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.black,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                task.category!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (task.hasAttachment)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.black, width: 1),
                        ),
                        child: const Icon(
                          Icons.attachment,
                          size: 16,
                          color: Colors.black,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 14,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FutureBuilder<String>(
                        future: _getCreatorEmail(task.createdBy),
                        builder: (context, snapshot) {
                          return Text(
                            snapshot.data ?? 'Loading...',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.share,
                            size: 12,
                            color: Colors.black.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${(task.sharedWith?.length ?? 0) + 1}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.black.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (task.createdAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _formatDate(task.createdAt!),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.black.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<String> _getCreatorEmail(String? creatorId) async {
    if (creatorId == null) return 'Unknown User';

    try {
      return await widget.taskController.getUserEmail(creatorId);
    } catch (e) {
      return 'Unknown User';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
