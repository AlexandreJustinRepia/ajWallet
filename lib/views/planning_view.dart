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
import '../models/debt.dart';
import '../widgets/financial_health_strip.dart';
import '../widgets/card_decorator.dart';
import '../widgets/shopping/shopping_lists_dashboard.dart';

import '../services/shopping_service.dart';
import 'planning_view_model.dart';


class PlanningView extends StatefulWidget {
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
  final GlobalKey? shoppingSectionKey;
  final GlobalKey? shoppingAddKey;

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
    this.shoppingSectionKey,
    this.shoppingAddKey,
    this.onReplaySection,
  });

  final Function(String)? onReplaySection;

  @override
  State<PlanningView> createState() => _PlanningViewState();
}

class _PlanningViewState extends State<PlanningView> {
  late final PlanningViewModel _viewModel = PlanningViewModel();

  @override
  void initState() {
    super.initState();
    final accountKey = SessionService.activeAccount?.key as int?;
    if (accountKey != null) {
      _viewModel.init(accountKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        if (_viewModel.isLoading && _viewModel.budgets.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final theme = Theme.of(context);
        final accountKey = SessionService.activeAccount?.key as int?;

        if (accountKey == null) {
          return const Center(child: Text('No active account'));
        }

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
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),

            // ── Health Snapshot Strip ────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24, top: 8),
                child: FinancialHealthStrip(
                  budgetUsedPct: _viewModel.budgetUsedPct,
                  savingsPct: _viewModel.savingsPct,
                  activeDebtAmount: _viewModel.activeDebtAmount,
                ),
              ),
            ),

            // ── Financial Intelligence Panel ─────────────────────────────
            if (_viewModel.insights.isNotEmpty)
              SliverToBoxAdapter(
                child: _IntelligencePanel(insights: _viewModel.insights),
              ),

            // Budgets Section
            SliverToBoxAdapter(
              child: _SectionCard(
                sectionKey: widget.budgetSectionKey,
                addKey: widget.budgetAddKey,
                title: 'Monthly Budgets',
                icon: Icons.pie_chart_outline_rounded,
                color: theme.colorScheme.secondary,
                count: _viewModel.budgets.length,
                onAdd: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddBudgetScreen(accountKey: accountKey),
                    ),
                  );
                  if (result == true) {
                    _viewModel.refresh();
                    widget.onRefresh();
                  }
                },
                onSettings: () async {
                  await Navigator.pushNamed(context, '/category_settings');
                  _viewModel.refresh();
                  widget.onRefresh();
                },
                summary: _viewModel.budgets.any((b) => b.month == DateTime.now().month)

                    ? _BudgetTotalSummary(
                        viewModel: _viewModel,
                      )
                    : null,
                child: (_viewModel.budgets.isEmpty && !widget.isTutorialActive)
                    ? const _EmptyState(
                        icon: Icons.pie_chart_outline_rounded,
                        message: 'No budgets set',
                      )
                    : Column(
                        children: [
                          if (widget.isTutorialActive && _viewModel.budgets.isEmpty)
                            Container(
                              key: widget.budgetIndicatorKey,
                              child: _PlanningItem(
                                title: 'Food & Drinks',
                                subtitle: DateFormat('MMM yyyy').format(DateTime.now()),
                                trailingText: '₱0 / ₱2000',
                                progress: 0.0,
                                progressColor: theme.colorScheme.secondary,
                                onDelete: () {},
                              ),
                            ),
                          ..._viewModel.budgets.asMap().entries.map((entry) {
                            final index = entry.key;
                            final b = entry.value;
                            
                            // USING OPTIMIZED LOOKUP
                            final currentSpending = _viewModel.getBudgetSpending(b);
                            final progress = b.amountLimit > 0
                                ? (currentSpending / b.amountLimit).clamp(0.0, 1.0)
                                : 0.0;
                            final isOver = currentSpending > b.amountLimit;

                            return Container(
                              key: index == 0 ? widget.budgetIndicatorKey : null,
                              child: _PlanningItem(
                                title: b.category,
                                subtitle: DateFormat('MMM yyyy')
                                    .format(DateTime(b.year, b.month)),
                                trailingText:
                                    '₱${currentSpending.toStringAsFixed(0)} / ₱${b.amountLimit.toStringAsFixed(0)}',
                                progress: progress,
                                progressColor: isOver
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.secondary,
                                isOverspent: isOver,
                                onDelete: () async {
                                  await DatabaseService.deleteBudget(b);
                                  _viewModel.refresh();
                                  widget.onRefresh();
                                },
                              ),
                            );
                          }),
                        ],
                      ),
              ),
            ),

            // Shopping List Section
            SliverToBoxAdapter(
              child: _SectionCard(
                sectionKey: widget.shoppingSectionKey,
                addKey: widget.shoppingAddKey,
                title: 'Smart Shopping List',
                icon: Icons.shopping_cart_outlined,
                color: theme.primaryColor,
                count: _viewModel.activeShoppingListsCount,
                onHelp: () => widget.onReplaySection?.call('shopping'),
                onAdd: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShoppingListsDashboard(accountKey: accountKey),
                      ),
                    );
                  _viewModel.refresh();
                  setState(() {});
                },
                child: Builder(
                  builder: (context) {
                    final activeLists = ShoppingService.getShoppingLists(accountKey).where((l) => !l.isSettled).toList();
                    
                    if (activeLists.isEmpty) {
                      return const _EmptyState(
                        icon: Icons.shopping_basket_outlined,
                        message: 'No active shopping lists',
                      );
                    }

                    return Column(
                      children: [
                        ...activeLists.take(3).map((list) {
                          final items = ShoppingService.getShoppingItems(accountKey, listId: list.id);
                          final boughtCount = items.where((i) => i.isBought).length;
                          final totalItems = items.length;
                          final progress = totalItems > 0 ? boughtCount / totalItems : 0.0;
                          
                          return _PlanningItem(
                            title: list.name.isEmpty ? 'Shopping List' : list.name,
                            subtitle: list.storeName ?? 'Any Store',
                            trailingText: '$boughtCount/$totalItems items',
                            progress: progress,
                            progressColor: theme.primaryColor,
                            onPrimaryAction: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ShoppingListsDashboard(accountKey: accountKey),
                                ),
                              );
                              _viewModel.refresh();
                              setState(() {});
                            },
                            primaryActionLabel: 'Open',
                            onDelete: () async {
                              await ShoppingService.deleteShoppingList(list);
                              _viewModel.refresh();
                              setState(() {});
                            },
                          );
                        }),
                        if (activeLists.length > 3)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: TextButton(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ShoppingListsDashboard(accountKey: accountKey),
                                  ),
                                );
                                _viewModel.refresh();
                                setState(() {});
                              },
                              child: Text('View all ${activeLists.length} lists', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // Goals Section
            SliverToBoxAdapter(
              child: _SectionCard(
                sectionKey: widget.goalSectionKey,
                addKey: widget.goalAddKey,
                title: 'Savings Goals',
                icon: Icons.flag_outlined,
                color: theme.primaryColor,
                count: _viewModel.goals.length,
                onAdd: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddGoalScreen(accountKey: accountKey),
                    ),
                  );
                  if (result == true) {
                    _viewModel.refresh();
                    widget.onRefresh();
                  }
                },
                child: (_viewModel.goals.isEmpty && !widget.isTutorialActive)
                    ? const _EmptyState(
                        icon: Icons.flag_outlined,
                        message: 'No savings goals',
                      )
                    : Column(
                        children: [
                          if (widget.isTutorialActive && _viewModel.goals.isEmpty)
                            _PlanningItem(
                              title: 'Vacation',
                              subtitle: 'Target: ₱10000',
                              trailingText: '₱0 saved',
                              progress: 0.0,
                              progressColor: theme.primaryColor,
                              primaryActionLabel: 'Save',
                              primaryActionKey: widget.goalFundKey,
                              onPrimaryAction: () {},
                              secondaryActionLabel: 'Withdraw',
                              secondaryActionKey: widget.goalWithdrawKey,
                              onSecondaryAction: () {},
                              onDelete: () {},
                            ),
                          ..._viewModel.goals.asMap().entries.map((entry) {
                            final index = entry.key;
                            final g = entry.value;
                            final progress = g.targetAmount > 0
                                ? (g.savedAmount / g.targetAmount).clamp(0.0, 1.0)
                                : 0.0;
                            return _PlanningItem(
                              title: g.name,
                              subtitle: 'Target: ₱${g.targetAmount.toStringAsFixed(0)}',
                              trailingText: '₱${g.savedAmount.toStringAsFixed(0)} saved',
                              progress: progress,
                              progressColor: theme.primaryColor,
                              primaryActionLabel: 'Save',
                              primaryActionKey: index == 0 ? widget.goalFundKey : null,
                              onPrimaryAction: () async {
                                final res = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FundGoalScreen(
                                      accountKey: accountKey,
                                      goal: g,
                                      isWithdrawing: false,
                                    ),
                                  ),
                                );
                                if (res == true) {
                                  _viewModel.refresh();
                                  widget.onRefresh();
                                }
                              },
                              secondaryActionLabel: 'Withdraw',
                              secondaryActionKey:
                                  index == 0 ? widget.goalWithdrawKey : null,
                              onSecondaryAction: () async {
                                final res = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FundGoalScreen(
                                      accountKey: accountKey,
                                      goal: g,
                                      isWithdrawing: true,
                                    ),
                                  ),
                                );
                                if (res == true) {
                                  _viewModel.refresh();
                                  widget.onRefresh();
                                }
                              },
                              onDelete: () async {
                                await DatabaseService.deleteGoal(g);
                                _viewModel.refresh();
                                widget.onRefresh();
                              },
                            );
                          }),
                        ],
                      ),
              ),
            ),

            // Debts Section
            SliverToBoxAdapter(
              child: _SectionCard(
                sectionKey: widget.debtSectionKey,
                addKey: widget.debtAddKey,
                title: 'Debts & Loans',
                icon: Icons.handshake_outlined,
                color: Colors.amber[700]!,
                count: _viewModel.debts.length,
                onAdd: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddDebtScreen(accountKey: accountKey),
                    ),
                  );
                  if (result == true) {
                    _viewModel.refresh();
                    widget.onRefresh();
                  }
                },
                child: (_viewModel.debts.isEmpty && !widget.isTutorialActive)
                    ? const _EmptyState(
                        icon: Icons.handshake_outlined,
                        message: 'No active debts',
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_viewModel.youOweDebts.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8, top: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.arrow_drop_down,
                                      color: Colors.red, size: 20),
                                  Text(
                                    'YOU OWE',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: theme.textTheme.bodyMedium?.color
                                          ?.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ..._viewModel.youOweDebts
                                .map((d) => _buildDebtItem(context, d, accountKey)),
                            const SizedBox(height: 16),
                          ],
                          if (_viewModel.owedToYouDebts.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8, top: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.arrow_drop_up,
                                      color: Colors.green, size: 20),
                                  Text(
                                    'OWED TO YOU',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: theme.textTheme.bodyMedium?.color
                                          ?.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ..._viewModel.owedToYouDebts
                                .map((d) => _buildDebtItem(context, d, accountKey)),
                          ],
                        ],
                      ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
    );
  }

  Widget _buildDebtItem(BuildContext context, Debt d, int accountKey) {
    final total = d.totalAmount;
    final paid = d.paidAmount;
    final remaining = total - paid;
    final progress = total > 0 ? (paid / total).clamp(0.0, 1.0) : 0.0;

    return _PlanningItem(
      title: d.personName,
      subtitle: d.dueDate != null
          ? 'Due: ${DateFormat('MMM dd, yyyy').format(d.dueDate!)}'
          : 'No due date',
      trailingText: '₱${remaining.toStringAsFixed(0)}',
      progress: progress,
      progressColor: Colors.amber[700]!,
      primaryActionLabel: d.isOwedToMe ? 'Receive' : 'Pay',
      onPrimaryAction: () async {
        final res = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddTransactionScreen(
              accountKey: accountKey,
              initialType:
                  d.isOwedToMe ? TransactionType.income : TransactionType.expense,
              initialDebtKey: d.key as int,
            ),
          ),
        );
        if (res == true) {
          _viewModel.refresh();
          widget.onRefresh();
        }
      },
      onSecondaryAction: () => _showDebtHistory(context, d, accountKey),
      secondaryActionLabel: 'History',
      secondaryActionIcon: Icons.history_rounded,
      onDelete: () async {
        await DatabaseService.deleteDebt(d);
        _viewModel.refresh();
        widget.onRefresh();
      },
    );
  }

  void _showDebtHistory(BuildContext context, Debt debt, int accountKey) {
    // We already have all transactions in ViewModel. Filter locally for history.
    final transactions = _viewModel.transactions
        .where((t) => t.debtKey == debt.key)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.all(24).copyWith(top: 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (debt.isOwedToMe ? Colors.green : Colors.red)
                            .withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.history_rounded,
                          color: debt.isOwedToMe ? Colors.green : Colors.red),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${debt.personName}\'s History',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          Text(debt.isOwedToMe ? 'Owed to you' : 'You owe',
                              style: TextStyle(
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withValues(alpha: 0.5))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: transactions.isEmpty
                    ? const Center(child: Text('No transaction history yet'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final tx = transactions[index];
                          final isPayment = tx.type ==
                              (debt.isOwedToMe
                                  ? TransactionType.income
                                  : TransactionType.expense);
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: isPayment
                                  ? const Color(0xFF00796B).withValues(alpha: 0.1)
                                  : const Color(0xFFF57C00).withValues(alpha: 0.1),
                              child: Icon(
                                  isPayment
                                      ? Icons.payment_rounded
                                      : Icons.handshake_rounded,
                                  color: isPayment
                                      ? const Color(0xFF00796B)
                                      : const Color(0xFFF57C00),
                                  size: 20),
                            ),
                            title: Text(tx.title,
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                                DateFormat('MMM dd, yyyy • hh:mm a')
                                    .format(tx.date),
                                style: const TextStyle(fontSize: 12)),
                            trailing: Text(
                              '${isPayment ? '+' : ''}₱${tx.amount.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: isPayment
                                    ? theme.primaryColor
                                    : theme.colorScheme.error,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
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
  final IconData? secondaryActionIcon;
  final VoidCallback onDelete;
  final bool isOverspent;

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
    this.secondaryActionIcon,
    required this.onDelete,
    this.isOverspent = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemWidget = Padding(
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
                    Row(
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (isOverspent) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.warning_amber_rounded,
                              size: 14, color: Colors.red),
                        ]
                      ],
                    ),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.5))),
                  ],
                ),
              ),
              Text(trailingText,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, val, _) {
                return LinearProgressIndicator(
                  value: val,
                  backgroundColor: progressColor.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  minHeight: 8,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                    fontSize: 10, color: progressColor, fontWeight: FontWeight.bold),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onSecondaryAction != null) ...[
                    TextButton.icon(
                      key: secondaryActionKey,
                      onPressed: onSecondaryAction,
                      icon: Icon(secondaryActionIcon ?? Icons.remove_circle_outline_rounded,
                          size: 14, color: progressColor.withValues(alpha: 0.7)),
                      label: Text(
                        secondaryActionLabel ?? 'Remove',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: progressColor.withValues(alpha: 0.7)),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        backgroundColor: progressColor.withValues(alpha: 0.05),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (onPrimaryAction != null)
                    TextButton.icon(
                      key: primaryActionKey,
                      onPressed: onPrimaryAction,
                      icon: Icon(Icons.add_circle_outline_rounded,
                          size: 14, color: progressColor),
                      label: Text(
                        primaryActionLabel ?? 'Add',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: progressColor),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        backgroundColor: progressColor.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return isOverspent ? _ShakeWidget(animate: true, child: itemWidget) : itemWidget;
  }
}

class _ShakeWidget extends StatefulWidget {
  final Widget child;
  final bool animate;

  const _ShakeWidget({required this.child, required this.animate});

  @override
  State<_ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<_ShakeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _animation = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 10.0).chain(CurveTween(curve: Curves.easeOut)),
          weight: 1),
      TweenSequenceItem(
          tween:
              Tween(begin: 10.0, end: -10.0).chain(CurveTween(curve: Curves.easeInOut)),
          weight: 2),
      TweenSequenceItem(
          tween:
              Tween(begin: -10.0, end: 10.0).chain(CurveTween(curve: Curves.easeInOut)),
          weight: 2),
      TweenSequenceItem(
          tween:
              Tween(begin: 10.0, end: -10.0).chain(CurveTween(curve: Curves.easeInOut)),
          weight: 2),
      TweenSequenceItem(
          tween: Tween(begin: -10.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
          weight: 1),
    ]).animate(_controller);

    if (widget.animate) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_animation.value, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _BudgetTotalSummary extends StatelessWidget {
  final PlanningViewModel viewModel;

  const _BudgetTotalSummary({
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final thisMonthBudgets = viewModel.budgets
        .where((b) => b.month == now.month && b.year == now.year)
        .toList();

    double totalSpent = 0;
    double totalLimit = 0;
    for (var b in thisMonthBudgets) {
      totalLimit += b.amountLimit;
      totalSpent += viewModel.getBudgetSpending(b);
    }

    final theme = Theme.of(context);
    final pct = totalLimit > 0 ? (totalSpent / totalLimit * 100).clamp(0.0, 100.0) : 0.0;
    final isOver = totalSpent > totalLimit;
    final barColor = isOver ? const Color(0xFFC62828) : const Color(0xFF2E7D32);
    final remaining = (totalLimit - totalSpent).clamp(0.0, double.infinity);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: barColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: barColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL THIS MONTH',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),

                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: barColor.withValues(alpha: 0.1),

                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isOver ? 'OVER BUDGET' : '${pct.toStringAsFixed(0)}% used',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: barColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₱${totalSpent.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: barColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '/ ₱${totalLimit.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const Spacer(),
              if (!isOver)
                Text(
                  '₱${remaining.toStringAsFixed(0)} left',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.7),
                  ),
                )
              else
                Text(
                  '₱${(totalSpent - totalLimit).toStringAsFixed(0)} over',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: (pct / 100).clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (_, val, _) => LinearProgressIndicator(
                value: val,
                minHeight: 8,
                backgroundColor: barColor.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
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
  final Widget? summary;
  final VoidCallback? onSettings;
  final VoidCallback? onHelp;

  const _SectionCard({
    this.sectionKey,
    this.addKey,
    required this.title,
    required this.icon,
    required this.color,
    required this.count,
    required this.onAdd,
    required this.child,
    this.summary,
    this.onSettings,
    this.onHelp,
  });


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: CardDecorator(
        child: Container(
          key: sectionKey,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.dividerColor, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
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
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        if (count > 0)
                          Text('$count active',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withValues(alpha: 0.5))),
                      ],
                    ),
                  ),
                  if (onHelp != null)
                    IconButton(
                      icon: const Icon(Icons.help_outline_rounded, size: 20),
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                      onPressed: onHelp,
                    ),
                  if (onSettings != null)
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, size: 20),
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                      onPressed: onSettings,
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
              summary ?? const SizedBox.shrink(),
              child,
            ],
          ),
        ),
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
                  color: theme.primaryColor.withValues(alpha: 0.1),
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
                  color: theme.primaryColor.withValues(alpha: 0.8),
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

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: CardDecorator(
        child: Container(
          width: 220,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withValues(alpha: 0.25),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.07),
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
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(insight.icon, size: 16, color: color),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
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
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color.withValues(
                        alpha: insight.urgency == InsightUrgency.high
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
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
