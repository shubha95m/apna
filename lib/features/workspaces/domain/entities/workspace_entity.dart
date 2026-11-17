class WorkspaceEntity {
  final String id;
  final String name;
  final String type; // 'personal' or 'family'
  final String ownerId;
  final String userRole; // 'owner', 'admin', 'writer', 'member', 'read_only', 'viewer'
  final DateTime createdAt;

  const WorkspaceEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.ownerId,
    required this.userRole,
    required this.createdAt,
  });

  bool get isPersonal => type == 'personal';
  bool get isFamily => type == 'family';
  bool get isOwner => userRole == 'owner';
  bool get isAdmin => userRole == 'owner' || userRole == 'admin';
  bool get canWrite =>
      userRole == 'owner' ||
      userRole == 'admin' ||
      userRole == 'writer' ||
      userRole == 'member';
  bool get isReadOnly => !canWrite;

  factory WorkspaceEntity.fromJson(Map<String, dynamic> json) {
    String resolvedRole = 'viewer';
    if (json['workspace_members'] != null && json['workspace_members'] is List) {
      final members = json['workspace_members'] as List;
      if (members.isNotEmpty && members.first is Map) {
        resolvedRole = (members.first['role'] as String?) ?? 'viewer';
      }
    } else if (json['role'] != null) {
      resolvedRole = json['role'] as String;
    }

    return WorkspaceEntity(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Workspace',
      type: json['type'] as String? ?? 'personal',
      ownerId: json['owner_id'] as String? ?? '',
      userRole: resolvedRole,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  WorkspaceEntity copyWith({
    String? id,
    String? name,
    String? type,
    String? ownerId,
    String? userRole,
    DateTime? createdAt,
  }) {
    return WorkspaceEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      ownerId: ownerId ?? this.ownerId,
      userRole: userRole ?? this.userRole,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
