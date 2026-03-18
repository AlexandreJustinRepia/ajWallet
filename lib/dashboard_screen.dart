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
import 'widgets/animated_count_text.dart';
import 'widgets/slide_in_list_item.dart';
import 'widgets/insight_card.dart';
import 'widgets/quick_add_input.dart';
import 'services/financial_insights_service.dart';

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
      const _ComingSoonView(
        title: 'AI Assistant',
        icon: Icons.psychology_outlined,
      ),
      _StatisticsView(onRefresh: _refresh),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _selectedIndex == 1
              ? 'Transactions'
              : _selectedIndex == 2
              ? 'Calendar'
              : _selectedIndex == 3
              ? 'Wallets'
              : _selectedIndex == 5
              ? 'Analytics'
              : 'AJ Wallet',
          style: theme.textTheme.titleLarge,
        ),
        automaticallyImplyLeading: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: PopupMenuButton<String>(
              offset: const Offset(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
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
              onSelected: (value) {
                if (value == 'theme') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ThemePickerScreen(),
                    ),
                  );
                } else if (value == 'logout') {
                  _showLogoutDialog(context);
                }
              },
              itemBuilder: (BuildContext context) => [
                _buildPopupItem(
                  Icons.palette_outlined,
                  'Theme Settings',
                  'theme',
                ),
                _buildPopupItem(Icons.logout_rounded, 'Logout', 'logout'),
              ],
            ),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      floatingActionButton: (_selectedIndex >= 0 && _selectedIndex <= 3)
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
              child: const Icon(Icons.add_rounded, size: 28),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: theme.dividerColor, width: 0.5),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) =>
              setState(() => _selectedIndex = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.grid_view_rounded),
              label: 'Hub',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_rounded),
              label: 'Transactions',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_today_rounded),
              label: 'Plan',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_rounded),
              label: 'Wallet',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_rounded),
              label: 'AI',
            ),
            NavigationDestination(
              icon: Icon(Icons.analytics_rounded),
              label: 'Stats',
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(
    IconData icon,
    String title,
    String value,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
}

class _HomeView extends StatefulWidget {
  final VoidCallback onRefresh;
  const _HomeView({required this.onRefresh});

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  double _prevBalance = 0;
  bool _showGlow = false;
  bool _isNetWorthMode = false;

  @override
  Widget build(BuildContext context) {
    final account = DatabaseService.getLatestAccount();
    final transactions = account != null
        ? DatabaseService.getTransactions(account.key as int)
        : <Transaction>[];
    final wallets = account != null
        ? DatabaseService.getWallets(account.key as int)
        : <Wallet>[];

    double totalBalance = wallets
        .where((w) => _isNetWorthMode || !w.isExcluded)
        .fold(0, (sum, wallet) => sum + wallet.balance);

    if (totalBalance != _prevBalance) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _showGlow = true;
          _prevBalance = totalBalance;
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) setState(() => _showGlow = false);
        });
      });
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, account?.name ?? "User"),
          const SizedBox(height: 32),
          _buildBalanceCard(context, totalBalance, _isNetWorthMode, (val) {
            setState(() => _isNetWorthMode = val);
          }),
          if (account != null) ...[
            const SizedBox(height: 16),
            QuickAddInput(
              accountKey: account.key as int,
              onSaved: widget.onRefresh,
            ),
          ],
          const SizedBox(height: 32),
          _buildRecentActivityHeader(context),
          const SizedBox(height: 16),
          if (transactions.isEmpty)
            _buildEmptyState(context)
          else
            ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length > 5 ? 5 : transactions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final tx = transactions[transactions.length - 1 - index];
                return SlideInListItem(
                  index: index,
                  child: _TransactionCard(tx: tx),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String name) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good Day,',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
            letterSpacing: 0.5,
          ),
        ),
        Text(
          name,
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(BuildContext context, double totalBalance,
      bool isNetWorth, Function(bool) onToggle) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedScale(
      scale: _showGlow ? 1.02 : 1.0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? Colors.white : Colors.black,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.white : Colors.black)
                  .withOpacity(_showGlow ? 0.3 : 0.1),
              blurRadius: _showGlow ? 40 : 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isNetWorth ? 'TOTAL NET WORTH' : 'TOTAL LIQUIDITY',
                      style: TextStyle(
                        color: (isDark ? Colors.black : Colors.white)
                            .withOpacity(0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isNetWorth
                          ? 'INCLUDES EXCLUDED WALLETS'
                          : 'SPENDABLE BALANCE ONLY',
                      style: TextStyle(
                        color: (isDark ? Colors.black : Colors.white)
                            .withOpacity(0.3),
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => onToggle(!isNetWorth),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.black : Colors.white)
                          .withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: (isDark ? Colors.black : Colors.white)
                            .withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      isNetWorth
                          ? Icons.account_balance_rounded
                          : Icons.payments_rounded,
                      color: (isDark ? Colors.black : Colors.white)
                          .withOpacity(0.5),
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            AnimatedCountText(
              value: totalBalance,
              prefix: '₱',
              style: theme.textTheme.displayMedium?.copyWith(
                color: isDark ? Colors.black : Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (isDark ? Colors.black : Colors.white).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'LIVE UPDATES',
                style: TextStyle(
                  color:
                      (isDark ? Colors.black : Colors.white).withOpacity(0.4),
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'RECENT ACTIVITY',
          style: theme.textTheme.labelLarge?.copyWith(
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
            fontSize: 10,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.cardColor,
            shape: BoxShape.circle,
            border: Border.all(color: theme.dividerColor, width: 0.5),
          ),
          child: Icon(
            Icons.horizontal_rule_rounded,
            size: 14,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.blur_on_rounded,
              size: 48,
              color: theme.dividerColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No activities recorded yet.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Transaction tx;
  const _TransactionCard({required this.tx});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = tx.type == TransactionType.income;
    final displayColor = isIncome
        ? theme.colorScheme.tertiary
        : theme.colorScheme.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: displayColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: displayColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.title, style: theme.textTheme.titleSmall),
                Text(tx.category, style: theme.textTheme.labelLarge),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'} ₱${tx.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: displayColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (tx.charge != null && tx.charge! > 0)
                Text(
                  'Fee: ₱${tx.charge!.toStringAsFixed(2)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.error.withOpacity(0.5),
                    fontSize: 10,
                  ),
                ),
              Text(
                DateFormat('MMM dd').format(tx.date),
                style: theme.textTheme.labelLarge,
              ),
            ],
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
    final transactions = account != null
        ? DatabaseService.getTransactions(account.key as int)
        : <Transaction>[];

    return transactions.isEmpty
        ? Center(child: Text('Vault empty', style: theme.textTheme.bodyMedium))
        : ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            itemCount: transactions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final tx = transactions[transactions.length - 1 - index];
              return SlideInListItem(
                index: index,
                child: _TransactionCard(tx: tx),
              );
            },
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
    final transactions = account != null
        ? DatabaseService.getTransactions(account.key as int)
        : <Transaction>[];
    final theme = Theme.of(context);

    List<Transaction> filteredTransactions = transactions.where((tx) {
      bool dateMatch = isSameDay(tx.date, _selectedDay ?? _focusedDay);
      bool typeMatch = _filter == null || tx.type == _filter;
      return dateMatch && typeMatch;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TableCalendar(
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
              selectedDecoration: BoxDecoration(
                color: theme.primaryColor,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
              outsideDaysVisible: false,
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: theme.textTheme.titleMedium!,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _FilterTab(
              label: 'All',
              isSelected: _filter == null,
              onTap: () => setState(() => _filter = null),
            ),
            const SizedBox(width: 8),
            _FilterTab(
              label: 'Income',
              isSelected: _filter == TransactionType.income,
              onTap: () => setState(() => _filter = TransactionType.income),
            ),
            const SizedBox(width: 8),
            _FilterTab(
              label: 'Expense',
              isSelected: _filter == TransactionType.expense,
              onTap: () => setState(() => _filter = TransactionType.expense),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: filteredTransactions.isEmpty
              ? Center(
                  child: Text('No records', style: theme.textTheme.bodyMedium),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: filteredTransactions.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _TransactionCard(tx: filteredTransactions[index]),
                ),
        ),
      ],
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _FilterTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor : theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? theme.primaryColor : theme.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? theme.scaffoldBackgroundColor
                : theme.textTheme.bodyMedium?.color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
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
    final wallets = account != null
        ? DatabaseService.getWallets(account.key as int)
        : <Wallet>[];

    return wallets.isEmpty
        ? Center(
            child: Text('Vault is empty', style: theme.textTheme.bodyMedium),
          )
        : ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: wallets.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final wallet = wallets[index];
              return InkWell(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WalletDetailsScreen(wallet: wallet),
                    ),
                  );
                  onRefresh();
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: wallet.isExcluded
                          ? theme.colorScheme.error.withOpacity(0.5)
                          : theme.dividerColor,
                      width: wallet.isExcluded ? 2 : 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: wallet.isExcluded
                              ? theme.colorScheme.error.withOpacity(0.1)
                              : theme.primaryColor.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getWalletIcon(wallet.type),
                          color: wallet.isExcluded
                              ? theme.colorScheme.error
                              : theme.primaryColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              wallet.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                decoration: wallet.isExcluded
                                    ? TextDecoration.lineThrough
                                    : null,
                                decorationColor: theme.colorScheme.error,
                                color: wallet.isExcluded
                                    ? theme.colorScheme.error.withOpacity(0.7)
                                    : null,
                              ),
                            ),
                            Text(
                              wallet.isExcluded
                                  ? 'Excluded from Liquidity'
                                  : wallet.type,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: wallet.isExcluded
                                    ? theme.colorScheme.error.withOpacity(0.5)
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₱${wallet.balance.toStringAsFixed(2)}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: wallet.isExcluded
                              ? theme.colorScheme.error.withOpacity(0.5)
                              : null,
                          decoration: wallet.isExcluded
                              ? TextDecoration.lineThrough
                              : null,
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
      case 'ATM':
        return Icons.credit_card_rounded;
      case 'Bank':
        return Icons.account_balance_rounded;
      case 'E-Wallet':
        return Icons.account_balance_wallet_rounded;
      case 'Savings':
        return Icons.savings_rounded;
      default:
        return Icons.wallet_rounded;
    }
  }
}

class _StatisticsView extends StatelessWidget {
  final VoidCallback onRefresh;
  const _StatisticsView({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final account = DatabaseService.getLatestAccount();
    final transactions = account != null
        ? DatabaseService.getTransactions(account.key as int)
        : <Transaction>[];
    final theme = Theme.of(context);

    double totalIncome = transactions
        .where((tx) => tx.type == TransactionType.income)
        .fold(0, (sum, tx) => sum + tx.amount);
    double totalExpense = transactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0, (sum, tx) => sum + tx.amount);

    final wallets = account != null
        ? DatabaseService.getWallets(account.key as int)
        : <Wallet>[];
    double totalBalance = wallets
        .where((w) => !w.isExcluded)
        .fold(0, (sum, wallet) => sum + wallet.balance);

    final insights = FinancialInsightsService.generateInsights(transactions, totalBalance);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChartSection(context, totalIncome, totalExpense),
          const SizedBox(height: 32),
          _buildSummarySection(context, totalIncome, totalExpense),
          if (insights.isNotEmpty) ...[
            const SizedBox(height: 48),
            _buildInsightsSection(context, insights),
          ],
        ],
      ),
    );
  }

  Widget _buildChartSection(BuildContext context, double totalIncome, double totalExpense) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.dividerColor, width: 0.5),
      ),
      child: SizedBox(
        height: 200,
        child: PieChart(
          PieChartData(
            sectionsSpace: 6,
            centerSpaceRadius: 60,
            sections: [
              PieChartSectionData(
                value: totalIncome == 0 && totalExpense == 0 ? 1 : totalIncome,
                color: theme.colorScheme.tertiary,
                title: '',
                radius: 12,
              ),
              PieChartSectionData(
                value: totalExpense,
                color: theme.colorScheme.error,
                title: '',
                radius: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context, double totalIncome, double totalExpense) {
    final theme = Theme.of(context);
    return Column(
      children: [
        _StatRow(
          label: 'Total Inflow',
          amount: totalIncome,
          color: theme.colorScheme.tertiary,
        ),
        const SizedBox(height: 12),
        _StatRow(
          label: 'Total Outflow',
          amount: totalExpense,
          color: theme.colorScheme.error,
        ),
        const SizedBox(height: 12),
        _StatRow(
          label: 'Net Position',
          amount: totalIncome - totalExpense,
          color: theme.primaryColor,
        ),
      ],
    );
  }

  Widget _buildInsightsSection(BuildContext context, List<Insight> insights) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'INTELLIGENT INSIGHTS',
          style: theme.textTheme.labelLarge?.copyWith(
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
            fontSize: 10,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
          ),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: insights.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return SlideInListItem(
              index: index,
              child: InsightCard(insight: insights[index]),
            );
          },
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  const _StatRow({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.titleMedium),
          Text(
            '₱${amount.toStringAsFixed(2)}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64,
              color: theme.primaryColor.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 24),
          Text(title, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Coming Soon!', style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
