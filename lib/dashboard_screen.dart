import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'account_list_screen.dart';
import 'theme_picker_screen.dart';
import 'add_transaction_screen.dart';
import 'add_wallet_screen.dart';
import 'wallet_details_screen.dart';
import 'models/transaction_model.dart';
import 'models/wallet.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart';

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
      _CalendarView(onRefresh: _refresh),
      _WalletsView(onRefresh: _refresh),
      const _ComingSoonView(title: 'AI Assistant', icon: Icons.psychology),
      _StatisticsView(onRefresh: _refresh),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_selectedIndex == 1 
            ? 'Transactions' 
            : _selectedIndex == 2 
                ? 'Calendar' 
                : _selectedIndex == 3
                    ? 'Wallets'
                    : _selectedIndex == 5
                        ? 'Statistics' 
                        : 'AJ Wallet'),
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
      floatingActionButton: (_selectedIndex == 0 || _selectedIndex == 1 || _selectedIndex == 2 || _selectedIndex == 3)
          ? FloatingActionButton(
              onPressed: () async {
                if (account != null) {
                  final Widget targetScreen = _selectedIndex == 3 
                      ? AddWalletScreen(accountKey: account.key as int)
                      : AddTransactionScreen(accountKey: account.key as int);
                  
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => targetScreen),
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
                icon: Icon(Icons.account_balance_wallet_outlined, color: theme.textTheme.bodyMedium?.color),
                selectedIcon: Icon(Icons.account_balance_wallet, color: theme.primaryColor),
                label: 'Wallets',
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
    final wallets = account != null ? DatabaseService.getWallets(account.key as int) : <Wallet>[];
    
    double totalBalance = wallets
        .where((w) => !w.isExcluded)
        .fold(0, (sum, wallet) => sum + wallet.balance);

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
                  '₱${totalBalance.toStringAsFixed(2)}',
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

class _CalendarView extends StatefulWidget {
  final VoidCallback onRefresh;
  const _CalendarView({required this.onRefresh});

  @override
  State<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<_CalendarView> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  TransactionType? _filter;

  @override
  Widget build(BuildContext context) {
    final account = DatabaseService.getLatestAccount();
    final transactions = account != null ? DatabaseService.getTransactions(account.key as int) : <Transaction>[];
    final theme = Theme.of(context);

    List<Transaction> filteredTransactions = transactions.where((tx) {
      bool dateMatch = isSameDay(tx.date, _selectedDay ?? _focusedDay);
      bool typeMatch = _filter == null || tx.type == _filter;
      return dateMatch && typeMatch;
    }).toList();

    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          calendarStyle: CalendarStyle(
            selectedDecoration: BoxDecoration(color: theme.primaryColor, shape: BoxShape.circle),
            todayDecoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.3), shape: BoxShape.circle),
          ),
          headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _filterChip('All', null, Colors.grey),
              const SizedBox(width: 8),
              _filterChip('Income', TransactionType.income, Colors.green),
              const SizedBox(width: 8),
              _filterChip('Expense', TransactionType.expense, Colors.red),
            ],
          ),
        ),
        Expanded(
          child: filteredTransactions.isEmpty
              ? const Center(child: Text('No transactions for this day', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: filteredTransactions.length,
                  itemBuilder: (context, index) {
                    return _TransactionTile(tx: filteredTransactions[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, TransactionType? type, Color color) {
    bool isSelected = _filter == type;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
      selected: isSelected,
      onSelected: (val) => setState(() => _filter = val ? type : null),
      selectedColor: color,
    );
  }
}

class _WalletsView extends StatelessWidget {
  final VoidCallback onRefresh;
  const _WalletsView({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final account = DatabaseService.getLatestAccount();
    final theme = Theme.of(context);
    final wallets = account != null ? DatabaseService.getWallets(account.key as int) : <Wallet>[];

    return wallets.isEmpty
        ? const Center(child: Text('No wallets added yet', style: TextStyle(color: Colors.grey)))
        : ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: wallets.length,
            itemBuilder: (context, index) {
              final wallet = wallets[index];
              return InkWell(
                onTap: () async {
                  await Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => WalletDetailsScreen(wallet: wallet))
                  );
                  onRefresh();
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: wallet.isExcluded ? Colors.red.withOpacity(0.3) : Colors.grey[200]!,
                      width: wallet.isExcluded ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: theme.primaryColor.withOpacity(0.1),
                        child: Icon(_getWalletIcon(wallet.type), color: theme.primaryColor),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              wallet.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                decoration: wallet.isExcluded ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            Text(
                              wallet.isExcluded ? 'Excluded' : wallet.type,
                              style: TextStyle(color: wallet.isExcluded ? Colors.red : Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₱${wallet.balance.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                          color: wallet.isExcluded ? Colors.grey : null,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  IconData _getWalletIcon(String type) {
    switch (type) {
      case 'ATM': return Icons.credit_card;
      case 'Bank': return Icons.account_balance;
      case 'E-Wallet': return Icons.phone_android;
      case 'Savings': return Icons.savings;
      default: return Icons.account_balance_wallet;
    }
  }
}

class _StatisticsView extends StatelessWidget {
  final VoidCallback onRefresh;
  const _StatisticsView({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final account = DatabaseService.getLatestAccount();
    final transactions = account != null ? DatabaseService.getTransactions(account.key as int) : <Transaction>[];
    final theme = Theme.of(context);

    double totalIncome = transactions.where((tx) => tx.type == TransactionType.income).fold(0, (sum, tx) => sum + tx.amount);
    double totalExpense = transactions.where((tx) => tx.type == TransactionType.expense).fold(0, (sum, tx) => sum + tx.amount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 50,
                sections: [
                  PieChartSectionData(value: totalIncome, color: Colors.green, title: 'Income', radius: 60, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  PieChartSectionData(value: totalExpense, color: Colors.red, title: 'Expense', radius: 60, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          _statCard('Total Income', totalIncome, Colors.green),
          const SizedBox(height: 16),
          _statCard('Total Expense', totalExpense, Colors.red),
          const SizedBox(height: 16),
          _statCard('Net Balance', totalIncome - totalExpense, Colors.blue),
        ],
      ),
    );
  }

  Widget _statCard(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          Text('₱${amount.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
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
