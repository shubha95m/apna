import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/note_entity.dart';
import '../../domain/repositories/note_repository.dart';
import '../models/note_model.dart';

class NoteRepositoryImpl implements NoteRepository {
  final SupabaseClient _client;

  NoteRepositoryImpl(this._client);

  @override
  Future<List<NoteEntity>> getNotes(String workspaceId) async {
    final response = await _client
        .from('notes')
        .select()
        .eq('workspace_id', workspaceId)
        .isFilter('deleted_at', null)
        .order('is_pinned', ascending: false)
        .order('updated_at', ascending: false);

    return (response as List).map((json) => NoteModel.fromJson(json)).toList();
  }

  @override
  Future<NoteEntity> createNote(NoteEntity note) async {
    final model = NoteModel(
      id: note.id,
      workspaceId: note.workspaceId,
      ownerId: note.ownerId,
      title: note.title,
      content: note.content,
      isPinned: note.isPinned,
      color: note.color,
      tags: note.tags,
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
    );

    final res = await _client.from('notes').insert(model.toJson()).select().single();
    return NoteModel.fromJson(res);
  }

  @override
  Future<NoteEntity> updateNote(NoteEntity note) async {
    final model = NoteModel(
      id: note.id,
      workspaceId: note.workspaceId,
      ownerId: note.ownerId,
      title: note.title,
      content: note.content,
      isPinned: note.isPinned,
      color: note.color,
      tags: note.tags,
      createdAt: note.createdAt,
      updatedAt: DateTime.now(),
    );

    final res = await _client
        .from('notes')
        .update(model.toJson())
        .eq('id', note.id)
        .select()
        .single();
    return NoteModel.fromJson(res);
  }

  @override
  Future<void> deleteNote(String id) async {
    await _client.from('notes').update({'deleted_at': DateTime.now().toIso8601String()}).eq('id', id);
  }
}
