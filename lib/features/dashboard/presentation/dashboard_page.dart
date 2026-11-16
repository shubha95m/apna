import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:apna/app/theme/app_colors.dart';
import 'package:apna/app/theme/app_typography.dart';
import 'package:apna/core/integrations/upi_launcher.dart';
import 'package:apna/shared/widgets/quick_action_item.dart';
import 'package:apna/shared/widgets/stat_badge.dart';
import '../../bills/domain/entities/bill_entity.dart';
import '../../bills/presentation/providers/bill_providers.dart';
import '../../documents/domain/entities/document_entity.dart';
import '../../documents/presentation/providers/document_providers.dart';
import '../../tasks/presentation/providers/task_providers.dart';
import '../../warranties/presentation/providers/warranty_providers.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceName = ref.watch(activeWorkspaceNameProvider);

    final documentsAsync = ref.watch(documentListNotifierProvider);
    final tasksAsync = ref.watch(taskListNotifierProvider);
    final billsAsync = ref.watch(billListNotifierProvider);
    final warrantiesAsync = ref.watch(warrantyListNotifierProvider);

    final documents = documentsAsync.valueOrNull ?? [];
    final tasks = tasksAsync.valueOrNull ?? [];
    final bills = billsAsync.valueOrNull ?? [];
    final warranties = warrantiesAsync.valueOrNull ?? [];

    final pendingTasksCount = tasks.where((t) => !t.isCompleted).length;
    final unpaidBills = bills.where((b) => !b.isPaid).toList();
    final totalUnpaidAmount = unpaidBills.fold(0.0, (sum, b) => sum + b.amount);
    final activeWarrantiesCount = warranties.where((w) => !w.isExpired).length;

    return Scaffold(
      backgroundColor: ApnaColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar Greeting
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 650;
                if (isWide) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: _buildGreeting(workspaceName)),
                      const SizedBox(width: 12),
                      _buildSearchBar(),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGreeting(workspaceName),
                    const SizedBox(height: 12),
                    _buildSearchBar(),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // Top Stat Cards (Real Live Data)
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 700;
                return GridView.count(
                  crossAxisCount: isWide ? 4 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: isWide ? 1.6 : 1.25,
                  children: [
                    StatBadgeCard(
                      count: '$pendingTasksCount',
                      label: 'Pending Tasks',
                      icon: Icons.check_circle_outline_rounded,
                      iconColor: ApnaColors.categoryTask,
                      backgroundColor: ApnaColors.successBg,
                      onTap: () => context.go('/tasks'),
                    ),
                    StatBadgeCard(
                      count: '${unpaidBills.length}',
                      label: 'Upcoming Bills',
                      subtext: '₹${totalUnpaidAmount.toStringAsFixed(0)}',
                      icon: Icons.receipt_long_rounded,
                      iconColor: ApnaColors.categoryBill,
                      backgroundColor: ApnaColors.errorBg,
                      onTap: () => context.go('/bills'),
                    ),
                    StatBadgeCard(
                      count: '$activeWarrantiesCount',
                      label: 'Active Warranties',
                      icon: Icons.verified_user_outlined,
                      iconColor: ApnaColors.categoryWarranty,
                      backgroundColor: ApnaColors.warningBg,
                      onTap: () => context.go('/warranty'),
                    ),
                    StatBadgeCard(
                      count: '${documents.length}',
                      label: 'Vault Documents',
                      subtext: 'Encrypted',
                      icon: Icons.folder_shared_outlined,
                      iconColor: ApnaColors.info,
                      backgroundColor: ApnaColors.infoBg,
                      onTap: () => context.go('/documents'),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Quick Actions
            _buildSectionHeader('Quick Actions'),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  QuickActionItem(
                    icon: Icons.upload_file_rounded,
                    label: 'Add Document',
                    onTap: () => context.go('/documents/add'),
                  ),
                  const SizedBox(width: 14),
                  QuickActionItem(
                    icon: Icons.add_task_rounded,
                    label: 'Add Task',
                    onTap: () => context.go('/tasks'),
                  ),
                  const SizedBox(width: 14),
                  QuickActionItem(
                    icon: Icons.payment_rounded,
                    label: 'Pay Bills',
                    onTap: () => context.go('/bills'),
                  ),
                  const SizedBox(width: 14),
                  QuickActionItem(
                    icon: Icons.currency_rupee_rounded,
                    label: 'Log Expense',
                    onTap: () => context.go('/expenses'),
                  ),
                  const SizedBox(width: 14),
                  QuickActionItem(
                    icon: Icons.verified_rounded,
                    label: 'Add Warranty',
                    onTap: () => context.go('/warranty'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Two-Column Grid: Upcoming Bills & Recent Documents
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 800;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildUpcomingBillsSection(context, unpaidBills)),
                      const SizedBox(width: 20),
                      Expanded(child: _buildRecentDocumentsSection(context, documents)),
                    ],
                  );
                }
                return Column(
                  children: [
                    _buildUpcomingBillsSection(context, unpaidBills),
                    const SizedBox(height: 20),
                    _buildRecentDocumentsSection(context, documents),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),

            // Connected Platform Pillars
            _buildSectionHeader('Apna Connected Pillars (Zero-Cost Supabase Free Tier)'),
            const SizedBox(height: 12),
            _buildEcosystemPillars(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting(String workspaceName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            const Text('Good Morning, Shubham', style: ApnaTypography.headingLarge),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: ApnaColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$workspaceName Workspace',
                style: const TextStyle(
                  color: ApnaColors.accentDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Here is your live household & personal summary across India.',
          style: ApnaTypography.bodySmall,
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: ApnaColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ApnaColors.border),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search, size: 18, color: ApnaColors.textSecondary),
          SizedBox(width: 8),
          Flexible(
            child: Text('Search everything (⌘K)', style: ApnaTypography.bodySmall, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingBillsSection(BuildContext context, List<BillEntity> unpaidBills) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ApnaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ApnaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text('Live Upcoming Bills', style: ApnaTypography.headingSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              TextButton(
                onPressed: () => context.go('/bills'),
                child: const Text('View All', style: TextStyle(color: ApnaColors.blue)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (unpaidBills.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('All bills paid! No pending dues.', style: TextStyle(color: ApnaColors.textSecondary)),
              ),
            )
          else
            ...unpaidBills.take(3).map((bill) {
              return Column(
                children: [
                  _buildBillRow(
                    context,
                    title: bill.title,
                    subtitle: 'Due ${DateFormat('dd MMM').format(bill.dueDate)} • ₹${bill.amount.toStringAsFixed(0)}',
                    amount: bill.amount,
                    vpa: bill.upiVpa ?? 'merchant@upi',
                    isDueSoon: bill.isOverdue || bill.dueDate.difference(DateTime.now()).inDays <= 3,
                  ),
                  const Divider(height: 16),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildBillRow(
    BuildContext context, {
    required String title,
    required String subtitle,
    required double amount,
    required String vpa,
    required bool isDueSoon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDueSoon ? ApnaColors.errorBg : ApnaColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.bolt_rounded,
            color: isDueSoon ? ApnaColors.error : ApnaColors.textSecondary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: ApnaTypography.titleMedium.copyWith(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: ApnaTypography.bodySmall.copyWith(
                  color: isDueSoon ? ApnaColors.error : ApnaColors.textSecondary,
                  fontWeight: isDueSoon ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.tonal(
          onPressed: () async {
            final launched = await UpiLauncher.launchUpiPayment(
              UpiPaymentRequest(
                payeeVpa: vpa,
                payeeName: title,
                amount: amount,
                transactionNote: 'Apna Bill - $title',
                transactionRef: 'APNA-${DateTime.now().millisecondsSinceEpoch}',
              ),
            );
            if (!context.mounted) return;
            if (!launched) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('UPI Intent: $vpa (₹$amount)')),
              );
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: ApnaColors.accent.withValues(alpha: 0.12),
            foregroundColor: ApnaColors.accentDark,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            visualDensity: VisualDensity.compact,
          ),
          child: const Text('Pay UPI', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildRecentDocumentsSection(BuildContext context, List<DocumentEntity> documents) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ApnaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ApnaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text('Live Vault Documents', style: ApnaTypography.headingSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              TextButton(
                onPressed: () => context.go('/documents'),
                child: const Text('View All', style: TextStyle(color: ApnaColors.blue)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (documents.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No documents uploaded yet.', style: TextStyle(color: ApnaColors.textSecondary)),
              ),
            )
          else
            ...documents.take(3).map((doc) {
              return Column(
                children: [
                  _buildDocRow(
                    context,
                    title: doc.title,
                    category: doc.category.name.toUpperCase(),
                    timeAgo: DateFormat('dd MMM yyyy').format(doc.createdAt),
                  ),
                  const Divider(height: 16),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildDocRow(
    BuildContext context, {
    required String title,
    required String category,
    required String timeAgo,
  }) {
    return InkWell(
      onTap: () => context.go('/documents'),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ApnaColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.description_outlined, color: ApnaColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: ApnaTypography.titleMedium.copyWith(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('$category • Added $timeAgo', style: ApnaTypography.bodySmall.copyWith(fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: ApnaColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildEcosystemPillars(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        return GridView.count(
          crossAxisCount: isWide ? 4 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: isWide ? 2.2 : 1.6,
          children: [
            _buildPillarCard(context, 'Documents Vault', 'KYC, Property, Insurance', Icons.folder_shared_outlined, '/documents'),
            _buildPillarCard(context, 'Tasks & Chores', 'Family reminders & chores', Icons.task_alt_rounded, '/tasks'),
            _buildPillarCard(context, 'Bills & UPI', 'One-click NPCI intent pay', Icons.payment_rounded, '/bills'),
            _buildPillarCard(context, 'Warranties', 'Claim & invoice vault', Icons.verified_user_outlined, '/warranty'),
          ],
        );
      },
    );
  }

  Widget _buildPillarCard(BuildContext context, String title, String subtitle, IconData icon, String route) {
    return InkWell(
      onTap: () => context.go(route),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ApnaColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ApnaColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: ApnaColors.primary, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(subtitle, style: ApnaTypography.bodySmall.copyWith(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: ApnaTypography.headingSmall,
    );
  }
}
