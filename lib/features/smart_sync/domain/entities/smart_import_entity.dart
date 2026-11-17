class SmartImportEntity {
  final String id;
  final String workspaceId;
  final String ownerId;
  final String sourceType; // 'sms', 'email', 'statement', 'manual'
  final String sender;
  final String snippet;
  final String parsedType; // 'bill', 'expense', 'warranty', 'task'
  final String? parsedId;
  final DateTime syncedAt;

  const SmartImportEntity({
    required this.id,
    required this.workspaceId,
    required this.ownerId,
    required this.sourceType,
    required this.sender,
    required this.snippet,
    required this.parsedType,
    this.parsedId,
    required this.syncedAt,
  });
}
