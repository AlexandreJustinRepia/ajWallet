import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../models/goal.dart';
import '../models/debt.dart';
import '../models/budget.dart';
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
  subscriptions,
  simulation,
  unknown
}

enum AITone {
  calm,
  strict,
  encouraging
}

enum AIActionType {
  createGoal,
  setLimit,
  viewTransactions,
  manageSubscription
}

class AIAction {
  final String label;
  final AIActionType type;
  final dynamic payload;

  AIAction({required this.label, required this.type, this.payload});
}

class AIResponse {
  final String result;
  final String insight;
  final AIIntent intent;
  final bool isPositive;
  final List<AIAction>? actions;
  final AITone tone;

  AIResponse({
    required this.result,
    required this.insight,
    required this.intent,
    this.isPositive = true,
    this.actions,
    this.tone = AITone.calm,
  });
}

class AIAssistantService {
  static AIResponse processQuery({
    required String query,
    required List<Transaction> transactions,
    required double balance,
    List<Goal>? goals,
    List<Debt>? debts,
    List<Budget>? budgets,
  }) {
    final lowerQuery = query.toLowerCase();
    final expenses = transactions.where((t) => t.type == TransactionType.expense).toList();
    final income = transactions.where((t) => t.type == TransactionType.income).toList();
    final allBudgets = budgets ?? [];

    // 1. Detect Intent
    final intent = _detectIntent(lowerQuery);
    final timeframe = _detectTimeframe(lowerQuery);
    final range = _getRangeForTimeframe(timeframe);

    final response = _process(intent, lowerQuery, expenses, income, range, timeframe, balance, goals, debts, allBudgets);
    return _applyAdaptiveTone(response, balance, expenses, allBudgets);
  }

  static AIResponse _process(AIIntent intent, String lowerQuery, List<Transaction> expenses, List<Transaction> income, DateTimeRange range, String timeframe, double balance, List<Goal>? goals, List<Debt>? debts, List<Budget> budgets) {
    switch (intent) {
      case AIIntent.runway:
        return _processRunway(expenses, balance, budgets);
      case AIIntent.largestExpense:
        return _processLargest(expenses, range);
      case AIIntent.anomalies:
        return _processAnomalies(expenses);
      case AIIntent.recurring:
        return _processRecurring(expenses);
      case AIIntent.subscriptions:
        return _processSubscriptions(expenses);
      case AIIntent.simulation:
        return _processSimulation(lowerQuery, expenses, balance, goals ?? []);
      case AIIntent.incomeTotal:
        return _processIncome(income, range, timeframe);
      case AIIntent.spendingTotal:
      case AIIntent.spendingCategory:
        if (lowerQuery.contains('budget for') || lowerQuery.contains('suggest budget')) {
          return _processBudgetSuggestion(lowerQuery, expenses);
        }
        return _processSpending(lowerQuery, expenses, range, timeframe);
      case AIIntent.savingsRate:
        return _processSavingsRate(expenses, income, range);
      case AIIntent.goalProgress:
        return _processGoals(goals ?? [], income, expenses);
      case AIIntent.debtStatus:
        return _processDebts(debts ?? []);
      case AIIntent.financialAdvice:
        return _processAdvice(expenses, income, balance, budgets);
      case AIIntent.unknown:
        return AIResponse(
          result: "I'm not quite sure how to analyze that yet.",
          insight: "Try asking about your 'spending', 'runway', 'goals', or ask a simulation like 'What if I save ₱100 more per day?'",
          intent: AIIntent.unknown,
        );
    }
  }

  static AIIntent _detectIntent(String query) {
    if (query.contains('what if') || query.contains('if i ') || query.contains('simulate')) return AIIntent.simulation;
    if (query.contains('runway') || query.contains('how long') || query.contains('last')) return AIIntent.runway;
    if (query.contains('largest') || query.contains('biggest') || query.contains('highest') || query.contains('most expensive')) return AIIntent.largestExpense;
    if (query.contains('unusual') || query.contains('anomaly') || query.contains('spike')) return AIIntent.anomalies;
    if (query.contains('recurring') || query.contains('often') || query.contains('pattern')) return AIIntent.recurring;
    if (query.contains('income') || query.contains('salary') || query.contains('earn') || query.contains('received')) return AIIntent.incomeTotal;
    if (query.contains('save') || query.contains('saving') || query.contains('savings rate')) return query.contains('goal') ? AIIntent.goalProgress : AIIntent.savingsRate;
    if (query.contains('goal') || query.contains('target')) return AIIntent.goalProgress;
    if (query.contains('subscription') || query.contains('netflix') || query.contains('spotify') || query.contains('monthly bill')) return AIIntent.subscriptions;
    if (query.contains('debt') || query.contains('owe') || query.contains('borrow') || query.contains('lent')) return AIIntent.debtStatus;
    if (query.contains('budget for') || query.contains('suggest budget')) return AIIntent.spendingCategory;
    if (query.contains('advice') || query.contains('tip') || query.contains('help') || query.contains('improve')) return AIIntent.financialAdvice;
    if (query.contains('spent') || query.contains('spending') || query.contains('total') || query.contains('cost')) return AIIntent.spendingTotal;
    return AIIntent.unknown;
  }

  static AIResponse _processBudgetSuggestion(String query, List<Transaction> transactions) {
    String? category;
    final categories = ['food', 'shopping', 'transfers', 'housing', 'bills', 'entertainment', 'health', 'travel', 'transport', 'others'];
    for (var cat in categories) {
      if (query.contains(cat)) {
        category = cat;
        break;
      }
    }

    if (category == null) {
      return AIResponse(
        result: "Select a Category",
        insight: "Which category would you like me to suggest a budget for? (e.g., 'Budget for Food')",
        intent: AIIntent.spendingCategory,
      );
    }

    final suggested = FinancialInsightsService.suggestBudget(category, transactions);
    if (suggested <= 0) {
      return AIResponse(
        result: "Insufficient Data",
        insight: "I don't have enough history for '$category' to suggest a realistic budget yet.",
        intent: AIIntent.spendingCategory,
        isPositive: false,
      );
    }

    return AIResponse(
      result: "₱${suggested.toStringAsFixed(0)} Suggested",
      insight: "Based on your last 3 months, a healthy budget for $category would be ₱${suggested.toStringAsFixed(0)} per month.",
      intent: AIIntent.spendingCategory,
      actions: [AIAction(label: "Set This Budget", type: AIActionType.setLimit)],
    );
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

  static AIResponse _processRunway(List<Transaction> expenses, double balance, List<Budget> budgets) {
    final projection = FinancialInsightsService.projectCashflow(expenses, balance, budgets);
    final daysRemaining = projection['days'] as int;

    if (daysRemaining <= 0) {
      return AIResponse(
        result: "Critical Balance",
        insight: "Your balance is extremely low relative to your spending history.",
        intent: AIIntent.runway,
        isPositive: false,
      );
    }

    String insight = "Based on your current burn rate, your balance is healthy.";
    bool isPositive = true;

    if (daysRemaining < 7) {
      insight = "Critical: You might run out of money in $daysRemaining days if spending continues.";
      isPositive = false;
    } else if (projection['isRisky'] == true) {
      insight = projection['warning'] ?? "Your upcoming budgets exceed your current balance.";
      isPositive = false;
    }

    return AIResponse(
      result: "$daysRemaining Days",
      insight: insight,
      intent: AIIntent.runway,
      isPositive: isPositive,
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

  static AIResponse _processSimulation(String query, List<Transaction> expenses, double balance, List<Goal> goals) {
    double? dailyIncrease;
    double? catReduction;
    String? reductionCat;

    // Very basic extraction
    final saveMatch = RegExp(r'save (?:₱|p)?(\d+)').firstMatch(query);
    if (saveMatch != null) {
      dailyIncrease = double.tryParse(saveMatch.group(1)!);
    }

    final redMatch = RegExp(r'reduce (\w+) by (?:₱|p)?(\d+)').firstMatch(query);
    if (redMatch != null) {
      reductionCat = redMatch.group(1);
      catReduction = double.tryParse(redMatch.group(2)!);
    }

    if (dailyIncrease == null && catReduction == null) {
      return AIResponse(
        result: "Simulation Ready",
        insight: "Try asking: 'What if I save ₱100 more per day?' or 'What if I reduce food by ₱1,000?'",
        intent: AIIntent.simulation,
      );
    }

    final impact = FinancialInsightsService.simulateImpact(
      expenses: expenses,
      balance: balance,
      goals: goals,
      dailySavingsIncrease: dailyIncrease,
      categoryReductionAmount: catReduction,
      reductionCategory: reductionCat,
    );

    if (impact.containsKey('error')) {
      return AIResponse(result: "Error", insight: impact['error'], intent: AIIntent.simulation, isPositive: false);
    }

    final runway = impact['runwayExtension'] as int;
    final goalImpacts = impact['goalImpacts'] as List<Map<String, dynamic>>;
    
    String msg = "If you make those changes:";
    if (runway != 0) msg += "\n• Your runway increases by $runway days.";
    for (var gi in goalImpacts) {
      if (gi['daysSaved'] > 0) msg += "\n• You'll reach '${gi['goalName']}' ${gi['daysSaved']} days sooner!";
    }

    return AIResponse(
      result: "Simulation Result",
      insight: msg,
      intent: AIIntent.simulation,
      actions: [AIAction(label: "Apply Changes", type: AIActionType.setLimit)],
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

  static AIResponse _processSubscriptions(List<Transaction> expenses) {
    final subs = FinancialInsightsService.detectSubscriptions(expenses);
    if (subs.isEmpty) {
      return AIResponse(
        result: "No subscriptions",
        insight: "I haven't detected any monthly recurring subscription patterns in your ledger.",
        intent: AIIntent.subscriptions,
        isPositive: true,
      );
    }

    final first = subs.first;
    return AIResponse(
      result: "${subs.length} Subscriptions",
      insight: "Detected ${first['name']} (₱${first['amount'].toStringAsFixed(0)}) as a monthly recurring expense.",
      intent: AIIntent.subscriptions,
      isPositive: false,
      actions: [
        AIAction(label: "View All", type: AIActionType.viewTransactions, payload: {'category': first['category']}),
      ],
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

  static AIResponse _processGoals(List<Goal> goals, List<Transaction> income, List<Transaction> expenses) {
    if (goals.isEmpty) {
      return AIResponse(
        result: "No active goals",
        insight: "You haven't set any savings goals yet. Setting one can help you stay focused!",
        intent: AIIntent.goalProgress,
        isPositive: false,
        actions: [AIAction(label: "Create Goal", type: AIActionType.createGoal)],
      );
    }

    final onTrack = goals.firstWhere((g) => g.savedAmount < g.targetAmount, orElse: () => goals.first);
    final percent = (onTrack.savedAmount / onTrack.targetAmount * 100).toStringAsFixed(0);
    
    // Calculate time to reach
    final lastMonth = DateTime.now().subtract(const Duration(days: 30));
    final monthlyIncome = income.where((e) => e.date.isAfter(lastMonth)).fold(0.0, (sum, e) => sum + e.amount);
    final monthlyExpense = expenses.where((e) => e.date.isAfter(lastMonth)).fold(0.0, (sum, e) => sum + e.amount);
    final monthlySavings = monthlyIncome - monthlyExpense;

    String prediction = "";
    if (monthlySavings > 0) {
      final remaining = onTrack.targetAmount - onTrack.savedAmount;
      final months = (remaining / monthlySavings).toStringAsFixed(1);
      
      // Strategy B Suggestion
      final fasterSavings = monthlySavings * 1.25;
      final fasterMonths = (remaining / fasterSavings).toStringAsFixed(1);
      final daysSaved = (double.parse(months) * 30 - double.parse(fasterMonths) * 30).floor();

      prediction = "\n\n• Current: Reach in $months months.\n• Strategy B: Increase savings by 25% → reach $daysSaved days sooner!";
    }

    return AIResponse(
      result: "$percent% Complete",
      insight: "Your goal '${onTrack.name}' is $percent% complete.$prediction",
      intent: AIIntent.goalProgress,
      isPositive: true,
      actions: [AIAction(label: "Switch Strategy", type: AIActionType.setLimit)],
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

  static AIResponse _processAdvice(List<Transaction> expenses, List<Transaction> income, double balance, List<Budget> budgets) {
    if (expenses.isEmpty) {
      return AIResponse(
        result: "Keep going!",
        insight: "Start tracking your expenses to get personalized financial advice.",
        intent: AIIntent.financialAdvice,
      );
    }

    final dailyAvgs = FinancialInsightsService.getDailyAveragesByDayOfWeek(expenses);
    final combinedWeekdays = (dailyAvgs[1] ?? 0 + (dailyAvgs[2] ?? 0) + (dailyAvgs[3] ?? 0) + (dailyAvgs[4] ?? 0)) / 4;
    final fridaySpend = dailyAvgs[5] ?? 0;

    if (fridaySpend > (combinedWeekdays * 1.5) && fridaySpend > 0) {
      return AIResponse(
        result: "Friday Spikes",
        insight: "You tend to spend ${((fridaySpend/combinedWeekdays - 1) * 100).toStringAsFixed(0)}% more on Fridays. Consider a weekend budget cap?",
        intent: AIIntent.financialAdvice,
        isPositive: false,
        actions: [AIAction(label: "Set Weekend Cap", type: AIActionType.setLimit)],
      );
    }

    final topCat = FinancialInsightsService.getCategoryData(expenses).entries.toList();
    topCat.sort((a, b) => b.value.compareTo(a.value));

    String tip = "Your biggest expense category is ${topCat.first.key}. Try to see if you can find alternatives there.";
    if (balance < 1000) {
      tip = "Your balance is getting low. It might be a good time to review non-essential expenses.";
    }

    return AIResponse(
      result: "Smart Tip",
      insight: tip,
      intent: AIIntent.financialAdvice,
    );
  }

  static AIResponse _applyAdaptiveTone(AIResponse response, double balance, List<Transaction> expenses, List<Budget> budgets) {
    AITone tone = AITone.calm;
    
    // Determine Tone
    final runway = FinancialInsightsService.projectCashflow(expenses, balance, budgets);
    int days = runway['days'] as int;

    if (days < 5 && days > 0) {
      tone = AITone.strict;
    } else if (response.isPositive && balance > 5000) {
      tone = AITone.encouraging;
    }

    // Add Payday Context if applicable
    String extra = "";
    if (tone == AITone.strict) {
      extra = "\n\nStay alert—funds are tight until your usual income patterns reappear.";
    }

    return AIResponse(
      result: response.result,
      insight: response.insight + extra,
      intent: response.intent,
      isPositive: response.isPositive,
      actions: response.actions,
      tone: tone,
    );
  }
}
