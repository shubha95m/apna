import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:apna/features/documents/presentation/providers/document_providers.dart';
import '../../data/repositories/calendar_repository_impl.dart';
import '../../domain/entities/calendar_event_entity.dart';
import '../../domain/repositories/calendar_repository.dart';

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  return CalendarRepositoryImpl(Supabase.instance.client);
});

final workspaceCalendarEventsProvider = FutureProvider<List<CalendarEventEntity>>((ref) async {
  final activeWorkspace = ref.watch(activeWorkspaceProvider);
  if (activeWorkspace == null) return [];
  final repo = ref.watch(calendarRepositoryProvider);
  return repo.getEvents(activeWorkspace.id);
});
