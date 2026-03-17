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
      const _ComingSoonView(title: 'Transactions', icon: Icons.receipt_long),
      const _ComingSoonView(title: 'Calendar', icon: Icons.calendar_month),
      const _ComingSoonView(title: 'AI Assistant', icon: Icons.psychology),
      const _ComingSoonView(title: 'Statistics', icon: Icons.bar_chart),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('AJ Wallet'),
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
      floatingActionButton: _selectedIndex == 0
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
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: theme.cardColor,
        selectedItemColor: theme.primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Transactions'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Calendar'),
          BottomNavigationBarItem(icon: Icon(Icons.psychology), label: 'AI'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
        ],
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
                  '\$${account?.budget.toStringAsFixed(2) ?? "0.00"}',
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
          Text(
            'Recent Transactions',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: transactions.isEmpty
                ? const Center(child: Text('No transactions yet', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: transactions.length > 5 ? 5 : transactions.length,
                    itemBuilder: (context, index) {
                      final tx = transactions[transactions.length - 1 - index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: tx.typeColor.withOpacity(0.1),
                          child: Icon(tx.type == TransactionType.income ? Icons.arrow_upward : Icons.arrow_downward, color: tx.typeColor),
                        ),
                        title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(DateFormat('MMM dd, yyyy').format(tx.date)),
                        trailing: Text(
                          '${tx.type == TransactionType.income ? '+' : '-'} \$${tx.amount.toStringAsFixed(2)}',
                          style: TextStyle(color: tx.typeColor, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      );
                    },
                  ),
          ),
        ],
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
