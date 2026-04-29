import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import '../services/balance_visibility_service.dart';
import '../services/financial_insights_service.dart';
import '../models/wallet.dart';
import '../models/transaction_model.dart';
import '../wallet_details_screen.dart';
import 'wallets/wallets_view_model.dart';

class WalletsView extends StatefulWidget {
  final VoidCallback onRefresh;
  final GlobalKey? walletListKey;
  final GlobalKey? singleWalletKey;
  final GlobalKey? lifeOfMoneyKey;

  const WalletsView({
    super.key,
    required this.onRefresh,
    this.walletListKey,
    this.singleWalletKey,
    this.lifeOfMoneyKey,
  });

  @override
  State<WalletsView> createState() => _WalletsViewState();
}

class _WalletsViewState extends State<WalletsView> {
  late WalletsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = WalletsViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 80),
          children: [
            Container(
              key: widget.lifeOfMoneyKey,
              child: _GlobalStatsBanner(
                wallets: _viewModel.wallets,
                transactions: _viewModel.transactions,
                totalBalance: _viewModel.totalBalance,
                totalIncome: _viewModel.totalIncome,
                totalExpense: _viewModel.totalExpense,
              ),
            ),
            const SizedBox(height: 28),

            // ── Section Label ───────────────────────────────────────────────
            Text(
              'MY WALLETS',
              style: theme.textTheme.labelLarge?.copyWith(
                letterSpacing: 2,
                fontWeight: FontWeight.w900,
                fontSize: 10,
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.4,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Wallet Cards ────────────────────────────────────────────────
            Container(
              key: widget.walletListKey,
              child: _viewModel.wallets.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'No wallets yet',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    )
                  : Column(
                      children: _viewModel.wallets.asMap().entries.map((entry) {
                        final index = entry.key;
                        final wallet = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Container(
                            key: index == 0 ? widget.singleWalletKey : null,
                            child: _WalletCard(
                              wallet: wallet,
                              onRefresh: widget.onRefresh,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        );
      },
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
    final expenses = transactions
        .where((tx) => tx.type == TransactionType.expense)
        .toList();

    double dailyAvg = 0;
    if (expenses.isNotEmpty) {
      final firstDate = expenses
          .map((e) => e.date)
          .reduce((a, b) => a.isBefore(b) ? a : b);
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
                          color: theme.textTheme.bodyMedium?.color?.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      ValueListenableBuilder<bool>(
                        valueListenable: BalanceVisibilityService.instance,
                        builder: (context, isHidden, _) {
                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              isHidden
                                  ? '₱ ••••••'
                                  : '₱${totalBalance.toStringAsFixed(2)}',
                              key: ValueKey(isHidden),
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: isHidden ? 4 : -1,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
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
                          color: theme.primaryColor.withValues(alpha: 0.06),
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
            child: ValueListenableBuilder<bool>(
              valueListenable: BalanceVisibilityService.instance,
              builder: (context, isHidden, _) {
                return Row(
                  children: [
                    _MiniStat(
                      label: 'INFLOW',
                      value: isHidden
                          ? '••••'
                          : '₱${totalIncome.toStringAsFixed(0)}',
                      color: theme.colorScheme.tertiary,
                    ),
                    _MiniStat(
                      label: 'OUTFLOW',
                      value: isHidden
                          ? '••••'
                          : '₱${totalExpense.toStringAsFixed(0)}',
                      color: theme.colorScheme.error,
                    ),
                    _MiniStat(
                      label: 'RUNWAY',
                      value: isHidden
                          ? '•• days'
                          : (daysRemaining == -1
                                ? '∞ days'
                                : '$daysRemaining days'),
                      color: theme.primaryColor,
                    ),
                  ],
                );
              },
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
          color: color.withValues(alpha: 0.07),
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
                color: color.withValues(alpha: 0.7),
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
    final isExcluded = wallet.isExcluded;
    final customColor = wallet.colorValue != null ? Color(wallet.colorValue!) : null;
    final accentColor = customColor ?? (isExcluded ? theme.colorScheme.error : theme.primaryColor);
    
    // Determine contrasting text color
    final bool hasCustomColor = customColor != null;
    final Color foregroundColor = hasCustomColor
        ? (customColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white)
        : (theme.textTheme.bodyLarge?.color ?? Colors.black);

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
            color: customColor ?? theme.cardColor,
            gradient: customColor != null
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      customColor,
                      customColor.withValues(alpha: 0.8),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isExcluded
                  ? theme.colorScheme.error.withValues(alpha: 0.5)
                  : (customColor != null 
                      ? customColor.withValues(alpha: 0.8) 
                      : theme.dividerColor),
              width: (isExcluded || customColor != null) ? 1.5 : 0.5,
            ),
            boxShadow: [
              if (customColor != null)
                BoxShadow(
                  color: customColor.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: hasCustomColor
                      ? foregroundColor.withValues(alpha: 0.2)
                      : accentColor.withValues(alpha: 0.07),
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.center,
                child: wallet.customImagePath != null
                    ? Image.file(
                        File(wallet.customImagePath!),
                        fit: BoxFit.cover,
                        width: 48,
                        height: 48,
                      )
                    : (wallet.iconPath != null
                        ? Padding(
                            padding: const EdgeInsets.all(12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.asset(
                                wallet.iconPath!,
                                fit: BoxFit.contain,
                                width: 22,
                                height: 22,
                              ),
                            ),
                          )
                        : Icon(
                            _walletIcon(wallet.type),
                            color: foregroundColor,
                            size: 22,
                          )),
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
                            color: foregroundColor,
                          ),
                        ),
                        if (isExcluded) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.visibility_off_rounded,
                            size: 14,
                            color: foregroundColor.withValues(alpha: 0.7),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      isExcluded ? 'Excluded from Liquidity' : wallet.type,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: foregroundColor.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ValueListenableBuilder<bool>(
                    valueListenable: BalanceVisibilityService.instance,
                    builder: (context, isHidden, _) {
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          isHidden
                              ? '₱ ••••'
                              : '₱${wallet.balance.toStringAsFixed(2)}',
                          key: ValueKey(isHidden),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: isHidden ? 3 : 0,
                            color: foregroundColor,
                          ),
                        ),
                      );
                    },
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: foregroundColor.withValues(alpha: 0.4),
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
