import '../../domain/entities/calendar_event_entity.dart';

class CalendarEventModel extends CalendarEventEntity {
  const CalendarEventModel({
    required super.id,
    required super.workspaceId,
    required super.ownerId,
    required super.title,
    required super.description,
    required super.startTime,
    super.endTime,
    super.isAllDay,
    super.category,
    super.referenceId,
  });

  factory CalendarEventModel.fromJson(Map<String, dynamic> json) {
    return CalendarEventModel(
      id: json['id'] as String,
      workspaceId: json['workspace_id'] as String,
      ownerId: json['owner_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time'] as String) : null,
      isAllDay: json['is_all_day'] as bool? ?? false,
      category: json['category'] as String? ?? 'general',
      referenceId: json['reference_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workspace_id': workspaceId,
      'owner_id': ownerId,
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'is_all_day': isAllDay,
      'category': category,
      'reference_id': referenceId,
    };
  }
}
