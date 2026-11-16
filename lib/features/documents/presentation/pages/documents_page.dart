import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
            icon: const Icon(Icons.search_rounded),
            onPressed: () {},
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
      body: SingleChildScrollView(
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
                    _buildCategoryFolder('Identity & KYC', '8 items', Icons.badge_rounded, ApnaColors.categoryKyc),
                    _buildCategoryFolder('Insurance', '6 items', Icons.security_rounded, ApnaColors.accentDark),
                    _buildCategoryFolder('Property', '5 items', Icons.apartment_rounded, ApnaColors.blue),
                    _buildCategoryFolder('Vehicle', '3 items', Icons.directions_car_rounded, ApnaColors.warning),
                    _buildCategoryFolder('Medical', '4 items', Icons.local_hospital_rounded, ApnaColors.categoryHealth),
                    _buildCategoryFolder('Financial', '5 items', Icons.account_balance_rounded, ApnaColors.success),
                    _buildCategoryFolder('Education', '7 items', Icons.school_rounded, ApnaColors.primaryLight),
                    _buildCategoryFolder('Agreements', '3 items', Icons.description_rounded, ApnaColors.textSecondary),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Files', style: ApnaTypography.headingSmall),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All', style: TextStyle(color: ApnaColors.blue)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            docsAsync.when(
              data: (docs) {
                if (docs.isEmpty) {
                  return _buildDefaultSampleDocs(context, ref);
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    return _buildDocTile(
                      context: context,
                      title: doc.title,
                      category: doc.category.displayName,
                      sizeText: doc.fileSizeBytes != null ? '${(doc.fileSizeBytes! / 1024 / 1024).toStringAsFixed(1)} MB' : '1.4 MB',
                      dateText: 'Added recently',
                      icon: _iconForCategory(doc.category),
                      onDelete: () => ref.read(documentListNotifierProvider.notifier).deleteDocument(doc.id),
                    );
                  },
                );
              },
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
              error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: ApnaColors.error))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultSampleDocs(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _buildDocTile(
          context: context,
          title: 'Home Insurance Policy.pdf',
          category: 'Insurance',
          sizeText: '2.4 MB',
          dateText: 'Today',
          icon: Icons.security_rounded,
        ),
        const SizedBox(height: 10),
        _buildDocTile(
          context: context,
          title: 'Passport - Shubham.pdf',
          category: 'Identity & KYC',
          sizeText: '1.1 MB',
          dateText: 'Yesterday',
          icon: Icons.badge_rounded,
        ),
        const SizedBox(height: 10),
        _buildDocTile(
          context: context,
          title: 'Car RC.jpg',
          category: 'Vehicle',
          sizeText: '3.2 MB',
          dateText: '3 days ago',
          icon: Icons.directions_car_rounded,
        ),
        const SizedBox(height: 10),
        _buildDocTile(
          context: context,
          title: 'Aadhaar Card - Shubham.pdf',
          category: 'Identity & KYC',
          sizeText: '840 KB',
          dateText: '5 days ago',
          icon: Icons.fingerprint_rounded,
        ),
      ],
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

  Widget _buildDocTile({
    required BuildContext context,
    required String title,
    required String category,
    required String sizeText,
    required String dateText,
    required IconData icon,
    VoidCallback? onDelete,
  }) {
    return Container(
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
                Text(title, style: ApnaTypography.titleMedium.copyWith(fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  '$category • $sizeText • $dateText',
                  style: ApnaTypography.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 18, color: ApnaColors.textSecondary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Sharing $title securely')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, size: 18, color: ApnaColors.textSecondary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Downloading $title')),
              );
            },
          ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: ApnaColors.error),
              onPressed: onDelete,
            ),
        ],
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
