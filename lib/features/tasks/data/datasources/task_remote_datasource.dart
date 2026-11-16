import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../app/configuration/supabase_config.dart';
import '../models/task_model.dart';

abstract interface class TaskRemoteDataSource {
  Future<List<TaskModel>> getTasks(String workspaceId);
  Future<TaskModel> addTask(TaskModel task);
  Future<TaskModel> updateTaskStatus(String taskId, String status);
  Future<void> deleteTask(String taskId);
}

class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<List<TaskModel>> getTasks(String workspaceId) async {
    if (!SupabaseConfig.isConfigured) return [];

    final response = await _client
        .from('tasks')
        .select()
        .eq('workspace_id', workspaceId)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => TaskModel.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  @override
  Future<TaskModel> addTask(TaskModel task) async {
    if (!SupabaseConfig.isConfigured) return task;

    final creatorId = _client.auth.currentUser?.id ?? task.creatorId;
    final payload = {
      'id': task.id,
      'workspace_id': task.workspaceId,
      'creator_id': creatorId,
      'assigned_to_id': task.assignedToId,
      'title': task.title,
      'description': task.description,
      'status': task.status.toLowerCase(),
      'priority': task.priority.toLowerCase(),
      'due_date': task.dueDate?.toIso8601String(),
      'created_at': task.createdAt.toIso8601String(),
      'updated_at': task.updatedAt.toIso8601String(),
    };

    await _client.from('tasks').insert(payload);
    return task;
  }

  @override
  Future<TaskModel> updateTaskStatus(String taskId, String status) async {
    if (!SupabaseConfig.isConfigured) throw Exception('Supabase not configured');

    final response = await _client
        .from('tasks')
        .update({
          'status': status.toLowerCase(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', taskId)
        .select()
        .single();

    return TaskModel.fromMap(Map<String, dynamic>.from(response));
  }

  @override
  Future<void> deleteTask(String taskId) async {
    if (!SupabaseConfig.isConfigured) return;

    await _client
        .from('tasks')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', taskId);
  }
}
