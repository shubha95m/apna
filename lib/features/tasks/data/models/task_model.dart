import '../../domain/entities/task_entity.dart';

class TaskModel extends TaskEntity {
  const TaskModel({
    required super.id,
    required super.workspaceId,
    required super.creatorId,
    super.assignedToId,
    required super.title,
    super.description,
    super.status = 'pending',
    super.priority = 'medium',
    super.dueDate,
    required super.createdAt,
    required super.updatedAt,
  });

  factory TaskModel.fromEntity(TaskEntity entity) {
    return TaskModel(
      id: entity.id,
      workspaceId: entity.workspaceId,
      creatorId: entity.creatorId,
      assignedToId: entity.assignedToId,
      title: entity.title,
      description: entity.description,
      status: entity.status,
      priority: entity.priority,
      dueDate: entity.dueDate,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as String,
      workspaceId: map['workspace_id'] as String,
      creatorId: map['creator_id'] as String? ?? 'user-anonymous',
      assignedToId: map['assigned_to_id'] as String?,
      title: map['title'] as String,
      description: map['description'] as String?,
      status: map['status'] as String? ?? 'pending',
      priority: map['priority'] as String? ?? 'medium',
      dueDate: map['due_date'] != null ? DateTime.tryParse(map['due_date'] as String) : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workspace_id': workspaceId,
      'creator_id': creatorId,
      'assigned_to_id': assignedToId,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'due_date': dueDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
