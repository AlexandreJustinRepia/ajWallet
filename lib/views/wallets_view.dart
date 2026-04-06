import 'package:flutter/material.dart';
import '../services/session_service.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/database_service.dart';
import '../services/financial_insights_service.dart';
import '../models/wallet.dart';
import '../models/transaction_model.dart';
import '../wallet_details_screen.dart';

class WalletsView extends StatelessWidget {
  final VoidCallback onRefresh;
  const WalletsView({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final account = SessionService.activeAccount;
    final theme = Theme.of(context);
    final wallets = account != null
        ? DatabaseService.getWallets(account.key as int)
        : <Wallet>[];
    final transactions = account != null
        ? DatabaseService.getTransactions(account.key as int)
        : <Transaction>[];

    final totalBalance = wallets
        .where((w) => !w.isExcluded)
        .fold(0.0, (sum, w) => sum + w.balance);
    final totalIncome = transactions
        .where((tx) => tx.type == TransactionType.income)
        .fold(0.0, (sum, tx) => sum + tx.amount);
    final totalExpense = transactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (sum, tx) => sum + tx.amount);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 80),
      children: [
        // ── Global Stats Banner ─────────────────────────────────────────
        _GlobalStatsBanner(
          wallets: wallets,
          transactions: transactions,
          totalBalance: totalBalance,
          totalIncome: totalIncome,
          totalExpense: totalExpense,
        ),
        const SizedBox(height: 28),

        // ── Section Label ───────────────────────────────────────────────
        Text(
          'MY WALLETS',
          style: theme.textTheme.labelLarge?.copyWith(
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
            fontSize: 10,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
          ),
        ),
        const SizedBox(height: 12),

        // ── Wallet Cards ────────────────────────────────────────────────
        if (wallets.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'No wallets yet',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
                ),
              ),
            ),
          )
        else
          ...wallets.map(
            (wallet) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _WalletCard(wallet: wallet, onRefresh: onRefresh),
            ),
          ),
      ],
    );
  }
}

// ============================================================================
// Global Stats Banner
// ============================================================================

class _GlobalStatsBanner extends StatelessWidget {
  final List<Wallet> wallets;
  final List<Transaction> transactions;
  final double totalBalance;
  final double totalIncome;
  final double totalExpense;

  const _GlobalStatsBanner({
    required this.wallets,
    required this.transactions,
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpense,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expenses =
        transactions.where((tx) => tx.type == TransactionType.expense).toList();

    double dailyAvg = 0;
    if (expenses.isNotEmpty) {
      final firstDate =
          expenses.map((e) => e.date).reduce((a, b) => a.isBefore(b) ? a : b);
      final days = DateTime.now().difference(firstDate).inDays + 1;
      dailyAvg = expenses.fold(0.0, (s, e) => s + e.amount) / days;
    }
    final daysRemaining = dailyAvg > 0 ? (totalBalance / dailyAvg).floor() : -1;
    String status;
    Color statusColor;

    if (totalBalance <= 0) {
      status = 'EMPTY';
      statusColor = theme.colorScheme.error;
    } else if (dailyAvg == 0 || daysRemaining > 30) {
      status = 'SURPLUS';
      statusColor = theme.colorScheme.tertiary;
    } else if (daysRemaining > 7) {
      status = 'NOMINAL';
      statusColor = theme.primaryColor;
    } else {
      status = 'CRITICAL';
      statusColor = theme.colorScheme.error;
    }

    final trendData = FinancialInsightsService.getWeeklyTrendLineData(expenses);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.dividerColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: balance + runway
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SPENDABLE BALANCE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: theme.textTheme.bodyMedium?.color
                              ?.withOpacity(0.4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₱${totalBalance.toStringAsFixed(2)}',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Trend mini-chart
          if (trendData.length > 1)
            SizedBox(
              height: 80,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: trendData
                            .asMap()
                            .entries
                            .map((e) => FlSpot(e.key.toDouble(), e.value))
                            .toList(),
                        isCurved: true,
                        color: theme.primaryColor,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: theme.primaryColor.withOpacity(0.06),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Bottom row: Inflow, Outflow, Burn Rate
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Row(
              children: [
                _MiniStat(
                  label: 'INFLOW',
                  value: '₱${totalIncome.toStringAsFixed(0)}',
                  color: theme.colorScheme.tertiary,
                ),
                _MiniStat(
                  label: 'OUTFLOW',
                  value: '₱${totalExpense.toStringAsFixed(0)}',
                  color: theme.colorScheme.error,
                ),
                _MiniStat(
                  label: 'RUNWAY',
                  value: daysRemaining == -1 ? '∞ days' : '$daysRemaining days',
                  color: theme.primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                color: color.withOpacity(0.7),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Wallet Card
// ============================================================================

class _WalletCard extends StatelessWidget {
  final Wallet wallet;
  final VoidCallback onRefresh;
  const _WalletCard({required this.wallet, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Determine color based on exclusion state
    final isExcluded = wallet.isExcluded;
    final accentColor =
        isExcluded ? theme.colorScheme.error : theme.primaryColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WalletDetailsScreen(wallet: wallet),
            ),
          );
          onRefresh();
        },
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isExcluded
                  ? theme.colorScheme.error.withOpacity(0.5)
                  : theme.dividerColor,
              width: isExcluded ? 1.5 : 0.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.07),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _walletIcon(wallet.type),
                  color: accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          wallet.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isExcluded
                                ? theme.colorScheme.error.withOpacity(0.7)
                                : null,
                          ),
                        ),
                        if (isExcluded) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.visibility_off_rounded,
                            size: 14,
                            color: theme.colorScheme.error.withOpacity(0.7),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      isExcluded ? 'Excluded from Liquidity' : wallet.type,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isExcluded
                            ? theme.colorScheme.error.withOpacity(0.5)
                            : theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                    Text(
                      '₱${wallet.balance.toStringAsFixed(2)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isExcluded
                            ? theme.colorScheme.error.withOpacity(0.5)
                            : null,
                      ),
                    ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color:
                        theme.textTheme.bodyMedium?.color?.withOpacity(0.3),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _walletIcon(String type) {
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
