import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/transaction_model.dart';
import 'services/database_service.dart';
import 'services/quick_add_service.dart';

class TransactionDetailsScreen extends StatelessWidget {
  final Transaction transaction;

  const TransactionDetailsScreen({super.key, required this.transaction});

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: const Text('This action cannot be undone. Are you sure you want to remove this record from your vault?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await DatabaseService.deleteTransaction(transaction);
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context, true); // Return to previous screen with refresh flag
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = transaction.type == TransactionType.income;
    final isTransfer = transaction.type == TransactionType.transfer;
    final displayColor = transaction.typeColor;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Transaction Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Amount Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: theme.dividerColor, width: 0.5),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: displayColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isTransfer 
                        ? Icons.swap_horiz_rounded 
                        : (isIncome ? Icons.south_west_rounded : Icons.north_east_rounded),
                      color: displayColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '${isIncome ? '+' : (isTransfer ? '' : '-')} ₱${transaction.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: displayColor,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    transaction.type.name.toUpperCase(),
                    style: TextStyle(
                      letterSpacing: 2,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Details List
            _InfoRow(
              icon: Icons.category_rounded,
              label: 'Category',
              value: transaction.category,
              theme: theme,
            ),
            const Divider(),
            _InfoRow(
              icon: Icons.calendar_today_rounded,
              label: 'Date',
              value: DateFormat('EEEE, MMM dd, yyyy').format(transaction.date),
              theme: theme,
            ),
            _InfoRow(
              icon: Icons.access_time_rounded,
              label: 'Time',
              value: DateFormat('hh:mm a').format(transaction.date),
              theme: theme,
            ),
            const Divider(),
            _InfoRow(
              icon: Icons.account_balance_wallet_rounded,
              label: isTransfer ? 'From Wallet' : 'Wallet',
              value: _getWalletName(transaction.walletKey),
              theme: theme,
            ),
            if (isTransfer)
              _InfoRow(
                icon: Icons.arrow_forward_rounded,
                label: 'To Wallet',
                value: _getWalletName(transaction.toWalletKey),
                theme: theme,
              ),
            if (transaction.charge != null && transaction.charge! > 0)
              _InfoRow(
                icon: Icons.receipt_long_rounded,
                label: 'Service Fee',
                value: '₱${transaction.charge!.toStringAsFixed(2)}',
                theme: theme,
              ),
            const Divider(),
            if (transaction.description.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _InfoLabel(label: 'Description', theme: theme),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.dividerColor, width: 0.5),
                    ),
                    child: Text(
                      transaction.description,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _getWalletName(int? key) {
    if (key == null) return 'Unknown';
    final wallet = DatabaseService.getWalletByKey(key);
    return wallet?.name ?? 'Unknown';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;

  const _InfoRow({required this.icon, required this.label, required this.value, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.dividerColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: theme.primaryColor),
          ),
          const SizedBox(width: 16),
          _InfoLabel(label: label, theme: theme),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _InfoLabel extends StatelessWidget {
  final String label;
  final ThemeData theme;

  const _InfoLabel({required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
      ),
    );
  }
}
