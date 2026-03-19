import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/database_service.dart';
import '../models/transaction_model.dart';
import '../models/wallet.dart';
import '../widgets/animated_count_text.dart';
import '../widgets/slide_in_list_item.dart';
import '../widgets/quick_add_input.dart';
import '../widgets/transaction_card.dart';
import '../services/financial_insights_service.dart';
import 'insight_card.dart';
import 'dashboard_helpers.dart';

class HomeView extends StatefulWidget {
  final VoidCallback onRefresh;
  const HomeView({super.key, required this.onRefresh});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
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

    final double totalBalance = wallets
        .where((w) => _isNetWorthMode || !w.isExcluded)
        .fold(0, (sum, wallet) => sum + wallet.balance);

    final insights = FinancialInsightsService.generateInsights(transactions, totalBalance);

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
          _buildHeader(context, account?.name ?? 'User'),
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
          if (insights.isNotEmpty) ...[
            _buildInsightsHeader(context),
            const SizedBox(height: 16),
            _buildInsightsList(context, insights),
            const SizedBox(height: 32),
          ],
          _buildRecentActivityHeader(context),
          const SizedBox(height: 16),
          if (transactions.isEmpty)
            _buildEmptyState(context)
          else
            _buildRecentTransactions(context, transactions),
        ],
      ),
    );
  }

  Widget _buildInsightsHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
        Icon(
          Icons.auto_awesome_rounded,
          size: 14,
          color: theme.colorScheme.tertiary,
        ),
      ],
    );
  }

  Widget _buildInsightsList(BuildContext context, List<Insight> insights) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: insights.length > 3 ? 3 : insights.length, // Show top 3
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          return SizedBox(
            width: 280,
            child: InsightCard(insight: insights[index]),
          );
        },
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

  Widget _buildBalanceCard(
    BuildContext context,
    double totalBalance,
    bool isNetWorth,
    ValueChanged<bool> onToggle,
  ) {
    final theme = Theme.of(context);
    final cardColor = theme.primaryColor;
    final contentColor = theme.colorScheme.onPrimary;

    return AnimatedScale(
      scale: _showGlow ? 1.02 : 1.0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: cardColor.withOpacity(_showGlow ? 0.3 : 0.1),
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
                      isNetWorth ? 'TOTAL NET WORTH' : 'TOTAL BALANCE',
                      style: TextStyle(
                        color: contentColor.withOpacity(0.5),
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
                        color: contentColor.withOpacity(0.3),
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
                      color: contentColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: contentColor.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      isNetWorth
                          ? Icons.account_balance_rounded
                          : Icons.payments_rounded,
                      color: contentColor.withOpacity(0.5),
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
                color: contentColor,
                fontSize: 42,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: contentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'LIVE UPDATES',
                style: TextStyle(
                  color: contentColor.withOpacity(0.4),
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
            Icon(Icons.blur_on_rounded, size: 48, color: theme.dividerColor),
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

  Widget _buildRecentTransactions(
    BuildContext context,
    List<Transaction> transactions,
  ) {
    final sortedTx = List<Transaction>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    final topTx = sortedTx.take(5).toList();

    final List<dynamic> items = [];
    DateTime? lastDate;
    for (final tx in topTx) {
      if (lastDate == null || !isSameDay(lastDate, tx.date)) {
        items.add(tx.date);
        lastDate = tx.date;
      }
      items.add(tx);
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item is DateTime) {
          return buildDateHeader(context, item);
        }
        final tx = item as Transaction;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SlideInListItem(
            index: index,
            child: TransactionCard(tx: tx, onRefresh: widget.onRefresh),
          ),
        );
      },
    );
  }
}
