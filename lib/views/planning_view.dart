import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/session_service.dart';
import '../services/database_service.dart';
import '../services/planning_intelligence_service.dart';
import '../screens/add_budget_screen.dart';
import '../screens/add_goal_screen.dart';
import '../screens/add_debt_screen.dart';
import '../models/transaction_model.dart';
import '../add_transaction_screen.dart';
import '../screens/fund_goal_screen.dart';

class PlanningView extends StatelessWidget {
  final VoidCallback onRefresh;
  final bool isTutorialActive;
  final GlobalKey? budgetSectionKey;
  final GlobalKey? budgetAddKey;
  final GlobalKey? budgetIndicatorKey;
  final GlobalKey? goalSectionKey;
  final GlobalKey? goalAddKey;
  final GlobalKey? goalFundKey;
  final GlobalKey? goalWithdrawKey;
  final GlobalKey? debtSectionKey;
  final GlobalKey? debtAddKey;

  const PlanningView({
    super.key, 
    required this.onRefresh,
    this.isTutorialActive = false,
    this.budgetSectionKey,
    this.budgetAddKey,
    this.budgetIndicatorKey,
    this.goalSectionKey,
    this.goalAddKey,
    this.goalFundKey,
    this.goalWithdrawKey,
    this.debtSectionKey,
    this.debtAddKey,
  });

  @override
  Widget build(BuildContext context) {
    final account = SessionService.activeAccount;
    final accountKey = account?.key as int?;
    
    if (accountKey == null) {
      return const Center(child: Text('No active account'));
    }

    final goals = DatabaseService.getGoals(accountKey);
    final budgets = DatabaseService.getBudgets(accountKey);
    final debts = DatabaseService.getDebts(accountKey);

    final theme = Theme.of(context);

    final transactions = DatabaseService.getTransactions(accountKey);
    final wallets = DatabaseService.getWallets(accountKey);
    final totalBalance = wallets
        .where((w) => !w.isExcluded)
        .fold(0.0, (sum, w) => sum + w.balance);

    final now = DateTime.now();

    // 1. Budget Used %
    final thisMonthBudgets = budgets.where((b) => b.month == now.month && b.year == now.year).toList();
    double totalBudgetLimit = 0;
    double totalBudgetSpent = 0;
    for (var b in thisMonthBudgets) {
      totalBudgetLimit += b.amountLimit;
      final spent = transactions
          .where((e) =>
              (e.budgetKey == b.key ||
               (e.category == b.category && e.date.month == now.month && e.date.year == now.year)) &&
              e.type == TransactionType.expense)
          .fold(0.0, (s, e) => s + e.amount);
      totalBudgetSpent += spent;
    }
    final budgetUsedPct = totalBudgetLimit > 0 ? (totalBudgetSpent / totalBudgetLimit * 100).clamp(0.0, 100.0) : 0.0;

    // 2. Savings Progress %
    final totalGoalTarget = goals.fold(0.0, (s, g) => s + g.targetAmount);
    final totalGoalSaved = goals.fold(0.0, (s, g) => s + g.savedAmount);
    final savingsPct = totalGoalTarget > 0 ? (totalGoalSaved / totalGoalTarget * 100).clamp(0.0, 100.0) : 0.0;

    // 3. Active Debts
    final activeDebtAmount = debts.where((d) => !d.isOwedToMe).fold(0.0, (s, d) => s + (d.totalAmount - d.paidAmount));

    final insights = PlanningIntelligenceService.generate(
      transactions: transactions,
      budgets: budgets,
      goals: goals,
      debts: debts,
      totalBalance: totalBalance,
      wallets: wallets,
    );

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Text(
              'FINANCIAL PLANNING',
              style: theme.textTheme.labelLarge?.copyWith(
                letterSpacing: 2,
                fontWeight: FontWeight.w900,
                fontSize: 10,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
              ),
            ),
          ),
        ),

        // ── Health Snapshot Strip ────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: _HealthSnapshotStrip(
              budgetUsedPct: budgetUsedPct,
              savingsPct: savingsPct,
              activeDebtAmount: activeDebtAmount,
            ),
          ),
        ),

        // ── Financial Intelligence Panel ─────────────────────────────
        if (insights.isNotEmpty)
          SliverToBoxAdapter(
            child: _IntelligencePanel(insights: insights),
          ),

        // Budgets Section
        SliverToBoxAdapter(
          child: _SectionCard(
            sectionKey: budgetSectionKey,
            addKey: budgetAddKey,
            title: 'Monthly Budgets',
            icon: Icons.pie_chart_outline_rounded,
            color: Colors.blue,
            count: budgets.length,
            onAdd: () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddBudgetScreen(accountKey: accountKey)));
              if (result == true) onRefresh();
            },
            child: (budgets.isEmpty && !isTutorialActive)
              ? const _EmptyState(icon: Icons.pie_chart_outline_rounded, message: 'No budgets set')
              : Column(
                  children: [
                    if (isTutorialActive && budgets.isEmpty)
                      Container(
                        key: budgetIndicatorKey,
                        child: _PlanningItem(
                          title: 'Food & Drinks',
                          subtitle: DateFormat('MMM yyyy').format(DateTime.now()),
                          trailingText: '₱0 / ₱2000',
                          progress: 0.0,
                          progressColor: Colors.blue,
                          onDelete: () {},
                        ),
                      ),
                    ...budgets.asMap().entries.map((entry) {
                      final index = entry.key;
                      final b = entry.value;
                    final currentSpending = DatabaseService.getTransactions(accountKey)
                        .where((t) => (t.budgetKey == b.key) || 
                                     (t.category == b.category && t.date.month == b.month && t.date.year == b.year))
                        .where((t) => t.type == TransactionType.expense)
                        .fold(0.0, (sum, t) => sum + t.amount);
                    final progress = b.amountLimit > 0 ? (currentSpending / b.amountLimit).clamp(0.0, 1.0) : 0.0;
                    final isOver = currentSpending > b.amountLimit;

                    return Container(
                      key: index == 0 ? budgetIndicatorKey : null,
                      child: _PlanningItem(
                        title: b.category,
                        subtitle: '${DateFormat('MMM yyyy').format(DateTime(b.year, b.month))}',
                        trailingText: '₱${currentSpending.toStringAsFixed(0)} / ₱${b.amountLimit.toStringAsFixed(0)}',
                        progress: progress,
                        progressColor: isOver ? Colors.red : Colors.blue,
                        onDelete: () async {
                          await DatabaseService.deleteBudget(b);
                          onRefresh();
                        },
                      ),
                    );
                  }).toList(),
                  ],
                ),
          ),
        ),

        // Goals Section
        SliverToBoxAdapter(
          child: _SectionCard(
            sectionKey: goalSectionKey,
            addKey: goalAddKey,
            title: 'Savings Goals',
            icon: Icons.flag_outlined,
            color: Colors.green,
            count: goals.length,
            onAdd: () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddGoalScreen(accountKey: accountKey)));
              if (result == true) onRefresh();
            },
            child: (goals.isEmpty && !isTutorialActive)
              ? const _EmptyState(icon: Icons.flag_outlined, message: 'No savings goals')
              : Column(
                  children: [
                    if (isTutorialActive && goals.isEmpty)
                      _PlanningItem(
                        title: 'Vacation',
                        subtitle: 'Target: ₱10000',
                        trailingText: '₱0 saved',
                        progress: 0.0,
                        progressColor: Colors.green,
                        primaryActionLabel: 'Save',
                        primaryActionKey: goalFundKey,
                        onPrimaryAction: () {},
                        secondaryActionLabel: 'Withdraw',
                        secondaryActionKey: goalWithdrawKey,
                        onSecondaryAction: () {},
                        onDelete: () {},
                      ),
                    ...goals.asMap().entries.map((entry) {
                      final index = entry.key;
                      final g = entry.value;
                    final progress = g.targetAmount > 0 ? (g.savedAmount / g.targetAmount).clamp(0.0, 1.0) : 0.0;
                    return _PlanningItem(
                      title: g.name,
                      subtitle: 'Target: ₱${g.targetAmount.toStringAsFixed(0)}',
                      trailingText: '₱${g.savedAmount.toStringAsFixed(0)} saved',
                      progress: progress,
                      progressColor: Colors.green,
                      primaryActionLabel: 'Save',
                      primaryActionKey: index == 0 ? goalFundKey : null,
                      onPrimaryAction: () async {
                        final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => FundGoalScreen(
                          accountKey: accountKey,
                          goal: g,
                          isWithdrawing: false,
                        )));
                        if (res == true) onRefresh();
                      },
                      secondaryActionLabel: 'Withdraw',
                      secondaryActionKey: index == 0 ? goalWithdrawKey : null,
                      onSecondaryAction: () async {
                        final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => FundGoalScreen(
                          accountKey: accountKey,
                          goal: g,
                          isWithdrawing: true,
                        )));
                        if (res == true) onRefresh();
                      },
                      onDelete: () async {
                        await DatabaseService.deleteGoal(g);
                        onRefresh();
                      },
                    );
                  }).toList(),
                  ],
                ),
          ),
        ),

        // Debts Section
        SliverToBoxAdapter(
          child: _SectionCard(
            sectionKey: debtSectionKey,
            addKey: debtAddKey,
            title: 'Debts & Loans',
            icon: Icons.handshake_outlined,
            color: Colors.orange,
            count: debts.length,
            onAdd: () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddDebtScreen(accountKey: accountKey)));
              if (result == true) onRefresh();
            },
            child: (debts.isEmpty && !isTutorialActive)
              ? const _EmptyState(icon: Icons.handshake_outlined, message: 'No active debts')
              : Column(
                  children: debts.map((d) {
                    final total = d.totalAmount;
                    final paid = d.paidAmount;
                    final remaining = total - paid;
                    final progress = total > 0 ? (paid / total).clamp(0.0, 1.0) : 0.0;
                    
                    return _PlanningItem(
                      title: d.personName,
                      subtitle: d.isOwedToMe ? 'Lent (Remaining)' : 'Borrowed (Remaining)',
                      trailingText: '₱${remaining.toStringAsFixed(0)}',
                      progress: progress,
                      progressColor: Colors.orange,
                      primaryActionLabel: d.isOwedToMe ? 'Receive' : 'Pay',
                      onPrimaryAction: () async {
                        final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddTransactionScreen(
                          accountKey: accountKey,
                          initialType: d.isOwedToMe ? TransactionType.income : TransactionType.expense,
                          initialDebtKey: d.key as int,
                        )));
                        if (res == true) onRefresh();
                      },
                      onDelete: () async {
                        await DatabaseService.deleteDebt(d);
                        onRefresh();
                      },
                    );
                  }).toList(),
                ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

class _PlanningItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String trailingText;
  final double progress;
  final Color progressColor;
  final String? primaryActionLabel;
  final GlobalKey? primaryActionKey;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final GlobalKey? secondaryActionKey;
  final VoidCallback? onSecondaryAction;
  final VoidCallback onDelete;

  const _PlanningItem({
    required this.title,
    required this.subtitle,
    required this.trailingText,
    required this.progress,
    required this.progressColor,
    this.primaryActionLabel,
    this.primaryActionKey,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.secondaryActionKey,
    this.onSecondaryAction,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5))),
                  ],
                ),
              ),
              Text(trailingText, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: progressColor.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 10, color: progressColor, fontWeight: FontWeight.bold),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onSecondaryAction != null) ...[
                    TextButton.icon(
                      key: secondaryActionKey,
                      onPressed: onSecondaryAction,
                      icon: Icon(Icons.remove_circle_outline_rounded, size: 14, color: progressColor.withOpacity(0.7)),
                      label: Text(
                        secondaryActionLabel ?? 'Remove',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: progressColor.withOpacity(0.7)),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        backgroundColor: progressColor.withOpacity(0.05),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (onPrimaryAction != null)
                    TextButton.icon(
                      key: primaryActionKey,
                      onPressed: onPrimaryAction,
                      icon: Icon(Icons.add_circle_outline_rounded, size: 14, color: progressColor),
                      label: Text(
                        primaryActionLabel ?? 'Add',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: progressColor),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        backgroundColor: progressColor.withOpacity(0.1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final GlobalKey? sectionKey;
  final GlobalKey? addKey;
  final String title;
  final IconData icon;
  final Color color;
  final int count;
  final VoidCallback onAdd;
  final Widget child;

  const _SectionCard({
    this.sectionKey,
    this.addKey,
    required this.title,
    required this.icon,
    required this.color,
    required this.count,
    required this.onAdd,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: sectionKey,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    if (count > 0)
                      Text('$count active', style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5))),
                  ],
                ),
              ),
              IconButton(
                key: addKey,
                icon: const Icon(Icons.add_circle_outline_rounded),
                color: theme.primaryColor,
                onPressed: onAdd,
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 32, color: theme.dividerColor),
            const SizedBox(height: 8),
            Text(message, style: TextStyle(color: theme.dividerColor)),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Financial Intelligence Panel
// ============================================================================

class _IntelligencePanel extends StatelessWidget {
  final List<PlanningInsight> insights;

  const _IntelligencePanel({required this.insights});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 14,
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'FINANCIAL INTELLIGENCE',
                style: theme.textTheme.labelLarge?.copyWith(
                  letterSpacing: 2,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  color: theme.primaryColor.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            itemCount: insights.length,
            itemBuilder: (context, index) {
              return _InsightCard(insight: insights[index]);
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  final PlanningInsight insight;

  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = insight.color;

    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(insight.icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  insight.badgeLabel,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Text(
              insight.message,
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Urgency dot indicator
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color.withOpacity(
                    insight.urgency == InsightUrgency.high
                        ? 1.0
                        : insight.urgency == InsightUrgency.medium
                            ? 0.6
                            : 0.3,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                insight.urgency == InsightUrgency.high
                    ? 'High priority'
                    : insight.urgency == InsightUrgency.medium
                        ? 'Worth acting on'
                        : 'Good to know',
                style: TextStyle(
                  fontSize: 9,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Health Snapshot Strip
// ============================================================================

class _HealthSnapshotStrip extends StatelessWidget {
  final double budgetUsedPct;
  final double savingsPct;
  final double activeDebtAmount;

  const _HealthSnapshotStrip({
    required this.budgetUsedPct,
    required this.savingsPct,
    required this.activeDebtAmount,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          _MiniHealthCard(
            label: 'BUDGET USED',
            value: '${budgetUsedPct.toStringAsFixed(0)}%',
            icon: Icons.pie_chart_rounded,
            color: Colors.blue,
          ),
          const SizedBox(width: 12),
          _MiniHealthCard(
            label: 'SAVINGS PROGRESS',
            value: '${savingsPct.toStringAsFixed(0)}%',
            icon: Icons.savings_rounded,
            color: Colors.green,
          ),
          const SizedBox(width: 12),
          _MiniHealthCard(
            label: 'ACTIVE DEBTS',
            value: '₱${activeDebtAmount.toStringAsFixed(0)}',
            icon: Icons.warning_rounded,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }
}

class _MiniHealthCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniHealthCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
