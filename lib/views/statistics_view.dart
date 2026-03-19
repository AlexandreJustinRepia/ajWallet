import 'package:flutter/material.dart';
import '../services/session_service.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/database_service.dart';
import '../services/financial_insights_service.dart';
import '../models/transaction_model.dart';
import '../models/wallet.dart';
import '../widgets/slide_in_list_item.dart';
import 'insight_card.dart';

class StatisticsView extends StatelessWidget {
  final VoidCallback onRefresh;
  const StatisticsView({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final account = SessionService.activeAccount;
    final transactions = account != null
        ? DatabaseService.getTransactions(account.key as int)
        : <Transaction>[];
    final wallets = account != null
        ? DatabaseService.getWallets(account.key as int)
        : <Wallet>[];

    final totalIncome = transactions
        .where((tx) => tx.type == TransactionType.income)
        .fold(0.0, (sum, tx) => sum + tx.amount);
    final totalExpense = transactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (sum, tx) => sum + tx.amount);
    final totalBalance = wallets
        .where((w) => !w.isExcluded)
        .fold(0.0, (sum, w) => sum + w.balance);

    final insights =
        FinancialInsightsService.generateInsights(transactions, totalBalance);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BurnRateCard(balance: totalBalance, transactions: transactions),
          const SizedBox(height: 32),
          _SpendingTrendCard(transactions: transactions),
          const SizedBox(height: 32),
          _CategoryBreakdownCard(transactions: transactions),
          const SizedBox(height: 32),
          _SummarySection(
            totalIncome: totalIncome,
            totalExpense: totalExpense,
          ),
          if (insights.isNotEmpty) ...[
            const SizedBox(height: 48),
            _InsightsSection(insights: insights),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Burn Rate Card
// ---------------------------------------------------------------------------
class _BurnRateCard extends StatelessWidget {
  final double balance;
  final List<Transaction> transactions;

  const _BurnRateCard({required this.balance, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expenses = transactions
        .where((tx) => tx.type == TransactionType.expense)
        .toList();

    double dailyAvg = 0;
    if (expenses.isNotEmpty) {
      final firstDate = expenses
          .map((e) => e.date)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      final days = DateTime.now().difference(firstDate).inDays + 1;
      dailyAvg = expenses.fold(0.0, (sum, e) => sum + e.amount) / days;
    }

    final daysRemaining = dailyAvg > 0 ? (balance / dailyAvg).floor() : 0;
    final status = daysRemaining > 30
        ? 'SURPLUS'
        : (daysRemaining > 7 ? 'NOMINAL' : 'CRITICAL');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.primaryColor,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DAILY BURN RATE',
            style: TextStyle(
              color: theme.scaffoldBackgroundColor.withOpacity(0.6),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₱${dailyAvg.toStringAsFixed(2)}',
            style: TextStyle(
              color: theme.scaffoldBackgroundColor,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _HeroStat(
                label: 'RUNWAY',
                value: '$daysRemaining Days',
                bgColor: theme.scaffoldBackgroundColor.withOpacity(0.1),
                textColor: theme.scaffoldBackgroundColor,
              ),
              const SizedBox(width: 12),
              _HeroStat(
                label: 'STATUS',
                value: status,
                bgColor: theme.scaffoldBackgroundColor.withOpacity(0.1),
                textColor: theme.scaffoldBackgroundColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Spending Trend Card
// ---------------------------------------------------------------------------
class _SpendingTrendCard extends StatelessWidget {
  final List<Transaction> transactions;
  const _SpendingTrendCard({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expenses = transactions
        .where((tx) => tx.type == TransactionType.expense)
        .toList();
    final trendData = FinancialInsightsService.getWeeklyTrendLineData(expenses);

    return _SectionCard(
      title: 'SPENDING TREND',
      child: SizedBox(
        height: 180,
        child: Padding(
          padding: const EdgeInsets.only(top: 24, right: 24, left: 12),
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
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: theme.primaryColor.withOpacity(0.05),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category Breakdown Card
// ---------------------------------------------------------------------------
class _CategoryBreakdownCard extends StatelessWidget {
  final List<Transaction> transactions;
  const _CategoryBreakdownCard({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expenses = transactions
        .where((tx) => tx.type == TransactionType.expense)
        .toList();
    final categoryData = FinancialInsightsService.getCategoryData(expenses);

    if (categoryData.isEmpty) return const SizedBox.shrink();

    final colors = [
      theme.primaryColor,
      theme.dividerColor,
      theme.textTheme.bodyMedium?.color?.withOpacity(0.5) ?? Colors.grey,
      theme.primaryColor.withOpacity(0.3),
      theme.primaryColor.withOpacity(0.6),
    ];

    return _SectionCard(
      title: 'CATEGORY BREAKDOWN',
      child: Row(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 40,
                sections: categoryData.entries
                    .toList()
                    .asMap()
                    .entries
                    .map((e) => PieChartSectionData(
                          value: e.value.value,
                          color: colors[e.key % colors.length],
                          radius: 8,
                          title: '',
                        ))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              children: categoryData.entries
                  .toList()
                  .asMap()
                  .entries
                  .map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: colors[e.key % colors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                e.value.key,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              '₱${e.value.value.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Summary Section
// ---------------------------------------------------------------------------
class _SummarySection extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;

  const _SummarySection({
    required this.totalIncome,
    required this.totalExpense,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        StatRow(
          label: 'Total Inflow',
          amount: totalIncome,
          color: theme.colorScheme.tertiary,
        ),
        const SizedBox(height: 12),
        StatRow(
          label: 'Total Outflow',
          amount: totalExpense,
          color: theme.colorScheme.error,
        ),
        const SizedBox(height: 12),
        StatRow(
          label: 'Net Position',
          amount: totalIncome - totalExpense,
          color: theme.primaryColor,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Insights Section
// ---------------------------------------------------------------------------
class _InsightsSection extends StatelessWidget {
  final List<Insight> insights;
  const _InsightsSection({required this.insights});

  @override
  Widget build(BuildContext context) {
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
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => SlideInListItem(
            index: index,
            child: InsightCard(insight: insights[index]),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable small widgets
// ---------------------------------------------------------------------------

/// A section card with a title label and child content.
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
            fontSize: 10,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.dividerColor, width: 0.5),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  final Color bgColor;
  final Color textColor;

  const _HeroStat({
    required this.label,
    required this.value,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: textColor.withOpacity(0.5),
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A stat row card used in the summary section.
class StatRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const StatRow({
    super.key,
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
