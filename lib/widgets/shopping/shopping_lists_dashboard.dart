import 'package:flutter/material.dart';
import '../../models/shopping_list.dart';
import '../../services/shopping_service.dart';
import '../../services/database_service.dart';
import 'shopping_list_screen.dart';
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
    // Relying on ValueListenableBuilder for UI updates
  }


  void _createNewList() async {
    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Shopping List'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Weekly Groceries, Party Supplies',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final newList = ShoppingList(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: result,
        accountKey: widget.accountKey,
        createdAt: DateTime.now(),
      );
      await ShoppingService.saveShoppingList(newList);
      _loadLists();
      
      // Navigate immediately
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Shopping Lists'),
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
                  Icon(Icons.shopping_bag_outlined, size: 80, color: theme.dividerColor.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  const Text('No shopping lists yet', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _createNewList,
                    icon: const Icon(Icons.add),
                    label: const Text('Create First List'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lists.length,
            itemBuilder: (context, index) {
              final list = lists[index];
              return _buildListCard(list, theme);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewList,
        label: const Text('New List'),
        icon: const Icon(Icons.add_shopping_cart_rounded),
      ),
    );
  }

  Widget _buildListCard(ShoppingList list, ThemeData theme) {
    // Get item count for this list
    final items = ShoppingService.getShoppingItems(widget.accountKey, listId: list.id);
    final boughtCount = items.where((i) => i.isBought).length;
    final totalCount = items.length;
    final progress = totalCount == 0 ? 0.0 : boughtCount / totalCount;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          list.name,
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          DateFormat('MMM dd, yyyy').format(list.createdAt),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (list.isSettled)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline, size: 14, color: Colors.green),
                          SizedBox(width: 4),
                          Text('SETTLED', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (value) async {
                      if (value == 'delete') {
                        final messenger = ScaffoldMessenger.of(context);
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete List?'),
                            content: Text('This will permanently delete "${list.name}" and all its items.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ShoppingService.deleteShoppingList(list);
                          messenger.showSnackBar(
                            const SnackBar(content: Text('List deleted.')),
                          );
                        }
                      } else if (value == 'unsettle') {

                        final messenger = ScaffoldMessenger.of(context);
                        await ShoppingService.unsettleList(list);
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Settlement revoked. Transaction deleted.')),
                        );
                      }



                    },
                    itemBuilder: (context) => [
                      if (list.isSettled)
                        const PopupMenuItem(
                          value: 'unsettle',
                          child: Row(children: [Icon(Icons.undo_rounded, size: 20), SizedBox(width: 8), Text('Undo Settlement')]),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red), SizedBox(width: 8), Text('Delete List', style: TextStyle(color: Colors.red))]),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    totalCount == 0 ? 'No items' : '$boughtCount / $totalCount items',
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (totalCount > 0)
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: progress == 1.0 ? Colors.green : theme.primaryColor,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                minHeight: 8,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
