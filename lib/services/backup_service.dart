import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:file_picker/file_picker.dart';
import 'package:crypto/crypto.dart';
import '../models/wallet.dart';
import '../models/transaction_model.dart';
import '../models/goal.dart';
import '../models/budget.dart';
import '../models/debt.dart';
import '../models/backup_history.dart';
import 'database_service.dart';

class BackupService {
  static const String _magicHeader = "AJ_BACKUP_V1";

  static Future<bool> exportBackup(String pin, int accountKey) async {
    try {
      // 1. Collect Data (Filtered by accountKey)
      final account = DatabaseService.getAccounts().firstWhere((a) => a.key == accountKey);
      final wallets = DatabaseService.getWallets(accountKey);
      final transactions = DatabaseService.getTransactions(accountKey);
      final goals = DatabaseService.getGoals(accountKey);
      final budgets = DatabaseService.getBudgets(accountKey);
      final debts = DatabaseService.getDebts(accountKey);

      final dataMap = {
        'header': _magicHeader,
        'timestamp': DateTime.now().toIso8601String(),
        'accounts': [
          {...account.toMap(), 'key': account.key as int}
        ],
        'wallets': wallets.map((e) => {...e.toMap(), 'key': e.key as int}).toList(),
        'transactions': transactions.map((e) => {...e.toMap(), 'key': e.key as int}).toList(),
        'goals': goals.map((e) => {...e.toMap(), 'key': e.key as int}).toList(),
        'budgets': budgets.map((e) => {...e.toMap(), 'key': e.key as int}).toList(),
        'debts': debts.map((e) => {...e.toMap(), 'key': e.key as int}).toList(),
      };

      final jsonString = jsonEncode(dataMap);

      // 2. Encryption
      final salt = enc.IV.fromSecureRandom(16);
      final key = _deriveKey(pin, salt.bytes);
      final iv = enc.IV.fromSecureRandom(16);

      final encrypter = enc.Encrypter(enc.AES(key));
      final encrypted = encrypter.encrypt(jsonString, iv: iv);

      // 3. Package: [Salt(16)] + [IV(16)] + [EncryptedData]
      final combined = BytesBuilder();
      combined.add(salt.bytes);
      combined.add(iv.bytes);
      combined.add(encrypted.bytes);

      // 4. Save File
      String? outputPath;
      final fileName = 'aj_wallet_backup_${DateTime.now().millisecondsSinceEpoch}.ajb';

      if (Platform.isAndroid || Platform.isIOS) {
        final selectedDirectory = await FilePicker.platform.getDirectoryPath(
          dialogTitle: 'Select Export Directory',
        );
        
        if (selectedDirectory != null) {
          outputPath = '$selectedDirectory/$fileName';
          final file = File(outputPath);
          await file.writeAsBytes(combined.toBytes());
        }
      } else {
        // Desktop/Web fallback
        outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Backup',
          fileName: fileName,
          type: FileType.any,
        );
        
        if (outputPath != null) {
          final file = File(outputPath);
          await file.writeAsBytes(combined.toBytes());
        }
      }
      final success = outputPath != null;

      await DatabaseService.saveBackupHistory(
        BackupHistory(
          accountKey: accountKey,
          type: 'export',
          timestamp: DateTime.now(),
          filePath: outputPath,
          success: success,
        ),
      );

      return success;
    } catch (e) {
      debugPrint('Export error: $e');
      await DatabaseService.saveBackupHistory(
        BackupHistory(
          accountKey: accountKey,
          type: 'export',
          timestamp: DateTime.now(),
          filePath: null,
          success: false,
        ),
      );
      return false;
    }
  }

  static Future<bool> importBackup(String pin, int targetAccountKey) async {
    try {
      // 1. Pick File
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );
      if (result == null || result.files.single.path == null) return false;

      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();

      if (bytes.length < 32) return false; // Salt(16) + IV(16)

      // 2. Extract Salt, IV, and Data
      final salt = Uint8List.sublistView(bytes, 0, 16);
      final iv = enc.IV(Uint8List.sublistView(bytes, 16, 32));
      final encryptedBytes = Uint8List.sublistView(bytes, 32);

      // 3. Decrypt
      final keyDerivation = _deriveKey(pin, salt);
      final encrypter = enc.Encrypter(enc.AES(keyDerivation));
      
      final decrypted = encrypter.decrypt(enc.Encrypted(encryptedBytes), iv: iv);
      final dataMap = jsonDecode(decrypted);

      if (dataMap['header'] != _magicHeader) return false;

      // 4. Restore Data (Clean Merge - Wipe account data first)
      await DatabaseService.wipeAccountData(targetAccountKey);
      
      final accountKeyMap = <int, int>{};
      final walletKeyMap = <int, int>{};
      final goalKeyMap = <int, int>{};
      final budgetKeyMap = <int, int>{};
      final debtKeyMap = <int, int>{};

      // Stage 1: Account Mapping & Update
      final targetAccount = DatabaseService.getAccounts().firstWhere((a) => a.key == targetAccountKey);
      final accountsJson = dataMap['accounts'] as List;
      if (accountsJson.isNotEmpty) {
        final aMap = accountsJson.first; // Use the first account from backup as the source
        final oldKey = aMap['key'] as int;
        accountKeyMap[oldKey] = targetAccountKey;
        
        // Update current account settings (non-security) - NOT updating name as per user request
        targetAccount.budget = aMap['budget'] ?? targetAccount.budget;
        // Biometrics and Lock settings
        targetAccount.isBiometricEnabled = aMap['isBiometricEnabled'] ?? targetAccount.isBiometricEnabled;
        targetAccount.autoLockDurationSeconds = aMap['autoLockDurationSeconds'] ?? targetAccount.autoLockDurationSeconds;
        
        await targetAccount.save();
      }
      
      // Stage 2: Wallets
      final walletsJson = dataMap['wallets'] as List;
      for (var wMap in walletsJson) {
        final oldKey = wMap['key'] as int;
        final wallet = Wallet.fromMap(wMap);
        wallet.accountKey = targetAccountKey;
        final newKey = await DatabaseService.saveWallet(wallet);
        walletKeyMap[oldKey] = newKey;
      }
      
      // Stage 3: Goals, Budgets, Debts
      if (dataMap.containsKey('goals')) {
        final goalsJson = dataMap['goals'] as List;
        for (var gMap in goalsJson) {
          final oldKey = gMap['key'] as int;
          final goal = Goal.fromMap(gMap);
          goal.accountKey = targetAccountKey;
          final newKey = await DatabaseService.saveGoal(goal);
          goalKeyMap[oldKey] = newKey;
        }
      }
      
      if (dataMap.containsKey('budgets')) {
        final budgetsJson = dataMap['budgets'] as List;
        for (var bMap in budgetsJson) {
          final oldKey = bMap['key'] as int;
          final budget = Budget.fromMap(bMap);
          budget.accountKey = targetAccountKey;
          final newKey = await DatabaseService.saveBudget(budget);
          budgetKeyMap[oldKey] = newKey;
        }
      }
      
      if (dataMap.containsKey('debts')) {
        final debtsJson = dataMap['debts'] as List;
        for (var dMap in debtsJson) {
          final oldKey = dMap['key'] as int;
          final debt = Debt.fromMap(dMap);
          debt.accountKey = targetAccountKey;
          final newKey = await DatabaseService.saveDebt(debt);
          debtKeyMap[oldKey] = newKey;
        }
      }
      
      // Stage 4: Transactions
      final transactionsJson = dataMap['transactions'] as List;
      for (var tMap in transactionsJson) {
        final transaction = Transaction.fromMap(tMap);
        transaction.accountKey = targetAccountKey;
        
        if (tMap['walletKey'] != null) {
          transaction.walletKey = walletKeyMap[tMap['walletKey'] as int];
        }
        if (tMap['toWalletKey'] != null) {
          transaction.toWalletKey = walletKeyMap[tMap['toWalletKey'] as int];
        }
        if (tMap['goalKey'] != null) {
          transaction.goalKey = goalKeyMap[tMap['goalKey'] as int];
        }
        if (tMap['budgetKey'] != null) {
          transaction.budgetKey = budgetKeyMap[tMap['budgetKey'] as int];
        }
        if (tMap['debtKey'] != null) {
          transaction.debtKey = debtKeyMap[tMap['debtKey'] as int];
        }
        
        // Save silently to avoid re-applying effects to already correct balances
        await DatabaseService.saveTransaction(transaction, silent: true);
      }
      await DatabaseService.saveBackupHistory(
        BackupHistory(
          accountKey: targetAccountKey,
          type: 'import',
          timestamp: DateTime.now(),
          filePath: result.files.single.path,
          success: true,
        ),
      );

      return true;
    } catch (e) {
      debugPrint('Import error: $e');
      
      await DatabaseService.saveBackupHistory(
        BackupHistory(
          accountKey: targetAccountKey,
          type: 'import',
          timestamp: DateTime.now(),
          filePath: null,
          success: false,
        ),
      );
      return false;
    }
  }

  static enc.Key _deriveKey(String pin, Uint8List salt) {
    // Basic PBKDF2-like derivation
    var hash = sha256.convert(utf8.encode(pin) + salt).bytes;
    // Iterate to increase difficulty
    for (int i = 0; i < 1000; i++) {
      hash = sha256.convert(hash + salt).bytes;
    }
    return enc.Key(Uint8List.fromList(hash));
  }
}
