import 'package:flutter/material.dart';
import '../services/quick_add_service.dart';
import '../models/transaction_model.dart';
import '../services/database_service.dart';

class QuickAddInput extends StatefulWidget {
  final int accountKey;
  final VoidCallback onSaved;

  const QuickAddInput({
    super.key,
    required this.accountKey,
    required this.onSaved,
  });

  @override
  State<QuickAddInput> createState() => _QuickAddInputState();
}

class _QuickAddInputState extends State<QuickAddInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  QuickAddResult? _preview;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updatePreview);
    _focusNode.addListener(() {
      setState(() => _isExpanded = _focusNode.hasFocus);
    });
  }

  void _updatePreview() {
    if (_controller.text.isEmpty) {
      setState(() => _preview = null);
      return;
    }
    setState(() => _preview = QuickAddService.parse(_controller.text));
  }

  Future<void> _submit() async {
    final result = _preview;
    if (result == null || result.amount <= 0) return;

    final wallets = DatabaseService.getWallets(widget.accountKey)
        .where((w) => !w.isExcluded)
        .toList();
    if (wallets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a wallet first')),
      );
      return;
    }

    int walletKey = wallets.first.key as int;
    int? toWalletKey;

    if (result.type == TransactionType.transfer) {
      final allWallets = DatabaseService.getWallets(widget.accountKey);
      
      if (result.fromWallet != null) {
        for (var w in allWallets) {
          if (w.name.toLowerCase() == result.fromWallet!.toLowerCase()) {
            walletKey = w.key as int;
            break;
          }
        }
      }

      if (result.toWallet != null) {
        for (var w in allWallets) {
          if (w.name.toLowerCase() == result.toWallet!.toLowerCase()) {
            toWalletKey = w.key as int;
            break;
          }
        }
      }
      
      // Default destination if not specified or not found
      if (toWalletKey == null) {
        if (wallets.length > 1) {
          toWalletKey = wallets.firstWhere((w) => (w.key as int) != walletKey).key as int;
        } else {
          // If only one wallet, transfer to itself (or show error?)
          toWalletKey = walletKey;
        }
      }
    }

    final transaction = Transaction(
      title: result.title,
      amount: result.amount,
      date: DateTime.now(),
      category: result.category,
      description: 'Quick added',
      type: result.type,
      accountKey: widget.accountKey,
      walletKey: walletKey,
      toWalletKey: toWalletKey,
    );

    await DatabaseService.saveTransaction(transaction);
    _controller.clear();
    _focusNode.unfocus();
    widget.onSaved();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.type == TransactionType.transfer 
            ? 'Transferred ₱${result.amount.toStringAsFixed(2)}' 
            : 'Added ₱${result.amount.toStringAsFixed(2)} to ${result.category}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isExpanded ? theme.primaryColor.withOpacity(0.5) : theme.dividerColor,
          width: _isExpanded ? 1.5 : 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isExpanded ? 0.08 : 0.02),
            blurRadius: _isExpanded ? 20 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.bolt_rounded,
                  color: _isExpanded ? theme.primaryColor : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: 'Quick add: "250 food"',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (_controller.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.send_rounded),
                    onPressed: _submit,
                    color: theme.primaryColor,
                  ),
              ],
            ),
          ),
          if (_preview != null && _preview!.amount > 0)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Row(
                children: [
                  _buildPreviewPill(
                    icon: QuickAddService.getCategoryIcon(_preview!.category),
                    label: _preview!.category,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildPreviewPill(
                    icon: _preview!.type == TransactionType.income 
                      ? Icons.arrow_downward_rounded 
                      : Icons.arrow_upward_rounded,
                    label: _preview!.type == TransactionType.income ? 'Income' : 'Expense',
                    color: QuickAddService.getTypeColor(_preview!.type),
                  ),
                  const Spacer(),
                  Text(
                    '₱${_preview!.amount.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: QuickAddService.getTypeColor(_preview!.type),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreviewPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
