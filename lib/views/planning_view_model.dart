import 'dart:async';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/planning_intelligence_service.dart';
import '../models/transaction_model.dart';
import '../models/budget.dart';
import '../models/goal.dart';
import '../models/debt.dart';
import '../models/wallet.dart';

class PlanningViewModel extends ChangeNotifier {
  int? _accountKey;
  bool _isLoading = false;

  // Stream Subscriptions
  StreamSubscription? _txSubscription;
  StreamSubscription? _walletSubscription;
  StreamSubscription? _budgetSubscription;
  StreamSubscription? _goalSubscription;
  StreamSubscription? _debtSubscription;

  List<Budget> _budgets = [];
  List<Goal> _goals = [];
  List<Debt> _debts = [];
  List<Transaction> _transactions = [];
  List<Wallet> _wallets = [];
  List<PlanningInsight> _insights = [];

  // Cached Computations
  double _budgetUsedPct = 0.0;
  double _savingsPct = 0.0;
  double _activeDebtAmount = 0.0;
  double _totalBalance = 0.0;

  // Pre-grouped data for O(1) lookups in UI loops
  final Map<int, double> _budgetSpentMap = {};
  final Map<String, double> _categorySpendingMap = {}; // Key: "category_month_year"
  List<Debt> _youOweDebts = [];
  List<Debt> _owedToYouDebts = [];

  // Getters
  bool get isLoading => _isLoading;
  List<Budget> get budgets => _budgets;
  List<Goal> get goals => _goals;
  List<Debt> get debts => _debts;
  List<Transaction> get transactions => _transactions;
  List<PlanningInsight> get insights => _insights;
  
  double get budgetUsedPct => _budgetUsedPct;
  double get savingsPct => _savingsPct;
  double get activeDebtAmount => _activeDebtAmount;
  double get totalBalance => _totalBalance;
  
  List<Debt> get youOweDebts => _youOweDebts;
  List<Debt> get owedToYouDebts => _owedToYouDebts;

  void init(int accountKey) {
    if (_accountKey == accountKey) return;
    _accountKey = accountKey;
    _setupListeners();
    refresh();
  }

  void _setupListeners() {
    _txSubscription?.cancel();
    _walletSubscription?.cancel();
    _budgetSubscription?.cancel();
    _goalSubscription?.cancel();
    _debtSubscription?.cancel();

    _txSubscription = DatabaseService.transactionWatcher.listen((_) => refresh());
    _walletSubscription = DatabaseService.walletWatcher.listen((_) => refresh());
    _budgetSubscription = DatabaseService.budgetWatcher.listen((_) => refresh());
    _goalSubscription = DatabaseService.goalWatcher.listen((_) => refresh());
    _debtSubscription = DatabaseService.debtWatcher.listen((_) => refresh());
  }

  Future<void> refresh() async {
    final key = _accountKey;
    if (key == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Fetch all data in parallel (or sequential if preferred, Hive is fast)
      _budgets = DatabaseService.getBudgets(key);
      _goals = DatabaseService.getGoals(key);
      _debts = DatabaseService.getDebts(key);
      _transactions = DatabaseService.getTransactions(key);
      _wallets = DatabaseService.getWallets(key);

      // 2. Perform Grouping & Pre-computations (Single Pass)
      _calculateMetrics(key);
      
      // 3. Generate Insights
      _insights = PlanningIntelligenceService.generate(
        transactions: _transactions,
        budgets: _budgets,
        goals: _goals,
        debts: _debts,
        totalBalance: _totalBalance,
        wallets: _wallets,
      );

    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _calculateMetrics(int key) {
    final now = DateTime.now();
    _budgetSpentMap.clear();
    _categorySpendingMap.clear();
    
    // Total Balance calculation
    _totalBalance = _wallets
        .where((w) => !w.isExcluded)
        .fold(0.0, (sum, w) => sum + w.balance);

    // Pre-group spending in a single pass over transactions
    for (final t in _transactions) {
      if (t.type != TransactionType.expense) continue;

      // Track by budgetKey if explicit
      if (t.budgetKey != null) {
        _budgetSpentMap[t.budgetKey!] = (_budgetSpentMap[t.budgetKey!] ?? 0) + t.amount;
      }

      // Track by category + date for categorical budgets
      final dateKey = "${t.category}_${t.date.month}_${t.date.year}";
      _categorySpendingMap[dateKey] = (_categorySpendingMap[dateKey] ?? 0) + t.amount;
    }

    // Budget Progress Summary
    double totalLimit = 0;
    double totalSpent = 0;
    final thisMonthBudgets = _budgets.where((b) => b.month == now.month && b.year == now.year).toList();
    
    for (var b in thisMonthBudgets) {
      totalLimit += b.amountLimit;
      totalSpent += getBudgetSpending(b);
    }
    _budgetUsedPct = totalLimit > 0 ? (totalSpent / totalLimit * 100).clamp(0.0, 100.0) : 0.0;

    // Savings Progress Summary
    final totalGoalTarget = _goals.fold(0.0, (s, g) => s + g.targetAmount);
    final totalGoalSaved = _goals.fold(0.0, (s, g) => s + g.savedAmount);
    _savingsPct = totalGoalTarget > 0 ? (totalGoalSaved / totalGoalTarget * 100).clamp(0.0, 100.0) : 0.0;

    // Debt Grouping
    _youOweDebts = _debts.where((d) => !d.isOwedToMe).toList();
    _owedToYouDebts = _debts.where((d) => d.isOwedToMe).toList();
    _activeDebtAmount = _youOweDebts.fold(0.0, (s, d) => s + (d.totalAmount - d.paidAmount).clamp(0.0, double.infinity));
  }

  /// Efficient lookup for budget spending
  double getBudgetSpending(Budget b) {
    // Priority 1: Explicit key match (if the budget has a key and transactions were linked)
    final byKey = b.key != null ? _budgetSpentMap[b.key as int] : null;
    if (byKey != null && byKey > 0) return byKey;

    // Priority 2: Categorical match for the relevant month/year
    final dateKey = "${b.category}_${b.month}_${b.year}";
    return _categorySpendingMap[dateKey] ?? 0.0;
  }
  @override
  void dispose() {
    _txSubscription?.cancel();
    _walletSubscription?.cancel();
    _budgetSubscription?.cancel();
    _goalSubscription?.cancel();
    _debtSubscription?.cancel();
    super.dispose();
  }
}
