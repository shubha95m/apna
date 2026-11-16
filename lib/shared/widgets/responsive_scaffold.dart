import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

class NavDestinationItem {
  final String label;
  final IconData icon;
  final String route;

  const NavDestinationItem({
    required this.label,
    required this.icon,
    required this.route,
  });
}

class ApnaResponsiveScaffold extends StatelessWidget {
  final Widget body;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final String workspaceName;
  final VoidCallback onWorkspaceToggle;

  const ApnaResponsiveScaffold({
    super.key,
    required this.body,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.workspaceName,
    required this.onWorkspaceToggle,
  });

  static const List<NavDestinationItem> destinations = [
    NavDestinationItem(label: 'Home', icon: Icons.home_rounded, route: '/'),
    NavDestinationItem(label: 'Documents', icon: Icons.folder_rounded, route: '/documents'),
    NavDestinationItem(label: 'Tasks', icon: Icons.check_circle_outline_rounded, route: '/tasks'),
    NavDestinationItem(label: 'Notes', icon: Icons.note_alt_outlined, route: '/notes'),
    NavDestinationItem(label: 'Bills & Payments', icon: Icons.receipt_long_rounded, route: '/bills'),
    NavDestinationItem(label: 'Warranty', icon: Icons.verified_user_outlined, route: '/warranty'),
    NavDestinationItem(label: 'Expenses', icon: Icons.account_balance_wallet_outlined, route: '/expenses'),
    NavDestinationItem(label: 'Calendar', icon: Icons.calendar_today_rounded, route: '/calendar'),
    NavDestinationItem(label: 'Health', icon: Icons.favorite_border_rounded, route: '/health'),
    NavDestinationItem(label: 'Property & Assets', icon: Icons.apartment_rounded, route: '/assets'),
    NavDestinationItem(label: 'Grocery', icon: Icons.shopping_cart_outlined, route: '/grocery'),
    NavDestinationItem(label: 'Contacts', icon: Icons.contacts_outlined, route: '/contacts'),
    NavDestinationItem(label: 'Memories', icon: Icons.photo_library_outlined, route: '/memories'),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 640 && screenWidth < 1024;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            _buildDesktopSidebar(context),
            const VerticalDivider(width: 1, thickness: 1, color: ApnaColors.border),
            Expanded(child: body),
          ],
        ),
      );
    }

    if (isTablet) {
      return Scaffold(
        body: Row(
          children: [
            _buildTabletRail(),
            const VerticalDivider(width: 1, thickness: 1, color: ApnaColors.border),
            Expanded(child: body),
          ],
        ),
      );
    }

    // Mobile layout
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex.clamp(0, 4),
        onDestinationSelected: onDestinationSelected,
        backgroundColor: ApnaColors.surface,
        indicatorColor: ApnaColors.surfaceSubtle,
        destinations: destinations.take(5).map((d) {
          return NavigationDestination(
            icon: Icon(d.icon),
            label: d.label,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDesktopSidebar(BuildContext context) {
    return Container(
      width: 260,
      color: ApnaColors.surface,
      child: Column(
        children: [
          // Workspace switcher header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: ApnaColors.border)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ApnaColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: onWorkspaceToggle,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Apna Workspace', style: ApnaTypography.bodySmall),
                              Text(workspaceName, style: ApnaTypography.titleMedium),
                            ],
                          ),
                          const Spacer(),
                          const Icon(Icons.unfold_more_rounded, size: 20, color: ApnaColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Nav items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              itemCount: destinations.length,
              itemBuilder: (context, index) {
                final item = destinations[index];
                final isSelected = selectedIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    dense: true,
                    selected: isSelected,
                    selectedTileColor: ApnaColors.surfaceSubtle,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    leading: Icon(
                      item.icon,
                      color: isSelected ? ApnaColors.accentDark : ApnaColors.textSecondary,
                      size: 20,
                    ),
                    title: Text(
                      item.label,
                      style: ApnaTypography.bodyMedium.copyWith(
                        color: isSelected ? ApnaColors.textPrimary : ApnaColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    onTap: () => onDestinationSelected(index),
                  ),
                );
              },
            ),
          ),
          // Status footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: ApnaColors.border)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: ApnaColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                const Text('Syncing across devices', style: ApnaTypography.bodySmall),
                const Spacer(),
                const Icon(Icons.sync_rounded, size: 16, color: ApnaColors.textSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletRail() {
    return NavigationRail(
      selectedIndex: selectedIndex.clamp(0, destinations.length - 1),
      onDestinationSelected: onDestinationSelected,
      labelType: NavigationRailLabelType.selected,
      backgroundColor: ApnaColors.surface,
      destinations: destinations.map((d) {
        return NavigationRailDestination(
          icon: Icon(d.icon),
          label: Text(d.label),
        );
      }).toList(),
    );
  }
}
