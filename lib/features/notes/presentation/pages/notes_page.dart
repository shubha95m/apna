import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:apna/app/theme/app_colors.dart';
import 'package:apna/app/theme/app_typography.dart';
import 'package:apna/features/authentication/presentation/providers/auth_providers.dart';
import 'package:apna/features/documents/presentation/providers/document_providers.dart';
import '../../domain/entities/note_entity.dart';
import '../providers/note_providers.dart';

class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
  String _searchQuery = '';
  static const _uuid = Uuid();

  void _showNoteDialog(BuildContext context, {NoteEntity? existingNote}) {
    final titleController = TextEditingController(text: existingNote?.title ?? '');
    final contentController = TextEditingController(text: existingNote?.content ?? '');
    final tagsController = TextEditingController(text: existingNote?.tags.join(', ') ?? '');
    bool isPinned = existingNote?.isPinned ?? false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(existingNote == null ? 'New Note' : 'Edit Note', style: ApnaTypography.headingSmall),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Title *',
                      hintText: 'e.g. Apartment Wi-Fi & Maintenance Rules',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: 'Content',
                      hintText: 'Write details, codes, contacts, or instructions...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: tagsController,
                    decoration: InputDecoration(
                      labelText: 'Tags (comma separated)',
                      hintText: 'e.g. home, wifi, important',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Pin to Top', style: TextStyle(fontWeight: FontWeight.w600)),
                    value: isPinned,
                    onChanged: (val) => setDialogState(() => isPinned = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: ApnaColors.primary),
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isEmpty) return;

                final user = ref.read(authControllerProvider).valueOrNull;
                final ws = ref.read(activeWorkspaceProvider);
                if (user == null || ws == null) return;

                final tags = tagsController.text
                    .split(',')
                    .map((t) => t.trim())
                    .where((t) => t.isNotEmpty)
                    .toList();

                final repo = ref.read(noteRepositoryProvider);
                if (existingNote == null) {
                  final newNote = NoteEntity(
                    id: _uuid.v4(),
                    workspaceId: ws.id,
                    ownerId: user.id,
                    title: title,
                    content: contentController.text.trim(),
                    isPinned: isPinned,
                    tags: tags,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  await repo.createNote(newNote);
                } else {
                  final updated = NoteEntity(
                    id: existingNote.id,
                    workspaceId: existingNote.workspaceId,
                    ownerId: existingNote.ownerId,
                    title: title,
                    content: contentController.text.trim(),
                    isPinned: isPinned,
                    tags: tags,
                    createdAt: existingNote.createdAt,
                    updatedAt: DateTime.now(),
                  );
                  await repo.updateNote(updated);
                }

                ref.invalidate(workspaceNotesProvider);
                if (context.mounted) Navigator.of(dialogCtx).pop();
              },
              child: Text(existingNote == null ? 'Create Note' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(workspaceNotesProvider);

    return Scaffold(
      backgroundColor: ApnaColors.background,
      appBar: AppBar(
        title: const Text('Notes & Documentation', style: ApnaTypography.headingSmall),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(workspaceNotesProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNoteDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Note'),
        backgroundColor: ApnaColors.primary,
        foregroundColor: Colors.white,
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading notes: $err')),
        data: (notes) {
          final filtered = notes.where((n) {
            if (_searchQuery.isEmpty) return true;
            final q = _searchQuery.toLowerCase();
            return n.title.toLowerCase().contains(q) ||
                n.content.toLowerCase().contains(q) ||
                n.tags.any((t) => t.toLowerCase().contains(q));
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search notes by title, keyword, or tag...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.note_alt_outlined, size: 64, color: ApnaColors.textSecondary.withOpacity(0.4)),
                            const SizedBox(height: 16),
                            const Text('No notes found', style: ApnaTypography.headingSmall),
                            const SizedBox(height: 8),
                            const Text('Keep family instructions, codes, passwords, and memos organized.', style: ApnaTypography.bodyMedium),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () => _showNoteDialog(context),
                              icon: const Icon(Icons.add),
                              label: const Text('Add First Note'),
                              style: FilledButton.styleFrom(backgroundColor: ApnaColors.primary),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, idx) {
                          final note = filtered[idx];
                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: note.isPinned ? ApnaColors.primary : ApnaColors.border,
                                width: note.isPinned ? 1.5 : 1.0,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Row(
                                children: [
                                  if (note.isPinned) ...[
                                    const Icon(Icons.push_pin, size: 16, color: ApnaColors.primary),
                                    const SizedBox(width: 6),
                                  ],
                                  Expanded(
                                    child: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ),
                                  Text(
                                    DateFormat('dd MMM').format(note.updatedAt),
                                    style: const TextStyle(fontSize: 12, color: ApnaColors.textSecondary),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (note.content.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      note.content,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: ApnaColors.textPrimary, height: 1.4),
                                    ),
                                  ],
                                  if (note.tags.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 6,
                                      children: note.tags.map((t) => Chip(
                                        label: Text('#$t', style: const TextStyle(fontSize: 11)),
                                        padding: EdgeInsets.zero,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      )).toList(),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (action) async {
                                  if (action == 'edit') {
                                    _showNoteDialog(context, existingNote: note);
                                  } else if (action == 'delete') {
                                    await ref.read(noteRepositoryProvider).deleteNote(note.id);
                                    ref.invalidate(workspaceNotesProvider);
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                  const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
