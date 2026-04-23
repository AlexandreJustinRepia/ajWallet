import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/shopping_item.dart';
import '../../models/shopping_list.dart';
import '../../services/shopping_service.dart';
import '../../services/database_service.dart';
import 'add_item_dialog.dart';
import '../../models/store.dart';
import 'package:intl/intl.dart';
import '../../transaction_details_screen.dart';
import 'bulk_add_screen.dart';

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
      _items = ShoppingService.getShoppingItems(
        widget.accountKey,
        listId: widget.shoppingList.id,
      );
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
                  final logoPath = Store.getLogoForStore(
                    widget.shoppingList.storeName,
                  );
                  if (logoPath == null) {
                    return const Icon(Icons.store_rounded, size: 24);
                  }
                  return Image.asset(
                    logoPath,
                    height: 24,
                    width: 24,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.store_rounded, size: 24),
                  );
                },
              ),
              const SizedBox(width: 12),
            ],
            Text(
              widget.shoppingList.name,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, size: 20),
            onPressed: () => _showTutorial(),
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
                              _buildSectionHeader(
                                'TO BUY',
                                pendingItems.length,
                              ),
                              ...pendingItems.map(
                                (item) => _buildItemTile(item, theme),
                              ),
                              const SizedBox(height: 24),
                            ],
                            if (boughtItems.isNotEmpty) ...[
                              _buildSectionHeader(
                                'COMPLETED',
                                boughtItems.length,
                                onAction: widget.shoppingList.isSettled
                                    ? null
                                    : _uncheckAll,
                                actionIcon: Icons.undo_rounded,
                              ),
                              ...boughtItems.map(
                                (item) =>
                                    _buildItemTile(item, theme, isBought: true),
                              ),
                            ],
                            _buildHistory(theme),
                          ],
                        ),
                ),
              ],
            ),
      floatingActionButton: widget.shoppingList.isSettled
          ? null
          : FloatingActionButton.extended(
              onPressed: _addItem,
              label: const Text('Add Item'),
              icon: const Icon(Icons.add_shopping_cart_rounded),
            ),
      bottomNavigationBar: _items.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tutorial / Hint
                  if (!widget.shoppingList.isSettled &&
                      _items.any((i) => i.isBought))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.primaryColor.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withValues(
                                  alpha: 0.1,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.auto_awesome_rounded,
                                size: 14,
                                color: theme.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'READY TO BUY?',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: theme.primaryColor,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Tap "Record Purchase" below to automatically log these items as a transaction.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 10,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOTAL ESTIMATE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.5),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₱${_items.fold(0.0, (sum, i) => sum + i.total).toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'BOUGHT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.green.withValues(alpha: 0.7),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₱${_items.where((i) => i.isBought).fold(0.0, (sum, i) => sum + i.total).toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (!widget.shoppingList.isSettled)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _items.any((i) => i.isBought)
                            ? _showSettleDialog
                            : null,
                        icon: const Icon(Icons.receipt_long_rounded),
                        label: const Text(
                          'Record Purchase',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _shopAgain,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Shop Again'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _unsettleList,
                            icon: const Icon(Icons.undo_rounded),
                            label: const Text('Undo'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
    );
  }

  double _calculateBoughtTotal() {
    return _items
        .where((item) => item.isBought && item.linkedTransactionKey == null)
        .fold(0.0, (sum, item) => sum + item.total);
  }

  Widget _buildSectionHeader(
    String title,
    int count, {
    VoidCallback? onAction,
    IconData? actionIcon,
  }) {
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
              style: TextStyle(
                fontSize: 10,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ),
          if (onAction != null) ...[
            const Spacer(),
            TextButton.icon(
              onPressed: onAction,
              icon: Icon(actionIcon, size: 14, color: Colors.orange),
              label: const Text(
                'Undo All',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
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
          colors: [
            theme.primaryColor,
            theme.primaryColor.withValues(alpha: 0.8),
          ],
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
                style: TextStyle(
                  color: theme.scaffoldBackgroundColor.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
              if (widget.shoppingList.storeName != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.shoppingList.storeName!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
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
    final categoriesInList = _items
        .where((i) => !i.isBought)
        .map((i) => i.category)
        .toSet();
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
                  isExceeded
                      ? Icons.warning_amber_rounded
                      : Icons.account_balance_wallet_outlined,
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
                      fontWeight: isExceeded
                          ? FontWeight.bold
                          : FontWeight.normal,
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

  Widget _buildItemTile(
    ShoppingItem item,
    ThemeData theme, {
    bool isBought = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBought
              ? Colors.transparent
              : theme.dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        onTap: widget.shoppingList.isSettled ? null : () => _editItem(item),
        leading: InkWell(
          onTap: item.imagePath != null
              ? () => _viewFullImage(item)
              : () => _toggleItem(item),
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isBought
                      ? Colors.green.withValues(alpha: 0.1)
                      : theme.dividerColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  image:
                      (item.imagePath != null &&
                          File(item.imagePath!).existsSync())
                      ? DecorationImage(
                          image: FileImage(File(item.imagePath!)),
                          fit: BoxFit.cover,
                          colorFilter: isBought
                              ? ColorFilter.mode(
                                  Colors.white.withValues(alpha: 0.5),
                                  BlendMode.dstIn,
                                )
                              : null,
                        )
                      : null,
                ),
                child:
                    (item.imagePath == null ||
                        !File(item.imagePath!).existsSync())
                    ? Icon(
                        isBought ? Icons.check_rounded : Icons.add_rounded,
                        color: isBought ? Colors.green : theme.dividerColor,
                        size: 20,
                      )
                    : null,
              ),
              if (item.imagePath != null && File(item.imagePath!).existsSync())
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: GestureDetector(
                    onTap: () => _toggleItem(item),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        isBought
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: isBought ? Colors.green : theme.dividerColor,
                        size: 18,
                      ),
                    ),
                  ),
                ),
            ],
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
        subtitle: Row(
          children: [
            Text(
              '${item.quantity} × ₱${item.price.toStringAsFixed(0)}',
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.dividerColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                item.category,
                style: TextStyle(
                  fontSize: 9,
                  color: theme.textTheme.bodySmall?.color?.withValues(
                    alpha: 0.6,
                  ),
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '₱${item.total.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: isBought
                    ? theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5)
                    : theme.primaryColor,
              ),
            ),
            if (!widget.shoppingList.isSettled)
              IconButton(
                icon: const Icon(Icons.more_vert_rounded, size: 18),
                onPressed: () => _showItemActions(item),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
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
          Icon(
            Icons.shopping_bag_outlined,
            size: 80,
            color: theme.dividerColor.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'Your list is empty',
            style: TextStyle(
              color: theme.dividerColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text('Add items to start planning', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  void _addItem() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BulkAddItemsScreen(
          accountKey: widget.shoppingList.accountKey,
          listId: widget.shoppingList.id,
          listName: widget.shoppingList.name,
        ),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 40,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settle List to Transactions',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This will record all bought items as a single expense transaction and update your budget.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              const Text(
                'Select Payment Wallet',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              RadioGroup<int>(
                groupValue: selectedWalletKey,
                onChanged: (val) =>
                    setModalState(() => selectedWalletKey = val),
                child: Column(
                  children: wallets
                      .map(
                        (w) => RadioListTile<int>(
                          title: Text(w.name),
                          subtitle: Text(
                            'Balance: ₱${w.balance.toStringAsFixed(2)}',
                          ),
                          value: w.key as int,
                          // groupValue and onChanged are now handled by the parent RadioGroup
                        ),
                      )
                      .toList(),
                ),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    final wallet = wallets.firstWhere(
                      (w) => w.key == selectedWalletKey,
                    );
                    final totalToSettle =
                        _calculateBoughtTotal(); // Helper to get total of items being settled

                    if (wallet.balance < totalToSettle) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Insufficient funds in ${wallet.name}! Need ₱${totalToSettle.toStringAsFixed(2)}, have ₱${wallet.balance.toStringAsFixed(2)}',
                            ),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                      return;
                    }

                    Navigator.pop(context);
                    await ShoppingService.settleList(
                      widget.shoppingList,
                      selectedWalletKey!,
                    );
                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('List settled to transactions!'),
                      ),
                    );
                    Navigator.pop(context); // Go back to dashboard
                  },

                  child: const Text(
                    'Confirm Settlement',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleItem(ShoppingItem item) async {
    if (widget.shoppingList.isSettled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Purchase recorded! Tap "Shop Again" to start a new shopping session.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await ShoppingService.toggleBought(item);
    _loadItems();
  }

  void _uncheckAll() async {
    final boughtItems = _items.where((i) => i.isBought).toList();
    if (boughtItems.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.undo_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Text('Undo All Checks?'),
          ],
        ),
        content: Text(
          'Move all ${boughtItems.length} items back to the shopping list?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).dividerColor),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Yes, Undo All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      for (var item in boughtItems) {
        item.isBought = false;
        await item.save();
      }
      _loadItems();
    }
  }

  void _viewFullImage(ShoppingItem item) {
    if (item.imagePath == null) return;
    final file = File(item.imagePath!);
    if (!file.existsSync()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Image file not found')));
      return;
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black.withValues(alpha: 0.9),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Hero(
                    tag: item.id,
                    child: Image.file(file, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.topRight,
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withValues(alpha: 0.5),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editItem(ShoppingItem item) async {
    final result = await showDialog(
      context: context,
      builder: (context) => AddShoppingItemDialog(
        accountKey: widget.accountKey,
        listId: widget.shoppingList.id,
        existingItem: item,
      ),
    );
    if (result == true) _loadItems();
  }

  void _showItemActions(ShoppingItem item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
            title: const Text(
              'Delete Item',
              style: TextStyle(color: Colors.red),
            ),
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

  void _showTutorial() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: Colors.amber),
            SizedBox(width: 12),
            Text('How it works'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTutorialStep(
              Icons.check_box_outlined,
              'Check items as you shop in the store.',
            ),
            const SizedBox(height: 16),
            _buildTutorialStep(
              Icons.receipt_long_rounded,
              'Tap "Record Purchase" to turn your list into a real transaction.',
            ),
            const SizedBox(height: 16),
            _buildTutorialStep(
              Icons.refresh_rounded,
              'Use "Shop Again" to reset the list for your next trip!',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialStep(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    );
  }

  Widget _buildHistory(ThemeData theme) {
    final history = ShoppingService.getPurchaseHistory(widget.shoppingList.id);
    if (history.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        _buildSectionHeader('PURCHASE HISTORY', history.length),
        const SizedBox(height: 12),
        ...history.map(
          (tx) => Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        TransactionDetailsScreen(transaction: tx),
                  ),
                );
                _loadItems(); // Refresh just in case
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.history_edu_rounded,
                        color: Colors.green,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '₱${tx.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            DateFormat(
                              'MMM dd, yyyy • hh:mm a',
                            ).format(tx.date),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: theme.dividerColor.withValues(alpha: 0.3),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _unsettleList() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Undo Purchase?'),
        content: const Text(
          'This will delete the latest transaction and let you edit the items again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Undo', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ShoppingService.unsettleList(widget.shoppingList);
      _loadItems();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Purchase undone.')));
      }
    }
  }

  void _shopAgain() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Shop Again?'),
        content: const Text(
          'This will reset your checkboxes for a new shopping trip. Your past purchase history will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Start New Run'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // 1. Mark as unsettled but DO NOT delete transaction
      widget.shoppingList.isSettled = false;
      widget.shoppingList.linkedTransactionKey =
          null; // Prepare for next settlement
      await widget.shoppingList.save();

      // 2. Uncheck all items
      for (var item in _items) {
        item.isBought = false;
        item.linkedTransactionKey = null;
        await item.save();
      }

      _loadItems();
    }
  }
}
