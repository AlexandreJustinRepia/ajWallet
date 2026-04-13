import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'models/account.dart';
import 'login_screen.dart';
import 'create_account_screen.dart';
import 'services/session_service.dart';
import 'dashboard_screen.dart';

class AccountListScreen extends StatefulWidget {
  const AccountListScreen({super.key});

  @override
  State<AccountListScreen> createState() => _AccountListScreenState();
}

class _AccountListScreenState extends State<AccountListScreen> {
  List<Account> _accounts = [];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  void _loadAccounts() {
    setState(() {
      _accounts = DatabaseService.getAccounts();
    });
  }

  void _confirmDelete(Account account) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final hintColor = textColor.withValues(alpha: 0.5);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text('Delete Account', style: TextStyle(color: textColor)),
        content: Text(
          'Are you sure you want to delete "${account.name}"? This action cannot be undone and all data will be lost.',
          style: TextStyle(color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: hintColor)),
          ),
          TextButton(
            onPressed: () async {
              await DatabaseService.deleteAccount(account);
              if (mounted) {
                Navigator.pop(context);
                _loadAccounts();
                if (_accounts.isEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateAccountScreen(),
                        ),
                      );
                    }
                  });
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final hintColor = textColor.withValues(alpha: 0.5);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 80, 32, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'RootEXP',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: theme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Select Your\nAccount',
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                            letterSpacing: -1.5,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _showGalleryTutorial(),
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.help_outline_rounded,
                              color: theme.primaryColor,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index < _accounts.length) {
                    final account = _accounts[index];
                    return _buildVaultCard(context, account);
                  } else {
                    return _buildAddAccountCard(context);
                  }
                }, childCount: _accounts.length + 1),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildAddAccountCard(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreateAccountScreen()),
        );
        _loadAccounts();
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.primaryColor.withValues(alpha: 0.2),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_rounded,
                color: theme.primaryColor.withValues(alpha: 0.6),
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'NEW ACCOUNT',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                color: theme.primaryColor.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onAccountSelected(BuildContext context, Account account) {
    if (account.pin == null || account.pin!.isEmpty) {
      SessionService.setActiveAccount(account);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const DashboardScreen(),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(account: account),
        ),
      );
    }
  }

  Widget _buildVaultCard(BuildContext context, Account account) {
    return _VaultCard(
      account: account,
      onTap: () => _onAccountSelected(context, account),
      onLongPress: () => _showAccountOptions(account),
    );
  }

  void _showGalleryTutorial() {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.touch_app_rounded, color: primaryColor),
              ),
              const SizedBox(height: 24),
              Text(
                'Manage Your Vaults',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'To Rename or Delete a vault, simply hold your finger on the card for a second.',
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color?.withValues(
                    alpha: 0.6,
                  ),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Got it!',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAccountOptions(Account account) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename Vault'),
              onTap: () {
                Navigator.pop(context);
                _showEditAccountDialog(account);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                'Delete Vault',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(account);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showEditAccountDialog(Account account) {
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
                if (mounted) {
                  Navigator.pop(context);
                  _loadAccounts();
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
}

class _VaultCard extends StatefulWidget {
  final Account account;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _VaultCard({
    required this.account,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<_VaultCard> createState() => _VaultCardState();
}

class _VaultCardState extends State<_VaultCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onLongPress: widget.onLongPress,
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(24),
            splashColor: primaryColor.withValues(alpha: 0.1),
            highlightColor: primaryColor.withValues(alpha: 0.05),
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _isPressed ? primaryColor : theme.dividerColor,
                  width: _isPressed ? 2.0 : 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isPressed
                        ? primaryColor.withValues(alpha: 0.15)
                        : theme.shadowColor.withValues(alpha: 0.03),
                    blurRadius: _isPressed ? 20 : 10,
                    offset: _isPressed ? const Offset(0, 8) : const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Decorative background element
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.03),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            (widget.account.pin != null &&
                                    widget.account.pin!.isNotEmpty)
                                ? Icons.lock_rounded
                                : Icons.account_balance_wallet_outlined,
                            color: primaryColor,
                            size: 20,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          widget.account.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'LEVEL ${widget.account.level}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
