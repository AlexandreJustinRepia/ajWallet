import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../models/budget.dart';
import '../models/goal.dart';
import '../models/debt.dart';
import '../models/wallet.dart';

/// Urgency levels used to sort insights, highest first.
enum InsightUrgency { high, medium, low }

/// A single actionable insight for the Planning page.
class PlanningInsight {
  final String message;
  final IconData icon;
  final Color color;
  final String badgeLabel;
  final InsightUrgency urgency;

  const PlanningInsight({
    required this.message,
    required this.icon,
    required this.color,
    required this.badgeLabel,
    this.urgency = InsightUrgency.low,
  });
}

class PlanningIntelligenceService {
  /// Maximum number of insights to surface at once so we don't overwhelm.
  static const int _maxInsights = 6;

  static List<PlanningInsight> generate({
    required List<Transaction> transactions,
    required List<Budget> budgets,
    required List<Goal> goals,
    required List<Debt> debts,
    required double totalBalance,
    required List<Wallet> wallets,
  }) {
    final insights = <PlanningInsight>[];

    final expenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();
    final income = transactions
        .where((t) => t.type == TransactionType.income)
        .toList();

    // --- 1. Budget Burn Rate (most urgent) ---
    insights.addAll(_budgetBurnRateInsights(expenses, budgets));

    // --- 2. Unallocated Cash ---
    final unallocated = _unallocatedCashInsight(budgets, goals, totalBalance, expenses);
    if (unallocated != null) insights.add(unallocated);

    // --- 3. Goal Accelerator ---
    insights.addAll(_goalAcceleratorInsights(goals, income, expenses));

    // --- 4. Goal Near Completion ---
    insights.addAll(_goalNearCompletionInsights(goals));

    // --- 5. Overdue Debts ---
    insights.addAll(_overdueDebtInsights(debts));

    // --- 6. Budget On-Track (positive reinforcement) ---
    insights.addAll(_budgetOnTrackInsights(expenses, budgets));

    // Sort by urgency (high → medium → low) and cap at max.
    insights.sort((a, b) => a.urgency.index.compareTo(b.urgency.index));
    return insights.take(_maxInsights).toList();
  }

  // ---------------------------------------------------------------------------
  // 1. Budget Burn Rate
  //    "You're likely to exceed your Food budget in 5 days"
  // ---------------------------------------------------------------------------
  static List<PlanningInsight> _budgetBurnRateInsights(
    List<Transaction> expenses,
    List<Budget> budgets,
  ) {
    final now = DateTime.now();
    final thisMonthBudgets =
        budgets.where((b) => b.month == now.month && b.year == now.year).toList();
    if (thisMonthBudgets.isEmpty || expenses.isEmpty) return [];

    final insights = <PlanningInsight>[];

    for (final b in thisMonthBudgets) {
      final monthExpenses = expenses.where(
        (e) =>
            (e.budgetKey == b.key ||
                (e.category == b.category &&
                    e.date.month == now.month &&
                    e.date.year == now.year)) &&
            e.type == TransactionType.expense,
      );

      final spent = monthExpenses.fold(0.0, (s, e) => s + e.amount);
      final remaining = b.amountLimit - spent;

      if (remaining <= 0) {
        // Already exceeded
        insights.add(PlanningInsight(
          message:
              'Your ${b.category} budget is over by ₱${(-remaining).toStringAsFixed(0)}.',
          icon: Icons.warning_amber_rounded,
          color: const Color(0xFFC62828), // Deep Red
          badgeLabel: 'OVER BUDGET',
          urgency: InsightUrgency.high,
        ));
        continue;
      }

      // Daily spending rate for this category this month
      final daysElapsed = now.day;
      if (daysElapsed == 0) continue;
      final dailyRate = spent / daysElapsed;

      if (dailyRate <= 0) continue;

      final daysUntilExceeded = (remaining / dailyRate).floor();
      final daysLeftInMonth =
          DateTime(now.year, now.month + 1, 0).day - now.day;

      if (daysUntilExceeded <= daysLeftInMonth) {
        // Will likely exceed budget before month end
        final urgency =
            daysUntilExceeded <= 3 ? InsightUrgency.high : InsightUrgency.medium;
        insights.add(PlanningInsight(
          message: daysUntilExceeded <= 0
              ? 'At this pace your ${b.category} budget will be exceeded today.'
              : 'You\'re likely to exceed your ${b.category} budget in $daysUntilExceeded day${daysUntilExceeded == 1 ? '' : 's'}.',
          icon: Icons.trending_up_rounded,
          color: daysUntilExceeded <= 3 ? const Color(0xFFC62828) : const Color(0xFFF57C00),
          badgeLabel: 'BUDGET RISK',
          urgency: urgency,
        ));
      }
    }

    return insights;
  }

  // ---------------------------------------------------------------------------
  // 2. Unallocated Cash
  //    "You have ₱3,200 unallocated this month"
  // ---------------------------------------------------------------------------
  static PlanningInsight? _unallocatedCashInsight(
    List<Budget> budgets,
    List<Goal> goals,
    double totalBalance,
    List<Transaction> expenses,
  ) {
    if (totalBalance <= 0) return null;

    final now = DateTime.now();

    // Sum up all active budget limits this month
    final totalBudgeted = budgets
        .where((b) => b.month == now.month && b.year == now.year)
        .fold(0.0, (s, b) => s + b.amountLimit);

    // Sum up all outstanding savings goals
    final totalGoalRemaining = goals
        .where((g) => g.savedAmount < g.targetAmount)
        .fold(0.0, (s, g) => s + (g.targetAmount - g.savedAmount));

    final totalAllocated = totalBudgeted + totalGoalRemaining;
    final unallocated = totalBalance - totalAllocated;

    // Only surface if meaningfully unallocated (more than ₱500)
    if (unallocated > 500) {
      return PlanningInsight(
        message:
            'You have ₱${unallocated.toStringAsFixed(0)} unallocated this month. Consider setting a budget or adding to a goal.',
        icon: Icons.savings_outlined,
        color: const Color(0xFF00796B), // Botanical Teal
        badgeLabel: 'UNALLOCATED',
        urgency: InsightUrgency.medium,
      );
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // 3. Goal Accelerator
  //    "Save ₱500 more/week to reach your Laptop goal 2 weeks earlier"
  // ---------------------------------------------------------------------------
  static List<PlanningInsight> _goalAcceleratorInsights(
    List<Goal> goals,
    List<Transaction> income,
    List<Transaction> expenses,
  ) {
    if (goals.isEmpty) return [];

    final now = DateTime.now();
    final last30Days = now.subtract(const Duration(days: 30));

    final recentIncome = income
        .where((t) => t.date.isAfter(last30Days))
        .fold(0.0, (s, t) => s + t.amount);
    final recentExpenses = expenses
        .where((t) => t.date.isAfter(last30Days))
        .fold(0.0, (s, t) => s + t.amount);

    final netMonthly = recentIncome - recentExpenses;
    if (netMonthly <= 0) return [];

    final insights = <PlanningInsight>[];

    for (final g in goals.where((g) => g.savedAmount < g.targetAmount)) {
      final remaining = g.targetAmount - g.savedAmount;
      final monthsAtCurrentRate = (remaining / netMonthly).ceil();

      // Simulate saving ₱500 more per month
      final boostAmount = 500.0;
      final boostedMonthly = netMonthly + boostAmount;
      final monthsWithBoost = (remaining / boostedMonthly).ceil();
      final monthsSaved = monthsAtCurrentRate - monthsWithBoost;

      if (monthsSaved >= 1) {
        final weeklyBoost = (boostAmount / 4).toStringAsFixed(0);
        insights.add(PlanningInsight(
          message:
              'Save ₱$weeklyBoost more/week to reach your "${g.name}" goal $monthsSaved month${monthsSaved == 1 ? '' : 's'} earlier.',
          icon: Icons.rocket_launch_rounded,
          color: const Color(0xFF2E7D32), // Forest Green
          badgeLabel: 'GOAL BOOST',
          urgency: InsightUrgency.low,
        ));
      }
    }

    return insights;
  }

  // ---------------------------------------------------------------------------
  // 4. Goal Near Completion
  //    "You're 92% toward your Vacation goal — almost there!"
  // ---------------------------------------------------------------------------
  static List<PlanningInsight> _goalNearCompletionInsights(List<Goal> goals) {
    return goals
        .where((g) =>
            g.targetAmount > 0 &&
            g.savedAmount < g.targetAmount &&
            (g.savedAmount / g.targetAmount) >= 0.85)
        .map((g) {
      final pct = ((g.savedAmount / g.targetAmount) * 100).toStringAsFixed(0);
      return PlanningInsight(
        message:
            'You\'re $pct% toward your "${g.name}" goal — almost there! ₱${(g.targetAmount - g.savedAmount).toStringAsFixed(0)} left.',
        icon: Icons.flag_rounded,
        color: const Color(0xFF2E7D32), // Forest Green
        badgeLabel: 'NEARLY DONE',
        urgency: InsightUrgency.low,
      );
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // 5. Overdue Debts
  //    "Your debt to Juan is past its due date"
  // ---------------------------------------------------------------------------
  static List<PlanningInsight> _overdueDebtInsights(List<Debt> debts) {
    final now = DateTime.now();
    return debts
        .where((d) =>
            d.dueDate != null &&
            d.dueDate!.isBefore(now) &&
            d.paidAmount < d.totalAmount)
        .map((d) {
      final daysOverdue = now.difference(d.dueDate!).inDays;
      final label = d.isOwedToMe ? 'receivable from' : 'payable to';
      return PlanningInsight(
        message:
            'Your ₱${(d.totalAmount - d.paidAmount).toStringAsFixed(0)} $label ${d.personName} is $daysOverdue day${daysOverdue == 1 ? '' : 's'} past due.',
        icon: Icons.schedule_rounded,
        color: const Color(0xFFC62828), // Deep Red
        badgeLabel: 'OVERDUE',
        urgency: InsightUrgency.high,
      );
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // 6. Budget On-Track (positive reinforcement)
  //    "Great! Your Groceries budget is on track for the month"
  // ---------------------------------------------------------------------------
  static List<PlanningInsight> _budgetOnTrackInsights(
    List<Transaction> expenses,
    List<Budget> budgets,
  ) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final monthProgress = now.day / daysInMonth;

    final thisMonthBudgets =
        budgets.where((b) => b.month == now.month && b.year == now.year).toList();
    if (thisMonthBudgets.isEmpty) return [];

    final insights = <PlanningInsight>[];

    for (final b in thisMonthBudgets) {
      final spent = expenses
          .where((e) =>
              (e.budgetKey == b.key ||
                  (e.category == b.category &&
                      e.date.month == now.month &&
                      e.date.year == now.year)) &&
              e.type == TransactionType.expense)
          .fold(0.0, (s, e) => s + e.amount);

      final budgetProgress = b.amountLimit > 0 ? spent / b.amountLimit : 0.0;

      // If spending rate is 20%+ below the expected proportional usage → on track
      if (budgetProgress < (monthProgress * 0.8) && spent > 0) {
        insights.add(PlanningInsight(
          message:
              'Great pace! Your ${b.category} budget is well under control this month.',
          icon: Icons.check_circle_outline_rounded,
          color: const Color(0xFF2E7D32), // Forest Green
          badgeLabel: 'ON TRACK',
          urgency: InsightUrgency.low,
        ));
        break; // Only show one positive reinforcement to avoid clutter
      }
    }

    return insights;
  }
}
