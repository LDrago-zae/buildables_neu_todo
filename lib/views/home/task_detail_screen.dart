import 'package:flutter/material.dart';
import 'package:buildables_neu_todo/core/app_colors.dart';
import 'package:buildables_neu_todo/models/task.dart';
import 'package:buildables_neu_todo/views/widgets/task_attachment_widget.dart';
import 'package:buildables_neu_todo/views/widgets/category_chip_selector.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;
  final List<String> categories;
  final Function(Task updatedTask) onTaskUpdated;

  const TaskDetailScreen({
    super.key,
    required this.task,
    required this.categories,
    required this.onTaskUpdated,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late TextEditingController _titleController;
  late String? _selectedCategory;
  late String? _attachmentUrl;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _selectedCategory = widget.task.category;
    _attachmentUrl = widget.task.attachmentUrl;

    print('TaskDetailScreen: Initialized with task: ${widget.task.title}');
    print('TaskDetailScreen: Attachment URL: $_attachmentUrl');
    print(
      'TaskDetailScreen: Task has attachment: ${widget.task.hasAttachment}',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final updatedTask = widget.task.copyWith(
      title: _titleController.text.trim(),
      category: _selectedCategory,
      attachmentUrl: _attachmentUrl,
      updatedAt: DateTime.now(),
    );

    widget.onTaskUpdated(updatedTask);
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TASK DETAILS',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: AppColors.background,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () {
              if (_isEditing) {
                _saveChanges();
              } else {
                setState(() => _isEditing = !_isEditing);
              }
            },
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            label: Text(_isEditing ? 'SAVE' : 'EDIT'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black,
              backgroundColor: AppColors.accentYellow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Colors.black, width: 2),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TITLE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_isEditing)
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter task title',
                      ),
                    )
                  else
                    Text(
                      widget.task.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Category Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CATEGORY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_isEditing)
                    CategoryChipSelector(
                      categories: widget.categories,
                      selectedCategory: _selectedCategory,
                      onCategorySelected: (category) {
                        setState(() => _selectedCategory = category);
                      },
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentCyan,
                        border: Border.all(color: Colors.black, width: 2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _selectedCategory ?? 'No category',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Status Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.task.done
                    ? AppColors.accentGreen
                    : AppColors.accentYellow,
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.task.done
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: Colors.black,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'STATUS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        widget.task.done ? 'COMPLETED' : 'PENDING',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Attachment Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ATTACHMENTS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TaskAttachmentWidget(
                    attachmentUrl: _attachmentUrl,
                    taskId: widget.task.id,
                    onAttachmentChanged: (newUrl) {
                      setState(() => _attachmentUrl = newUrl);
                      if (!_isEditing) {
                        // Auto-save attachment changes
                        final updatedTask = widget.task.copyWith(
                          attachmentUrl: newUrl,
                          updatedAt: DateTime.now(),
                        );
                        widget.onTaskUpdated(updatedTask);
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Sharing Section (if task has sharing capabilities)
            if (widget.task.sharedWith?.isNotEmpty == true)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentPurple,
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SHARED WITH',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...widget.task.sharedWith!.map(
                      (email) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.person,
                                size: 16,
                                color: Colors.black54,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                email,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Metadata Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DETAILS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMetadataRow(
                    'Created',
                    _formatDate(widget.task.createdAt),
                  ),
                  const SizedBox(height: 8),
                  _buildMetadataRow(
                    'Updated',
                    _formatDate(widget.task.updatedAt),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ),
        const Text(' : ', style: TextStyle(color: Colors.black54)),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
