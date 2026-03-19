import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'models/wallet.dart';
import 'models/transaction_model.dart';
import 'services/database_service.dart';
import 'services/financial_insights_service.dart';
import 'widgets/transaction_card.dart';

class WalletDetailsScreen extends StatefulWidget {
  final Wallet wallet;
  const WalletDetailsScreen({super.key, required this.wallet});

  @override
  State<WalletDetailsScreen> createState() => _WalletDetailsScreenState();
}

class _WalletDetailsScreenState extends State<WalletDetailsScreen> {
  late bool _isExcluded;

  @override
  void initState() {
    super.initState();
    _isExcluded = widget.wallet.isExcluded;
  }

  void _toggleExclusion() async {
    setState(() {
      _isExcluded = !_isExcluded;
    });
    widget.wallet.isExcluded = _isExcluded;
    await DatabaseService.updateWallet(widget.wallet);
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transactions =
        DatabaseService.getWalletTransactions(widget.wallet.key as int);

    // Wallet Analytics
    final income = transactions
        .where((tx) =>
            tx.type == TransactionType.income ||
            (tx.type == TransactionType.transfer &&
                tx.toWalletKey == widget.wallet.key))
        .fold(0.0, (s, tx) => s + tx.amount);
    final expense = transactions
        .where((tx) =>
            tx.type == TransactionType.expense ||
            (tx.type == TransactionType.transfer &&
                tx.walletKey == widget.wallet.key)) // A transfer "from" this wallet has the main walletKey as this wallet
        .fold(0.0, (s, tx) => s + tx.amount);

    final expensesOnly =
        transactions.where((tx) => tx.type == TransactionType.expense).toList();
    final trendData =
        FinancialInsightsService.getWeeklyTrendLineData(expensesOnly);
    final categoryData =
        FinancialInsightsService.getCategoryData(expensesOnly);

    double dailyAvg = 0;
    if (expensesOnly.isNotEmpty) {
      final firstDate = expensesOnly
          .map((e) => e.date)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      final days = DateTime.now().difference(firstDate).inDays + 1;
      dailyAvg = expensesOnly.fold(0.0, (s, e) => s + e.amount) / days;
    }
    final daysRemaining =
        dailyAvg > 0 ? (widget.wallet.balance / dailyAvg).floor() : 0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.wallet.name),
            if (_isExcluded) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.visibility_off_rounded,
                size: 16,
                color: theme.colorScheme.error.withOpacity(0.7),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
                _isExcluded ? Icons.visibility_off : Icons.visibility,
                color: _isExcluded ? Colors.red : theme.primaryColor),
            onPressed: _toggleExclusion,
            tooltip: _isExcluded ? 'Excluded from total' : 'Included in total',
          ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Wallet Balance Header ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(
                    bottom: BorderSide(
                        color: theme.dividerColor.withOpacity(0.1))),
              ),
              child: Column(
                children: [
                  Text(
                    'CURRENT BALANCE',
                    style: TextStyle(
                      color:
                          theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₱${widget.wallet.balance.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1),
                  ),
                  if (_isExcluded)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'EXCLUDED FROM TOTAL',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Wallet Analytics ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Net Flow
                  Row(
                    children: [
                      _StatBox(
                        label: 'INFLOW',
                        value: '₱${income.toStringAsFixed(0)}',
                        color: theme.colorScheme.tertiary,
                      ),
                      const SizedBox(width: 12),
                      _StatBox(
                        label: 'OUTFLOW',
                        value: '₱${expense.toStringAsFixed(0)}',
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 12),
                      _StatBox(
                        label: 'RUNWAY',
                        value: '$daysRemaining days',
                        color: theme.primaryColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Trend
                  if (trendData.length > 1) ...[
                    Text(
                      'SPENDING TREND',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: theme.textTheme.bodyMedium?.color
                            ?.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 120,
                      padding: const EdgeInsets.only(top: 16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: theme.dividerColor, width: 0.5),
                      ),
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: trendData.asMap().entries.map((e) {
                                return FlSpot(e.key.toDouble(), e.value);
                              }).toList(),
                              isCurved: true,
                              color: theme.primaryColor,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color:
                                    theme.primaryColor.withOpacity(0.06),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Pie Chart
                  if (categoryData.isNotEmpty) ...[
                    Text(
                      'CATEGORY BREAKDOWN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: theme.textTheme.bodyMedium?.color
                            ?.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: theme.dividerColor, width: 0.5),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 28,
                                sections: categoryData.entries
                                    .toList()
                                    .asMap()
                                    .entries
                                    .map((e) {
                                  final colors = [
                                    theme.primaryColor,
                                    theme.colorScheme.tertiary,
                                    theme.colorScheme.error,
                                    theme.colorScheme.secondary,
                                    theme.primaryColor.withOpacity(0.5),
                                  ];
                                  return PieChartSectionData(
                                    value: e.value.value,
                                    color: colors[e.key % colors.length],
                                    radius: 6,
                                    title: '',
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: categoryData.entries
                                  .toList()
                                  .take(4) // Show top 4
                                  .map((e) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 2),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              e.key,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              '₱${e.value.toStringAsFixed(0)}',
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
                          )
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Transaction History ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Text(
                'WALLET HISTORY',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                ),
              ),
            ),
          ),
          transactions.isEmpty
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        'No transactions',
                        style: TextStyle(
                          color: theme.dividerColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final tx =
                            transactions[transactions.length - 1 - index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child:
                              TransactionCard(tx: tx, onRefresh: _refresh),
                        );
                      },
                      childCount: transactions.length,
                    ),
                  ),
                ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: color.withOpacity(0.7),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
