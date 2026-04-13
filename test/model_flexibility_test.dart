import 'package:flutter_test/flutter_test.dart';
import 'package:root_exp/models/account.dart';
import 'package:root_exp/models/transaction_model.dart';

void main() {
  group('Model Flexibility (Backup/Restore Resilience)', () {
    
    group('Account.fromMap', () {
      test('handles standard map correctly', () {
        final map = {
          'name': 'Main Account',
          'budget': 1000.0,
          'pin': '1234',
          'isBiometricEnabled': true,
          'fakePin': '0000',
          'isFake': false,
          'maxFailedAttempts': 3,
          'isWipeEnabled': true,
          'autoLockDurationSeconds': 60,
          'hasSeenTutorial': true,
        };
        final account = Account.fromMap(map);
        
        expect(account.name, 'Main Account');
        expect(account.budget, 1000.0);
        expect(account.hasSeenTutorial, isTrue);
      });

      test('handles missing hasSeenTutorial (added in later update)', () {
        final map = {
          'name': 'Old Account',
          'budget': 500.0,
          'pin': '1111',
          'isBiometricEnabled': false,
          'fakePin': null,
          'isFake': false,
          'maxFailedAttempts': 5,
          'isWipeEnabled': false,
          'autoLockDurationSeconds': 30,
          // 'hasSeenTutorial' missing
        };
        final account = Account.fromMap(map);
        
        expect(account.hasSeenTutorial, isFalse, reason: 'Should default to false if missing');
      });
    });

    group('Transaction.fromMap', () {
      test('handles standard transaction map', () {
        final map = {
          'title': 'Coffee',
          'amount': 5.0,
          'date': DateTime.now().toIso8601String(),
          'category': 'Food',
          'description': 'Morning coffee',
          'type': 1, // expense
          'accountKey': 0,
          'walletKey': 1,
          'toWalletKey': null,
          'charge': 0.0,
          'goalKey': null,
          'budgetKey': null,
          'debtKey': null,
        };
        final tx = Transaction.fromMap(map);
        
        expect(tx.title, 'Coffee');
        expect(tx.type, TransactionType.expense);
      });
    });
  });
}
