import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import 'financial_insights_service.dart';

enum AIIntent {
  spendingTotal,
  spendingCategory,
  largestExpense,
  runway,
  anomalies,
  recurring,
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
  static AIResponse processQuery(String query, List<Transaction> transactions, double balance) {
    final lowerQuery = query.toLowerCase();
    final expenses = transactions.where((t) => t.type == TransactionType.expense).toList();

    if (lowerQuery.contains('how long') || lowerQuery.contains('last') || lowerQuery.contains('runway')) {
      return _processRunway(expenses, balance);
    } else if (lowerQuery.contains('largest') || lowerQuery.contains('biggest') || lowerQuery.contains('highest')) {
      return _processLargest(expenses);
    } else if (lowerQuery.contains('unusual') || lowerQuery.contains('anomaly') || lowerQuery.contains('spike')) {
      return _processAnomalies(expenses);
    } else if (lowerQuery.contains('recurring') || lowerQuery.contains('often')) {
      return _processRecurring(expenses);
    } else if (lowerQuery.contains('spent') || lowerQuery.contains('spending') || lowerQuery.contains('total')) {
      return _processSpending(lowerQuery, expenses);
    }

    return AIResponse(
      result: "I'm not quite sure how to analyze that yet.",
      insight: "Try asking about your total spending, largest expense, or how long your balance will last.",
      intent: AIIntent.unknown,
      isPositive: false,
    );
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

  static AIResponse _processLargest(List<Transaction> expenses) {
    final range = DateTimeRange(start: DateTime.now().subtract(const Duration(days: 30)), end: DateTime.now().add(const Duration(days: 1)));
    final largest = FinancialInsightsService.getLargestExpense(expenses, range);

    if (largest == null) {
      return AIResponse(
        result: "No expenses found",
        insight: "I couldn't find any outgoing transactions in the last 30 days.",
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

  static AIResponse _processSpending(String query, List<Transaction> expenses) {
    DateTimeRange range;
    String timeframe = "this month";

    if (query.contains('week')) {
      range = DateTimeRange(start: DateTime.now().subtract(const Duration(days: 7)), end: DateTime.now().add(const Duration(days: 1)));
      timeframe = "this week";
    } else if (query.contains('today')) {
      range = DateTimeRange(start: DateTime.now().subtract(const Duration(days: 0)), end: DateTime.now().add(const Duration(days: 1)));
      timeframe = "today";
    } else {
      range = DateTimeRange(start: DateTime.now().subtract(const Duration(days: 30)), end: DateTime.now().add(const Duration(days: 1)));
    }

    // Check for category
    final categories = ['food', 'shopping', 'transfers', 'housing', 'bills', 'entertainment', 'health', 'travel', 'others'];
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
}
