import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/calendar_event_entity.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../models/calendar_event_model.dart';

class CalendarRepositoryImpl implements CalendarRepository {
  final SupabaseClient _client;

  CalendarRepositoryImpl(this._client);

  @override
  Future<List<CalendarEventEntity>> getEvents(String workspaceId) async {
    final response = await _client
        .from('calendar_events')
        .select()
        .eq('workspace_id', workspaceId)
        .order('start_time', ascending: true);

    return (response as List).map((json) => CalendarEventModel.fromJson(json)).toList();
  }

  @override
  Future<CalendarEventEntity> createEvent(CalendarEventEntity event) async {
    final model = CalendarEventModel(
      id: event.id,
      workspaceId: event.workspaceId,
      ownerId: event.ownerId,
      title: event.title,
      description: event.description,
      startTime: event.startTime,
      endTime: event.endTime,
      isAllDay: event.isAllDay,
      category: event.category,
      referenceId: event.referenceId,
    );

    final res = await _client.from('calendar_events').insert(model.toJson()).select().single();
    return CalendarEventModel.fromJson(res);
  }

  @override
  Future<void> deleteEvent(String id) async {
    await _client.from('calendar_events').delete().eq('id', id);
  }
}
