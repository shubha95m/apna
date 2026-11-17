import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:apna/app/theme/app_colors.dart';
import 'package:apna/app/theme/app_typography.dart';
import 'package:apna/core/integrations/upi_launcher.dart';
import 'package:apna/shared/widgets/quick_action_item.dart';
import 'package:apna/shared/widgets/stat_badge.dart';
import '../../authentication/presentation/providers/auth_providers.dart';
import '../../bills/domain/entities/bill_entity.dart';
import '../../bills/presentation/providers/bill_providers.dart';
import '../../documents/domain/entities/document_entity.dart';
import '../../documents/presentation/providers/document_providers.dart';
import '../../permissions/presentation/smart_sync_permission_dialog.dart';
import '../../tasks/presentation/providers/task_providers.dart';
import '../../warranties/presentation/providers/warranty_providers.dart';
import '../../workspaces/presentation/widgets/manage_family_members_dialog.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        SmartSyncPermissionDialog.showIfNeeded(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
      body: SafeArea(
        child: SingleChildScrollView(
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
                      Expanded(child: _buildGreeting(context, ref, workspaceName)),
                      const SizedBox(width: 12),
                      _buildSearchBar(),
                      const SizedBox(width: 12),
                      _buildUserProfileButton(context, ref, workspaceName),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildGreeting(context, ref, workspaceName)),
                        _buildUserProfileButton(context, ref, workspaceName),
                      ],
                    ),
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
    ),
  );
  }

  Widget _buildGreeting(BuildContext context, WidgetRef ref, String workspaceName) {
    final hour = DateTime.now().hour;
    final timeGreeting = hour < 12
        ? 'Good Morning'
        : (hour < 17 ? 'Good Afternoon' : 'Good Evening');

    final authUser = ref.watch(authControllerProvider).valueOrNull;
    final fullName = authUser?.fullName?.trim();
    final rawName = (fullName != null && fullName.isNotEmpty)
        ? fullName.split(' ').first
        : (authUser?.email.isNotEmpty == true ? authUser!.email.split('@').first : 'User');
    final capitalizedName = rawName.isNotEmpty
        ? '${rawName[0].toUpperCase()}${rawName.length > 1 ? rawName.substring(1) : ''}'
        : 'User';

    final activeWs = ref.watch(activeWorkspaceProvider);
    final userRole = ref.watch(activeWorkspaceRoleProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Text('$timeGreeting, $capitalizedName', style: ApnaTypography.headingLarge),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: ApnaColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$workspaceName (${userRole.toUpperCase()})',
                style: const TextStyle(
                  color: ApnaColors.accentDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (activeWs != null && activeWs.isFamily)
              InkWell(
                onTap: () => ManageFamilyMembersDialog.show(context, activeWs),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: ApnaColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ApnaColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.group_outlined, size: 14, color: ApnaColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        activeWs.isAdmin ? 'Manage Family' : 'Family Members',
                        style: const TextStyle(
                          color: ApnaColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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

  Widget _buildUserProfileButton(BuildContext context, WidgetRef ref, String workspaceName) {
    final authUser = ref.watch(authControllerProvider).valueOrNull;
    final activeWs = ref.watch(activeWorkspaceProvider);
    final userRole = ref.watch(activeWorkspaceRoleProvider);
    final email = authUser?.email ?? 'user@apna.family';
    final fullName = authUser?.fullName?.trim() ?? 'Apna User';
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U';

    return PopupMenuButton<String>(
      tooltip: 'Account & Settings',
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ApnaColors.primary.withValues(alpha: 0.3), width: 1.5),
        ),
        child: CircleAvatar(
          radius: 18,
          backgroundColor: ApnaColors.primary,
          child: Text(
            initial,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
      ),
      itemBuilder: (ctx) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: ApnaColors.primaryLight,
                    child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: ApnaColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          email,
                          style: const TextStyle(fontSize: 12, color: ApnaColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ApnaColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield_outlined, size: 14, color: ApnaColors.accentDark),
                    const SizedBox(width: 6),
                    Text(
                      'Workspace: $workspaceName (${userRole.toUpperCase()})',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ApnaColors.accentDark),
                    ),
                  ],
                ),
              ),
              const Divider(height: 16),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'toggle_workspace',
          child: Row(
            children: [
              const Icon(Icons.swap_horiz_rounded, size: 20, color: ApnaColors.primary),
              const SizedBox(width: 12),
              Text(
                workspaceName == 'Family' ? 'Switch to Personal' : 'Switch to Family',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        if (activeWs?.isFamily == true)
          PopupMenuItem<String>(
            value: 'manage_family',
            child: Row(
              children: [
                const Icon(Icons.group_outlined, size: 20, color: ApnaColors.accentDark),
                const SizedBox(width: 12),
                Text(
                  activeWs?.isAdmin == true ? 'Manage Family Members' : 'View Family Members',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        const PopupMenuItem<String>(
          value: 'sign_out',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 20, color: ApnaColors.error),
              SizedBox(width: 12),
              Text(
                'Sign Out',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ApnaColors.error),
              ),
            ],
          ),
        ),
      ],
      onSelected: (value) async {
        if (value == 'toggle_workspace') {
          final workspaces = ref.read(userWorkspacesProvider).valueOrNull ?? [];
          final active = ref.read(activeWorkspaceProvider);
          if (active?.isFamily == true) {
            final personal = workspaces.where((w) => w.isPersonal).firstOrNull;
            if (personal != null) {
              ref.read(selectedWorkspaceIdProvider.notifier).state = personal.id;
            }
          } else {
            final family = workspaces.where((w) => w.isFamily).firstOrNull;
            if (family != null) {
              ref.read(selectedWorkspaceIdProvider.notifier).state = family.id;
            }
          }
        } else if (value == 'manage_family') {
          final active = ref.read(activeWorkspaceProvider);
          if (active != null) {
            ManageFamilyMembersDialog.show(context, active);
          }
        } else if (value == 'sign_out') {
          await ref.read(authControllerProvider.notifier).signOut();
        }
      },
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
