import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/shopping_list.dart';
import '../../services/shopping_service.dart';
import '../../services/database_service.dart';
import 'shopping_list_screen.dart';
import '../../models/store.dart';
import 'package:intl/intl.dart';

class ShoppingListsDashboard extends StatefulWidget {
  final int accountKey;

  const ShoppingListsDashboard({super.key, required this.accountKey});

  @override
  State<ShoppingListsDashboard> createState() => _ShoppingListsDashboardState();
}

class _ShoppingListsDashboardState extends State<ShoppingListsDashboard> {
  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  void _loadLists() {
    setState(() {});
  }

  void _createNewList() async {
    final nameController = TextEditingController();
    String? selectedStoreName;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: const Text('New Shopping List', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'List Name',
                    hintText: 'e.g. Weekly Groceries',
                    prefixIcon: const Icon(Icons.edit_note_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('STORE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.2, color: Colors.grey)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final store = await _showStorePicker(context);
                    if (store != null) {
                      setModalState(() => selectedStoreName = store.name);
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        if (selectedStoreName != null) ...[
                          Builder(
                            builder: (context) {
                              final logoPath = Store.getLogoForStore(selectedStoreName);
                              if (logoPath == null) return const Icon(Icons.store_rounded, size: 24);
                              return Image.asset(
                                logoPath,
                                height: 24,
                                width: 24,
                                fit: BoxFit.contain,
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          Text(
                            selectedStoreName!,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ] else ...[
                          const Icon(Icons.store_rounded, size: 24, color: Colors.grey),
                          const SizedBox(width: 12),
                          const Text('Select Store (Optional)', style: TextStyle(color: Colors.grey)),
                        ],
                        const Spacer(),
                        const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context, {
                'name': nameController.text,
                'store': selectedStoreName,
              }),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    if (result != null && result['name'].isNotEmpty) {
      final newList = ShoppingList(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: result['name'],
        accountKey: widget.accountKey,
        createdAt: DateTime.now(),
        storeName: result['store'],
      );
      await ShoppingService.saveShoppingList(newList);
      _loadLists();

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ShoppingListScreen(
              accountKey: widget.accountKey,
              shoppingList: newList,
            ),
          ),
        ).then((_) => _loadLists());
      }
    }
  }

  Future<Store?> _showStorePicker(BuildContext context) {
    final theme = Theme.of(context);
    return showModalBottomSheet<Store>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  const Icon(Icons.store_rounded, size: 28),
                  const SizedBox(width: 16),
                  Text(
                    'Select Store',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: Store.convenienceStores.length,
                itemBuilder: (context, index) {
                  final store = Store.convenienceStores[index];
                  return InkWell(
                    onTap: () => Navigator.pop(context, store),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(store.logoPath, height: 50, width: 50, fit: BoxFit.contain),
                          const SizedBox(height: 12),
                          Text(
                            store.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Shopping Lists', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: _createNewList,
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: DatabaseService.shoppingListListenable,
        builder: (context, box, _) {
          final lists = ShoppingService.getShoppingLists(widget.accountKey);
          
          if (lists.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.shopping_bag_outlined, size: 80, color: theme.primaryColor.withValues(alpha: 0.2)),
                  ),
                  const SizedBox(height: 24),
                  const Text('No shopping lists yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('Plan your next grocery run easily.', style: TextStyle(color: theme.textTheme.bodySmall?.color)),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _createNewList,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Create First List'),
                  ),
                ],
              ),
            );
          }

          int totalItems = 0;
          int boughtItems = 0;
          for (var list in lists) {
            final items = ShoppingService.getShoppingItems(widget.accountKey, listId: list.id);
            totalItems += items.length;
            boughtItems += items.where((i) => i.isBought).length;
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
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
                  child: Row(
                    children: [
                      _buildSummaryStat(
                        'Active Lists',
                        lists.where((l) => !l.isSettled).length.toString(),
                        Colors.white,
                      ),
                      Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.2), margin: const EdgeInsets.symmetric(horizontal: 20)),
                      _buildSummaryStat(
                        'Items to Buy',
                        (totalItems - boughtItems).toString(),
                        Colors.white,
                      ),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final list = lists[index];
                      return _buildListCard(list, theme);
                    },
                    childCount: lists.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewList,
        label: const Text('New List'),
        icon: const Icon(Icons.add_shopping_cart_rounded),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildListCard(ShoppingList list, ThemeData theme) {
    final items = ShoppingService.getShoppingItems(widget.accountKey, listId: list.id);
    final boughtCount = items.where((i) => i.isBought).length;
    final totalCount = items.length;
    final progress = totalCount == 0 ? 0.0 : boughtCount / totalCount;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ShoppingListScreen(
                  accountKey: widget.accountKey,
                  shoppingList: list,
                ),
              ),
            ).then((_) => _loadLists());
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          if (list.storeName != null) ...[
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Builder(
                                builder: (context) {
                                  final logoPath = Store.getLogoForStore(list.storeName);
                                  if (logoPath == null) return Icon(Icons.store_rounded, size: 20, color: theme.primaryColor);
                                  return Image.asset(
                                    logoPath,
                                    height: 20,
                                    width: 20,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => Icon(Icons.store_rounded, size: 20, color: theme.primaryColor),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  list.name,
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  DateFormat('EEEE, MMM dd').format(list.createdAt),
                                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, letterSpacing: 0.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (list.isSettled)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline, size: 12, color: Colors.green),
                            SizedBox(width: 4),
                            Text('SETTLED', style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ],
                        ),
                      ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, size: 20),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      onSelected: (value) async {
                        if (value == 'delete') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete List?'),
                              content: Text('Delete "${list.name}" and all its items?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await ShoppingService.deleteShoppingList(list);
                            _loadLists();
                          }
                        } else if (value == 'unsettle') {
                          await ShoppingService.unsettleList(list);
                          _loadLists();
                        }
                      },
                      itemBuilder: (context) => [
                        if (list.isSettled)
                          const PopupMenuItem(
                            value: 'unsettle',
                            child: Row(children: [Icon(Icons.undo_rounded, size: 18), SizedBox(width: 8), Text('Undo Settlement')]),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))]),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (items.isNotEmpty) ...[
                  SizedBox(
                    height: 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: items.length > 5 ? 6 : items.length,
                      itemBuilder: (context, i) {
                        if (i == 5 && items.length > 5) {
                          return Container(
                            width: 36,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: theme.dividerColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '+${items.length - 5}',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.primaryColor),
                              ),
                            ),
                          );
                        }
                        final item = items[i];
                        return Container(
                          width: 36,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: theme.dividerColor.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                            image: (item.imagePath != null && File(item.imagePath!).existsSync())
                                ? DecorationImage(
                                    image: FileImage(File(item.imagePath!)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: (item.imagePath == null || !File(item.imagePath!).existsSync())
                              ? Icon(Icons.shopping_basket_outlined, size: 16, color: theme.dividerColor.withValues(alpha: 0.3))
                              : null,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      totalCount == 0 ? 'No items' : '$boughtCount / $totalCount items',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                    if (totalCount > 0)
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: progress == 1.0 ? Colors.green : theme.primaryColor,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) => Stack(
                    children: [
                      Container(
                        height: 6,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: theme.dividerColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                        height: 6,
                        width: constraints.maxWidth * progress,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [theme.primaryColor, theme.primaryColor.withValues(alpha: 0.7)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
