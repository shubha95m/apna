import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_remote_datasource.dart';
import '../models/task_model.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource _remoteDataSource;
  final List<TaskModel> _localCache = [];

  TaskRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<List<TaskEntity>, AppFailure>> getTasks(String workspaceId) async {
    try {
      final remoteTasks = await _remoteDataSource.getTasks(workspaceId);
      _localCache.clear();
      _localCache.addAll(remoteTasks);
      return Success(remoteTasks);
    } catch (e) {
      if (_localCache.isNotEmpty) {
        return Success(_localCache.where((t) => t.workspaceId == workspaceId).toList());
      }
      return Failure(DatabaseFailure('Failed to load tasks: $e'));
    }
  }

  @override
  Future<Result<TaskEntity, AppFailure>> addTask(TaskEntity task) async {
    try {
      final model = TaskModel.fromEntity(task);
      final saved = await _remoteDataSource.addTask(model);
      _localCache.insert(0, saved);
      return Success(saved);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to add task: $e'));
    }
  }

  @override
  Future<Result<TaskEntity, AppFailure>> updateTaskStatus(String taskId, String status) async {
    try {
      final updated = await _remoteDataSource.updateTaskStatus(taskId, status);
      final index = _localCache.indexWhere((t) => t.id == taskId);
      if (index != -1) _localCache[index] = updated;
      return Success(updated);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to update task: $e'));
    }
  }

  @override
  Future<Result<void, AppFailure>> deleteTask(String taskId) async {
    try {
      await _remoteDataSource.deleteTask(taskId);
      _localCache.removeWhere((t) => t.id == taskId);
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to delete task: $e'));
    }
  }
}
