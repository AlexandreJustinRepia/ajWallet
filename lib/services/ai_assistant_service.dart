import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../models/goal.dart';
import '../models/debt.dart';
import 'financial_insights_service.dart';

enum AIIntent {
  spendingTotal,
  spendingCategory,
  largestExpense,
  runway,
  anomalies,
  recurring,
  incomeTotal,
  savingsRate,
  debtStatus,
  goalProgress,
  financialAdvice,
  unknown
}

class AIResponse {
  final String result;
  final String insight;
  final AIIntent intent;
  final bool isPositive;

  AIResponse({
    required this.result,
    required this.insight,
    required this.intent,
    this.isPositive = true,
  });
}

class AIAssistantService {
  static AIResponse processQuery({
    required String query,
    required List<Transaction> transactions,
    required double balance,
    List<Goal>? goals,
    List<Debt>? debts,
  }) {
    final lowerQuery = query.toLowerCase();
    final expenses = transactions.where((t) => t.type == TransactionType.expense).toList();
    final income = transactions.where((t) => t.type == TransactionType.income).toList();

    // 1. Detect Intent
    final intent = _detectIntent(lowerQuery);
    final timeframe = _detectTimeframe(lowerQuery);
    final range = _getRangeForTimeframe(timeframe);

    switch (intent) {
      case AIIntent.runway:
        return _processRunway(expenses, balance);
      case AIIntent.largestExpense:
        return _processLargest(expenses, range);
      case AIIntent.anomalies:
        return _processAnomalies(expenses);
      case AIIntent.recurring:
        return _processRecurring(expenses);
      case AIIntent.incomeTotal:
        return _processIncome(income, range, timeframe);
      case AIIntent.spendingTotal:
      case AIIntent.spendingCategory:
        return _processSpending(lowerQuery, expenses, range, timeframe);
      case AIIntent.savingsRate:
        return _processSavingsRate(expenses, income, range);
      case AIIntent.goalProgress:
        return _processGoals(goals ?? []);
      case AIIntent.debtStatus:
        return _processDebts(debts ?? []);
      case AIIntent.financialAdvice:
        return _processAdvice(expenses, income, balance);
      case AIIntent.unknown:
        return AIResponse(
          result: "I'm not quite sure how to analyze that yet.",
          insight: "Try asking about your income, spending habits, savings goals, or for some financial advice.",
          intent: AIIntent.unknown,
          isPositive: false,
        );
    }
  }

  static AIIntent _detectIntent(String query) {
    if (query.contains('runway') || query.contains('how long') || query.contains('last')) return AIIntent.runway;
    if (query.contains('largest') || query.contains('biggest') || query.contains('highest') || query.contains('most expensive')) return AIIntent.largestExpense;
    if (query.contains('unusual') || query.contains('anomaly') || query.contains('spike')) return AIIntent.anomalies;
    if (query.contains('recurring') || query.contains('often') || query.contains('pattern')) return AIIntent.recurring;
    if (query.contains('income') || query.contains('salary') || query.contains('earn') || query.contains('received')) return AIIntent.incomeTotal;
    if (query.contains('save') || query.contains('saving') || query.contains('savings rate')) return query.contains('goal') ? AIIntent.goalProgress : AIIntent.savingsRate;
    if (query.contains('goal') || query.contains('target')) return AIIntent.goalProgress;
    if (query.contains('debt') || query.contains('owe') || query.contains('borrow') || query.contains('lent')) return AIIntent.debtStatus;
    if (query.contains('advice') || query.contains('tip') || query.contains('help') || query.contains('improve')) return AIIntent.financialAdvice;
    if (query.contains('spent') || query.contains('spending') || query.contains('total') || query.contains('cost')) return AIIntent.spendingTotal;
    return AIIntent.unknown;
  }

  static String _detectTimeframe(String query) {
    if (query.contains('today')) return 'today';
    if (query.contains('yesterday')) return 'yesterday';
    if (query.contains('this week')) return 'this week';
    if (query.contains('last week')) return 'last week';
    if (query.contains('this month')) return 'this month';
    if (query.contains('last month')) return 'last month';
    if (query.contains('this year')) return 'this year';
    if (query.contains('all time') || query.contains('ever')) return 'all time';
    return 'this month'; // Default
  }

  static DateTimeRange _getRangeForTimeframe(String timeframe) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    switch (timeframe) {
      case 'today':
        return DateTimeRange(start: today, end: now.add(const Duration(days: 1)));
      case 'yesterday':
        return DateTimeRange(start: today.subtract(const Duration(days: 1)), end: today);
      case 'this week':
        return DateTimeRange(start: today.subtract(Duration(days: now.weekday - 1)), end: now.add(const Duration(days: 1)));
      case 'last week':
        final start = today.subtract(Duration(days: now.weekday + 6));
        return DateTimeRange(start: start, end: start.add(const Duration(days: 7)));
      case 'this month':
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now.add(const Duration(days: 1)));
      case 'last month':
        return DateTimeRange(start: DateTime(now.year, now.month - 1, 1), end: DateTime(now.year, now.month, 1));
      case 'this year':
        return DateTimeRange(start: DateTime(now.year, 1, 1), end: now.add(const Duration(days: 1)));
      case 'all time':
        return DateTimeRange(start: DateTime(2000), end: now.add(const Duration(days: 365)));
      default:
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now.add(const Duration(days: 1)));
    }
  }

  static AIResponse _processRunway(List<Transaction> expenses, double balance) {
    final firstDate = expenses.isEmpty ? DateTime.now() : expenses.map((e) => e.date).reduce((a, b) => a.isBefore(b) ? a : b);
    final days = DateTime.now().difference(firstDate).inDays + 1;
    final totalExpense = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final avgDaily = days >= 3 ? totalExpense / days : 0.0;

    if (avgDaily <= 0) {
      return AIResponse(
        result: "Insufficient data",
        insight: "I need at least 3 days of transactions to project your runway.",
        intent: AIIntent.runway,
        isPositive: false,
      );
    }

    final daysRemaining = (balance / avgDaily).floor();
    return AIResponse(
      result: "$daysRemaining Days",
      insight: daysRemaining < 7 
          ? "Your balance is depleting faster than usual. Consider pacing your outflows." 
          : "Based on your current burn rate, your balance is healthy.",
      intent: AIIntent.runway,
      isPositive: daysRemaining >= 7,
    );
  }

  static AIResponse _processLargest(List<Transaction> expenses, DateTimeRange range) {
    final largest = FinancialInsightsService.getLargestExpense(expenses, range);

    if (largest == null) {
      return AIResponse(
        result: "No expenses found",
        insight: "I couldn't find any outgoing transactions in the selected period.",
        intent: AIIntent.largestExpense,
        isPositive: true,
      );
    }

    return AIResponse(
      result: "₱${largest.amount.toStringAsFixed(2)}",
      insight: "Your largest expense was '${largest.title}' in the ${largest.category} category.",
      intent: AIIntent.largestExpense,
      isPositive: false,
    );
  }

  static AIResponse _processAnomalies(List<Transaction> expenses) {
    final anomalies = FinancialInsightsService.getAnomalies(expenses);
    if (anomalies.isEmpty) {
      return AIResponse(
        result: "Clean Ledger",
        insight: "No unusual spending spikes detected in your recent history.",
        intent: AIIntent.anomalies,
        isPositive: true,
      );
    }

    return AIResponse(
      result: "${anomalies.length} Anomali${anomalies.length > 1 ? 'es' : 'y'}",
      insight: "Detected transactions significantly higher than your average spend.",
      intent: AIIntent.anomalies,
      isPositive: false,
    );
  }

  static AIResponse _processRecurring(List<Transaction> expenses) {
    final categories = FinancialInsightsService.getRecurringCategories(expenses);
    if (categories.isEmpty) {
      return AIResponse(
        result: "No patterns found",
        insight: "Your spending doesn't show any frequent recurring categories yet.",
        intent: AIIntent.recurring,
        isPositive: true,
      );
    }

    return AIResponse(
      result: categories.first,
      insight: "You spend frequently on ${categories.first}. This appears to be a recurring pattern.",
      intent: AIIntent.recurring,
      isPositive: false,
    );
  }

  static AIResponse _processIncome(List<Transaction> income, DateTimeRange range, String timeframe) {
    final total = income
        .where((e) => e.date.isAfter(range.start) && e.date.isBefore(range.end))
        .fold(0.0, (sum, e) => sum + e.amount);

    return AIResponse(
      result: "₱${total.toStringAsFixed(2)}",
      insight: "This is your total earnings for $timeframe.",
      intent: AIIntent.incomeTotal,
      isPositive: total > 0,
    );
  }

  static AIResponse _processSpending(String query, List<Transaction> expenses, DateTimeRange range, String timeframe) {
    final categories = ['food', 'shopping', 'transfers', 'housing', 'bills', 'entertainment', 'health', 'travel', 'transport', 'others'];
    String? foundCategory;
    for (var cat in categories) {
      if (query.contains(cat)) {
        foundCategory = cat;
        break;
      }
    }

    if (foundCategory != null) {
      final total = FinancialInsightsService.getSpendingForCategory(expenses, foundCategory, range);
      return AIResponse(
        result: "₱${total.toStringAsFixed(2)}",
        insight: "Total spent on ${foundCategory.toUpperCase()} $timeframe.",
        intent: AIIntent.spendingCategory,
      );
    } else {
      final total = FinancialInsightsService.getTotalSpending(expenses, range);
      return AIResponse(
        result: "₱${total.toStringAsFixed(2)}",
        insight: "Your total outflows for $timeframe.",
        intent: AIIntent.spendingTotal,
      );
    }
  }

  static AIResponse _processSavingsRate(List<Transaction> expenses, List<Transaction> income, DateTimeRange range) {
    final totalExpense = expenses
        .where((e) => e.date.isAfter(range.start) && e.date.isBefore(range.end))
        .fold(0.0, (sum, e) => sum + e.amount);
    final totalIncome = income
        .where((e) => e.date.isAfter(range.start) && e.date.isBefore(range.end))
        .fold(0.0, (sum, e) => sum + e.amount);

    if (totalIncome <= 0) {
      return AIResponse(
        result: "No income data",
        insight: "I can't calculate your savings rate without recorded income.",
        intent: AIIntent.savingsRate,
        isPositive: false,
      );
    }

    final savings = totalIncome - totalExpense;
    final rate = (savings / totalIncome) * 100;

    return AIResponse(
      result: "${rate.toStringAsFixed(1)}%",
      insight: rate > 20 
          ? "Excellent! You are saving a healthy portion of your income." 
          : "You're saving about ${rate.toStringAsFixed(0)}% of your earnings. Aiming for 20% is a common goal.",
      intent: AIIntent.savingsRate,
      isPositive: rate >= 15,
    );
  }

  static AIResponse _processGoals(List<Goal> goals) {
    if (goals.isEmpty) {
      return AIResponse(
        result: "No active goals",
        insight: "You haven't set any savings goals yet. Setting one can help you stay focused!",
        intent: AIIntent.goalProgress,
        isPositive: false,
      );
    }

    final completed = goals.where((g) => g.savedAmount >= g.targetAmount).length;
    final onTrack = goals.firstWhere((g) => g.savedAmount < g.targetAmount, orElse: () => goals.first);

    return AIResponse(
      result: "${goals.length} Goals",
      insight: completed > 0 
          ? "You've completed $completed goals! '${onTrack.name}' is currently at ${(onTrack.savedAmount / onTrack.targetAmount * 100).toStringAsFixed(0)}%." 
          : "Your goal '${onTrack.name}' is ${(onTrack.savedAmount / onTrack.targetAmount * 100).toStringAsFixed(0)}% complete.",
      intent: AIIntent.goalProgress,
      isPositive: true,
    );
  }

  static AIResponse _processDebts(List<Debt> debts) {
    if (debts.isEmpty) {
      return AIResponse(
        result: "Debt Free",
        insight: "You have no outstanding debts or loans recorded. Great job!",
        intent: AIIntent.debtStatus,
        isPositive: true,
      );
    }

    final iOwe = debts.where((d) => !d.isOwedToMe).fold(0.0, (sum, d) => sum + (d.totalAmount - d.paidAmount));
    final owedMe = debts.where((d) => d.isOwedToMe).fold(0.0, (sum, d) => sum + (d.totalAmount - d.paidAmount));

    return AIResponse(
      result: "₱${iOwe.toStringAsFixed(0)} Due",
      insight: owedMe > 0 
          ? "You owe ₱${iOwe.toStringAsFixed(0)}, while others owe you ₱${owedMe.toStringAsFixed(0)}." 
          : "Your total outstanding debt to others is ₱${iOwe.toStringAsFixed(0)}.",
      intent: AIIntent.debtStatus,
      isPositive: iOwe < owedMe,
    );
  }

  static AIResponse _processAdvice(List<Transaction> expenses, List<Transaction> income, double balance) {
    if (expenses.isEmpty) {
      return AIResponse(
        result: "Keep going!",
        insight: "Start tracking your expenses to get personalized financial advice.",
        intent: AIIntent.financialAdvice,
      );
    }

    final topCat = FinancialInsightsService.getCategoryData(expenses).entries.toList();
    topCat.sort((a, b) => b.value.compareTo(a.value));

    String tip = "Your biggest expense category is ${topCat.first.key}. Try to see if you can find alternatives there.";
    if (balance < 1000) {
      tip = "Your balance is getting low. It might be a good time to review non-essential expenses.";
    } else if (topCat.first.key.toLowerCase() == 'food') {
      tip = "Dining out seems to be a major expense. Meal prepping could save you a significant amount each month.";
    }

    return AIResponse(
      result: "Smart Tip",
      insight: tip,
      intent: AIIntent.financialAdvice,
    );
  }
}
