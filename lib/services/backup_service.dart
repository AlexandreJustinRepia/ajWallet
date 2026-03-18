import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import '../models/account.dart';
import '../models/wallet.dart';
import '../models/transaction_model.dart';
import 'database_service.dart';

class BackupService {
  static const String _magicHeader = "AJ_BACKUP_V1";

  static Future<bool> exportBackup(String pin) async {
    try {
      // 1. Collect Data
      final accounts = DatabaseService.getAccounts();
      final wallets = DatabaseService.getAllWallets();
      final transactions = DatabaseService.getAllTransactions();

      final dataMap = {
        'header': _magicHeader,
        'timestamp': DateTime.now().toIso8601String(),
        'accounts': accounts.map((e) => e.toMap()).toList(),
        'wallets': wallets.map((e) => e.toMap()).toList(),
        'transactions': transactions.map((e) => e.toMap()).toList(),
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
      if (Platform.isAndroid || Platform.isIOS) {
        final directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
        outputPath = '${directory.path}/aj_wallet_backup_${DateTime.now().millisecondsSinceEpoch}.ajb';
        final file = File(outputPath);
        await file.writeAsBytes(combined.toBytes());
      } else {
        // Desktop/Web fallback or use file_picker to save
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Backup',
          fileName: 'aj_wallet_backup.ajb',
          type: FileType.any,
        );
        if (result != null) {
          final file = File(result);
          await file.writeAsBytes(combined.toBytes());
          outputPath = result;
        }
      }

      return outputPath != null;
    } catch (e) {
      print('Export error: $e');
      return false;
    }
  }

  static Future<bool> importBackup(String pin) async {
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
      final key = _deriveKey(pin, salt);
      final encrypter = enc.Encrypter(enc.AES(key));
      
      final decrypted = encrypter.decrypt(enc.Encrypted(encryptedBytes), iv: iv);
      final dataMap = jsonDecode(decrypted);

      if (dataMap['header'] != _magicHeader) return false;

      // 4. Restore Data
      await DatabaseService.wipeAllData();

      final accountsJson = dataMap['accounts'] as List;
      final walletsJson = dataMap['wallets'] as List;
      final transactionsJson = dataMap['transactions'] as List;

      for (var a in accountsJson) {
        await DatabaseService.saveAccount(Account.fromMap(a));
      }
      for (var w in walletsJson) {
        await DatabaseService.saveWallet(Wallet.fromMap(w));
      }
      for (var t in transactionsJson) {
        await DatabaseService.saveTransaction(Transaction.fromMap(t));
      }

      return true;
    } catch (e) {
      print('Import error: $e');
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
