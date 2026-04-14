import 'package:flutter/material.dart';
import 'dashboard_profile_menu.dart';

class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int selectedIndex;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;

  const DashboardAppBar({
    super.key,
    required this.selectedIndex,
    required this.onRefresh,
    required this.onLogout,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  String get _appBarTitle => switch (selectedIndex) {
    1 => 'Transactions',
    2 => 'Wallets',
    3 => 'Planning',
    4 => 'Assistant',
    _ => 'RootEXP',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      title: selectedIndex == 0
          ? _buildBrandedTitle(theme)
          : Text(_appBarTitle, style: theme.textTheme.titleLarge),
      automaticallyImplyLeading: false,
      actions: [
        DashboardProfileMenu(
          onRefresh: onRefresh,
          onLogout: onLogout,
        ),
      ],
    );
  }

  Widget _buildBrandedTitle(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Root',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w500,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(width: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: theme.primaryColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'EXP',
            style: TextStyle(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}
