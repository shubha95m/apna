import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:apna/app/theme/app_colors.dart';
import 'package:apna/app/theme/app_typography.dart';
import 'package:apna/features/authentication/presentation/providers/auth_providers.dart';
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

  PlatformFile? _pickedFile;
  Uint8List? _fileBytes;
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _docNumberController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'doc', 'docx', 'txt'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        Uint8List? bytes = file.bytes;
        if (bytes == null && !kIsWeb && file.path != null) {
          bytes = await File(file.path!).readAsBytes();
        }

        setState(() {
          _pickedFile = file;
          _fileBytes = bytes;
          if (_titleController.text.trim().isEmpty) {
            final dotIdx = file.name.lastIndexOf('.');
            final name = dotIdx > 0 ? file.name.substring(0, dotIdx) : file.name;
            _titleController.text = name.replaceAll(RegExp(r'[-_]'), ' ');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick file: $e'), backgroundColor: ApnaColors.error),
        );
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String _resolveMimeType(String fileName) {
    final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
    return switch (ext) {
      'pdf' => 'application/pdf',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'txt' => 'text/plain',
      'doc' => 'application/msword',
      'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      _ => 'application/octet-stream',
    };
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    try {
      final workspaceId = ref.read(activeWorkspaceIdProvider);
      final currentUserId = Supabase.instance.client.auth.currentUser?.id ??
          ref.read(authControllerProvider).valueOrNull?.id ??
          const Uuid().v4();
      final docId = const Uuid().v4();

      String? storagePath;
      String? fileName = _pickedFile?.name;
      int? fileSize = _pickedFile?.size ?? _fileBytes?.length;
      String mimeType = fileName != null ? _resolveMimeType(fileName) : 'application/pdf';

      if (_fileBytes != null && fileName != null) {
        storagePath = await ref.read(documentListNotifierProvider.notifier).uploadFile(
          fileName: fileName,
          bytes: _fileBytes!,
          mimeType: mimeType,
        );
      }

      final newDoc = DocumentEntity(
        id: docId,
        workspaceId: workspaceId,
        ownerId: currentUserId,
        title: _titleController.text.trim(),
        category: _selectedCategory,
        documentNumber: _docNumberController.text.trim().isNotEmpty ? _docNumberController.text.trim() : null,
        tags: _tagsController.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList(),
        fileName: fileName ?? '${_titleController.text.trim()}.pdf',
        fileSizeBytes: fileSize,
        mimeType: mimeType,
        storagePath: storagePath,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = await ref.read(documentListNotifierProvider.notifier).addDocument(newDoc);
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document "${newDoc.title}" uploaded & saved to secure vault!'),
            backgroundColor: ApnaColors.success,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved to offline cache (will sync when online).'),
            backgroundColor: ApnaColors.warning,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload error: $e'), backgroundColor: ApnaColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
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
                      onTap: _isUploading ? null : _pickFile,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _pickedFile != null ? ApnaColors.surfaceSubtle : ApnaColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _pickedFile != null ? ApnaColors.accentDark : ApnaColors.border,
                            width: _pickedFile != null ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _pickedFile != null ? Icons.check_circle_outline_rounded : Icons.cloud_upload_outlined,
                              color: _pickedFile != null ? ApnaColors.success : ApnaColors.accentDark,
                              size: 32,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _pickedFile != null ? _pickedFile!.name : 'Attach PDF, Image or Document',
                                    style: ApnaTypography.titleMedium.copyWith(fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _pickedFile != null
                                        ? '${_formatFileSize(_pickedFile!.size)} • Ready to upload to vault'
                                        : 'Click to select from device storage',
                                    style: ApnaTypography.bodySmall.copyWith(
                                      color: _pickedFile != null ? ApnaColors.success : ApnaColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_pickedFile != null)
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 20, color: ApnaColors.textSecondary),
                                onPressed: () {
                                  setState(() {
                                    _pickedFile = null;
                                    _fileBytes = null;
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isUploading ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: ApnaColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _isUploading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Uploading to Vault...', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                ],
                              )
                            : const Text('Save Document to Vault', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
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
