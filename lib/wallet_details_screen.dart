import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/wallet.dart';
import 'models/transaction_model.dart';
import 'services/database_service.dart';

class WalletDetailsScreen extends StatefulWidget {
  final Wallet wallet;
  const WalletDetailsScreen({super.key, required this.wallet});

  @override
  State<WalletDetailsScreen> createState() => _WalletDetailsScreenState();
}

class _WalletDetailsScreenState extends State<WalletDetailsScreen> {
  late bool _isExcluded;

  @override
  void initState() {
    super.initState();
    _isExcluded = widget.wallet.isExcluded;
  }

  void _toggleExclusion() async {
    setState(() {
      _isExcluded = !_isExcluded;
    });
    widget.wallet.isExcluded = _isExcluded;
    await DatabaseService.updateWallet(widget.wallet);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transactions = DatabaseService.getWalletTransactions(widget.wallet.key as int);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.wallet.name),
        actions: [
          IconButton(
            icon: Icon(_isExcluded ? Icons.visibility_off : Icons.visibility, 
                 color: _isExcluded ? Colors.red : theme.primaryColor),
            onPressed: _toggleExclusion,
            tooltip: _isExcluded ? 'Excluded from total' : 'Included in total',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(bottom: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
            ),
            child: Column(
              children: [
                Text(
                  'Current Balance',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  '₱${widget.wallet.balance.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                ),
                if (_isExcluded)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      '(Excluded from Total Balance)',
                      style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Row(
              children: [
                Text('History', style: theme.textTheme.titleLarge),
              ],
            ),
          ),
          Expanded(
            child: transactions.isEmpty
                ? const Center(child: Text('No transactions for this wallet', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final tx = transactions[transactions.length - 1 - index];
                      return _TransactionTile(tx: tx, walletKey: widget.wallet.key as int);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction tx;
  final int walletKey;
  const _TransactionTile({required this.tx, required this.walletKey});

  @override
  Widget build(BuildContext context) {
    bool isIncoming = tx.type == TransactionType.income || (tx.type == TransactionType.transfer && tx.toWalletKey == walletKey);
    Color displayColor = isIncoming ? Colors.green : Colors.red;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: displayColor.withOpacity(0.1),
        child: Icon(
          isIncoming ? Icons.arrow_upward : Icons.arrow_downward,
          color: displayColor,
          size: 20,
        ),
      ),
      title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('${tx.category} • ${DateFormat('MMM dd').format(tx.date)}'),
      trailing: Text(
        '${isIncoming ? '+' : '-'} ₱${tx.amount.toStringAsFixed(2)}',
        style: TextStyle(color: displayColor, fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}
