import 'package:flutter/material.dart';
import '../services/session_service.dart';
import '../services/database_service.dart';
import '../screens/add_budget_screen.dart';
import '../screens/add_goal_screen.dart';
import '../screens/add_debt_screen.dart';

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
              ? _EmptyState(icon: Icons.pie_chart_outline_rounded, message: 'No budgets set')
              : Column(
                  children: budgets.map((b) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${b.category} • ${b.month}/${b.year}'),
                    subtitle: Text('Limit: ₱${b.amountLimit.toStringAsFixed(2)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await DatabaseService.deleteBudget(b);
                        onRefresh();
                      },
                    ),
                  )).toList(),
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
              ? _EmptyState(icon: Icons.flag_outlined, message: 'No savings goals')
              : Column(
                  children: goals.map((g) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(g.name),
                    subtitle: Text('₱${g.savedAmount.toStringAsFixed(2)} / ₱${g.targetAmount.toStringAsFixed(2)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await DatabaseService.deleteGoal(g);
                        onRefresh();
                      },
                    ),
                  )).toList(),
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
              ? _EmptyState(icon: Icons.handshake_outlined, message: 'No active debts')
              : Column(
                  children: debts.map((d) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(d.personName),
                    subtitle: Text('${d.isOwedToMe ? 'Owes you' : 'You owe'} ₱${(d.totalAmount - d.paidAmount).toStringAsFixed(2)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await DatabaseService.deleteDebt(d);
                        onRefresh();
                      },
                    ),
                  )).toList(),
                ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
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
