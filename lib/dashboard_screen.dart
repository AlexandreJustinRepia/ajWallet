import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'account_list_screen.dart';
import 'theme_picker_screen.dart';
import 'add_transaction_screen.dart';
import 'models/transaction_model.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final account = DatabaseService.getLatestAccount();

    final List<Widget> _pages = [
      _HomeView(onRefresh: _refresh),
      _TransactionsView(onRefresh: _refresh),
      const _ComingSoonView(title: 'Calendar', icon: Icons.calendar_month),
      const _ComingSoonView(title: 'AI Assistant', icon: Icons.psychology),
      const _ComingSoonView(title: 'Statistics', icon: Icons.bar_chart),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_selectedIndex == 1 ? 'Transactions' : 'AJ Wallet'),
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton<String>(
            icon: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: theme.dividerColor),
              ),
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(Icons.person, size: 28),
              ),
            ),
            onSelected: (value) {
              if (value == 'theme') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ThemePickerScreen()));
              } else if (value == 'logout') {
                _showLogoutDialog(context);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'theme',
                child: Row(
                  children: [
                    Icon(Icons.palette_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Theme Settings'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 12),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _pages[_selectedIndex],
      floatingActionButton: (_selectedIndex == 0 || _selectedIndex == 1)
          ? FloatingActionButton(
              onPressed: () async {
                if (account != null) {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddTransactionScreen(accountKey: account.key as int),
                    ),
                  );
                  if (result == true) _refresh();
                }
              },
              backgroundColor: theme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Icon(Icons.add, color: theme.scaffoldBackgroundColor),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: theme.dividerColor.withOpacity(0.1), width: 1)),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            indicatorColor: theme.primaryColor.withOpacity(0.1),
            labelTextStyle: MaterialStateProperty.all(
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) => setState(() => _selectedIndex = index),
            backgroundColor: theme.cardColor,
            elevation: 0,
            height: 65,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.home_outlined, color: theme.textTheme.bodyMedium?.color),
                selectedIcon: Icon(Icons.home, color: theme.primaryColor),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined, color: theme.textTheme.bodyMedium?.color),
                selectedIcon: Icon(Icons.receipt_long, color: theme.primaryColor),
                label: 'Docs',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined, color: theme.textTheme.bodyMedium?.color),
                selectedIcon: Icon(Icons.calendar_month, color: theme.primaryColor),
                label: 'Calendar',
              ),
              NavigationDestination(
                icon: Icon(Icons.psychology_outlined, color: theme.textTheme.bodyMedium?.color),
                selectedIcon: Icon(Icons.psychology, color: theme.primaryColor),
                label: 'AI',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined, color: theme.textTheme.bodyMedium?.color),
                selectedIcon: Icon(Icons.bar_chart, color: theme.primaryColor),
                label: 'Stats',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const AccountListScreen()),
                (route) => false,
              );
            },
            child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _HomeView extends StatelessWidget {
  final VoidCallback onRefresh;
  const _HomeView({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final account = DatabaseService.getLatestAccount();
    final theme = Theme.of(context);
    final transactions = account != null ? DatabaseService.getTransactions(account.key as int) : <Transaction>[];

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, ${account?.name ?? "User"}',
            style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Balance',
                  style: TextStyle(color: theme.scaffoldBackgroundColor.withOpacity(0.7), fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  '₱${account?.budget.toStringAsFixed(2) ?? "0.00"}',
                  style: TextStyle(
                    color: theme.scaffoldBackgroundColor,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: theme.textTheme.titleLarge,
              ),
              if (transactions.isNotEmpty)
                TextButton(
                  onPressed: () {
                    // This could change the tab to Transactions tab
                  },
                  child: const Text('View All'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: transactions.isEmpty
                ? const Center(child: Text('No transactions yet', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: transactions.length > 5 ? 5 : transactions.length,
                    itemBuilder: (context, index) {
                      final tx = transactions[transactions.length - 1 - index];
                      return _TransactionTile(tx: tx);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TransactionsView extends StatelessWidget {
  final VoidCallback onRefresh;
  const _TransactionsView({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final account = DatabaseService.getLatestAccount();
    final theme = Theme.of(context);
    final transactions = account != null ? DatabaseService.getTransactions(account.key as int) : <Transaction>[];

    return Column(
      children: [
        if (transactions.isEmpty)
          const Expanded(
            child: Center(child: Text('No transactions yet', style: TextStyle(color: Colors.grey))),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final tx = transactions[transactions.length - 1 - index];
                return _TransactionTile(tx: tx);
              },
            ),
          ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction tx;
  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: tx.typeColor.withOpacity(0.1),
        child: Icon(
          tx.type == TransactionType.income 
              ? Icons.arrow_upward 
              : tx.type == TransactionType.expense 
                  ? Icons.arrow_downward 
                  : Icons.sync, 
          color: tx.typeColor,
          size: 20,
        ),
      ),
      title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('${tx.category} • ${DateFormat('MMM dd, yyyy').format(tx.date)}'),
      trailing: Text(
        '${tx.type == TransactionType.income ? '+' : tx.type == TransactionType.expense ? '-' : ''} ₱${tx.amount.toStringAsFixed(2)}',
        style: TextStyle(color: tx.typeColor, fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}

class _ComingSoonView extends StatelessWidget {
  final String title;
  final IconData icon;

  const _ComingSoonView({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: theme.primaryColor.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Feature Coming Soon',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
