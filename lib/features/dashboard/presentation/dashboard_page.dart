import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:apna/app/theme/app_colors.dart';
import 'package:apna/app/theme/app_typography.dart';
import 'package:apna/core/integrations/upi_launcher.dart';
import 'package:apna/shared/widgets/quick_action_item.dart';
import 'package:apna/shared/widgets/stat_badge.dart';
import '../../documents/presentation/providers/document_providers.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceName = ref.watch(activeWorkspaceNameProvider);

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
                final isWide = constraints.maxWidth > 500;
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

            // Top Stat Cards
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
                      count: '5',
                      label: 'Pending Tasks',
                      icon: Icons.check_circle_outline_rounded,
                      iconColor: ApnaColors.categoryTask,
                      backgroundColor: ApnaColors.successBg,
                      onTap: () => context.go('/tasks'),
                    ),
                    StatBadgeCard(
                      count: '3',
                      label: 'Upcoming Bills',
                      subtext: '₹4,860',
                      icon: Icons.receipt_long_rounded,
                      iconColor: ApnaColors.categoryBill,
                      backgroundColor: ApnaColors.errorBg,
                      onTap: () => context.go('/bills'),
                    ),
                    StatBadgeCard(
                      count: '2',
                      label: 'Expiring Warranties',
                      icon: Icons.verified_user_outlined,
                      iconColor: ApnaColors.categoryWarranty,
                      backgroundColor: ApnaColors.warningBg,
                      onTap: () => context.go('/warranty'),
                    ),
                    StatBadgeCard(
                      count: '1',
                      label: 'Upcoming Event',
                      subtext: 'Doctor Appt',
                      icon: Icons.calendar_today_rounded,
                      iconColor: ApnaColors.info,
                      backgroundColor: ApnaColors.infoBg,
                      onTap: () => context.go('/calendar'),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Quick Actions Bar
            const Text('Quick Actions', style: ApnaTypography.headingSmall),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  QuickActionItem(
                    label: 'Add Document',
                    icon: Icons.upload_file_rounded,
                    onTap: () => context.go('/documents/add'),
                  ),
                  const SizedBox(width: 10),
                  QuickActionItem(
                    label: 'Create Task',
                    icon: Icons.add_task_rounded,
                    onTap: () => _showFeedback(context, 'Task creation modal'),
                  ),
                  const SizedBox(width: 10),
                  QuickActionItem(
                    label: 'Add Bill',
                    icon: Icons.add_card_rounded,
                    onTap: () => _showFeedback(context, 'Bill entry dialog'),
                  ),
                  const SizedBox(width: 10),
                  QuickActionItem(
                    label: 'Add Note',
                    icon: Icons.note_add_rounded,
                    onTap: () => _showFeedback(context, 'Note editor'),
                  ),
                  const SizedBox(width: 10),
                  QuickActionItem(
                    label: 'Add Expense',
                    icon: Icons.account_balance_wallet_rounded,
                    onTap: () => _showFeedback(context, 'Expense tracker'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Two-column split: Bills & Upcoming on Left, Documents on Right
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 840;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildUpcomingSection(context)),
                      const SizedBox(width: 20),
                      Expanded(child: _buildRecentDocumentsSection(context)),
                    ],
                  );
                }
                return Column(
                  children: [
                    _buildUpcomingSection(context),
                    const SizedBox(height: 20),
                    _buildRecentDocumentsSection(context),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),

            // Ecosystem & Security Highlights
            _buildEcosystemPillars(),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting(String workspaceName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Good Morning, Shubham', style: ApnaTypography.headingLarge),
        const SizedBox(height: 4),
        Text(
          "Here's what's happening in your $workspaceName space",
          style: ApnaTypography.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: ApnaColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ApnaColors.border),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search, size: 18, color: ApnaColors.textSecondary),
          SizedBox(width: 8),
          Text('Search everything (⌘K)', style: ApnaTypography.bodySmall),
        ],
      ),
    );
  }

  Widget _buildUpcomingSection(BuildContext context) {
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
                child: Text('Recent & Upcoming Bills', style: ApnaTypography.headingSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              TextButton(
                onPressed: () => context.go('/bills'),
                child: const Text('View All', style: TextStyle(color: ApnaColors.blue)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildBillRow(
            context,
            title: 'Electricity Bill',
            subtitle: 'Due in 2 days • ₹1,850',
            amount: 1850.0,
            vpa: 'tneb@billpay',
            isDueSoon: true,
          ),
          const Divider(height: 20),
          _buildBillRow(
            context,
            title: 'Water Utility Bill',
            subtitle: 'Due on 15 Jan • ₹620',
            amount: 620.0,
            vpa: 'cmwssb@upi',
            isDueSoon: false,
          ),
          const Divider(height: 20),
          _buildBillRow(
            context,
            title: 'Internet (Airtel Broadband)',
            subtitle: 'Due on 20 Jan • ₹799',
            amount: 799.0,
            vpa: 'airtelbroadband@upi',
            isDueSoon: false,
          ),
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
              _showFeedback(context, 'Opening UPI payment intent for $title (₹$amount)');
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

  Widget _buildRecentDocumentsSection(BuildContext context) {
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
                child: Text('Recent Documents', style: ApnaTypography.headingSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              TextButton(
                onPressed: () => context.go('/documents'),
                child: const Text('View All', style: TextStyle(color: ApnaColors.blue)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildDocItem('Home Insurance Policy.pdf', 'Insurance • Added today', Icons.security_rounded),
          const Divider(height: 18),
          _buildDocItem('Passport - Shubham.pdf', 'Identity/KYC • 1.1 MB • Yesterday', Icons.badge_rounded),
          const Divider(height: 18),
          _buildDocItem('Laptop Warranty.pdf', 'Warranty • 2.4 MB • 3 days ago', Icons.laptop_mac_rounded),
          const Divider(height: 18),
          _buildDocItem('Car RC.jpg', 'Vehicle • 3.2 MB • 3 days ago', Icons.directions_car_rounded),
        ],
      ),
    );
  }

  Widget _buildDocItem(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: ApnaColors.surfaceSubtle,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          child: Icon(icon, color: ApnaColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: ApnaTypography.titleMedium.copyWith(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(subtitle, style: ApnaTypography.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: ApnaColors.textTertiary),
      ],
    );
  }

  Widget _buildEcosystemPillars() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [ApnaColors.primary, ApnaColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return const Wrap(
            alignment: WrapAlignment.spaceAround,
            runSpacing: 14,
            spacing: 14,
            children: [
              _PillarBadge(icon: Icons.sync_rounded, title: 'Real-time Sync', subtitle: 'All devices'),
              _PillarBadge(icon: Icons.offline_pin_rounded, title: 'Offline Ready', subtitle: 'SQLite Outbox'),
              _PillarBadge(icon: Icons.qr_code_rounded, title: 'UPI Payments', subtitle: 'GPay, PhonePe, Paytm'),
              _PillarBadge(icon: Icons.verified_user_rounded, title: 'DPDP Compliant', subtitle: 'India Legal Notice'),
            ],
          );
        },
      ),
    );
  }

  static void _showFeedback(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }
}

class _PillarBadge extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PillarBadge({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: ApnaColors.accentLight, size: 22),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(color: ApnaColors.textTertiary, fontSize: 10)),
      ],
    );
  }
}
