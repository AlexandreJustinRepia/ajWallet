import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/session_service.dart';
import '../services/database_service.dart';
import '../screens/add_budget_screen.dart';
import '../screens/add_goal_screen.dart';
import '../screens/add_debt_screen.dart';
import '../models/transaction_model.dart';

class PlanningView extends StatelessWidget {
  final VoidCallback onRefresh;
  const PlanningView({super.key, required this.onRefresh});

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

        // Budgets Section
        SliverToBoxAdapter(
          child: _SectionCard(
            title: 'Monthly Budgets',
            icon: Icons.pie_chart_outline_rounded,
            color: Colors.blue,
            count: budgets.length,
            onAdd: () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddBudgetScreen(accountKey: accountKey)));
              if (result == true) onRefresh();
            },
            child: budgets.isEmpty 
              ? const _EmptyState(icon: Icons.pie_chart_outline_rounded, message: 'No budgets set')
              : Column(
                  children: budgets.map((b) {
                    final currentSpending = DatabaseService.getTransactions(accountKey)
                        .where((t) => (t.budgetKey == b.key) || 
                                     (t.category == b.category && t.date.month == b.month && t.date.year == b.year))
                        .where((t) => t.type == TransactionType.expense)
                        .fold(0.0, (sum, t) => sum + t.amount);
                    final progress = b.amountLimit > 0 ? (currentSpending / b.amountLimit).clamp(0.0, 1.0) : 0.0;
                    final isOver = currentSpending > b.amountLimit;

                    return _PlanningItem(
                      title: b.category,
                      subtitle: '${DateFormat('MMM yyyy').format(DateTime(b.year, b.month))}',
                      trailingText: '₱${currentSpending.toStringAsFixed(0)} / ₱${b.amountLimit.toStringAsFixed(0)}',
                      progress: progress,
                      progressColor: isOver ? Colors.red : Colors.blue,
                      onDelete: () async {
                        await DatabaseService.deleteBudget(b);
                        onRefresh();
                      },
                    );
                  }).toList(),
                ),
          ),
        ),

        // Goals Section
        SliverToBoxAdapter(
          child: _SectionCard(
            title: 'Savings Goals',
            icon: Icons.flag_outlined,
            color: Colors.green,
            count: goals.length,
            onAdd: () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddGoalScreen(accountKey: accountKey)));
              if (result == true) onRefresh();
            },
            child: goals.isEmpty 
              ? const _EmptyState(icon: Icons.flag_outlined, message: 'No savings goals')
              : Column(
                  children: goals.map((g) {
                    final progress = g.targetAmount > 0 ? (g.savedAmount / g.targetAmount).clamp(0.0, 1.0) : 0.0;
                    return _PlanningItem(
                      title: g.name,
                      subtitle: 'Target: ₱${g.targetAmount.toStringAsFixed(0)}',
                      trailingText: '₱${g.savedAmount.toStringAsFixed(0)} saved',
                      progress: progress,
                      progressColor: Colors.green,
                      onDelete: () async {
                        await DatabaseService.deleteGoal(g);
                        onRefresh();
                      },
                    );
                  }).toList(),
                ),
          ),
        ),

        // Debts Section
        SliverToBoxAdapter(
          child: _SectionCard(
            title: 'Debts & Loans',
            icon: Icons.handshake_outlined,
            color: Colors.orange,
            count: debts.length,
            onAdd: () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddDebtScreen(accountKey: accountKey)));
              if (result == true) onRefresh();
            },
            child: debts.isEmpty 
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
  final VoidCallback onDelete;

  const _PlanningItem({
    required this.title,
    required this.subtitle,
    required this.trailingText,
    required this.progress,
    required this.progressColor,
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
          const SizedBox(height: 4),
          Text(
            '${(progress * 100).toStringAsFixed(0)}%',
            style: TextStyle(fontSize: 10, color: progressColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final int count;
  final VoidCallback onAdd;
  final Widget child;

  const _SectionCard({
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
