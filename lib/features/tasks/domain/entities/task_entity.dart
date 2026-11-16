class TaskEntity {
  final String id;
  final String workspaceId;
  final String creatorId;
  final String? assignedToId;
  final String title;
  final String? description;
  final String status; // 'pending', 'in_progress', 'completed', 'cancelled'
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskEntity({
    required this.id,
    required this.workspaceId,
    required this.creatorId,
    this.assignedToId,
    required this.title,
    this.description,
    this.status = 'pending',
    this.priority = 'medium',
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isCompleted => status == 'completed';

  TaskEntity copyWith({
    String? id,
    String? workspaceId,
    String? creatorId,
    String? assignedToId,
    String? title,
    String? description,
    String? status,
    String? priority,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskEntity(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      creatorId: creatorId ?? this.creatorId,
      assignedToId: assignedToId ?? this.assignedToId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
