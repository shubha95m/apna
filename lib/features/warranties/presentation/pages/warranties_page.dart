import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import 'package:apna/features/documents/presentation/providers/document_providers.dart';
import '../../domain/entities/warranty_entity.dart';
import '../providers/warranty_providers.dart';

class WarrantiesPage extends ConsumerStatefulWidget {
  const WarrantiesPage({super.key});

  @override
  ConsumerState<WarrantiesPage> createState() => _WarrantiesPageState();
}

class _WarrantiesPageState extends ConsumerState<WarrantiesPage> {
  String _filter = 'ACTIVE'; // ALL, ACTIVE, EXPIRING_SOON, EXPIRED

  void _showAddWarrantyDialog(BuildContext context) {
    final itemController = TextEditingController();
    final brandController = TextEditingController();
    final modelController = TextEditingController();
    final serialController = TextEditingController();
    final monthsController = TextEditingController(text: '24');
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final notesController = TextEditingController();
    DateTime purchaseDate = DateTime.now().subtract(const Duration(days: 90));

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add Product Warranty', style: ApnaTypography.headingSmall),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: itemController,
                    decoration: InputDecoration(
                      labelText: 'Product / Appliance Name *',
                      hintText: 'e.g. LG OLED 55" Smart TV',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: brandController,
                          decoration: InputDecoration(
                            labelText: 'Brand *',
                            hintText: 'e.g. LG / Samsung',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: monthsController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Warranty (Months) *',
                            hintText: '24',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: modelController,
                          decoration: InputDecoration(
                            labelText: 'Model Number',
                            hintText: 'e.g. OLED55C3PSA',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: serialController,
                          decoration: InputDecoration(
                            labelText: 'Serial Number',
                            hintText: 'e.g. LG9876543210',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: phoneController,
                          decoration: InputDecoration(
                            labelText: 'Support Toll-Free Phone',
                            hintText: 'e.g. 1800-315-9999',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: 'Support Email',
                            hintText: 'service@brand.com',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    decoration: InputDecoration(
                      labelText: 'Notes / Inclusions',
                      hintText: 'e.g. Includes 3-year panel warranty, 1-year general',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.shopping_bag_outlined, size: 18, color: ApnaColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        'Purchase Date: ${DateFormat('dd MMM yyyy').format(purchaseDate)}',
                        style: ApnaTypography.bodyMedium,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: purchaseDate,
                            firstDate: DateTime(2015),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setDialogState(() => purchaseDate = picked);
                          }
                        },
                        child: const Text('Change Date'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: ApnaColors.primary),
              onPressed: () {
                final item = itemController.text.trim();
                final brand = brandController.text.trim();
                final months = int.tryParse(monthsController.text.trim()) ?? 12;
                if (item.isEmpty || brand.isEmpty) return;

                final expiry = DateTime(
                  purchaseDate.year,
                  purchaseDate.month + months,
                  purchaseDate.day,
                );

                final workspaceId = ref.read(activeWorkspaceIdProvider);
                final newWarranty = WarrantyEntity(
                  id: const Uuid().v4(),
                  workspaceId: workspaceId,
                  itemName: item,
                  brand: brand,
                  modelNumber: modelController.text.trim().isNotEmpty ? modelController.text.trim() : null,
                  serialNumber: serialController.text.trim().isNotEmpty ? serialController.text.trim() : null,
                  purchaseDate: purchaseDate,
                  warrantyMonths: months,
                  expiryDate: expiry,
                  supportPhone: phoneController.text.trim().isNotEmpty ? phoneController.text.trim() : null,
                  supportEmail: emailController.text.trim().isNotEmpty ? emailController.text.trim() : null,
                  notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                ref.read(warrantyListNotifierProvider.notifier).addWarranty(newWarranty);
                Navigator.pop(dialogCtx);
              },
              child: const Text('Save Warranty'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final warrantiesAsync = ref.watch(warrantyListNotifierProvider);

    return Scaffold(
      backgroundColor: ApnaColors.background,
      body: warrantiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: ApnaColors.error),
              const SizedBox(height: 12),
              Text('Failed to load warranties: $err', style: ApnaTypography.bodyMedium),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.refresh(warrantyListNotifierProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (warranties) {
          final activeWarranties = warranties.where((w) => !w.isExpired).toList();
          final expiringSoon = warranties.where((w) => !w.isExpired && w.daysRemaining <= 60).toList();
          final expiredWarranties = warranties.where((w) => w.isExpired).toList();

          final filtered = warranties.where((w) {
            if (_filter == 'ACTIVE') return !w.isExpired;
            if (_filter == 'EXPIRING_SOON') return !w.isExpired && w.daysRemaining <= 60;
            if (_filter == 'EXPIRED') return w.isExpired;
            return true;
          }).toList();

          return CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Warranties & Appliance Invoices', style: ApnaTypography.headingLarge),
                              const SizedBox(height: 4),
                              Text(
                                '${activeWarranties.length} active warranties • ${expiringSoon.length} expiring soon • Supabase Cloud Ledger',
                                style: ApnaTypography.bodyMedium,
                              ),
                            ],
                          ),
                          if (ref.watch(canWriteCurrentWorkspaceProvider))
                            FilledButton.icon(
                              onPressed: () => _showAddWarrantyDialog(context),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Warranty'),
                              style: FilledButton.styleFrom(
                                backgroundColor: ApnaColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.visibility_outlined, size: 14, color: ApnaColors.textSecondary),
                                  SizedBox(width: 4),
                                  Text('Read Only', style: TextStyle(fontSize: 12, color: ApnaColors.textSecondary, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Filter chips
                      Row(
                        children: [
                          _buildFilterChip('ACTIVE', 'Active (${activeWarranties.length})'),
                          const SizedBox(width: 8),
                          _buildFilterChip('EXPIRING_SOON', 'Expiring Soon (${expiringSoon.length})'),
                          const SizedBox(width: 8),
                          _buildFilterChip('ALL', 'All Warranties (${warranties.length})'),
                          const SizedBox(width: 8),
                          _buildFilterChip('EXPIRED', 'Expired (${expiredWarranties.length})'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Warranty Cards
              if (filtered.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_outlined, size: 56, color: ApnaColors.textSecondary),
                        SizedBox(height: 12),
                        Text('No warranties found in this view', style: ApnaTypography.headingSmall),
                        SizedBox(height: 4),
                        Text('Track appliance guarantees and invoices with one tap.', style: ApnaTypography.bodySmall),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final warranty = filtered[index];
                        return _buildWarrantyCard(warranty);
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _filter == filterKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _filter = filterKey);
      },
      selectedColor: ApnaColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : ApnaColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        fontSize: 13,
      ),
    );
  }

  Widget _buildWarrantyCard(WarrantyEntity warranty) {
    final isExpired = warranty.isExpired;
    final daysRemaining = warranty.daysRemaining;

    return Card(
      margin: const EdgeInsets.only(bottom: 14.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: ApnaColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: ApnaColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Icon(Icons.verified_user_rounded, color: ApnaColors.accentDark, size: 24),
                  ),
                ),
                const SizedBox(width: 14),

                // Name & Brand
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(warranty.itemName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(
                        '${warranty.brand}${warranty.modelNumber != null ? ' • Model: ${warranty.modelNumber}' : ''}${warranty.serialNumber != null ? ' • S/N: ${warranty.serialNumber}' : ''}',
                        style: const TextStyle(fontSize: 13, color: ApnaColors.textSecondary),
                      ),
                    ],
                  ),
                ),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isExpired
                        ? ApnaColors.error.withOpacity(0.12)
                        : (daysRemaining <= 60 ? ApnaColors.warning.withOpacity(0.12) : ApnaColors.accentDark.withOpacity(0.12)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isExpired ? 'EXPIRED' : '$daysRemaining DAYS LEFT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isExpired
                          ? ApnaColors.error
                          : (daysRemaining <= 60 ? ApnaColors.warning : ApnaColors.accentDark),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Metadata row
            Row(
              children: [
                const Icon(Icons.shopping_bag_outlined, size: 14, color: ApnaColors.textSecondary),
                const SizedBox(width: 4),
                Text('Bought: ${DateFormat('dd MMM yyyy').format(warranty.purchaseDate)}', style: const TextStyle(fontSize: 12, color: ApnaColors.textSecondary)),
                const SizedBox(width: 16),
                const Icon(Icons.event_busy_outlined, size: 14, color: ApnaColors.textSecondary),
                const SizedBox(width: 4),
                Text('Expires: ${DateFormat('dd MMM yyyy').format(warranty.expiryDate)} (${warranty.warrantyMonths} mos)', style: const TextStyle(fontSize: 12, color: ApnaColors.textSecondary)),
                const Spacer(),
                if (warranty.supportPhone != null) ...[
                  IconButton(
                    icon: const Icon(Icons.phone_outlined, size: 18, color: ApnaColors.accentDark),
                    tooltip: 'Call Support: ${warranty.supportPhone}',
                    onPressed: () => launchUrl(Uri.parse('tel:${warranty.supportPhone}')),
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: ApnaColors.textSecondary),
                  tooltip: 'Delete Warranty',
                  onPressed: () => ref.read(warrantyListNotifierProvider.notifier).deleteWarranty(warranty.id),
                ),
              ],
            ),
            if (warranty.notes != null && warranty.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Notes: ${warranty.notes}',
                style: const TextStyle(fontSize: 12, color: ApnaColors.textSecondary, fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
