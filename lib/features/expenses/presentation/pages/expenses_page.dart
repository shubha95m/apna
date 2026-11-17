import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import 'package:apna/features/authentication/presentation/providers/auth_providers.dart';
import 'package:apna/features/documents/presentation/providers/document_providers.dart';
import '../../domain/entities/expense_entity.dart';
import '../providers/expense_providers.dart';

class ExpensesPage extends ConsumerStatefulWidget {
  const ExpensesPage({super.key});

  @override
  ConsumerState<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends ConsumerState<ExpensesPage> {
  String _selectedCategory = 'ALL';

  void _showAddExpenseDialog(BuildContext context) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String category = 'Groceries';
    String paymentMode = 'upi';
    DateTime expenseDate = DateTime.now();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Log Shared Expense', style: ApnaTypography.headingSmall),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Expense Description *',
                      hintText: 'e.g. Weekly Grocery - Blinkit',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Amount (₹) *',
                            prefixText: '₹ ',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: category,
                          decoration: InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Groceries', child: Text('Groceries')),
                            DropdownMenuItem(value: 'Utilities', child: Text('Utilities')),
                            DropdownMenuItem(value: 'Dining', child: Text('Dining')),
                            DropdownMenuItem(value: 'Shopping', child: Text('Shopping')),
                            DropdownMenuItem(value: 'Travel', child: Text('Travel')),
                            DropdownMenuItem(value: 'Health', child: Text('Health')),
                            DropdownMenuItem(value: 'Other', child: Text('Other')),
                          ],
                          onChanged: (val) {
                            if (val != null) setDialogState(() => category = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: paymentMode,
                    decoration: InputDecoration(
                      labelText: 'Payment Mode',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'upi', child: Text('UPI (GPay / PhonePe / Paytm)')),
                      DropdownMenuItem(value: 'card', child: Text('Credit / Debit Card')),
                      DropdownMenuItem(value: 'cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'net_banking', child: Text('Net Banking')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => paymentMode = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    decoration: InputDecoration(
                      labelText: 'Notes (Optional)',
                      hintText: 'Add details or split notes...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 18, color: ApnaColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        'Date: ${DateFormat('dd MMM yyyy').format(expenseDate)}',
                        style: ApnaTypography.bodyMedium,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: expenseDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setDialogState(() => expenseDate = picked);
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
                final title = titleController.text.trim();
                final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
                if (title.isEmpty || amount <= 0) return;

                final workspaceId = ref.read(activeWorkspaceIdProvider);
                final currentUserId = Supabase.instance.client.auth.currentUser?.id ??
                    ref.read(authControllerProvider).valueOrNull?.id ??
                    'user-anonymous';
                final newExpense = ExpenseEntity(
                  id: const Uuid().v4(),
                  workspaceId: workspaceId,
                  paidById: currentUserId,
                  title: title,
                  amount: amount,
                  category: category,
                  paymentMode: paymentMode,
                  expenseDate: expenseDate,
                  notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                  createdAt: DateTime.now(),
                );

                ref.read(expenseListNotifierProvider.notifier).addExpense(newExpense);
                Navigator.pop(dialogCtx);
              },
              child: const Text('Save Expense'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expenseListNotifierProvider);

    return Scaffold(
      backgroundColor: ApnaColors.background,
      body: SafeArea(
        child: expensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: ApnaColors.error),
              const SizedBox(height: 12),
              Text('Failed to load expenses: $err', style: ApnaTypography.bodyMedium),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.refresh(expenseListNotifierProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (expenses) {
          final totalSpent = expenses.fold(0.0, (sum, e) => sum + e.amount);

          final filtered = expenses.where((e) {
            if (_selectedCategory == 'ALL') return true;
            return e.category.toLowerCase() == _selectedCategory.toLowerCase();
          }).toList();

          return CustomScrollView(
            slivers: [
              // Header & Total Spent Banner
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
                              const Text('Expenses & Shared Split', style: ApnaTypography.headingLarge),
                              const SizedBox(height: 4),
                              Text(
                                '${expenses.length} transactions • Total: ₹${totalSpent.toStringAsFixed(2)} • Real Supabase Ledger',
                                style: ApnaTypography.bodyMedium,
                              ),
                            ],
                          ),
                          if (ref.watch(canWriteCurrentWorkspaceProvider))
                            FilledButton.icon(
                              onPressed: () => _showAddExpenseDialog(context),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Log Expense'),
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

                      // Metric Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: ApnaColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: ApnaColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Recorded Spend', style: ApnaTypography.bodySmall),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${totalSpent.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: ApnaColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            Container(width: 1, height: 44, color: ApnaColors.border),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Transactions', style: ApnaTypography.bodySmall),
                                const SizedBox(height: 4),
                                Text(
                                  '${expenses.length}',
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: ApnaColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Container(width: 1, height: 44, color: ApnaColors.border),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Payment Modes', style: ApnaTypography.bodySmall),
                                SizedBox(height: 4),
                                Text(
                                  'UPI, Card, Cash',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: ApnaColors.accentDark,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Filter chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('ALL', 'All (${expenses.length})'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Groceries', 'Groceries'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Utilities', 'Utilities'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Dining', 'Dining'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Travel', 'Travel'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Shopping', 'Shopping'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Health', 'Health'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Expenses List
              if (filtered.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_wallet_outlined, size: 56, color: ApnaColors.textSecondary),
                        SizedBox(height: 12),
                        Text('No expenses in this view', style: ApnaTypography.headingSmall),
                        SizedBox(height: 4),
                        Text('Log expenses to track shared family household budget.', style: ApnaTypography.bodySmall),
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
                        final expense = filtered[index];
                        return _buildExpenseCard(expense);
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}

  Widget _buildFilterChip(String category, String label) {
    final isSelected = _selectedCategory == category;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _selectedCategory = category);
      },
      selectedColor: ApnaColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : ApnaColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        fontSize: 13,
      ),
    );
  }

  Widget _buildExpenseCard(ExpenseEntity expense) {
    IconData modeIcon;
    switch (expense.paymentMode.toLowerCase()) {
      case 'upi':
        modeIcon = Icons.bolt_rounded;
        break;
      case 'card':
        modeIcon = Icons.credit_card_rounded;
        break;
      case 'cash':
        modeIcon = Icons.payments_outlined;
        break;
      default:
        modeIcon = Icons.account_balance_rounded;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: ApnaColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
        child: Row(
          children: [
            // Mode icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: ApnaColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(modeIcon, color: ApnaColors.accentDark, size: 22),
              ),
            ),
            const SizedBox(width: 14),

            // Title & Category
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(expense.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: ApnaColors.accentLight.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          expense.category.toUpperCase(),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ApnaColors.accentDark),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('dd MMM yyyy').format(expense.expenseDate),
                        style: const TextStyle(fontSize: 12, color: ApnaColors.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• ${expense.paymentMode.toUpperCase()}',
                        style: const TextStyle(fontSize: 12, color: ApnaColors.textSecondary),
                      ),
                    ],
                  ),
                  if (expense.notes != null && expense.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(expense.notes!, style: const TextStyle(fontSize: 12, color: ApnaColors.textSecondary)),
                  ],
                ],
              ),
            ),

            // Amount & Delete
            Row(
              children: [
                Text(
                  '₹${expense.amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: ApnaColors.textPrimary),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: ApnaColors.textSecondary),
                  onPressed: () => ref.read(expenseListNotifierProvider.notifier).deleteExpense(expense.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
