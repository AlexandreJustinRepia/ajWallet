import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';

import 'package:hive_flutter/hive_flutter.dart';
import '../models/account.dart';
import '../models/app_theme.dart';
import '../models/transaction_model.dart';
import '../models/wallet.dart';
import '../models/goal.dart';
import '../models/budget.dart';
import '../models/debt.dart';
import '../models/backup_history.dart';
import '../models/squad.dart';
import '../models/squad_member.dart';
import '../models/squad_transaction.dart';
import '../models/category.dart';
import '../models/shopping_item.dart';
import '../models/product.dart';
import '../models/shopping_list.dart';




class DatabaseService {
  static const String _boxName = 'accounts';
  static const String _transactionBoxName = 'transactions';
  static const String _walletBoxName = 'wallets';
  static const String _goalBoxName = 'goals';
  static const String _budgetBoxName = 'budgets';
  static const String _debtBoxName = 'debts';
  static const String _backupHistoryBoxName = 'backup_history';
  static const String _squadBoxName = 'squads';
  static const String _squadMemberBoxName = 'squad_members';
  static const String _squadTransactionBoxName = 'squad_transactions';
  static const String _categoryBoxName = 'categories';
  static const String _shoppingItemBoxName = 'shopping_items';
  static const String _productBoxName = 'product_catalog';
  static const String _shoppingListBoxName = 'shopping_lists';
  static const String _shoppingDraftBoxName = 'shopping_drafts';




  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(AccountAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(AppThemeAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(TransactionTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(TransactionAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(WalletAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(GoalAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(BudgetAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(DebtAdapter());
    }
    if (!Hive.isAdapterRegistered(9)) {
      Hive.registerAdapter(SquadAdapter());
    }
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(SquadMemberAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(SquadTransactionAdapter());
    }
    if (Hive.isAdapterRegistered(12) == false) {
      Hive.registerAdapter(SplitTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(CategoryAdapter());
    }
    if (!Hive.isAdapterRegistered(14)) {
      Hive.registerAdapter(ShoppingItemAdapter());
    }
    if (!Hive.isAdapterRegistered(15)) {
      Hive.registerAdapter(ProductAdapter());
    }
    if (!Hive.isAdapterRegistered(16)) {
      Hive.registerAdapter(ShoppingListAdapter());
    }




    await _openTypedBox<Account>(_boxName);

    await _openTypedBox<Transaction>(_transactionBoxName);
    await _openTypedBox<Wallet>(_walletBoxName);
    await _openTypedBox<Goal>(_goalBoxName);
    await _openTypedBox<Budget>(_budgetBoxName);
    await _openTypedBox<Debt>(_debtBoxName);
    await _openTypedBox<Squad>(_squadBoxName);
    await _openTypedBox<SquadMember>(_squadMemberBoxName);
    await _openTypedBox<SquadTransaction>(_squadTransactionBoxName);
    await _openTypedBox<Category>(_categoryBoxName);
    await _openTypedBox<ShoppingItem>(_shoppingItemBoxName);
    await _openTypedBox<Product>(_productBoxName);
    await _openTypedBox<ShoppingList>(_shoppingListBoxName);
    await _openTypedBox<ShoppingItem>(_shoppingDraftBoxName);
    await _openUntypedBox(_backupHistoryBoxName);


    // Seed categories if empty
    await _initDefaultCategories();
  }


  static Box<Account> get _box => Hive.box<Account>(_boxName);
  static Box<Transaction> get _transactionBox =>
      Hive.box<Transaction>(_transactionBoxName);
  static Box<Wallet> get _walletBox => Hive.box<Wallet>(_walletBoxName);
  static Box<Goal> get _goalBox => Hive.box<Goal>(_goalBoxName);
  static Box<Budget> get _budgetBox => Hive.box<Budget>(_budgetBoxName);
  static Box<Debt> get _debtBox => Hive.box<Debt>(_debtBoxName);
  static Box<Squad> get _squadBox => Hive.box<Squad>(_squadBoxName);
  static Box<SquadMember> get _memberBox =>
      Hive.box<SquadMember>(_squadMemberBoxName);
  static Box<SquadTransaction> get _squadTxBox =>
      Hive.box<SquadTransaction>(_squadTransactionBoxName);
  static Box<Category> get _categoryBox => Hive.box<Category>(_categoryBoxName);
  static Box<ShoppingItem> get shoppingItemBox => Hive.box<ShoppingItem>(_shoppingItemBoxName);
  static Box<Product> get productCatalogBox => Hive.box<Product>(_productBoxName);
  static Box<ShoppingItem> get shoppingDraftBox => Hive.box<ShoppingItem>(_shoppingDraftBoxName);



  // Watchers for reactive UI
  static Stream<BoxEvent> get transactionWatcher => _transactionBox.watch();
  static Stream<BoxEvent> get walletWatcher => _walletBox.watch();
  static Stream<BoxEvent> get goalWatcher => _goalBox.watch();
  static Stream<BoxEvent> get budgetWatcher => _budgetBox.watch();
  static Stream<BoxEvent> get debtWatcher => _debtBox.watch();
  static Stream<BoxEvent> get squadWatcher => _squadBox.watch();
  static Stream<BoxEvent> get memberWatcher => _memberBox.watch();
  static Stream<BoxEvent> get squadTxWatcher => _squadTxBox.watch();
  static Stream<BoxEvent> get shoppingListWatcher => _shoppingListBox.watch();
  static Stream<BoxEvent> get shoppingItemWatcher => shoppingItemBox.watch();
  static Stream<BoxEvent> get categoryWatcher => _categoryBox.watch();
  static ValueListenable<Box<SquadTransaction>> get squadTxListenable => _squadTxBox.listenable();
  static ValueListenable<Box<ShoppingList>> get shoppingListListenable => _shoppingListBox.listenable();



  static Future<void> _openTypedBox<T>(String boxName) async {
    try {
      await Hive.openBox<T>(boxName);
      return;
    } catch (_) {
      await _safeDeleteBox(boxName);
    }

    try {
      await Hive.openBox<T>(boxName);
      return;
    } catch (_) {
      await _safeDeleteBox(boxName);
    }

    await Hive.openBox<T>(boxName);
  }

  static Future<void> _openUntypedBox(String boxName) async {
    try {
      await Hive.openBox(boxName);
      return;
    } catch (_) {
      await _safeDeleteBox(boxName);
    }

    try {
      await Hive.openBox(boxName);
      return;
    } catch (_) {
      await _safeDeleteBox(boxName);
    }

    await Hive.openBox(boxName);
  }

  static Future<void> _safeDeleteBox(String boxName) async {
    try {
      await Hive.deleteBoxFromDisk(boxName);
    } catch (_) {
      // ignore failures when deleting corrupted or incomplete box files
    }
  }

  static Future<int> saveAccount(Account account) async {
    return await _box.add(account);
  }

  static Future<void> updateAccount(Account account) async {
    await account.save();
  }

  static Future<void> deleteAccount(Account account) async {
    await account.delete();
  }

  static List<Account> getAccounts() {
    return _box.values.toList();
  }

  static Account? getLatestAccount() {
    if (_box.isEmpty) return null;
    // Return the first non-fake account as the primary one for initial loading
    return _box.values.firstWhere(
      (a) => !a.isFake,
      orElse: () => _box.values.last,
    );
  }

  static Account? getFakeAccount(String primaryName) {
    try {
      return _box.values.firstWhere(
        (a) => a.isFake && a.name.contains(primaryName),
      );
    } catch (_) {
      return null;
    }
  }

  // Wallet Operations
  static Future<int> saveWallet(Wallet wallet) async {
    return await _walletBox.add(wallet);
  }

  static Future<void> updateWallet(Wallet wallet) async {
    await wallet.save();
  }

  static Future<void> deleteWallet(Wallet wallet) async {
    final walletKey = wallet.key as int;
    // 1. Delete all transactions involving this wallet
    final transactionsToDelete = _transactionBox.values
        .where((t) => t.walletKey == walletKey || t.toWalletKey == walletKey)
        .toList();

    for (var tx in transactionsToDelete) {
      await tx.delete();
    }

    // 2. Delete the wallet itself
    await wallet.delete();
  }

  static List<Wallet> getWallets(int accountKey) {
    return _walletBox.values.where((w) => w.accountKey == accountKey).toList();
  }

  static List<Wallet> getAllWallets() {
    return _walletBox.values.toList();
  }

  static Wallet? getWallet(int key) {
    return _walletBox.get(key);
  }

  // Transaction Operations
  static Future<int> saveTransaction(
    Transaction transaction, {
    bool silent = false,
  }) async {
    final key = await _transactionBox.add(transaction);
    if (!silent) {
      await _applyTransactionEffect(transaction, isReversing: false);
    }
    return key;
  }

  static Future<void> deleteTransaction(Transaction transaction) async {
    await _applyTransactionEffect(transaction, isReversing: true);
    await transaction.delete();
  }

  static Future<void> deleteTransactionByKey(int key) async {
    final tx = _transactionBox.get(key);
    if (tx != null) {
      await deleteTransaction(tx);
    }
  }


  static Future<void> updateTransaction(
    Transaction oldTx,
    Transaction newTx,
  ) async {
    // 1. Reverse old transaction's effect
    await _applyTransactionEffect(oldTx, isReversing: true);
    // 2. Apply new transaction's effect
    await _applyTransactionEffect(newTx, isReversing: false);
    // 3. Save new data (assuming it's the same HiveObject or we update its fields)
    await newTx.save();
  }

  static Future<void> _applyTransactionEffect(
    Transaction tx, {
    required bool isReversing,
  }) async {
    double amount = isReversing ? -tx.amount : tx.amount;
    double charge = isReversing ? -(tx.charge ?? 0) : (tx.charge ?? 0);

    // Handle Income/Expense wallet updates
    if (tx.type == TransactionType.income && tx.walletKey != null) {
      final wallet = _walletBox.get(tx.walletKey);
      if (wallet != null) {
        wallet.balance += amount;
        await wallet.save();
      }
    } else if (tx.type == TransactionType.expense && tx.walletKey != null) {
      final wallet = _walletBox.get(tx.walletKey);
      if (wallet != null) {
        wallet.balance -= amount;
        await wallet.save();
      }
    }
    // Handle Transfers between wallets
    else if (tx.type == TransactionType.transfer &&
        tx.walletKey != null &&
        tx.toWalletKey != null) {
      final fromWallet = _walletBox.get(tx.walletKey);
      final toWallet = _walletBox.get(tx.toWalletKey);
      if (fromWallet != null && toWallet != null) {
        double fromDeduction = tx.amount + (tx.charge ?? 0);
        if (isReversing) fromDeduction = -fromDeduction;

        fromWallet.balance -= fromDeduction;
        toWallet.balance += amount;

        await fromWallet.save();
        await toWallet.save();
      }
    }

    // Update global account budget
    final account = _box.values.firstWhere((a) => a.key == tx.accountKey);
    if (tx.type == TransactionType.income) {
      account.budget += amount;
    } else if (tx.type == TransactionType.expense) {
      account.budget -= amount;
    } else if (tx.type == TransactionType.transfer) {
      // Transfers themselves don't change total budget, only charges do
      account.budget -= charge;
    }

    await account.save();

    // ── Update Linked Planning Entities ──────────────────────────────
    if (tx.goalKey != null) {
      final goal = _goalBox.get(tx.goalKey);
      if (goal != null) {
        double adjustment = isReversing ? -tx.amount : tx.amount;
        if (tx.type == TransactionType.expense) {
          goal.savedAmount += adjustment; // Deduct from wallet, add to goal
        } else if (tx.type == TransactionType.income) {
          goal.savedAmount -= adjustment; // Add to wallet, deduct from goal
        }
        await goal.save();
      }
    }

    if (tx.debtKey != null) {
      final debt = _debtBox.get(tx.debtKey);
      if (debt != null) {
        double adjustment = isReversing ? -tx.amount : tx.amount;
        if (debt.isOwedToMe) {
          // LENT: Income = they paid me back. Expense = I lent more.
          if (tx.type == TransactionType.income) {
            debt.paidAmount += adjustment;
          } else if (tx.type == TransactionType.expense) {
            debt.totalAmount += adjustment;
          }
        } else {
          // BORROWED: Expense = I paid them back. Income = I borrowed more.
          if (tx.type == TransactionType.expense) {
            debt.paidAmount += adjustment;
          } else if (tx.type == TransactionType.income) {
            debt.totalAmount += adjustment;
          }
        }
        await debt.save();
      }
    }
  }

  static Box<dynamic> get _backupHistoryBox => Hive.box(_backupHistoryBoxName);

  static Future<int> saveBackupHistory(BackupHistory history) async {
    final box = _backupHistoryBox;
    return await box.add(history.toMap());
  }

  static List<BackupHistory> getBackupHistory(int accountKey) {
    final box = _backupHistoryBox;
    return box.values
        .map((e) => BackupHistory.fromMap(Map<String, dynamic>.from(e)))
        .where((h) => h.accountKey == accountKey)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  static List<Transaction> getTransactions(int accountKey) {
    return _transactionBox.values
        .where((t) => t.accountKey == accountKey)
        .toList();
  }

  static List<Transaction> getAllTransactions() {
    return _transactionBox.values.toList();
  }

  static String? getFrequentCategoryForDescription(String description, TransactionType type) {
    if (description.isEmpty) return null;
    
    final lowerDesc = description.toLowerCase();
    final transactions = _transactionBox.values.where((t) => 
      t.type == type && t.description.toLowerCase().contains(lowerDesc)
    );

    if (transactions.isEmpty) return null;

    final counts = <String, int>{};
    for (var tx in transactions) {
      counts[tx.category] = (counts[tx.category] ?? 0) + 1;
    }

    var bestCategory = counts.entries.first.key;
    var maxCount = counts.entries.first.value;

    for (var entry in counts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        bestCategory = entry.key;
      }
    }

    return bestCategory;
  }


  static List<Transaction> getWalletTransactions(int walletKey) {
    return _transactionBox.values
        .where((t) => t.walletKey == walletKey || t.toWalletKey == walletKey)
        .toList();
  }

  // Goal Operations
  static Future<int> saveGoal(Goal goal) async {
    return await _goalBox.add(goal);
  }

  static Future<void> updateGoal(Goal goal) async {
    await goal.save();
  }

  static Future<void> deleteGoal(Goal goal) async {
    await goal.delete();
  }

  static List<Goal> getGoals(int accountKey) {
    return _goalBox.values.where((g) => g.accountKey == accountKey).toList();
  }

  static List<Goal> getAllGoals() {
    return _goalBox.values.toList();
  }

  // Budget Operations
  static Future<int> saveBudget(Budget budget) async {
    return await _budgetBox.add(budget);
  }

  static Future<void> updateBudget(Budget budget) async {
    await budget.save();
  }

  static Future<void> deleteBudget(Budget budget) async {
    await budget.delete();
  }

  static List<Budget> getBudgets(int accountKey) {
    return _budgetBox.values.where((b) => b.accountKey == accountKey).toList();
  }

  static List<Budget> getAllBudgets() {
    return _budgetBox.values.toList();
  }

  static Budget? getBudgetForCategory(
    int accountKey,
    String category,
    int month,
    int year,
  ) {
    try {
      return _budgetBox.values.firstWhere(
        (b) =>
            b.accountKey == accountKey &&
            b.category == category &&
            b.month == month &&
            b.year == year,
      );
    } catch (_) {
      return null;
    }
  }

  // Category Operations
  static Future<int> saveCategory(Category category) async {
    // Set orderIndex to the end of its type list
    final existing = getCategories(category.type);
    category.orderIndex = existing.length;
    return await _categoryBox.add(category);
  }


  static Future<void> updateCategory(Category category) async {
    await category.save();
  }

  static Future<void> deleteCategory(Category category) async {
    await category.delete();
  }

  static List<Category> getCategories(TransactionType? type) {
    List<Category> list;
    if (type == null) {
      list = _categoryBox.values.cast<Category>().toList();
    } else {
      list = _categoryBox.values.cast<Category>().where((c) => c.type == type).toList();
    }
    
    // Sort by orderIndex
    list.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return list;
  }

  static Future<void> updateCategoriesOrder(List<Category> categories) async {
    for (int i = 0; i < categories.length; i++) {
      categories[i].orderIndex = i;
      await categories[i].save();
    }
  }


  static Category? getCategoryByName(String name) {
    try {
      return _categoryBox.values.cast<Category>().firstWhere((c) => c.name == name);
    } catch (_) {
      return null;
    }
  }


  static Future<void> _initDefaultCategories() async {
    if (_categoryBox.isNotEmpty) return;

    final defaults = [
      // Expense Categories (index 0-8)
      Category(name: 'Food & Drinks', iconCode: Icons.fastfood.codePoint, type: TransactionType.expense, isDefault: true, orderIndex: 0),
      Category(name: 'Transportation', iconCode: Icons.directions_car.codePoint, type: TransactionType.expense, isDefault: true, orderIndex: 1),
      Category(name: 'Shopping', iconCode: Icons.shopping_bag.codePoint, type: TransactionType.expense, isDefault: true, orderIndex: 2),
      Category(name: 'Entertainment', iconCode: Icons.movie.codePoint, type: TransactionType.expense, isDefault: true, orderIndex: 3),
      Category(name: 'Health', iconCode: Icons.medical_services.codePoint, type: TransactionType.expense, isDefault: true, orderIndex: 4),
      Category(name: 'Utilities', iconCode: Icons.home.codePoint, type: TransactionType.expense, isDefault: true, orderIndex: 5),
      Category(name: 'Education', iconCode: Icons.school.codePoint, type: TransactionType.expense, isDefault: true, orderIndex: 6),
      Category(name: 'Pet Food', iconCode: Icons.pets.codePoint, type: TransactionType.expense, isDefault: true, orderIndex: 7),
      Category(name: 'Lend', iconCode: Icons.handshake_rounded.codePoint, type: TransactionType.expense, isDefault: true, orderIndex: 8),
      Category(name: 'Others', iconCode: Icons.more_horiz.codePoint, type: TransactionType.expense, isDefault: true, orderIndex: 9),
      
      // Income Categories (index 0-5)
      Category(name: 'Salary', iconCode: Icons.work.codePoint, type: TransactionType.income, isDefault: true, orderIndex: 0),
      Category(name: 'Bonus', iconCode: Icons.card_giftcard.codePoint, type: TransactionType.income, isDefault: true, orderIndex: 1),
      Category(name: 'Dividend', iconCode: Icons.pie_chart.codePoint, type: TransactionType.income, isDefault: true, orderIndex: 2),
      Category(name: 'Gift', iconCode: Icons.redeem.codePoint, type: TransactionType.income, isDefault: true, orderIndex: 3),
      Category(name: 'Investment', iconCode: Icons.trending_up.codePoint, type: TransactionType.income, isDefault: true, orderIndex: 4),
      Category(name: 'Borrow', iconCode: Icons.handshake_rounded.codePoint, type: TransactionType.income, isDefault: true, orderIndex: 5),
      Category(name: 'Others', iconCode: Icons.more_horiz.codePoint, type: TransactionType.income, isDefault: true, orderIndex: 6),
    ];


    await _categoryBox.addAll(defaults);
  }

  static Future<void> ensureCategoryExists(String name, TransactionType type, IconData icon) async {
    final list = _categoryBox.values.cast<Category>().where((c) => c.type == type && c.name == name).toList();
    if (list.isEmpty) {
      final existing = getCategories(type);
      await _categoryBox.add(Category(
        name: name,
        iconCode: icon.codePoint,
        type: type,
        isDefault: true,
        orderIndex: existing.length,
      ));
    }
  }


  // Debt Operations
  static Future<int> saveDebt(Debt debt) async {
    return await _debtBox.add(debt);
  }

  static Future<void> updateDebt(Debt debt) async {
    await debt.save();
  }

  static Future<void> deleteDebt(Debt debt) async {
    final debtKey = debt.key as int;
    // 1. Delete all transactions linked to this debt
    // We use deleteTransaction so it also reverses balance effects
    final linkedTxs = _transactionBox.values
        .where((t) => t.debtKey == debtKey)
        .toList();

    for (var tx in linkedTxs) {
      await deleteTransaction(tx);
    }

    // 2. Delete the debt itself
    await debt.delete();
  }

  static List<Debt> getDebts(int accountKey) {
    return _debtBox.values.where((d) => d.accountKey == accountKey).toList();
  }

  static List<Debt> getAllDebts() {
    return _debtBox.values.toList();
  }

  // Squad Operations
  static Future<int> saveSquad(Squad squad) async {
    return await _squadBox.add(squad);
  }

  static Future<void> updateSquad(Squad squad) async {
    await squad.save();
  }

  static Future<void> deleteSquad(Squad squad) async {
    final squadKey = squad.key as int;
    // Delete members
    final members = _memberBox.values.where((m) => m.squadKey == squadKey).toList();
    for (var m in members) {
      await m.delete();
    }
    // Delete squad transactions
    final txs =
        _squadTxBox.values.where((tx) => tx.squadKey == squadKey).toList();
    for (var tx in txs) {
      await deleteSquadTransaction(tx);
    }
    await squad.delete();
  }

  static List<Squad> getSquads(int accountKey) {
    return _squadBox.values.where((s) => s.accountKey == accountKey).toList();
  }

  static Squad? getSquad(int key) {
    return _squadBox.get(key);
  }

  // Member Operations
  static Future<int> saveSquadMember(SquadMember member) async {
    return await _memberBox.add(member);
  }

  static Future<void> updateSquadMember(SquadMember member) async {
    await member.save();
  }

  static Future<void> deleteSquadMember(SquadMember member) async {
    await member.delete();
  }

  static List<SquadMember> getSquadMembers(int squadKey) {
    return _memberBox.values.where((m) => m.squadKey == squadKey).toList();
  }

  // Squad Transaction Operations
  static Future<int> saveSquadTransaction(
    SquadTransaction tx, {
    bool silent = false,
  }) async {
    final key = await _squadTxBox.add(tx);

    // If a wallet is selected, we sync this to personal Transactions
    if (!silent && tx.walletKey != null) {
      final squad = getSquad(tx.squadKey);
      final squadName = squad?.name ?? 'Squad';

      TransactionType mainType = TransactionType.expense;
      if (tx.isSettlement) {
        // Find if user is the one paying or receiving
        final payer = _memberBox.get(tx.payerMemberKey);
        if (payer != null && !payer.isYou) {
          // Someone else paid YOU back
          mainType = TransactionType.income;
        }
      }

      final mainTx = Transaction(
        title: '[$squadName] ${tx.title}',
        amount: tx.amount,
        date: tx.date,
        category: tx.isSettlement ? 'Settlement' : 'Group Split',
        description: 'Auto-linked from Squad Transaction',
        type: mainType,
        accountKey: squad?.accountKey ?? 0,
        walletKey: tx.walletKey,
        squadTxKey: key,
      );

      // This will handle balance, budget, and other side effects
      await saveTransaction(mainTx);
    }
    return key;
  }

  static Future<void> updateSquadTransaction(SquadTransaction tx) async {
    await tx.save();
  }

  static Future<void> deleteSquadTransaction(SquadTransaction tx) async {
    // 1. Find and delete linked main transaction
    try {
      final linkedTx = _transactionBox.values.firstWhere(
        (t) => t.squadTxKey == tx.key,
      );
      await deleteTransaction(linkedTx);
    } catch (_) {
      // No linked transaction found, or already deleted
      // Fallback: manually restore balance if it was a legacy squad tx
      if (tx.walletKey != null && !tx.isSettlement) {
        final wallet = _walletBox.get(tx.walletKey);
        if (wallet != null) {
          wallet.balance += tx.amount;
          await wallet.save();
        }
      }
    }

    // 2. Cascade delete linked settlements if this was a bill
    if (!tx.isSettlement) {
      final linkedSettlements = _squadTxBox.values
          .where((s) => s.relatedBillKey == tx.key)
          .toList();
      for (var s in linkedSettlements) {
        await deleteSquadTransaction(s);
      }
    }

    await tx.delete();
  }

  static List<SquadTransaction> getSquadTransactions(int squadKey) {
    return _squadTxBox.values.where((tx) => tx.squadKey == squadKey).toList();
  }

  static Future<void> wipeAccountData(int accountKey) async {
    // Delete wallets
    final walletKeys = _walletBox.values
        .where((w) => w.accountKey == accountKey)
        .map((w) => w.key)
        .toList();
    for (var key in walletKeys) {
      await _walletBox.delete(key);
    }

    // Delete transactions
    final txKeys = _transactionBox.values
        .where((t) => t.accountKey == accountKey)
        .map((t) => t.key)
        .toList();
    for (var key in txKeys) {
      await _transactionBox.delete(key);
    }

    // Delete goals
    final goalKeys = _goalBox.values
        .where((g) => g.accountKey == accountKey)
        .map((g) => g.key)
        .toList();
    for (var key in goalKeys) {
      await _goalBox.delete(key);
    }

    // Delete budgets
    final budgetKeys = _budgetBox.values
        .where((b) => b.accountKey == accountKey)
        .map((b) => b.key)
        .toList();
    for (var key in budgetKeys) {
      await _budgetBox.delete(key);
    }

    // Delete debts
    final debtKeys = _debtBox.values
        .where((d) => d.accountKey == accountKey)
        .map((d) => d.key)
        .toList();
    for (var key in debtKeys) {
      await _debtBox.delete(key);
    }

    // Delete squads and related
    final squads =
        _squadBox.values.where((s) => s.accountKey == accountKey).toList();
    for (var s in squads) {
      await deleteSquad(s);
    }

    // Delete shopping lists and items
    final shoppingLists =
        _shoppingListBox.values.where((l) => l.accountKey == accountKey).toList();
    for (var list in shoppingLists) {
      final items =
          shoppingItemBox.values.where((i) => i.listId == list.id).toList();
      for (var item in items) {
        await item.delete();
      }
      await list.delete();
    }
  }

  static Future<void> wipeAllData() async {
    await _box.clear();
    await _transactionBox.clear();
    await _walletBox.clear();
    await _goalBox.clear();
    await _budgetBox.clear();
    await _debtBox.clear();
    await _squadBox.clear();
    await _memberBox.clear();
    await _squadTxBox.clear();
    await _categoryBox.clear();
    await _shoppingListBox.clear();
    await shoppingItemBox.clear();
    await productCatalogBox.clear();
  }

  static Box<ShoppingList> get _shoppingListBox => Hive.box<ShoppingList>(_shoppingListBoxName);

  static Wallet? getWalletByKey(int key) {

    final box = Hive.box<Wallet>(_walletBoxName);
    return box.get(key);
  }
}
