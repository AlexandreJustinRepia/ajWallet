import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' hide Category;
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:file_picker/file_picker.dart';
import 'package:crypto/crypto.dart';
import '../models/wallet.dart';
import '../models/transaction_model.dart';
import '../models/goal.dart';
import '../models/budget.dart';
import '../models/debt.dart';
import '../models/squad.dart';
import '../models/squad_member.dart';
import '../models/squad_transaction.dart';
import '../models/backup_history.dart';
import '../models/category.dart';
import '../models/shopping_item.dart';
import '../models/product.dart';
import '../models/shopping_list.dart';
import 'database_service.dart';
import 'shopping_service.dart';

class BackupService {
  static const String _magicHeader = "AJ_BACKUP_V1";
  static const String defaultPin = "0000";

  static Future<bool> exportBackup(String pin, int accountKey, {String? name}) async {
    try {
      // 1. Collect Data (Filtered by accountKey)
      final account = DatabaseService.getAccounts().firstWhere((a) => a.key == accountKey);
      final wallets = DatabaseService.getWallets(accountKey);
      final transactions = DatabaseService.getTransactions(accountKey);
      final goals = DatabaseService.getGoals(accountKey);
      final budgets = DatabaseService.getBudgets(accountKey);
      final debts = DatabaseService.getDebts(accountKey);
      final squads = DatabaseService.getSquads(accountKey);
      final categories = DatabaseService.getCategories(null);
      final shoppingLists = ShoppingService.getShoppingLists(accountKey);
      final products = ShoppingService.getProductCatalog(accountKey);
      final squadMembers = <SquadMember>[];
      final squadTransactions = <SquadTransaction>[];
      final shoppingItems = <ShoppingItem>[];
      final shoppingDrafts = <ShoppingItem>[];

      for (var squad in squads) {
        final sk = squad.key as int;
        squadMembers.addAll(DatabaseService.getSquadMembers(sk));
        squadTransactions.addAll(DatabaseService.getSquadTransactions(sk));
      }

      for (var list in shoppingLists) {
        shoppingItems.addAll(ShoppingService.getShoppingItems(accountKey, listId: list.id));
      }

      shoppingDrafts.addAll(DatabaseService.shoppingDraftBox.values
          .where((item) => item.accountKey == accountKey));

      final dataMap = {
        'header': _magicHeader,
        'timestamp': DateTime.now().toIso8601String(),
        'accounts': [
          {...account.toMap(), 'key': account.key}
        ],
        'wallets': wallets.map((e) => {...e.toMap(), 'key': e.key}).toList(),
        'transactions': transactions.map((e) => {...e.toMap(), 'key': e.key}).toList(),
        'goals': goals.map((e) => {...e.toMap(), 'key': e.key}).toList(),
        'budgets': budgets.map((e) => {...e.toMap(), 'key': e.key}).toList(),
        'debts': debts.map((e) => {...e.toMap(), 'key': e.key}).toList(),
        'squads': squads.map((e) => {...e.toMap(), 'key': e.key}).toList(),
        'squadMembers': squadMembers.map((e) => {...e.toMap(), 'key': e.key}).toList(),
        'squadTransactions': squadTransactions.map((e) => {...e.toMap(), 'key': e.key}).toList(),
        'categories': categories.map((e) => {...e.toMap(), 'key': e.key}).toList(),
        'shoppingLists': shoppingLists.map((e) => {...e.toMap(), 'key': e.key}).toList(),
        'shoppingItems': shoppingItems.map((e) => {...e.toMap(), 'key': e.key}).toList(),
        'shoppingDrafts': shoppingDrafts.map((e) => {...e.toMap(), 'key': e.key}).toList(),
        'products': products.map((e) => {...e.toMap(), 'key': e.key}).toList(),
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
      final fileName = name != null && name.trim().isNotEmpty
          ? '${name.trim().replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_')}.ajb'
          : 'aj_wallet_backup_${DateTime.now().millisecondsSinceEpoch}.ajb';

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
      final squadKeyMap = <int, int>{};
      final memberKeyMap = <int, int>{};
      final squadTxKeyMap = <int, int>{};
      final transactionKeyMap = <int, int>{};

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

      // Stage 3.5: Squads
      if (dataMap.containsKey('squads')) {
        final squadsJson = dataMap['squads'] as List;
        for (var sMap in squadsJson) {
          final oldKey = sMap['key'] as int;
          final squad = Squad.fromMap(sMap);
          squad.accountKey = targetAccountKey;
          final newKey = await DatabaseService.saveSquad(squad);
          squadKeyMap[oldKey] = newKey;
        }
      }

      // Stage 3.6: Squad Members
      if (dataMap.containsKey('squadMembers')) {
        final membersJson = dataMap['squadMembers'] as List;
        for (var mMap in membersJson) {
          final oldKey = mMap['key'] as int;
          final member = SquadMember.fromMap(mMap);
          if (squadKeyMap.containsKey(mMap['squadKey'] as int)) {
            member.squadKey = squadKeyMap[mMap['squadKey'] as int]!;
            final newKey = await DatabaseService.saveSquadMember(member);
            memberKeyMap[oldKey] = newKey;
          }
        }
      }

      // Stage 3.7: Squad Transactions
      if (dataMap.containsKey('squadTransactions')) {
        final squadTxsJson = dataMap['squadTransactions'] as List;
        final squadTxs = <int, SquadTransaction>{};

        for (var stMap in squadTxsJson) {
          final oldKey = stMap['key'] as int;
          final tx = SquadTransaction.fromMap(stMap);
          
          if (squadKeyMap.containsKey(stMap['squadKey'] as int) && 
              memberKeyMap.containsKey(stMap['payerMemberKey'] as int)) {
            
            tx.squadKey = squadKeyMap[stMap['squadKey'] as int]!;
            tx.payerMemberKey = memberKeyMap[stMap['payerMemberKey'] as int]!;
            
            if (stMap['walletKey'] != null) {
              tx.walletKey = walletKeyMap[stMap['walletKey'] as int];
            }

            // Remap memberSplits keys
            final oldSplits = Map<int, double>.from(tx.memberSplits);
            tx.memberSplits.clear();
            oldSplits.forEach((oldMemberKey, share) {
              final newMemberKey = memberKeyMap[oldMemberKey];
              if (newMemberKey != null) {
                tx.memberSplits[newMemberKey] = share;
              }
            });

            // Save silently to avoid duplicating personal transactions (they will be restored in Stage 4)
            final newKey = await DatabaseService.saveSquadTransaction(tx, silent: true);
            squadTxKeyMap[oldKey] = newKey;
            squadTxs[oldKey] = tx;
          }
        }

        // Stage 3.8: Re-link Settlements (relatedBillKey)
        for (var stMap in squadTxsJson) {
          if (stMap['relatedBillKey'] != null) {
            final oldBillKey = stMap['relatedBillKey'] as int;
            final newBillKey = squadTxKeyMap[oldBillKey];
            if (newBillKey != null) {
              final oldTxKey = stMap['key'] as int;
              final newTxKey = squadTxKeyMap[oldTxKey];
              if (newTxKey != null) {
                final tx = squadTxs[oldTxKey]!;
                tx.relatedBillKey = newBillKey;
                await tx.save();
              }
            }
          }
        }
      }
      
      // Stage 3.8: Categories (Restore custom ones, keep defaults)
      if (dataMap.containsKey('categories')) {
        final categoriesJson = dataMap['categories'] as List;
        for (var cMap in categoriesJson) {
          final category = Category.fromMap(cMap);
          // Check if category already exists by name
          if (DatabaseService.getCategoryByName(category.name) == null) {
            await DatabaseService.saveCategory(category);
          }
        }
      }

      // Stage 3.9: Products (Product Catalog)
      if (dataMap.containsKey('products')) {
        final productsJson = dataMap['products'] as List;
        for (var pMap in productsJson) {
          final product = Product.fromMap(pMap);
          product.accountKey = targetAccountKey;
          await ShoppingService.saveProduct(product);
        }
      }

      // Stage 3.10: Shopping Lists
      if (dataMap.containsKey('shoppingLists')) {
        final listsJson = dataMap['shoppingLists'] as List;
        for (var lMap in listsJson) {
          final list = ShoppingList.fromMap(lMap);
          list.accountKey = targetAccountKey;
          // Temporarily nullify linkedTransactionKey; will remap in Stage 5
          list.linkedTransactionKey = null; 
          await ShoppingService.saveShoppingList(list);
        }
      }

      // Stage 3.11: Shopping Items
      if (dataMap.containsKey('shoppingItems')) {
        final itemsJson = dataMap['shoppingItems'] as List;
        for (var iMap in itemsJson) {
          final item = ShoppingItem.fromMap(iMap);
          item.accountKey = targetAccountKey;
          // Temporarily nullify linkedTransactionKey; will remap in Stage 5
          item.linkedTransactionKey = null;
          await ShoppingService.saveShoppingItem(item);
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
        if (tMap['squadTxKey'] != null) {
          transaction.squadTxKey = squadTxKeyMap[tMap['squadTxKey'] as int];
        }
        
        // Save silently to avoid re-applying effects to already correct balances
        final newTxKey = await DatabaseService.saveTransaction(transaction, silent: true);
        transactionKeyMap[tMap['key'] as int] = newTxKey;
      }

      // Stage 5: Post-Transaction Link Remapping (Shopping Lists & Items)
      if (dataMap.containsKey('shoppingLists')) {
        final listsJson = dataMap['shoppingLists'] as List;
        final lists = ShoppingService.getShoppingLists(targetAccountKey);
        for (var lMap in listsJson) {
          if (lMap['linkedTransactionKey'] != null) {
            final oldTxKey = lMap['linkedTransactionKey'] as int;
            final newTxKey = transactionKeyMap[oldTxKey];
            if (newTxKey != null) {
              final list = lists.firstWhere((l) => l.id == lMap['id']);
              list.linkedTransactionKey = newTxKey;
              await list.save();
            }
          }
        }
      }

      if (dataMap.containsKey('shoppingItems')) {
        final itemsJson = dataMap['shoppingItems'] as List;
        final items = ShoppingService.getShoppingItems(targetAccountKey);
        for (var iMap in itemsJson) {
          if (iMap['linkedTransactionKey'] != null) {
            final oldTxKey = iMap['linkedTransactionKey'] as int;
            final newTxKey = transactionKeyMap[oldTxKey];
            if (newTxKey != null) {
              final item = items.firstWhere((i) => i.id == iMap['id']);
              item.linkedTransactionKey = newTxKey;
              await item.save();
            }
          }
        }
      }

      // Stage 6: Shopping Drafts
      if (dataMap.containsKey('shoppingDrafts')) {
        final draftsJson = dataMap['shoppingDrafts'] as List;
        for (var dMap in draftsJson) {
          final draft = ShoppingItem.fromMap(dMap);
          draft.accountKey = targetAccountKey;
          await DatabaseService.shoppingDraftBox.add(draft);
        }
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

      // Final Step: Sync Categories (Ensure new defaults exist and types are correct)
      await DatabaseService.syncDefaultCategories();

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
