import '../models/squad_member.dart';
import '../models/squad_transaction.dart';
import 'database_service.dart';

class SquadBalances {
  final Map<int, double> memberNetBalances; // memberKey -> net (positive if they get back, negative if they owe)
  final double youOwe;
  final double youAreOwed;
  final double net;

  SquadBalances({
    required this.memberNetBalances,
    required this.youOwe,
    required this.youAreOwed,
    required this.net,
  });
}

class SquadService {
  static SquadBalances calculateBalances(int squadKey) {
    final members = DatabaseService.getSquadMembers(squadKey);
    final transactions = DatabaseService.getSquadTransactions(squadKey);

    Map<int, double> balances = {};
    for (var m in members) {
      balances[m.key as int] = 0.0;
    }

    for (var tx in transactions) {
      // Payer gets back the full amount (relative to the pool)
      final payerKey = tx.payerMemberKey;
      if (balances.containsKey(payerKey)) {
        balances[payerKey] = (balances[payerKey] ?? 0) + tx.amount;
      }

      // Each member in splits owes their share
      if (tx.splitType == SplitType.equal) {
        final share = tx.amount / tx.memberSplits.length;
        for (var memberKey in tx.memberSplits.keys) {
          if (balances.containsKey(memberKey)) {
            balances[memberKey] = (balances[memberKey] ?? 0) - share;
          }
        }
      } else if (tx.splitType == SplitType.amount) {
        for (var entry in tx.memberSplits.entries) {
          if (balances.containsKey(entry.key)) {
            balances[entry.key] = (balances[entry.key] ?? 0) - entry.value;
          }
        }
      } else if (tx.splitType == SplitType.percentage) {
        for (var entry in tx.memberSplits.entries) {
          if (balances.containsKey(entry.key)) {
            final share = (entry.value / 100) * tx.amount;
            balances[entry.key] = (balances[entry.key] ?? 0) - share;
          }
        }
      }
    }

    // Now identify "You" and calculate summaries
    double youOwe = 0;
    double youAreOwed = 0;
    double net = 0;

    final you = members.cast<SquadMember?>().firstWhere((m) => m?.isYou ?? false, orElse: () => null);
    
    if (you != null) {
      final yourBalance = balances[you.key as int] ?? 0;
      net = yourBalance;

      // To get individual "You owe" vs "You are owed" correctly (Splitwise style),
      // we need to see how your balance is composed.
      // Simplify: if net > 0, you are owed (total). If net < 0, you owe (total).
      // But the user wants "You are owed: 500, You owe: 200". This usually comes from 
      // summing up positive and negative debts with specific people.
      
      // Let's calculate pairwise debts for a more detailed view.
      final debts = _calculatePairwiseDebts(members, transactions);
      final yourKey = you.key as int;

      for (var other in members) {
        final otherKey = other.key as int;
        if (otherKey == yourKey) continue;

        double owesYou = debts[otherKey]?[yourKey] ?? 0;
        double youOweOther = debts[yourKey]?[otherKey] ?? 0;

        final diff = owesYou - youOweOther;
        if (diff > 0) {
          youAreOwed += diff;
        } else if (diff < 0) {
          youOwe += diff.abs();
        }
      }
    }

    return SquadBalances(
      memberNetBalances: balances,
      youOwe: youOwe,
      youAreOwed: youAreOwed,
      net: net,
    );
  }

  static Map<int, Map<int, double>> _calculatePairwiseDebts(
      List<SquadMember> members, List<SquadTransaction> transactions) {
    // result[A][B] = how much A owes B
    Map<int, Map<int, double>> debts = {};
    for (var m1 in members) {
      debts[m1.key as int] = {};
      for (var m2 in members) {
        debts[m1.key as int]![m2.key as int] = 0.0;
      }
    }

    for (var tx in transactions) {
      final payer = tx.payerMemberKey;
      
      if (tx.splitType == SplitType.equal) {
        final share = tx.amount / tx.memberSplits.length;
        for (var ower in tx.memberSplits.keys) {
          if (ower != payer) {
            debts[ower]![payer] = (debts[ower]![payer] ?? 0) + share;
          }
        }
      } else if (tx.splitType == SplitType.amount) {
        for (var entry in tx.memberSplits.entries) {
          final ower = entry.key;
          final share = entry.value;
          if (ower != payer) {
            debts[ower]![payer] = (debts[ower]![payer] ?? 0) + share;
          }
        }
      } else if (tx.splitType == SplitType.percentage) {
        for (var entry in tx.memberSplits.entries) {
          final ower = entry.key;
          final share = (entry.value / 100) * tx.amount;
          if (ower != payer) {
            debts[ower]![payer] = (debts[ower]![payer] ?? 0) + share;
          }
        }
      }
    }
    
    return debts;
  }
}
