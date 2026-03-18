import 'package:flutter/material.dart';
import '../models/transaction_model.dart';

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
}
