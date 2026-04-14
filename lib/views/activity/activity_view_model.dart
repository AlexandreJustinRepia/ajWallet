import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../services/session_service.dart';
import '../../models/transaction_model.dart';
import 'package:table_calendar/table_calendar.dart';

class ActivityViewModel extends ChangeNotifier {
  final bool isTutorialActive;
  
  List<Transaction> _allTransactions = [];
  List<Transaction> _filteredTransactions = [];
  
  String _searchQuery = '';
  TransactionType? _filter;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  StreamSubscription? _txSubscription;

  ActivityViewModel({required this.isTutorialActive}) {
    _selectedDay = _focusedDay;
    _setupListeners();
    refresh();
  }

  // Getters
  List<Transaction> get filteredTransactions => _filteredTransactions;
  String get searchQuery => _searchQuery;
  TransactionType? get filter => _filter;
  DateTime get focusedDay => _focusedDay;
  DateTime? get selectedDay => _selectedDay;

  set searchQuery(String val) {
    _searchQuery = val.toLowerCase();
    _applyFilters();
    notifyListeners();
  }

  set filter(TransactionType? val) {
    _filter = val;
    _applyFilters();
    notifyListeners();
  }

  void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    _selectedDay = selectedDay;
    _focusedDay = focusedDay;
    _applyFilters();
    notifyListeners();
  }

  void onPageChanged(DateTime focusedDay) {
    _focusedDay = focusedDay;
    notifyListeners();
  }

  void refresh() {
    final account = SessionService.activeAccount;
    
    if (isTutorialActive) {
      final now = DateTime.now();
      _allTransactions = [
        Transaction(accountKey: 0, title: 'Grocery Run', amount: 250.00, type: TransactionType.expense, date: now, category: 'Food', description: 'Bought some food at the store'),
        Transaction(accountKey: 0, title: 'Salary', amount: 5000.00, type: TransactionType.income, date: now.subtract(const Duration(days: 1)), category: 'Salary', description: 'Monthly salary from work'),
        Transaction(accountKey: 0, title: 'Transfer to Savings', amount: 500.00, type: TransactionType.transfer, date: now.subtract(const Duration(days: 2)), category: 'Transfer', description: 'Moving cash to savings'),
      ];
    } else if (account != null) {
      _allTransactions = DatabaseService.getTransactions(account.key as int);
    } else {
      _allTransactions = [];
    }
    
    _applyFilters();
    notifyListeners();
  }

  void _setupListeners() {
    if (isTutorialActive) return;
    _txSubscription?.cancel();
    _txSubscription = DatabaseService.transactionWatcher.listen((_) => refresh());
  }

  void _applyFilters() {
    _filteredTransactions = _allTransactions.where((tx) {
      if (_filter != null && tx.type != _filter) return false;
      if (_searchQuery.isNotEmpty) {
        if (!tx.title.toLowerCase().contains(_searchQuery) && 
            !tx.category.toLowerCase().contains(_searchQuery)) return false;
      }
      return true;
    }).toList();
    
    _filteredTransactions.sort((a, b) => b.date.compareTo(a.date));
  }

  // Helper for List View: returns mixed list of DateTimes (headers) and Transactions
  List<dynamic> getGroupedItems() {
    final List<dynamic> items = [];
    DateTime? lastDate;
    
    for (final tx in _filteredTransactions) {
      if (lastDate == null || !isSameDay(lastDate, tx.date)) {
        items.add(tx.date);
        lastDate = tx.date;
      }
      items.add(tx);
    }
    return items;
  }

  // Day specific stats for calendar
  List<Transaction> getTransactionsForSelectedDay() {
    return _filteredTransactions.where((tx) => isSameDay(tx.date, _selectedDay ?? _focusedDay)).toList();
  }

  @override
  void dispose() {
    _txSubscription?.cancel();
    super.dispose();
  }
}
