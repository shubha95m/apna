import '../entities/calendar_event_entity.dart';

abstract class CalendarRepository {
  Future<List<CalendarEventEntity>> getEvents(String workspaceId);
  Future<CalendarEventEntity> createEvent(CalendarEventEntity event);
  Future<void> deleteEvent(String id);
}
