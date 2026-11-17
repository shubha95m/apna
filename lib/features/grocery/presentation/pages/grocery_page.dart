import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:apna/app/theme/app_colors.dart';
import 'package:apna/app/theme/app_typography.dart';
import 'package:apna/features/authentication/presentation/providers/auth_providers.dart';
import 'package:apna/features/documents/presentation/providers/document_providers.dart';
import '../../domain/entities/grocery_item_entity.dart';
import '../providers/grocery_providers.dart';

class GroceryPage extends ConsumerStatefulWidget {
  const GroceryPage({super.key});

  @override
  ConsumerState<GroceryPage> createState() => _GroceryPageState();
}

class _GroceryPageState extends ConsumerState<GroceryPage> {
  static const _uuid = Uuid();

  final List<Map<String, String>> _quickPresets = [
    {'name': 'Full Cream Milk', 'unit': 'L', 'qty': '1', 'cat': 'Dairy'},
    {'name': 'Brown Bread', 'unit': 'pkt', 'qty': '1', 'cat': 'Pantry'},
    {'name': 'Farm Fresh Eggs', 'unit': 'pcs', 'qty': '6', 'cat': 'Dairy'},
    {'name': 'Chakki Fresh Atta', 'unit': 'kg', 'qty': '5', 'cat': 'Pantry'},
    {'name': 'Basmati Rice', 'unit': 'kg', 'qty': '5', 'cat': 'Pantry'},
    {'name': 'Cooking Oil', 'unit': 'L', 'qty': '1', 'cat': 'Pantry'},
    {'name': 'Fresh Tomatoes', 'unit': 'kg', 'qty': '1', 'cat': 'Produce'},
    {'name': 'Bananas', 'unit': 'pcs', 'qty': '6', 'cat': 'Produce'},
    {'name': 'Laundry Detergent', 'unit': 'kg', 'qty': '2', 'cat': 'Household'},
  ];

  Future<void> _addQuickPreset(Map<String, String> preset) async {
    final user = ref.read(authControllerProvider).valueOrNull;
    final ws = ref.read(activeWorkspaceProvider);
    if (user == null || ws == null) return;

    final item = GroceryItemEntity(
      id: _uuid.v4(),
      workspaceId: ws.id,
      ownerId: user.id,
      name: preset['name']!,
      quantity: double.tryParse(preset['qty']!) ?? 1.0,
      unit: preset['unit']!,
      category: preset['cat']!,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await ref.read(groceryRepositoryProvider).addItem(item);
    ref.invalidate(workspaceGroceryItemsProvider);
  }

  void _showAddItemDialog(BuildContext context) {
    final nameController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    String unit = 'pcs';
    String category = 'Pantry';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add Shopping Item', style: ApnaTypography.headingSmall),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Item Name *',
                      hintText: 'e.g. Green Tea Bags',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: qtyController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Qty',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: unit,
                          decoration: InputDecoration(
                            labelText: 'Unit',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: const ['pcs', 'kg', 'g', 'L', 'ml', 'pkt', 'box', 'bottle']
                              .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                              .toList(),
                          onChanged: (val) => setDialogState(() => unit = val ?? 'pcs'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const ['Produce', 'Dairy', 'Pantry', 'Household', 'Snacks', 'Beverages', 'General']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) => setDialogState(() => category = val ?? 'General'),
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
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final user = ref.read(authControllerProvider).valueOrNull;
                final ws = ref.read(activeWorkspaceProvider);
                if (user == null || ws == null) return;

                final item = GroceryItemEntity(
                  id: _uuid.v4(),
                  workspaceId: ws.id,
                  ownerId: user.id,
                  name: name,
                  quantity: double.tryParse(qtyController.text.trim()) ?? 1.0,
                  unit: unit,
                  category: category,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                await ref.read(groceryRepositoryProvider).addItem(item);
                ref.invalidate(workspaceGroceryItemsProvider);
                if (context.mounted) Navigator.of(dialogCtx).pop();
              },
              child: const Text('Add Item'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(workspaceGroceryItemsProvider);
    final activeWs = ref.watch(activeWorkspaceProvider);

    return Scaffold(
      backgroundColor: ApnaColors.background,
      appBar: AppBar(
        title: Text(
          activeWs?.isFamily == true ? 'Family Grocery List' : 'Grocery & Shopping',
          style: ApnaTypography.headingSmall,
        ),
        actions: [
          IconButton(
            tooltip: 'Clear Purchased Items',
            icon: const Icon(Icons.cleaning_services_rounded),
            onPressed: () async {
              if (activeWs != null) {
                await ref.read(groceryRepositoryProvider).clearPurchased(activeWs.id);
                ref.invalidate(workspaceGroceryItemsProvider);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(workspaceGroceryItemsProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemDialog(context),
        icon: const Icon(Icons.add_shopping_cart_rounded),
        label: const Text('Add Item'),
        backgroundColor: ApnaColors.primary,
        foregroundColor: Colors.white,
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (items) {
          final pending = items.where((i) => !i.isPurchased).toList();
          final completed = items.where((i) => i.isPurchased).toList();

          return CustomScrollView(
            slivers: [
              // Summary card
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: ApnaColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Need to Buy', style: TextStyle(color: ApnaColors.textSecondary, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(
                              '${pending.length} items',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: ApnaColors.primary),
                            ),
                          ],
                        ),
                      ),
                      Container(height: 40, width: 1, color: ApnaColors.border),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Purchased', style: TextStyle(color: ApnaColors.textSecondary, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(
                              '${completed.length} items',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: ApnaColors.success),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Quick Preset Chips Header
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Text('Quick Essentials', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: ApnaColors.textSecondary)),
                ),
              ),

              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: _quickPresets.map((preset) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          avatar: const Icon(Icons.add, size: 16, color: ApnaColors.primary),
                          label: Text('${preset['name']} (${preset['qty']} ${preset['unit']})'),
                          onPressed: () => _addQuickPreset(preset),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: ApnaColors.border),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Items List
              if (items.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_basket_outlined, size: 64, color: ApnaColors.border),
                        SizedBox(height: 16),
                        Text('Your shopping list is clear!', style: ApnaTypography.headingSmall),
                        SizedBox(height: 8),
                        Text('Tap the quick essentials above or add custom items.', style: ApnaTypography.bodyMedium),
                      ],
                    ),
                  ),
                )
              else ...[
                if (pending.isNotEmpty) ...[
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Text('TO BUY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: ApnaColors.textSecondary, letterSpacing: 1.0)),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, idx) {
                        final item = pending[idx];
                        return _buildItemTile(item);
                      },
                      childCount: pending.length,
                    ),
                  ),
                ],

                if (completed.isNotEmpty) ...[
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: Text('COMPLETED', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: ApnaColors.success, letterSpacing: 1.0)),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, idx) {
                        final item = completed[idx];
                        return _buildItemTile(item);
                      },
                      childCount: completed.length,
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildItemTile(GroceryItemEntity item) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: ApnaColors.border),
      ),
      child: CheckboxListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        activeColor: ApnaColors.success,
        value: item.isPurchased,
        onChanged: (val) async {
          await ref.read(groceryRepositoryProvider).togglePurchased(item.id, val ?? false);
          ref.invalidate(workspaceGroceryItemsProvider);
        },
        title: Text(
          item.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            decoration: item.isPurchased ? TextDecoration.lineThrough : null,
            color: item.isPurchased ? ApnaColors.textSecondary : ApnaColors.textPrimary,
          ),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: ApnaColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 1)} ${item.unit}',
                style: const TextStyle(color: ApnaColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Text(item.category, style: const TextStyle(fontSize: 12, color: ApnaColors.textSecondary)),
          ],
        ),
        secondary: IconButton(
          icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
          onPressed: () async {
            await ref.read(groceryRepositoryProvider).deleteItem(item.id);
            ref.invalidate(workspaceGroceryItemsProvider);
          },
        ),
      ),
    );
  }
}
