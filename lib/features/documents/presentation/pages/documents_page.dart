import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:apna/app/theme/app_colors.dart';
import 'package:apna/app/theme/app_typography.dart';
import '../../domain/entities/document_entity.dart';
import '../providers/document_providers.dart';

class DocumentsPage extends ConsumerStatefulWidget {
  final DocumentCategory? initialCategory;

  const DocumentsPage({super.key, this.initialCategory});

  @override
  ConsumerState<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends ConsumerState<DocumentsPage> {
  DocumentCategory? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchOpen = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleCategory(DocumentCategory category) {
    setState(() {
      if (_selectedCategory == category) {
        _selectedCategory = null; // Toggle off to show all
      } else {
        _selectedCategory = category;
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _searchController.clear();
      _searchQuery = '';
    });
  }

  String _itemCountText(int count) => count == 1 ? '1 item' : '$count items';

  String _formatFileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return 'Document';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat('dd MMM yyyy').format(dt);
  }

  Future<void> _openOrDownloadDoc(DocumentEntity doc) async {
    if (doc.storagePath != null && doc.storagePath!.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening ${doc.title}...'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Document: ${doc.title} (${doc.category.displayName})')),
      );
    }
  }

  void _showDocumentDetails(DocumentEntity doc) {
    final canWrite = ref.read(canWriteCurrentWorkspaceProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ApnaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final catColor = _colorForCategory(doc.category);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: ApnaColors.border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(_iconForCategory(doc.category), color: catColor, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(doc.title, style: ApnaTypography.headingSmall),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              doc.category.displayName,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: catColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),

                // Details grid
                _buildDetailRow(Icons.description_outlined, 'File Name', doc.fileName ?? 'Unnamed file'),
                _buildDetailRow(Icons.data_usage_rounded, 'File Size', _formatFileSize(doc.fileSizeBytes)),
                _buildDetailRow(Icons.calendar_today_rounded, 'Uploaded', DateFormat('dd MMM yyyy, hh:mm a').format(doc.createdAt)),
                if (doc.documentNumber != null && doc.documentNumber!.isNotEmpty)
                  _buildDetailRow(Icons.pin_rounded, 'Document Number', doc.documentNumber!),
                if (doc.tags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.tag_rounded, size: 18, color: ApnaColors.textSecondary),
                        const SizedBox(width: 10),
                        const Text('Tags:', style: ApnaTypography.bodySmall),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: doc.tags.map((tag) {
                              return Chip(
                                label: Text(tag, style: const TextStyle(fontSize: 11)),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Security Badge
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ApnaColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: ApnaColors.border),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined, size: 20, color: ApnaColors.success),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Encrypted & secured in Supabase Vault (Row-Level Security protected)',
                          style: TextStyle(fontSize: 11, color: ApnaColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: const Text('Open / Download File'),
                        style: FilledButton.styleFrom(
                          backgroundColor: ApnaColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _openOrDownloadDoc(doc);
                        },
                      ),
                    ),
                    if (canWrite) ...[
                      const SizedBox(width: 12),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ApnaColors.error,
                          side: const BorderSide(color: ApnaColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _confirmDeleteDoc(doc);
                        },
                        child: const Icon(Icons.delete_outline_rounded, size: 20),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: ApnaColors.textSecondary),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(label, style: ApnaTypography.bodySmall.copyWith(color: ApnaColors.textSecondary)),
          ),
          Expanded(
            child: Text(
              value,
              style: ApnaTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteDoc(DocumentEntity doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to permanently remove "${doc.title}" from your vault?'),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted "${doc.title}"')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(documentListNotifierProvider);
    final workspaceName = ref.watch(activeWorkspaceNameProvider);

    return Scaffold(
      backgroundColor: ApnaColors.background,
      appBar: AppBar(
        title: Text('Documents — $workspaceName', style: ApnaTypography.headingSmall),
        actions: [
          IconButton(
            icon: Icon(_isSearchOpen ? Icons.close_rounded : Icons.search_rounded),
            tooltip: _isSearchOpen ? 'Close search' : 'Search documents',
            onPressed: () {
              setState(() {
                _isSearchOpen = !_isSearchOpen;
                if (!_isSearchOpen) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh documents',
            onPressed: () => ref.read(documentListNotifierProvider.notifier).loadDocuments(),
          ),
          if (ref.watch(canWriteCurrentWorkspaceProvider))
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
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: ApnaColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ApnaColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.visibility_outlined, size: 14, color: ApnaColors.textSecondary),
                  SizedBox(width: 4),
                  Text('Viewer (Read Only)', style: TextStyle(fontSize: 12, color: ApnaColors.textSecondary, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: docsAsync.when(
        data: (allDocs) {
          // Filter by category and search query
          final filteredDocs = allDocs.where((doc) {
            final matchesCategory = _selectedCategory == null || doc.category == _selectedCategory;
            if (!matchesCategory) return false;

            if (_searchQuery.isEmpty) return true;
            final inTitle = doc.title.toLowerCase().contains(_searchQuery);
            final inCategory = doc.category.displayName.toLowerCase().contains(_searchQuery);
            final inFileName = doc.fileName?.toLowerCase().contains(_searchQuery) ?? false;
            final inDocNumber = doc.documentNumber?.toLowerCase().contains(_searchQuery) ?? false;
            final inTags = doc.tags.any((t) => t.toLowerCase().contains(_searchQuery));
            return inTitle || inCategory || inFileName || inDocNumber || inTags;
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Collapsible Search Input
                if (_isSearchOpen) ...[
                  TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search by title, number, tag, or category...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      filled: true,
                      fillColor: ApnaColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: ApnaColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: ApnaColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: ApnaColors.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Categories Header with reset action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Categories', style: ApnaTypography.headingSmall),
                    if (_selectedCategory != null)
                      TextButton.icon(
                        onPressed: () => setState(() => _selectedCategory = null),
                        icon: const Icon(Icons.clear_all_rounded, size: 18),
                        label: const Text('Show All Categories', style: TextStyle(color: ApnaColors.primary)),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // Interactive Clickable Category Cards
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
                          category: DocumentCategory.kyc,
                          title: 'Identity & KYC',
                          docs: allDocs,
                          icon: Icons.badge_rounded,
                          color: ApnaColors.categoryKyc,
                        ),
                        _buildCategoryFolder(
                          category: DocumentCategory.insurance,
                          title: 'Insurance',
                          docs: allDocs,
                          icon: Icons.security_rounded,
                          color: ApnaColors.accentDark,
                        ),
                        _buildCategoryFolder(
                          category: DocumentCategory.property,
                          title: 'Property',
                          docs: allDocs,
                          icon: Icons.apartment_rounded,
                          color: ApnaColors.blue,
                        ),
                        _buildCategoryFolder(
                          category: DocumentCategory.vehicle,
                          title: 'Vehicle',
                          docs: allDocs,
                          icon: Icons.directions_car_rounded,
                          color: ApnaColors.warning,
                        ),
                        _buildCategoryFolder(
                          category: DocumentCategory.medical,
                          title: 'Medical',
                          docs: allDocs,
                          icon: Icons.local_hospital_rounded,
                          color: ApnaColors.categoryHealth,
                        ),
                        _buildCategoryFolder(
                          category: DocumentCategory.financial,
                          title: 'Financial',
                          docs: allDocs,
                          icon: Icons.account_balance_rounded,
                          color: ApnaColors.success,
                        ),
                        _buildCategoryFolder(
                          category: DocumentCategory.education,
                          title: 'Education',
                          docs: allDocs,
                          icon: Icons.school_rounded,
                          color: ApnaColors.primaryLight,
                        ),
                        _buildCategoryFolder(
                          category: DocumentCategory.agreements,
                          title: 'Agreements',
                          docs: allDocs,
                          icon: Icons.description_rounded,
                          color: ApnaColors.textSecondary,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Section Title & Filter Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          _selectedCategory != null
                              ? '${_selectedCategory!.displayName} Documents (${filteredDocs.length})'
                              : 'Vault Documents (${filteredDocs.length})',
                          style: ApnaTypography.headingSmall,
                        ),
                        if (_selectedCategory != null || _searchQuery.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: ApnaColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _selectedCategory != null ? _selectedCategory!.displayName : 'Filtered',
                                  style: const TextStyle(fontSize: 12, color: ApnaColors.primary, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: _clearFilters,
                                  child: const Icon(Icons.close_rounded, size: 14, color: ApnaColors.primary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (allDocs.isNotEmpty)
                      Text(
                        'Total in Vault: ${allDocs.length}',
                        style: ApnaTypography.bodySmall.copyWith(color: ApnaColors.accentDark, fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // Document List / Empty State
                if (filteredDocs.isEmpty)
                  _buildNoResultsState(context, isFiltered: _selectedCategory != null || _searchQuery.isNotEmpty)
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredDocs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      return _buildDocTile(
                        context: context,
                        doc: doc,
                      );
                    },
                  ),
              ],
            ),
          );
        },
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

  Widget _buildCategoryFolder({
    required DocumentCategory category,
    required String title,
    required List<DocumentEntity> docs,
    required IconData icon,
    required Color color,
  }) {
    final count = docs.where((d) => d.category == category).length;
    final isSelected = _selectedCategory == category;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _toggleCategory(category),
        borderRadius: BorderRadius.circular(14),
        hoverColor: color.withValues(alpha: 0.05),
        splashColor: color.withValues(alpha: 0.1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : ApnaColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : ApnaColors.border,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? color : color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: ApnaTypography.titleMedium.copyWith(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? color : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _itemCountText(count),
                      style: ApnaTypography.bodySmall.copyWith(
                        color: isSelected ? color.withValues(alpha: 0.8) : ApnaColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 12, color: Colors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoResultsState(BuildContext context, {required bool isFiltered}) {
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
            child: Icon(
              isFiltered ? Icons.search_off_rounded : Icons.cloud_upload_outlined,
              size: 40,
              color: ApnaColors.accentDark,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isFiltered ? 'No matching documents found' : 'No Documents in Vault Yet',
            style: ApnaTypography.headingSmall,
          ),
          const SizedBox(height: 8),
          Text(
            isFiltered
                ? 'Try selecting another category or clearing your search filters.'
                : 'Keep your Aadhaar, Passport, Vehicle RC, Insurance & Property deeds safe and accessible anywhere.',
            textAlign: TextAlign.center,
            style: ApnaTypography.bodySmall,
          ),
          const SizedBox(height: 20),
          if (isFiltered)
            OutlinedButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Show All Documents'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            )
          else if (ref.watch(canWriteCurrentWorkspaceProvider))
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
            )
          else
            const Text(
              'No documents in this workspace yet. You have Read-Only view access.',
              style: TextStyle(fontSize: 13, color: ApnaColors.textSecondary, fontStyle: FontStyle.italic),
            ),
        ],
      ),
    );
  }

  Widget _buildDocTile({
    required BuildContext context,
    required DocumentEntity doc,
  }) {
    final sizeText = _formatFileSize(doc.fileSizeBytes);
    final dateText = _formatDate(doc.createdAt);
    final catColor = _colorForCategory(doc.category);
    final icon = _iconForCategory(doc.category);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showDocumentDetails(doc),
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
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.12),
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                ),
                child: Icon(icon, color: catColor, size: 22),
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
                    Row(
                      children: [
                        Text(
                          '${doc.category.displayName} • $sizeText • $dateText',
                          style: ApnaTypography.bodySmall,
                        ),
                        if (doc.documentNumber != null && doc.documentNumber!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: ApnaColors.surfaceSubtle,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '#${doc.documentNumber}',
                              style: const TextStyle(fontSize: 10, color: ApnaColors.textSecondary),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (doc.storagePath != null)
                IconButton(
                  icon: const Icon(Icons.download_rounded, size: 20, color: ApnaColors.accentDark),
                  tooltip: 'Download / View File',
                  onPressed: () => _openOrDownloadDoc(doc),
                ),
              IconButton(
                icon: const Icon(Icons.info_outline_rounded, size: 20, color: ApnaColors.textSecondary),
                tooltip: 'Document Details',
                onPressed: () => _showDocumentDetails(doc),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _colorForCategory(DocumentCategory cat) {
    return switch (cat) {
      DocumentCategory.kyc => ApnaColors.categoryKyc,
      DocumentCategory.insurance => ApnaColors.accentDark,
      DocumentCategory.property => ApnaColors.blue,
      DocumentCategory.vehicle => ApnaColors.warning,
      DocumentCategory.medical => ApnaColors.categoryHealth,
      DocumentCategory.financial => ApnaColors.success,
      DocumentCategory.education => ApnaColors.primaryLight,
      DocumentCategory.agreements => ApnaColors.textSecondary,
      DocumentCategory.other => ApnaColors.primary,
    };
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
