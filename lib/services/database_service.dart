import 'package:flutter/foundation.dart';
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
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(SplitTypeAdapter());
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
    await _openUntypedBox(_backupHistoryBoxName);
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

  // Watchers for reactive UI
  static Stream<BoxEvent> get transactionWatcher => _transactionBox.watch();
  static Stream<BoxEvent> get walletWatcher => _walletBox.watch();
  static Stream<BoxEvent> get goalWatcher => _goalBox.watch();
  static Stream<BoxEvent> get budgetWatcher => _budgetBox.watch();
  static Stream<BoxEvent> get debtWatcher => _debtBox.watch();
  static Stream<BoxEvent> get squadWatcher => _squadBox.watch();
  static Stream<BoxEvent> get memberWatcher => _memberBox.watch();
  static Stream<BoxEvent> get squadTxWatcher => _squadTxBox.watch();
  static ValueListenable<Box<SquadTransaction>> get squadTxListenable => _squadTxBox.listenable();

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

  // Debt Operations
  static Future<int> saveDebt(Debt debt) async {
    return await _debtBox.add(debt);
  }

  static Future<void> updateDebt(Debt debt) async {
    await debt.save();
  }

  static Future<void> deleteDebt(Debt debt) async {
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
  }

  static Wallet? getWalletByKey(int key) {
    final box = Hive.box<Wallet>(_walletBoxName);
    return box.get(key);
  }
}
