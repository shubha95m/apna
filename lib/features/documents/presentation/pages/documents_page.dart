import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:apna/app/theme/app_colors.dart';
import 'package:apna/app/theme/app_typography.dart';
import '../../domain/entities/document_entity.dart';
import '../providers/document_providers.dart';

class DocumentsPage extends ConsumerWidget {
  const DocumentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(documentListNotifierProvider);
    final workspaceName = ref.watch(activeWorkspaceNameProvider);

    return Scaffold(
      backgroundColor: ApnaColors.background,
      appBar: AppBar(
        title: Text('Documents — $workspaceName', style: ApnaTypography.headingSmall),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh documents',
            onPressed: () => ref.read(documentListNotifierProvider.notifier).loadDocuments(),
          ),
          FilledButton.icon(
            onPressed: () => context.go('/documents/add'),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Document'),
            style: FilledButton.styleFrom(
              backgroundColor: ApnaColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: docsAsync.when(
        data: (docs) => SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Categories', style: ApnaTypography.headingSmall),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 700;
                  return GridView.count(
                    crossAxisCount: isWide ? 4 : 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 2.2,
                    children: [
                      _buildCategoryFolder(
                        'Identity & KYC',
                        '${docs.where((d) => d.category == DocumentCategory.kyc).length} items',
                        Icons.badge_rounded,
                        ApnaColors.categoryKyc,
                      ),
                      _buildCategoryFolder(
                        'Insurance',
                        '${docs.where((d) => d.category == DocumentCategory.insurance).length} items',
                        Icons.security_rounded,
                        ApnaColors.accentDark,
                      ),
                      _buildCategoryFolder(
                        'Property',
                        '${docs.where((d) => d.category == DocumentCategory.property).length} items',
                        Icons.apartment_rounded,
                        ApnaColors.blue,
                      ),
                      _buildCategoryFolder(
                        'Vehicle',
                        '${docs.where((d) => d.category == DocumentCategory.vehicle).length} items',
                        Icons.directions_car_rounded,
                        ApnaColors.warning,
                      ),
                      _buildCategoryFolder(
                        'Medical',
                        '${docs.where((d) => d.category == DocumentCategory.medical).length} items',
                        Icons.local_hospital_rounded,
                        ApnaColors.categoryHealth,
                      ),
                      _buildCategoryFolder(
                        'Financial',
                        '${docs.where((d) => d.category == DocumentCategory.financial).length} items',
                        Icons.account_balance_rounded,
                        ApnaColors.success,
                      ),
                      _buildCategoryFolder(
                        'Education',
                        '${docs.where((d) => d.category == DocumentCategory.education).length} items',
                        Icons.school_rounded,
                        ApnaColors.primaryLight,
                      ),
                      _buildCategoryFolder(
                        'Agreements',
                        '${docs.where((d) => d.category == DocumentCategory.agreements).length} items',
                        Icons.description_rounded,
                        ApnaColors.textSecondary,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Vault Documents (${docs.length})', style: ApnaTypography.headingSmall),
                  if (docs.isNotEmpty)
                    Text(
                      'End-to-End Vault',
                      style: ApnaTypography.bodySmall.copyWith(color: ApnaColors.accentDark, fontWeight: FontWeight.w600),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (docs.isEmpty)
                _buildEmptyState(context)
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    return _buildDocTile(
                      context: context,
                      ref: ref,
                      doc: doc,
                    );
                  },
                ),
            ],
          ),
        ),
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(48),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: ApnaColors.error, size: 48),
                const SizedBox(height: 16),
                Text('Error loading documents: $err', style: const TextStyle(color: ApnaColors.error)),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.read(documentListNotifierProvider.notifier).loadDocuments(),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: ApnaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ApnaColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: ApnaColors.surfaceSubtle,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_upload_outlined, size: 40, color: ApnaColors.accentDark),
          ),
          const SizedBox(height: 16),
          const Text('No Documents in Vault Yet', style: ApnaTypography.headingSmall),
          const SizedBox(height: 8),
          const Text(
            'Keep your Aadhaar, Passport, Vehicle RC, Insurance & Property deeds safe and accessible anywhere.',
            textAlign: TextAlign.center,
            style: ApnaTypography.bodySmall,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => context.go('/documents/add'),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Upload First Document'),
            style: FilledButton.styleFrom(
              backgroundColor: ApnaColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFolder(String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: ApnaColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ApnaColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: ApnaTypography.titleMedium.copyWith(fontSize: 13), maxLines: 1),
                Text(count, style: ApnaTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return 'Document';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat('dd MMM yyyy').format(dt);
  }

  Future<void> _openOrDownloadDoc(BuildContext context, WidgetRef ref, DocumentEntity doc) async {
    if (doc.storagePath != null && doc.storagePath!.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Opening ${doc.title}...')),
      );
      final url = await ref.read(documentListNotifierProvider.notifier).getDownloadUrl(doc.storagePath!);
      if (url != null) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          await launchUrl(uri);
        }
        return;
      }
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Document: ${doc.title} (${doc.category.displayName})')),
      );
    }
  }

  Widget _buildDocTile({
    required BuildContext context,
    required WidgetRef ref,
    required DocumentEntity doc,
  }) {
    final sizeText = _formatFileSize(doc.fileSizeBytes);
    final dateText = _formatDate(doc.createdAt);
    final icon = _iconForCategory(doc.category);

    return InkWell(
      onTap: () => _openOrDownloadDoc(context, ref, doc),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ApnaColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ApnaColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: ApnaColors.surfaceSubtle,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: Icon(icon, color: ApnaColors.primary, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.title,
                    style: ApnaTypography.titleMedium.copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${doc.category.displayName} • $sizeText • $dateText',
                    style: ApnaTypography.bodySmall,
                  ),
                ],
              ),
            ),
            if (doc.storagePath != null)
              IconButton(
                icon: const Icon(Icons.download_rounded, size: 20, color: ApnaColors.accentDark),
                tooltip: 'Download / View File',
                onPressed: () => _openOrDownloadDoc(context, ref, doc),
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20, color: ApnaColors.error),
              tooltip: 'Delete Document',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Document'),
                    content: Text('Are you sure you want to delete "${doc.title}"?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: ApnaColors.error),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  ref.read(documentListNotifierProvider.notifier).deleteDocument(doc.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Deleted "${doc.title}"')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForCategory(DocumentCategory cat) {
    return switch (cat) {
      DocumentCategory.kyc => Icons.badge_rounded,
      DocumentCategory.insurance => Icons.security_rounded,
      DocumentCategory.property => Icons.apartment_rounded,
      DocumentCategory.vehicle => Icons.directions_car_rounded,
      DocumentCategory.medical => Icons.local_hospital_rounded,
      DocumentCategory.financial => Icons.account_balance_rounded,
      DocumentCategory.education => Icons.school_rounded,
      DocumentCategory.agreements => Icons.description_rounded,
      DocumentCategory.other => Icons.folder_rounded,
    };
  }
}
