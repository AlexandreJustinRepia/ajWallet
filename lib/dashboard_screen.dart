import 'package:flutter/material.dart';
import 'services/session_service.dart';
import 'services/database_service.dart';
import 'models/account.dart';
import 'account_list_screen.dart';
import 'theme_picker_screen.dart';
import 'add_transaction_screen.dart';
import 'wallet_form_screen.dart';
import 'security_settings_screen.dart';
import 'views/home_view.dart';
import 'views/activity_view.dart';
import 'views/wallets_view.dart';
import 'views/planning_view.dart';
import 'widgets/ai_assistant_view.dart';
import 'screens/about_screen.dart';
import 'services/update_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  void _refresh() => setState(() {});

  // ---------------------------------------------------------------------------
  // App Bar
  // ---------------------------------------------------------------------------

  String get _appBarTitle => switch (_selectedIndex) {
    1 => 'Activity',
    2 => 'Wallets',
    3 => 'Planning',
    4 => 'Assistant',
    _ => 'AJWallet',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accountKey = SessionService.activeAccount?.key as int?;

    final pages = [
      HomeView(onRefresh: _refresh),
      ActivityView(onRefresh: _refresh),
      WalletsView(onRefresh: _refresh),
      PlanningView(onRefresh: _refresh),
      const AIAssistantView(),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_appBarTitle, style: theme.textTheme.titleLarge),
        automaticallyImplyLeading: false,
        actions: [_buildProfileMenu(context, theme)],
      ),
      body: Column(
        children: [
          _buildUpdateBanner(theme),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _refresh();
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: pages[_selectedIndex],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onFabPressed(context, accountKey),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      bottomNavigationBar: _buildBottomNavBar(theme),
    );
  }

  // ---------------------------------------------------------------------------
  // FAB
  // ---------------------------------------------------------------------------

  Future<void> _onFabPressed(BuildContext context, int? accountKey) async {
    if (accountKey == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No active account found.')));
      return;
    }

    final targetScreen = _selectedIndex == 2
        ? WalletFormScreen(accountKey: accountKey)
        : AddTransactionScreen(accountKey: accountKey);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => targetScreen),
    );
    if (!mounted) return;
    if (result == true) _refresh();
  }

  // ---------------------------------------------------------------------------
  // Bottom navigation bar
  // ---------------------------------------------------------------------------

  Widget _buildBottomNavBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
      ),
      child: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Wallets',
          ),
          NavigationDestination(
            icon: Icon(Icons.track_changes_rounded),
            label: 'Plan',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_rounded),
            label: 'Assistant',
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Profile popup menu
  // ---------------------------------------------------------------------------

  Widget _buildProfileMenu(BuildContext context, ThemeData theme) {
    final account = SessionService.activeAccount;
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: PopupMenuButton<String>(
        offset: const Offset(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: theme.dividerColor, width: 1.5),
          ),
          child: CircleAvatar(
            radius: 14,
            backgroundColor: theme.cardColor,
            child: Icon(
              Icons.person_outline,
              size: 20,
              color: theme.primaryColor,
            ),
          ),
        ),
        onSelected: (value) => _onMenuSelected(context, value),
        itemBuilder: (context) => [
          _buildPopupHeader(context, account?.name ?? 'User'),
          const PopupMenuDivider(),
          _buildPopupItem(Icons.palette_outlined, 'Theme Settings', 'theme'),
          _buildPopupItem(Icons.account_circle_outlined, 'Account', 'account'),
          _buildPopupItem(Icons.security_rounded, 'Security', 'security'),
          _buildPopupItem(Icons.info_outline_rounded, 'About AJ Wallet', 'about'),
          const PopupMenuDivider(),
          _buildPopupItem(
            Icons.logout_rounded,
            'Logout',
            'logout',
            color: theme.colorScheme.error,
          ),
        ],
      ),
    );
  }

  void _onMenuSelected(BuildContext context, String value) async {
    final account = SessionService.activeAccount;
    switch (value) {
      case 'account':
        if (account != null) _showEditAccountDialog(context, account);
      case 'theme':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ThemePickerScreen()),
        );
      case 'security':
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SecuritySettingsScreen(),
          ),
        );
        if (result == true) _refresh();
      case 'about':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AboutScreen()),
        );
      case 'logout':
        _showLogoutDialog(context);
    }
  }

  void _showEditAccountDialog(BuildContext context, Account account) {
    final theme = Theme.of(context);
    final controller = TextEditingController(text: account.name);
    final editFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Edit Account Name'),
        content: Form(
          key: editFormKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              labelText: 'Account Name',
              hintText: 'e.g. My Savings',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter a name' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5))),
          ),
          ElevatedButton(
            onPressed: () async {
              if (editFormKey.currentState!.validate()) {
                account.name = controller.text.trim();
                await DatabaseService.updateAccount(account);
                if (mounted) {
                  Navigator.pop(context);
                  _refresh();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(
    IconData icon,
    String title,
    String value, {
    Color? color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupHeader(BuildContext context, String name) {
    final theme = Theme.of(context);
    return PopupMenuItem<String>(
      enabled: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.person_rounded,
              color: theme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Account',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Logout dialog
  // ---------------------------------------------------------------------------

  void _showLogoutDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Exit Vault'),
        content: const Text(
          'Are you sure you want to log out of your session?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const AccountListScreen(),
                ),
                (route) => false,
              );
            },
            child: Text(
              'Logout',
              style: TextStyle(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Update Banner
  // ---------------------------------------------------------------------------

  Widget _buildUpdateBanner(ThemeData theme) {
    return ValueListenableBuilder<UpdateInfo?>(
      valueListenable: UpdateService.updateNotifier,
      builder: (context, info, _) {
        if (info == null) return const SizedBox.shrink();

        final backgroundColor = theme.colorScheme.primary;
        final foregroundColor = theme.colorScheme.onPrimary;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            boxShadow: [
              BoxShadow(
                color: backgroundColor.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.system_update_rounded, color: foregroundColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Update Available (${info.latestVersion})',
                      style: TextStyle(
                        color: foregroundColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      info.releaseNotes,
                      style: TextStyle(
                        color: foregroundColor.withOpacity(0.8),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => UpdateService.launchDownload(),
                style: TextButton.styleFrom(
                  backgroundColor: foregroundColor.withOpacity(0.15),
                  foregroundColor: foregroundColor,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'UPDATE',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: foregroundColor.withOpacity(0.7),
                  size: 18,
                ),
                onPressed: () => UpdateService.updateNotifier.value = null,
              ),
            ],
          ),
        );
      },
    );
  }
}
