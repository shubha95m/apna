import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/integrations/upi_launcher.dart';
import 'package:apna/features/documents/presentation/providers/document_providers.dart';
import '../../domain/entities/bill_entity.dart';
import '../providers/bill_providers.dart';

class BillsPage extends ConsumerStatefulWidget {
  const BillsPage({super.key});

  @override
  ConsumerState<BillsPage> createState() => _BillsPageState();
}

class _BillsPageState extends ConsumerState<BillsPage> {
  String _filter = 'UNPAID'; // ALL, UNPAID, PAID

  void _showAddBillDialog(BuildContext context) {
    final titleController = TextEditingController();
    final providerController = TextEditingController();
    final consumerNoController = TextEditingController();
    final amountController = TextEditingController();
    final vpaController = TextEditingController();
    String category = 'electricity';
    DateTime dueDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add Recurring Bill', style: ApnaTypography.headingSmall),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Bill Title *',
                      hintText: 'e.g. BSES Electricity Bill',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: providerController,
                          decoration: InputDecoration(
                            labelText: 'Provider Name *',
                            hintText: 'e.g. BSES Rajdhani',
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
                            DropdownMenuItem(value: 'electricity', child: Text('Electricity')),
                            DropdownMenuItem(value: 'water', child: Text('Water')),
                            DropdownMenuItem(value: 'internet', child: Text('Broadband')),
                            DropdownMenuItem(value: 'mobile', child: Text('Mobile')),
                            DropdownMenuItem(value: 'gas', child: Text('Gas (PNG/LPG)')),
                            DropdownMenuItem(value: 'rent', child: Text('Rent')),
                            DropdownMenuItem(value: 'dth', child: Text('DTH TV')),
                            DropdownMenuItem(value: 'other', child: Text('Other')),
                          ],
                          onChanged: (val) {
                            if (val != null) setDialogState(() => category = val);
                          },
                        ),
                      ),
                    ],
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
                            hintText: 'e.g. 3240',
                            prefixText: '₹ ',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: consumerNoController,
                          decoration: InputDecoration(
                            labelText: 'Consumer / CA No.',
                            hintText: 'e.g. CA-102938475',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: vpaController,
                    decoration: InputDecoration(
                      labelText: 'Biller UPI ID (VPA) for 1-Click Pay',
                      hintText: 'e.g. bsesrajdhani@icici',
                      prefixIcon: const Icon(Icons.payment_rounded, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 18, color: ApnaColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        'Due Date: ${DateFormat('dd MMM yyyy').format(dueDate)}',
                        style: ApnaTypography.bodyMedium,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: dueDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setDialogState(() => dueDate = picked);
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
                final provider = providerController.text.trim();
                final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
                if (title.isEmpty || provider.isEmpty || amount <= 0) return;

                final workspaceId = ref.read(activeWorkspaceIdProvider);
                final newBill = BillEntity(
                  id: const Uuid().v4(),
                  workspaceId: workspaceId,
                  title: title,
                  providerName: provider,
                  category: category,
                  amount: amount,
                  consumerNumber: consumerNoController.text.trim().isNotEmpty ? consumerNoController.text.trim() : null,
                  upiVpa: vpaController.text.trim().isNotEmpty ? vpaController.text.trim() : null,
                  dueDate: dueDate,
                  paymentStatus: 'unpaid',
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                ref.read(billListNotifierProvider.notifier).addBill(newBill);
                Navigator.pop(dialogCtx);
              },
              child: const Text('Save Bill'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _payWithUpi(BillEntity bill) async {
    final vpa = bill.upiVpa ?? 'merchant@upi';
    final request = UpiPaymentRequest(
      payeeVpa: vpa,
      payeeName: bill.providerName,
      amount: bill.amount,
      transactionRef: 'BILL-${bill.id.substring(0, 8)}',
      transactionNote: '${bill.title} payment via Apna',
    );

    final launched = await UpiLauncher.launchUpiPayment(request);
    if (!mounted) return;

    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('UPI URI: ${request.toUri()}\nOpen UPI app (GPay/PhonePe/Paytm) to complete payment.'),
          backgroundColor: ApnaColors.primary,
          duration: const Duration(seconds: 5),
        ),
      );
    }

    // Offer to mark as paid
    _showMarkAsPaidPrompt(bill);
  }

  void _showMarkAsPaidPrompt(BillEntity bill) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Payment Status'),
        content: Text('Did you successfully complete payment of ₹${bill.amount.toStringAsFixed(2)} for ${bill.title}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Not Yet'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ApnaColors.accentDark),
            onPressed: () {
              ref.read(billListNotifierProvider.notifier).markAsPaid(bill.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bill marked as paid! Synced to Supabase.')),
              );
            },
            child: const Text('Yes, Mark as Paid'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final billsAsync = ref.watch(billListNotifierProvider);

    return Scaffold(
      backgroundColor: ApnaColors.background,
      body: SafeArea(
        child: billsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: ApnaColors.error),
              const SizedBox(height: 12),
              Text('Failed to load bills: $err', style: ApnaTypography.bodyMedium),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.refresh(billListNotifierProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (bills) {
          final unpaidBills = bills.where((b) => !b.isPaid).toList();
          final paidBills = bills.where((b) => b.isPaid).toList();
          final totalPayable = unpaidBills.fold(0.0, (sum, b) => sum + b.amount);

          final filteredBills = bills.where((b) {
            if (_filter == 'UNPAID') return !b.isPaid;
            if (_filter == 'PAID') return b.isPaid;
            return true;
          }).toList();

          return CustomScrollView(
            slivers: [
              // Header & Total Payable Banner
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
                              const Text('Bills & Utility Payments', style: ApnaTypography.headingLarge),
                              const SizedBox(height: 4),
                              Text(
                                '${unpaidBills.length} bills due • Total payable: ₹${totalPayable.toStringAsFixed(0)} • NPCI UPI Integrated',
                                style: ApnaTypography.bodyMedium,
                              ),
                            ],
                          ),
                          if (ref.watch(canWriteCurrentWorkspaceProvider))
                            FilledButton.icon(
                              onPressed: () => _showAddBillDialog(context),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Bill'),
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

                      // Metric Banner
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [ApnaColors.primary, Color(0xFF2C3E50)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Upcoming Dues', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${totalPayable.toStringAsFixed(2)}',
                                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Container(width: 1, height: 44, color: Colors.white24),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Unpaid Bills', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                const SizedBox(height: 4),
                                Text(
                                  '${unpaidBills.length}',
                                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Container(width: 1, height: 44, color: Colors.white24),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Paid This Cycle', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                const SizedBox(height: 4),
                                Text(
                                  '${paidBills.length}',
                                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Filter chips
                      Row(
                        children: [
                          _buildFilterChip('UNPAID', 'Pending Dues (${unpaidBills.length})'),
                          const SizedBox(width: 8),
                          _buildFilterChip('ALL', 'All Bills (${bills.length})'),
                          const SizedBox(width: 8),
                          _buildFilterChip('PAID', 'Paid History (${paidBills.length})'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Bills List
              if (filteredBills.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 56, color: ApnaColors.textSecondary),
                        SizedBox(height: 12),
                        Text('No bills found', style: ApnaTypography.headingSmall),
                        SizedBox(height: 4),
                        Text('All utility bills are settled or no records exist.', style: ApnaTypography.bodySmall),
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
                        final bill = filteredBills[index];
                        return _buildBillCard(bill);
                      },
                      childCount: filteredBills.length,
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

  Widget _buildBillCard(BillEntity bill) {
    IconData categoryIcon;
    switch (bill.category.toLowerCase()) {
      case 'electricity':
        categoryIcon = Icons.bolt_rounded;
        break;
      case 'water':
        categoryIcon = Icons.water_drop_rounded;
        break;
      case 'internet':
      case 'broadband':
        categoryIcon = Icons.wifi_rounded;
        break;
      case 'mobile':
        categoryIcon = Icons.phone_android_rounded;
        break;
      case 'gas':
        categoryIcon = Icons.local_fire_department_rounded;
        break;
      case 'rent':
        categoryIcon = Icons.home_work_rounded;
        break;
      default:
        categoryIcon = Icons.receipt_rounded;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 14.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: ApnaColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          children: [
            // Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: ApnaColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Icon(categoryIcon, color: ApnaColors.primary, size: 24),
              ),
            ),
            const SizedBox(width: 16),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(bill.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: bill.isPaid
                              ? ApnaColors.accentDark.withOpacity(0.12)
                              : (bill.isOverdue ? ApnaColors.error.withOpacity(0.12) : ApnaColors.warning.withOpacity(0.12)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          bill.isPaid ? 'PAID' : (bill.isOverdue ? 'OVERDUE' : 'DUE SOON'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: bill.isPaid
                                ? ApnaColors.accentDark
                                : (bill.isOverdue ? ApnaColors.error : ApnaColors.warning),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${bill.providerName}${bill.consumerNumber != null ? ' • CA: ${bill.consumerNumber}' : ''}',
                    style: const TextStyle(fontSize: 13, color: ApnaColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_month_outlined, size: 14, color: bill.isOverdue ? ApnaColors.error : ApnaColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'Due: ${DateFormat('dd MMM yyyy').format(bill.dueDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: bill.isOverdue ? ApnaColors.error : ApnaColors.textSecondary,
                          fontWeight: bill.isOverdue ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (bill.upiVpa != null) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.payment_rounded, size: 14, color: ApnaColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(bill.upiVpa!, style: const TextStyle(fontSize: 12, color: ApnaColors.textSecondary)),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Amount & Actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${bill.amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: ApnaColors.textPrimary),
                ),
                const SizedBox(height: 8),
                if (!bill.isPaid)
                  Row(
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => ref.read(billListNotifierProvider.notifier).markAsPaid(bill.id),
                        child: const Text('Mark Paid', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: ApnaColors.accentDark,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _payWithUpi(bill),
                        icon: const Icon(Icons.bolt_rounded, size: 16),
                        label: const Text('Pay with UPI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 16, color: ApnaColors.accentDark),
                      const SizedBox(width: 4),
                      Text(
                        'Paid ${bill.paidAt != null ? DateFormat('dd MMM').format(bill.paidAt!) : ''}',
                        style: const TextStyle(color: ApnaColors.accentDark, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
