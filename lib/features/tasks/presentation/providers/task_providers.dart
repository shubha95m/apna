import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apna/features/documents/presentation/providers/document_providers.dart';
import 'package:apna/features/tasks/domain/entities/task_entity.dart';
import 'package:apna/features/tasks/domain/repositories/task_repository.dart';
import 'package:apna/features/tasks/data/datasources/task_remote_datasource.dart';
import 'package:apna/features/tasks/data/repositories/task_repository_impl.dart';

final taskRemoteDataSourceProvider = Provider<TaskRemoteDataSource>((ref) {
  return TaskRemoteDataSourceImpl();
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final remoteDataSource = ref.watch(taskRemoteDataSourceProvider);
  return TaskRepositoryImpl(remoteDataSource);
});

class TaskListNotifier extends StateNotifier<AsyncValue<List<TaskEntity>>> {
  final TaskRepository _repository;
  final String _workspaceId;

  TaskListNotifier(this._repository, this._workspaceId)
      : super(const AsyncValue.loading()) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    state = const AsyncValue.loading();
    final result = await _repository.getTasks(_workspaceId);
    result.fold(
      (tasks) => state = AsyncValue.data(tasks),
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
    );
  }

  Future<void> addTask(TaskEntity task) async {
    final result = await _repository.addTask(task);
    result.fold(
      (newTask) {
        final current = state.value ?? [];
        state = AsyncValue.data([newTask, ...current]);
      },
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
    );
  }

  Future<void> toggleTaskStatus(TaskEntity task) async {
    final newStatus = task.isCompleted ? 'pending' : 'completed';
    final current = state.value ?? [];
    final updatedList = current.map((t) => t.id == task.id ? t.copyWith(status: newStatus) : t).toList();
    state = AsyncValue.data(updatedList);

    final result = await _repository.updateTaskStatus(task.id, newStatus);
    result.fold(
      (updatedTask) {
        state = AsyncValue.data(current.map((t) => t.id == task.id ? updatedTask : t).toList());
      },
      (failure) {
        state = AsyncValue.data(current);
      },
    );
  }

  Future<void> deleteTask(String taskId) async {
    final current = state.value ?? [];
    state = AsyncValue.data(current.where((t) => t.id != taskId).toList());
    await _repository.deleteTask(taskId);
  }
}

final taskListNotifierProvider =
    StateNotifierProvider<TaskListNotifier, AsyncValue<List<TaskEntity>>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  return TaskListNotifier(repository, workspaceId);
});
