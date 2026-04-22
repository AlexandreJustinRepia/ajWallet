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
        for (var recipient in tx.memberSplits.keys) {
          if (recipient != payer) {
            if (tx.isSettlement) {
              // Payer is giving money back to recipient
              debts[payer]![recipient] = (debts[payer]![recipient] ?? 0) - share;
            } else {
              // Regular bill: ower owes share to payer
              debts[recipient]![payer] = (debts[recipient]![payer] ?? 0) + share;
            }
          }
        }
      } else if (tx.splitType == SplitType.amount) {
        for (var entry in tx.memberSplits.entries) {
          final recipient = entry.key;
          final share = entry.value;
          if (recipient != payer) {
            if (tx.isSettlement) {
              debts[payer]![recipient] = (debts[payer]![recipient] ?? 0) - share;
            } else {
              debts[recipient]![payer] = (debts[recipient]![payer] ?? 0) + share;
            }
          }
        }
      } else if (tx.splitType == SplitType.percentage) {
        for (var entry in tx.memberSplits.entries) {
          final recipient = entry.key;
          final share = (entry.value / 100) * tx.amount;
          if (recipient != payer) {
            if (tx.isSettlement) {
              debts[payer]![recipient] = (debts[payer]![recipient] ?? 0) - share;
            } else {
              debts[recipient]![payer] = (debts[recipient]![payer] ?? 0) + share;
            }
          }
        }
      }
    }
    
    return debts;
  }

  static Map<int, double> calculateBillRemaining(
    SquadTransaction tx,
    List<SquadMember> members,
    List<SquadTransaction> allTxs,
  ) {
    if (tx.isSettlement) return {};

    final relatedPayments = allTxs
        .where((t) => t.isSettlement && t.relatedBillKey == tx.key)
        .toList();
    final bills = allTxs.where((t) => !t.isSettlement).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    Map<int, double> remainingMap = {};

    for (var member in members) {
      final memberKey = member.key as int;
      if (!tx.memberSplits.containsKey(memberKey)) continue;

      double share = tx.memberSplits[memberKey]!;
      if (tx.splitType == SplitType.percentage) {
        share = (share / 100) * tx.amount;
      } else if (tx.splitType == SplitType.equal) {
        share = tx.amount / tx.memberSplits.length;
      }

      if (memberKey == tx.payerMemberKey) {
        remainingMap[memberKey] = 0.0;
        continue;
      }

      final explicit = relatedPayments
          .where((p) => p.payerMemberKey == memberKey)
          .map((p) => p.amount)
          .fold(0.0, (a, b) => a + b);

      double totalP = allTxs
          .where((t) => t.isSettlement && t.payerMemberKey == memberKey)
          .map((t) => t.amount)
          .fold(0.0, (a, b) => a + b);

      double prevS = 0;
      for (var b in bills) {
        if (b.key == tx.key) break;
        if (b.memberSplits.containsKey(memberKey)) {
          double s = b.memberSplits[memberKey]!;
          if (b.splitType == SplitType.percentage) {
            s = (s / 100) * b.amount;
          } else if (b.splitType == SplitType.equal) {
            s = b.amount / b.memberSplits.length;
          }
          prevS += s;
        }
      }

      final availC = (totalP - prevS - explicit).clamp(0.0, double.infinity);
      final attrA = availC.clamp(
        0.0,
        (share - explicit).clamp(0.0, double.infinity),
      );

      remainingMap[memberKey] = (share - explicit - attrA).clamp(
        0.0,
        double.infinity,
      );
    }

    return remainingMap;
  }
}
