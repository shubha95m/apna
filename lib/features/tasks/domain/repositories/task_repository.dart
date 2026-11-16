import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/task_entity.dart';

abstract interface class TaskRepository {
  Future<Result<List<TaskEntity>, AppFailure>> getTasks(String workspaceId);
  Future<Result<TaskEntity, AppFailure>> addTask(TaskEntity task);
  Future<Result<TaskEntity, AppFailure>> updateTaskStatus(String taskId, String status);
  Future<Result<void, AppFailure>> deleteTask(String taskId);
}
