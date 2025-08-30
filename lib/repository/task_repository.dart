import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';

class TaskRepository {
  static final TaskRepository _instance = TaskRepository._internal();
  factory TaskRepository() => _instance;
  TaskRepository._internal();

  late AppDatabase _localDb;
  late SupabaseClient _supabase;
  late Connectivity _connectivity;

  void initialize({required SupabaseClient supabase, required Connectivity connectivity}) {
    _localDb = AppDatabase();
    _supabase = supabase;
    _connectivity = connectivity;
  }

// Methods will be added below
}