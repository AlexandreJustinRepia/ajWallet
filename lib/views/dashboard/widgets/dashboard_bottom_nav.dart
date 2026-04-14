import 'package:flutter/material.dart';
import '../dashboard_keys.dart';

class DashboardBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onSelected;
  final DashboardKeys keys;

  const DashboardBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.keys,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelected,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            key: keys.activityTabKey,
            icon: const Icon(Icons.receipt_long_rounded),
            label: 'Activity',
          ),
          NavigationDestination(
            key: keys.walletsTabKey,
            icon: const Icon(Icons.account_balance_wallet_rounded),
            label: 'Wallets',
          ),
          NavigationDestination(
            key: keys.planTabKey,
            icon: const Icon(Icons.track_changes_rounded),
            label: 'Plan',
          ),
          const NavigationDestination(
            icon: Icon(Icons.auto_awesome_rounded),
            label: 'Assistant',
          ),
        ],
      ),
    );
  }
}
