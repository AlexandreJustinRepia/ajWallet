import 'package:flutter/material.dart';
import '../../../services/session_service.dart';
import '../../../services/database_service.dart';
import '../../../models/account.dart';
import '../../../theme_picker_screen.dart';
import '../../../security_settings_screen.dart';
import '../../../screens/about_screen.dart';

class DashboardProfileMenu extends StatelessWidget {
  final VoidCallback onRefresh;
  final VoidCallback onLogout;

  const DashboardProfileMenu({
    super.key,
    required this.onRefresh,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          _buildPopupItem(Icons.account_circle_outlined, 'Account', 'account'),
          _buildPopupItem(Icons.palette_outlined, 'Theme Settings', 'theme'),
          _buildPopupItem(Icons.security_rounded, 'Security', 'security'),
          _buildPopupItem(Icons.info_outline_rounded, 'About', 'about'),
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
        break;
      case 'theme':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ThemePickerScreen()),
        );
        break;
      case 'security':
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SecuritySettingsScreen(),
          ),
        );
        if (result == true) onRefresh();
        break;
      case 'about':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AboutScreen()),
        );
        break;
      case 'logout':
        _showLogoutDialog(context);
        break;
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) =>
                (value == null || value.trim().isEmpty) ? 'Enter a name' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.5,
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (editFormKey.currentState!.validate()) {
                account.name = controller.text.trim();
                await DatabaseService.updateAccount(account);
                if (context.mounted) {
                  Navigator.pop(context);
                  onRefresh();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

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
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.5,
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onLogout();
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
              color: theme.primaryColor.withValues(alpha: 0.1),
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
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.5,
                    ),
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
}
