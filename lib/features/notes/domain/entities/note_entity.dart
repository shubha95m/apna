class NoteEntity {
  final String id;
  final String workspaceId;
  final String ownerId;
  final String title;
  final String content;
  final bool isPinned;
  final String color;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NoteEntity({
    required this.id,
    required this.workspaceId,
    required this.ownerId,
    required this.title,
    required this.content,
    this.isPinned = false,
    this.color = '#FFFFFF',
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });
}
