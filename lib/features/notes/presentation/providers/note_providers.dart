import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:apna/features/documents/presentation/providers/document_providers.dart';
import '../../data/repositories/note_repository_impl.dart';
import '../../domain/entities/note_entity.dart';
import '../../domain/repositories/note_repository.dart';

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepositoryImpl(Supabase.instance.client);
});

final workspaceNotesProvider = FutureProvider<List<NoteEntity>>((ref) async {
  final activeWorkspace = ref.watch(activeWorkspaceProvider);
  if (activeWorkspace == null) return [];
  final repo = ref.watch(noteRepositoryProvider);
  return repo.getNotes(activeWorkspace.id);
});
