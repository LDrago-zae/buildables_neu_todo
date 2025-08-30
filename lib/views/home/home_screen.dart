import 'package:flutter/material.dart';
import 'package:buildables_neu_todo/core/app_colors.dart';
import '../auth/login_screen.dart';
import 'package:buildables_neu_todo/controllers/task_controller.dart';
import 'package:buildables_neu_todo/models/task.dart';
import 'package:buildables_neu_todo/views/widgets/app_bottom_nav.dart';
import 'home_tab.dart';
import 'tasks_tab.dart';
import 'profile_tab.dart';
import 'add_task_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late final TaskController _taskController;
  final List<String> _categories = const <String>[
    'Work',
    'Personal',
    'Study',
    'Shopping',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _taskController = TaskController(initial: const <Task>[])
      ..addListener(() => setState(() {}));
  }

  void _showAddTaskSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return AddTaskBottomSheet(
          categories: _categories,
          onSubmit: (title, category) {
            setState(() {
              _taskController.addTask(title, category: category);
            });
          },
          onError: (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to add task: $error')),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _buildBody(),
      bottomNavigationBar: AppBottomNav(
        selectedIndex: _selectedIndex,
        onTabChange: (index) => setState(() => _selectedIndex = index),
      ),
      floatingActionButton: _selectedIndex != 2
          ? FloatingActionButton(
              backgroundColor: AppColors.accentYellow,
              onPressed: _showAddTaskSheet,
              child: const Icon(Icons.add, color: Colors.black),
            )
          : null,
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return HomeTab(
          tasks: _taskController.tasks,
          completedCount: _taskController.completedCount,
          pendingCount: _taskController.pendingCount,
          onViewAll: () => setState(() => _selectedIndex = 1),
          onToggle: (i) => _taskController.toggleTask(i),
        );
      case 1:
        return TasksTab(
          tasks: _taskController.tasks,
          categories: _categories,
          onAddTaskTap: _showAddTaskSheet,
          onToggle: (i) => _taskController.toggleTask(i),
          onDelete: (i) => _taskController.deleteTask(i),
          onEdit: (i, title, category) =>
              _taskController.updateTask(i, title: title, category: category),
        );
      case 2:
      default:
        final completed = _taskController.completedCount;
        final pending = _taskController.pendingCount;
        return ProfileTab(
          completed: completed,
          pending: pending,
          onLogout: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          },
        );
    }
  }
}
