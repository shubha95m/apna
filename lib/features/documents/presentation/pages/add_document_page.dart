import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:apna/app/theme/app_colors.dart';
import 'package:apna/app/theme/app_typography.dart';
import '../../domain/entities/document_entity.dart';
import '../providers/document_providers.dart';

class AddDocumentPage extends ConsumerStatefulWidget {
  const AddDocumentPage({super.key});

  @override
  ConsumerState<AddDocumentPage> createState() => _AddDocumentPageState();
}

class _AddDocumentPageState extends ConsumerState<AddDocumentPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _docNumberController = TextEditingController();
  final _tagsController = TextEditingController();
  DocumentCategory _selectedCategory = DocumentCategory.kyc;
  String? _pickedFileName;
  int? _pickedFileSize;

  @override
  void dispose() {
    _titleController.dispose();
    _docNumberController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _simulateFilePick() {
    setState(() {
      _pickedFileName = '${_titleController.text.trim().isEmpty ? 'Document' : _titleController.text.trim()}.pdf';
      _pickedFileSize = 1420000;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final workspaceId = ref.read(activeWorkspaceIdProvider);
    final newDoc = DocumentEntity(
      id: const Uuid().v4(),
      workspaceId: workspaceId,
      ownerId: 'user-default-shubham',
      title: _titleController.text.trim(),
      category: _selectedCategory,
      documentNumber: _docNumberController.text.trim().isNotEmpty ? _docNumberController.text.trim() : null,
      tags: _tagsController.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList(),
      fileName: _pickedFileName ?? '${_titleController.text.trim()}.pdf',
      fileSizeBytes: _pickedFileSize ?? 1024 * 800,
      mimeType: 'application/pdf',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    ref.read(documentListNotifierProvider.notifier).addDocument(newDoc);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Document "${newDoc.title}" encrypted & saved to offline vault')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApnaColors.background,
      appBar: AppBar(
        title: const Text('Add New Document', style: ApnaTypography.headingSmall),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ApnaColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ApnaColors.border),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Document Details', style: ApnaTypography.headingSmall),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Document Title (e.g. Passport, PAN Card)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a title' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<DocumentCategory>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: DocumentCategory.values.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(cat.displayName),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategory = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _docNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Document / Reference Number (Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _tagsController,
                      decoration: const InputDecoration(
                        labelText: 'Tags (comma-separated, e.g. kyc, family, urgent)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    InkWell(
                      onTap: _simulateFilePick,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: ApnaColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: ApnaColors.border, style: BorderStyle.solid),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cloud_upload_outlined, color: ApnaColors.accentDark, size: 28),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _pickedFileName ?? 'Attach PDF or Image file',
                                  style: ApnaTypography.titleMedium.copyWith(fontSize: 14),
                                ),
                                Text(
                                  _pickedFileSize != null
                                      ? '${(_pickedFileSize! / 1024 / 1024).toStringAsFixed(1)} MB ready to upload'
                                      : 'Click to select from device storage',
                                  style: ApnaTypography.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: ApnaColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Save Document to Vault', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
