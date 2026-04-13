import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../transaction_details_screen.dart';
import 'card_decorator.dart';

/// A tappable card that displays a single transaction row.
class TransactionCard extends StatelessWidget {
  final Transaction tx;
  final VoidCallback? onRefresh;

  const TransactionCard({super.key, required this.tx, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = tx.type == TransactionType.income;
    final isTransfer = tx.type == TransactionType.transfer;
    final displayColor = tx.typeColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransactionDetailsScreen(transaction: tx),
            ),
          );
          if (result == true) onRefresh?.call();
        },
        borderRadius: BorderRadius.circular(20),
        child: CardDecorator(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.dividerColor, width: 0.5),
            ),
            child: Row(
              children: [
                _TypeIcon(
                  isTransfer: isTransfer,
                  isIncome: isIncome,
                  color: displayColor,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tx.title, style: theme.textTheme.titleSmall),
                      Text(tx.category, style: theme.textTheme.labelLarge),
                    ],
                  ),
                ),
                _AmountColumn(
                  tx: tx,
                  isIncome: isIncome,
                  isTransfer: isTransfer,
                  displayColor: displayColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeIcon extends StatelessWidget {
  final bool isTransfer;
  final bool isIncome;
  final Color color;

  const _TypeIcon({
    required this.isTransfer,
    required this.isIncome,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        isTransfer
            ? Icons.swap_horiz_rounded
            : (isIncome
                ? Icons.south_west_rounded
                : Icons.north_east_rounded),
        color: color,
        size: 18,
      ),
    );
  }
}

class _AmountColumn extends StatelessWidget {
  final Transaction tx;
  final bool isIncome;
  final bool isTransfer;
  final Color displayColor;

  const _AmountColumn({
    required this.tx,
    required this.isIncome,
    required this.isTransfer,
    required this.displayColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prefix = isIncome ? '+' : (isTransfer ? '' : '-');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$prefix ₱${tx.amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: displayColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        if (tx.charge != null && tx.charge! > 0)
          Text(
            'Fee: ₱${tx.charge!.toStringAsFixed(2)}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.error.withValues(alpha:0.5),
              fontSize: 10,
            ),
          ),
        Text(
          DateFormat('MMM dd').format(tx.date),
          style: theme.textTheme.labelLarge,
        ),
      ],
    );
  }
}
