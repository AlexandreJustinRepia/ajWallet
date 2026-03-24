import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../models/budget.dart';
import '../models/goal.dart';
import '../models/debt.dart';

class Insight {
  final String message;
  final IconData icon;
  final Color color;

  Insight({
    required this.message,
    required this.icon,
    this.color = Colors.blue,
  });
}

class FinancialInsightsService {
  static List<Insight> generateInsights(List<Transaction> transactions, double currentBalance) {
    if (transactions.isEmpty) return [];

    final insights = <Insight>[];

    final expenses = transactions.where((t) => t.type == TransactionType.expense).toList();
    if (expenses.isEmpty) return [];

    // 1. Weekly spending trends
    final weeklyTrend = _calculateWeeklyTrend(expenses);
    if (weeklyTrend != null) insights.add(weeklyTrend);

    // 2. Spending spikes
    final spike = _detectSpikes(expenses);
    if (spike != null) insights.add(spike);

    // 3. Most frequent expense category
    final topCategory = _getTopCategory(expenses);
    if (topCategory != null) insights.add(topCategory);

    // 4. Daily average spending
    final dailyAvg = _calculateDailyAverage(expenses);
    if (dailyAvg != null) insights.add(dailyAvg);

    // 5. Predicted days until balance reaches zero
    final prediction = _predictExhaustion(expenses, currentBalance);
    if (prediction != null) insights.add(prediction);

    return insights;
  }

  static Insight? _calculateWeeklyTrend(List<Transaction> expenses) {
    final now = DateTime.now();
    final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));

    double thisWeekTotal = 0;
    double lastWeekTotal = 0;

    for (var tx in expenses) {
      if (tx.date.isAfter(thisWeekStart)) {
        thisWeekTotal += tx.amount;
      } else if (tx.date.isAfter(lastWeekStart) && tx.date.isBefore(thisWeekStart)) {
        lastWeekTotal += tx.amount;
      }
    }

    if (lastWeekTotal == 0) return null;

    final diff = ((thisWeekTotal - lastWeekTotal) / lastWeekTotal) * 100;
    final isIncrease = diff > 0;
    
    return Insight(
      message: isIncrease 
          ? "Reflecting on this week's pace may help find balance" 
          : "Your spending has been more intentional this week",
      icon: isIncrease ? Icons.trending_up_rounded : Icons.trending_down_rounded,
      color: isIncrease ? Colors.grey : Colors.green,
    );
  }

  static Insight? _detectSpikes(List<Transaction> expenses) {
    if (expenses.isEmpty) return null;

    final firstDate = expenses.map((e) => e.date).reduce((a, b) => a.isBefore(b) ? a : b);
    final days = DateTime.now().difference(firstDate).inDays + 1;
    if (days < 3) return null;

    final totalExpense = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final avgDaily = totalExpense / days;
    
    // Check for today's spending spike
    final today = DateTime.now();
    final todayTotal = expenses.where((e) => e.date.year == today.year && e.date.month == today.month && e.date.day == today.day)
        .fold(0.0, (sum, e) => sum + e.amount);

    if (avgDaily > 0 && todayTotal > (avgDaily * 2.5)) {
      return Insight(
        message: "A subtle spending spike was detected today",
        icon: Icons.bolt_rounded,
        color: Colors.grey,
      );
    }
    return null;
  }

  static Insight? _getTopCategory(List<Transaction> expenses) {
    if (expenses.isEmpty) return null;

    final categoryCounts = <String, int>{};
    for (var tx in expenses) {
      categoryCounts[tx.category] = (categoryCounts[tx.category] ?? 0) + 1;
    }

    final topCategory = categoryCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    return Insight(
      message: "$topCategory accounts for most of your outflows",
      icon: Icons.pie_chart_outline_rounded,
      color: Colors.grey,
    );
  }

  static Insight? _calculateDailyAverage(List<Transaction> expenses) {
    if (expenses.isEmpty) return null;

    final firstDate = expenses.map((e) => e.date).reduce((a, b) => a.isBefore(b) ? a : b);
    final days = DateTime.now().difference(firstDate).inDays + 1;

    final totalExpense = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final avg = totalExpense / days;

    return Insight(
      message: "Daily average spending sits at ₱${avg.toStringAsFixed(2)}",
      icon: Icons.calendar_today_rounded,
      color: Colors.grey,
    );
  }

  static Insight? _predictExhaustion(List<Transaction> expenses, double balance) {
    if (expenses.isEmpty || balance <= 0) return null;

    final firstDate = expenses.map((e) => e.date).reduce((a, b) => a.isBefore(b) ? a : b);
    final days = DateTime.now().difference(firstDate).inDays + 1;
    
    // We need at least a few days of data for a realistic prediction
    if (days < 3) return null;

    final totalExpense = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final avgDaily = totalExpense / days;

    if (avgDaily <= 0) return null;

    final daysRemaining = (balance / avgDaily).floor();

    return Insight(
      message: daysRemaining < 7 
          ? "Pacing your outflows may extend your runway" 
          : "Your current runway is approximately $daysRemaining days",
      icon: Icons.hourglass_bottom_rounded,
      color: daysRemaining < 7 ? Colors.orange.withOpacity(0.7) : Colors.grey,
    );
  }

  static Map<String, double> getCategoryData(List<Transaction> expenses) {
    final totals = <String, double>{};
    for (var tx in expenses) {
      totals[tx.category] = (totals[tx.category] ?? 0) + tx.amount;
    }
    return totals;
  }

  static List<double> getWeeklyTrendLineData(List<Transaction> expenses) {
    final now = DateTime.now();
    final data = List.generate(7, (_) => 0.0);
    
    for (var tx in expenses) {
      final daysDiff = now.difference(tx.date).inDays;
      if (daysDiff >= 0 && daysDiff < 7) {
        data[6 - daysDiff] += tx.amount;
      }
    }
    return data;
  }

  // AI Dedicated Methods
  static double getSpendingForCategory(List<Transaction> expenses, String category, DateTimeRange range) {
    return expenses
        .where((e) => e.category.toLowerCase() == category.toLowerCase() && 
                      e.date.isAfter(range.start) && 
                      e.date.isBefore(range.end))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  static double getTotalSpending(List<Transaction> expenses, DateTimeRange range) {
    return expenses
        .where((e) => e.date.isAfter(range.start) && e.date.isBefore(range.end))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  static Transaction? getLargestExpense(List<Transaction> expenses, DateTimeRange range) {
    final rangeExpenses = expenses.where((e) => e.date.isAfter(range.start) && e.date.isBefore(range.end)).toList();
    if (rangeExpenses.isEmpty) return null;
    return rangeExpenses.reduce((a, b) => a.amount > b.amount ? a : b);
  }

  static List<Transaction> getAnomalies(List<Transaction> expenses) {
    if (expenses.isEmpty) return [];
    final avg = expenses.fold(0.0, (sum, e) => sum + e.amount) / expenses.length;
    // Anomaly defined as 3x the average transaction amount
    return expenses.where((e) => e.amount > (avg * 3)).toList();
  }

  static List<String> getRecurringCategories(List<Transaction> expenses) {
    if (expenses.isEmpty) return [];
    final categoryCounts = <String, int>{};
    for (var tx in expenses) {
      categoryCounts[tx.category] = (categoryCounts[tx.category] ?? 0) + 1;
    }
    return categoryCounts.entries.where((e) => e.value >= 3).map((e) => e.key).toList();
  }

  static List<Map<String, dynamic>> detectSubscriptions(List<Transaction> expenses) {
    final groups = <String, List<Transaction>>{};
    for (var tx in expenses) {
      final key = '${tx.category}_${tx.amount.toStringAsFixed(0)}';
      groups.putIfAbsent(key, () => []).add(tx);
    }

    final subscriptions = <Map<String, dynamic>>[];
    for (var transactions in groups.values) {
      if (transactions.length < 2) continue;
      transactions.sort((a, b) => a.date.compareTo(b.date));
      
      int monthlyCount = 0;
      for (int i = 0; i < transactions.length - 1; i++) {
        final diff = transactions[i+1].date.difference(transactions[i].date).inDays;
        if (diff >= 25 && diff <= 35) monthlyCount++;
      }

      if (monthlyCount >= 1) {
        subscriptions.add({
          'name': transactions.first.title,
          'amount': transactions.first.amount,
          'category': transactions.first.category,
          'confidence': monthlyCount >= 2 ? 'high' : 'medium',
        });
      }
    }
    return subscriptions;
  }

  static Map<String, dynamic> projectCashflow(List<Transaction> expenses, double balance, List<Budget> budgets) {
    if (expenses.isEmpty) return {'days': -1};

    final firstDate = expenses.map((e) => e.date).reduce((a, b) => a.isBefore(b) ? a : b);
    final historyDays = DateTime.now().difference(firstDate).inDays + 1;
    final totalExpense = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final avgDaily = historyDays >= 3 ? totalExpense / historyDays : 0.0;

    if (avgDaily <= 0) return {'days': -1};

    final now = DateTime.now();
    double remainingBudgeted = 0;
    for (var budget in budgets.where((b) => b.month == now.month && b.year == now.year)) {
      final spent = expenses.where((e) => e.category == budget.category && e.date.month == now.month).fold(0.0, (sum, e) => sum + e.amount);
      if (budget.amountLimit > spent) remainingBudgeted += (budget.amountLimit - spent);
    }

    final simpleDays = (balance / avgDaily).floor();
    if (remainingBudgeted > balance) {
      return {'days': (balance / avgDaily).floor(), 'isRisky': true, 'warning': 'Your committed budgets exceed your current balance.'};
    }

    return {'days': simpleDays, 'isRisky': simpleDays < 10, 'remainingBudgeted': remainingBudgeted};
  }

  static double getTrendDirection(List<Transaction> expenses) {
    final now = DateTime.now();
    final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
    double thisWeekTotal = expenses.where((tx) => tx.date.isAfter(thisWeekStart)).fold(0.0, (sum, tx) => sum + tx.amount);
    double lastWeekTotal = expenses.where((tx) => tx.date.isAfter(lastWeekStart) && tx.date.isBefore(thisWeekStart)).fold(0.0, (sum, tx) => sum + tx.amount);
    if (lastWeekTotal == 0) return 0.0;
    return ((thisWeekTotal - lastWeekTotal) / lastWeekTotal) * 100;
  }

  static Map<int, double> getDailyAveragesByDayOfWeek(List<Transaction> expenses) {
    if (expenses.isEmpty) return {};
    final dayTotals = <int, double>{};
    final dayCounts = <int, Set<String>>{};
    for (var tx in expenses) {
      final dow = tx.date.weekday;
      final dateStr = '${tx.date.year}-${tx.date.month}-${tx.date.day}';
      dayTotals[dow] = (dayTotals[dow] ?? 0.0) + tx.amount;
      dayCounts.putIfAbsent(dow, () => {}).add(dateStr);
    }
    final avgs = <int, double>{};
    for (var dow in dayTotals.keys) avgs[dow] = dayTotals[dow]! / dayCounts[dow]!.length;
    return avgs;
  }

  static Map<String, dynamic> simulateImpact({
    required List<Transaction> expenses,
    required double balance,
    required List<Goal> goals,
    double? dailySavingsIncrease,
    double? categoryReductionAmount,
    String? reductionCategory,
  }) {
    final firstDate = expenses.isEmpty ? DateTime.now() : expenses.map((e) => e.date).reduce((a, b) => a.isBefore(b) ? a : b);
    final historyDays = DateTime.now().difference(firstDate).inDays + 1;
    final totalExpense = expenses.fold(0.0, (sum, e) => sum + e.amount);
    double avgDaily = historyDays >= 3 ? totalExpense / historyDays : 0.0;

    if (avgDaily <= 0) return {'error': 'Insufficient history'};

    // Apply simulation
    double newAvgDaily = avgDaily;
    if (dailySavingsIncrease != null) {
      newAvgDaily = (newAvgDaily - dailySavingsIncrease).clamp(0, double.infinity);
    }
    
    if (categoryReductionAmount != null && reductionCategory != null) {
      final catTotal = expenses.where((e) => e.category.toLowerCase() == reductionCategory.toLowerCase()).fold(0.0, (sum, e) => sum + e.amount);
      final catAvg = catTotal / historyDays;
      final reduction = (categoryReductionAmount / 30).clamp(0, catAvg); // monthly reduction to daily
      newAvgDaily = (newAvgDaily - reduction).clamp(0, double.infinity);
    }

    final currentRunway = (balance / avgDaily).floor();
    final newRunway = newAvgDaily > 0 ? (balance / newAvgDaily).floor() : 999;
    
    final results = <String, dynamic>{
      'runwayExtension': newRunway - currentRunway,
      'goalImpacts': <Map<String, dynamic>>[],
    };

    for (var goal in goals) {
      if (goal.savedAmount >= goal.targetAmount) continue;
      
      final remaining = goal.targetAmount - goal.savedAmount;
      // Assume monthly savings is current (Income - Expenses)
      // For simulation, we just look at the delta in daily burn
      final monthlySavingsDelta = (avgDaily - newAvgDaily) * 30;
      
      results['goalImpacts'].add({
        'goalName': goal.name,
        'monthlySavingsDelta': monthlySavingsDelta,
        'daysSaved': monthlySavingsDelta > 0 ? (remaining / (monthlySavingsDelta / 30)).floor() : 0,
      });
    }

    return results;
  }

  static double suggestBudget(String category, List<Transaction> transactions) {
    final now = DateTime.now();
    final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
    
    final catExpenses = transactions
        .where((t) => t.type == TransactionType.expense && 
                      t.category.toLowerCase() == category.toLowerCase() && 
                      t.date.isAfter(threeMonthsAgo))
        .toList();

    if (catExpenses.isEmpty) return 0.0;

    // Group by month
    final monthlyTotals = <String, double>{};
    for (var tx in catExpenses) {
      final monthKey = '${tx.date.year}-${tx.date.month}';
      monthlyTotals[monthKey] = (monthlyTotals[monthKey] ?? 0.0) + tx.amount;
    }

    if (monthlyTotals.isEmpty) return 0.0;
    
    // Suggest the median of monthly spending
    final values = monthlyTotals.values.toList()..sort();
    return values[values.length ~/ 2];
  }

  static Map<String, dynamic> getDebtPaymentImpact({
    required double amount,
    required double balance,
    required List<Transaction> expenses,
    required List<Budget> budgets,
  }) {
    final currentRunway = projectCashflow(expenses, balance, budgets)['days'] as int;
    final newRunway = projectCashflow(expenses, balance - amount, budgets)['days'] as int;
    
    return {
      'currentRunway': currentRunway,
      'newRunway': newRunway,
      'isRisky': newRunway < 3 && currentRunway >= 3,
      'daysLost': currentRunway - newRunway,
    };
  }

  static Map<String, dynamic>? suggestDebtOptimizations(Debt debt, List<Transaction> transactions) {
    if (debt.isOwedToMe) return null; // Only optimize debts I OWE
    
    final remaining = debt.totalAmount - debt.paidAmount;
    if (remaining <= 0) return null;

    // Calculate spare monthly cashflow (last 30 days)
    final lastMonth = transactions.where((t) => t.date.isAfter(DateTime.now().subtract(const Duration(days: 30))));
    final income = lastMonth.where((t) => t.type == TransactionType.income).fold(0.0, (sum, t) => sum + t.amount);
    final expense = lastMonth.where((t) => t.type == TransactionType.expense).fold(0.0, (sum, t) => sum + t.amount);
    final spare = (income - expense) * 0.2; // Use 20% of spare cash for extra payoff

    if (spare <= 50) return null; // Too little spare cash to suggest

    return {
      'extraAmount': spare,
      'monthsSaved': (remaining / spare).toStringAsFixed(1), // Simplified
    };
  }
}
