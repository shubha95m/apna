class CalendarEventEntity {
  final String id;
  final String workspaceId;
  final String ownerId;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isAllDay;
  final String category; // 'bill', 'warranty', 'health', 'task', 'general'
  final String? referenceId;

  const CalendarEventEntity({
    required this.id,
    required this.workspaceId,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.startTime,
    this.endTime,
    this.isAllDay = false,
    this.category = 'general',
    this.referenceId,
  });
}
