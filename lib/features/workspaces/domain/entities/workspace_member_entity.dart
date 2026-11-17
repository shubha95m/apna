class WorkspaceMemberEntity {
  final String memberId;
  final String userId;
  final String email;
  final String fullName;
  final String role; // 'owner', 'admin', 'writer', 'member', 'read_only', 'viewer'
  final DateTime joinedAt;
  final bool isOwner;

  const WorkspaceMemberEntity({
    required this.memberId,
    required this.userId,
    required this.email,
    required this.fullName,
    required this.role,
    required this.joinedAt,
    required this.isOwner,
  });

  bool get isAdmin => isOwner || role == 'owner' || role == 'admin';
  bool get canWrite =>
      isOwner ||
      role == 'owner' ||
      role == 'admin' ||
      role == 'writer' ||
      role == 'member';
  bool get isReadOnly => !canWrite;

  String get displayName => fullName.isNotEmpty ? fullName : email.split('@').first;
  String get initials {
    final name = displayName.trim();
    if (name.isEmpty) return 'U';
    final parts = name.split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  factory WorkspaceMemberEntity.fromJson(Map<String, dynamic> json) {
    return WorkspaceMemberEntity(
      memberId: (json['member_id'] ?? json['id'] ?? '') as String,
      userId: (json['user_id'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      fullName: (json['full_name'] ?? '') as String,
      role: (json['role'] ?? 'viewer') as String,
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'] as String)
          : DateTime.now(),
      isOwner: (json['is_owner'] as bool?) ?? (json['role'] == 'owner'),
    );
  }
}
