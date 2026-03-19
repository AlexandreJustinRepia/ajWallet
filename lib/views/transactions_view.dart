import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/database_service.dart';
import '../models/transaction_model.dart';
import '../widgets/slide_in_list_item.dart';
import '../widgets/transaction_card.dart';
import 'dashboard_helpers.dart';

class TransactionsView extends StatelessWidget {
  final VoidCallback onRefresh;
  const TransactionsView({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final account = DatabaseService.getLatestAccount();
    final theme = Theme.of(context);
    final transactions = account != null
        ? DatabaseService.getTransactions(account.key as int)
        : <Transaction>[];

    if (transactions.isEmpty) {
      return Center(
        child: Text('Vault empty', style: theme.textTheme.bodyMedium),
      );
    }

    // Sort by date descending and group by day.
    final sortedTx = List<Transaction>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    final List<dynamic> items = [];
    DateTime? lastDate;
    for (final tx in sortedTx) {
      if (lastDate == null || !isSameDay(lastDate, tx.date)) {
        items.add(tx.date);
        lastDate = tx.date;
      }
      items.add(tx);
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item is DateTime) {
          return buildDateHeader(context, item);
        }
        final tx = item as Transaction;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SlideInListItem(
            index: index,
            child: TransactionCard(tx: tx, onRefresh: onRefresh),
          ),
        );
      },
    );
  }
}
