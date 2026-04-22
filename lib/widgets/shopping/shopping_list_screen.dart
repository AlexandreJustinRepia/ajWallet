import 'package:flutter/material.dart';
import '../../models/shopping_item.dart';
import '../../models/shopping_list.dart';
import '../../services/shopping_service.dart';
import '../../services/database_service.dart';
import 'add_item_dialog.dart';
import '../../models/store.dart';
import 'package:intl/intl.dart';


class ShoppingListScreen extends StatefulWidget {
  final int accountKey;
  final ShoppingList shoppingList;

  const ShoppingListScreen({
    super.key,
    required this.accountKey,
    required this.shoppingList,
  });


  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  List<ShoppingItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() {
    setState(() {
      _items = ShoppingService.getShoppingItems(widget.accountKey, listId: widget.shoppingList.id);
      _isLoading = false;
    });
  }


  double get _totalEstimated => _items
      .where((item) => !item.isBought)
      .fold(0.0, (sum, item) => sum + item.total);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final boughtItems = _items.where((item) => item.isBought).toList();
    final pendingItems = _items.where((item) => !item.isBought).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.shoppingList.storeName != null) ...[
              Builder(
                builder: (context) {
                  final logoPath = Store.getLogoForStore(widget.shoppingList.storeName);
                  if (logoPath == null) return const Icon(Icons.store_rounded, size: 24);
                  return Image.asset(
                    logoPath,
                    height: 24,
                    width: 24,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.store_rounded, size: 24),
                  );
                },
              ),
              const SizedBox(width: 12),
            ],
            Text(widget.shoppingList.name, style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        centerTitle: true,
        actions: [
          if (widget.shoppingList.isSettled)
            IconButton(
              icon: const Icon(Icons.undo_rounded),
              tooltip: 'Revoke Settlement',
              onPressed: () async {
                await ShoppingService.unsettleList(widget.shoppingList);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settlement revoked. Items are now editable.')),
                  );
                  setState(() {});
                }
              },

            )
          else if (boughtItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.receipt_long_rounded),
              tooltip: 'Settle to Transactions',
              onPressed: _showSettleDialog,
            ),
        ],
      ),


      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildBudgetSummary(theme),
                Expanded(
                  child: _items.isEmpty
                      ? _buildEmptyState(theme)
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            if (pendingItems.isNotEmpty) ...[
                              _buildSectionHeader('TO BUY', pendingItems.length),
                              ...pendingItems.map((item) => _buildItemTile(item, theme)),
                              const SizedBox(height: 24),
                            ],
                            if (boughtItems.isNotEmpty) ...[
                              _buildSectionHeader('COMPLETED', boughtItems.length),
                              ...boughtItems.map((item) => _buildItemTile(item, theme, isBought: true)),
                            ],
                          ],
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addItem,
        label: const Text('Add Item'),
        icon: const Icon(Icons.add_shopping_cart_rounded),
      ),
    );
  }

  double _calculateBoughtTotal() {
    return _items
        .where((item) => item.isBought && item.linkedTransactionKey == null)
        .fold(0.0, (sum, item) => sum + item.total);
  }

  Widget _buildSectionHeader(String title, int count) {

    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.dividerColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(fontSize: 10, color: theme.textTheme.bodySmall?.color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetSummary(ThemeData theme) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primaryColor, theme.primaryColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Estimated',
                style: TextStyle(color: theme.scaffoldBackgroundColor.withValues(alpha: 0.7), fontSize: 13),
              ),
              if (widget.shoppingList.storeName != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.shoppingList.storeName!,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '₱${NumberFormat('#,##0.00').format(_totalEstimated)}',
            style: TextStyle(
              color: theme.scaffoldBackgroundColor,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          _buildActiveCategoryWarnings(),
        ],
      ),
    );
  }

  Widget _buildActiveCategoryWarnings() {
    final categoriesInList = _items.where((i) => !i.isBought).map((i) => i.category).toSet();
    final indicators = <Widget>[];

    for (var cat in categoriesInList) {
      final impact = ShoppingService.getBudgetImpact(widget.accountKey, cat);
      final limit = impact['limit']!;
      final anticipated = impact['totalAnticipated']!;
      final remaining = limit - anticipated;

      if (limit > 0) {
        final isExceeded = anticipated > limit;
        indicators.add(
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Icon(
                  isExceeded ? Icons.warning_amber_rounded : Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isExceeded
                        ? 'Exceeds $cat budget by ₱${(anticipated - limit).toStringAsFixed(0)}'
                        : '$cat: ₱${remaining.toStringAsFixed(0)} remaining',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: isExceeded ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                if (!isExceeded && limit > 0)
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (impact['spent']! / limit).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }
    }

    return Column(children: indicators);
  }


  Widget _buildItemTile(ShoppingItem item, ThemeData theme, {bool isBought = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBought ? Colors.transparent : theme.dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: GestureDetector(
          onTap: () => _toggleItem(item),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isBought ? Colors.green.withValues(alpha: 0.1) : theme.dividerColor.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isBought ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: isBought ? Colors.green : theme.dividerColor,
              size: 24,
            ),
          ),
        ),
        title: Text(
          item.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: isBought ? TextDecoration.lineThrough : null,
            color: isBought ? theme.textTheme.bodySmall?.color : null,
          ),
        ),
        subtitle: Text(
          '${item.quantity} x ₱${item.price.toStringAsFixed(2)} • ${item.category}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '₱${item.total.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: isBought ? theme.textTheme.bodySmall?.color : theme.primaryColor,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert_rounded, size: 20),
              onPressed: () => _showItemActions(item),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: theme.dividerColor.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            'Your list is empty',
            style: TextStyle(color: theme.dividerColor, fontWeight: FontWeight.bold),
          ),
          Text(
            'Add items to start planning',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  void _addItem() async {
    final result = await showDialog(
      context: context,
      builder: (context) => AddShoppingItemDialog(
        accountKey: widget.accountKey,
        listId: widget.shoppingList.id,
      ),
    );
    if (result == true) _loadItems();
  }


  void _showSettleDialog() async {
    final wallets = DatabaseService.getWallets(widget.accountKey);
    if (wallets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a wallet first')),
      );
      return;
    }

    int? selectedWalletKey = wallets.first.key as int;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Settle List to Transactions', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('This will record all bought items as a single expense transaction and update your budget.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              
              const Text('Select Payment Wallet', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              RadioGroup<int>(
                groupValue: selectedWalletKey,
                onChanged: (val) => setModalState(() => selectedWalletKey = val),
                child: Column(
                  children: wallets.map((w) => RadioListTile<int>(
                    title: Text(w.name),
                    subtitle: Text('Balance: ₱${w.balance.toStringAsFixed(2)}'),
                    value: w.key as int,
                    // groupValue and onChanged are now handled by the parent RadioGroup
                  )).toList(),
                ),
              ),


              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () async {
                    final wallet = wallets.firstWhere((w) => w.key == selectedWalletKey);
                    final totalToSettle = _calculateBoughtTotal(); // Helper to get total of items being settled
                    
                    if (wallet.balance < totalToSettle) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Insufficient funds in ${wallet.name}! Need ₱${totalToSettle.toStringAsFixed(2)}, have ₱${wallet.balance.toStringAsFixed(2)}'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                      return;
                    }

                    Navigator.pop(context);
                    await ShoppingService.settleList(widget.shoppingList, selectedWalletKey!);
                    if (!context.mounted) return;
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('List settled to transactions!')),
                    );
                    Navigator.pop(context); // Go back to dashboard
                  },


                  child: const Text('Confirm Settlement', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleItem(ShoppingItem item) async {

     await ShoppingService.toggleBought(item);
     _loadItems();
  }

  void _showItemActions(ShoppingItem item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit Item'),
            onTap: () async {
              Navigator.pop(context);
              final result = await showDialog(
                context: context,
                builder: (context) => AddShoppingItemDialog(
                  accountKey: widget.accountKey,
                  listId: widget.shoppingList.id,
                  existingItem: item,
                ),

              );
              if (result == true) _loadItems();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Delete Item', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await ShoppingService.deleteShoppingItem(item);
              if (!context.mounted) return;
              Navigator.pop(context);
              _loadItems();
            },

          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
