import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../models/transaction_model.dart';
import '../../../widgets/slide_in_list_item.dart';
import '../../../widgets/transaction_card.dart';
import '../../dashboard_helpers.dart';

class RecentActivitySection extends StatelessWidget {
  final List<Transaction> transactions;
  final VoidCallback onRefresh;
  final GlobalKey? headerKey;
  final GlobalKey? sampleTransactionKey;

  const RecentActivitySection({
    super.key,
    required this.transactions,
    required this.onRefresh,
    this.headerKey,
    this.sampleTransactionKey,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 16),
        if (transactions.isEmpty)
          _buildEmptyState(context)
        else
          _buildRecentTransactions(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      key: headerKey,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'RECENT ACTIVITY',
          style: theme.textTheme.labelLarge?.copyWith(
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
            fontSize: 10,
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.cardColor,
            shape: BoxShape.circle,
            border: Border.all(color: theme.dividerColor, width: 0.5),
          ),
          child: Icon(
            Icons.horizontal_rule_rounded,
            size: 14,
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.blur_on_rounded, size: 48, color: theme.dividerColor),
            const SizedBox(height: 16),
            Text(
              'No activities recorded yet.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(BuildContext context) {
    final sortedTx = List<Transaction>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    final topTx = sortedTx.take(5).toList();

    final List<dynamic> items = [];
    DateTime? lastDate;
    for (final tx in topTx) {
      if (lastDate == null || !isSameDay(lastDate, tx.date)) {
        items.add(tx.date);
        lastDate = tx.date;
      }
      items.add(tx);
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item is DateTime) {
          return buildDateHeader(context, item);
        }
        final tx = item as Transaction;
        final isFirstTx = topTx.isNotEmpty && tx == topTx.first;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SlideInListItem(
            index: index,
            child: TransactionCard(
              key: isFirstTx ? sampleTransactionKey : null,
              tx: tx,
              onRefresh: onRefresh,
            ),
          ),
        );
      },
    );
  }
}
