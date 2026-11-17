import '../entities/note_entity.dart';

abstract class NoteRepository {
  Future<List<NoteEntity>> getNotes(String workspaceId);
  Future<NoteEntity> createNote(NoteEntity note);
  Future<NoteEntity> updateNote(NoteEntity note);
  Future<void> deleteNote(String id);
}
