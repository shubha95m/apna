import '../../domain/entities/note_entity.dart';

class NoteModel extends NoteEntity {
  const NoteModel({
    required super.id,
    required super.workspaceId,
    required super.ownerId,
    required super.title,
    required super.content,
    super.isPinned,
    super.color,
    super.tags,
    required super.createdAt,
    required super.updatedAt,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] as String,
      workspaceId: json['workspace_id'] as String,
      ownerId: json['owner_id'] as String,
      title: json['title'] as String,
      content: json['content'] as String? ?? '',
      isPinned: json['is_pinned'] as bool? ?? false,
      color: json['color'] as String? ?? '#FFFFFF',
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workspace_id': workspaceId,
      'owner_id': ownerId,
      'title': title,
      'content': content,
      'is_pinned': isPinned,
      'color': color,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
