import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/database_service.dart';
import '../models/transaction_model.dart';
import '../widgets/category_form_dialog.dart';

class CategorySettingsScreen extends StatefulWidget {
  const CategorySettingsScreen({super.key});

  @override
  State<CategorySettingsScreen> createState() => _CategorySettingsScreenState();
}

class _CategorySettingsScreenState extends State<CategorySettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _addCategory() async {
    final TransactionType initialType = _tabController.index == 0 
        ? TransactionType.expense 
        : TransactionType.income;

    final Category? newCategory = await showDialog<Category>(
      context: context,
      builder: (context) => CategoryFormDialog(initialType: initialType),
    );

    if (newCategory != null) {
      await DatabaseService.saveCategory(newCategory);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Category "${newCategory.name}" created')),
        );
      }
    }
  }

  Future<void> _editCategory(Category category) async {
    final Category? updatedCategory = await showDialog<Category>(
      context: context,
      builder: (context) => CategoryFormDialog(
        existingCategory: category,
        initialType: category.type,
      ),
    );

    if (updatedCategory != null) {
      // Check if name changed to update transactions (Bonus Feature)
      final String oldName = category.name;
      final String newName = updatedCategory.name;

      category.name = newName;
      category.iconCode = updatedCategory.iconCode;
      category.type = updatedCategory.type;
      category.keywords = updatedCategory.keywords;
      
      await DatabaseService.updateCategory(category);

      if (oldName != newName) {
        // Update existing transactions and budgets with the new name
        _syncCategoryNames(oldName, newName);
      }


      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Category updated')),
        );
      }
    }
  }

  void _syncCategoryNames(String oldName, String newName) async {
     int updatedTxCount = 0;
     int updatedBudgetCount = 0;

     // Update Transactions
     final transactions = DatabaseService.getAllTransactions();
     for (var tx in transactions) {
       if (tx.category == oldName) {
         tx.category = newName;
         await tx.save();
         updatedTxCount++;
       }
     }

     // Update Budgets
     final budgets = DatabaseService.getAllBudgets();
     for (var b in budgets) {
       if (b.category == oldName) {
         b.category = newName;
         await b.save();
         updatedBudgetCount++;
       }
     }

     if (mounted && (updatedTxCount > 0 || updatedBudgetCount > 0)) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Updated $updatedTxCount transactions and $updatedBudgetCount budgets')),
       );
     }
  }


  Future<void> _deleteCategory(Category category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text('Are you sure you want to delete "${category.name}"? Transactions using this category will be moved to "Others".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final name = category.name;
      await DatabaseService.deleteCategory(category);
      
      // Move transactions to "Others"
      _moveTransactionsToOthers(name, category.type);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category deleted')),
        );
      }
    }
  }

  void _moveTransactionsToOthers(String deletedName, TransactionType type) async {
    final transactions = DatabaseService.getAllTransactions();
    for (var tx in transactions) {
      if (tx.category == deletedName && tx.type == type) {
        tx.category = 'Others';
        await tx.save();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text('Categories'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Expense'),
            Tab(text: 'Income'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoryList(TransactionType.expense),
          _buildCategoryList(TransactionType.income),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategory,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryList(TransactionType type) {
     final theme = Theme.of(context);
    return StreamBuilder(

      stream: DatabaseService.categoryWatcher,
      builder: (context, snapshot) {
        final categories = DatabaseService.getCategories(type);

        if (categories.isEmpty) {
          return const Center(child: Text('No custom categories yet.'));
        }

        return ReorderableListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          onReorder: (oldIndex, newIndex) {
            if (newIndex > oldIndex) newIndex--;
            final item = categories.removeAt(oldIndex);
            categories.insert(newIndex, item);
            DatabaseService.updateCategoriesOrder(categories);
          },
          itemBuilder: (context, index) {
            final category = categories[index];
            return Card(
              key: ValueKey(category.name + category.type.toString()),
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(category.icon, color: theme.primaryColor),
                ),
                title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: category.isDefault 
                    ? Text('Default', style: TextStyle(color: Colors.grey.withValues(alpha: 0.6), fontSize: 12)) 
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => _editCategory(category),
                    ),
                    if (!category.isDefault)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        onPressed: () => _deleteCategory(category),
                      ),
                    const SizedBox(width: 4),
                    const Icon(Icons.drag_indicator, color: Colors.grey, size: 20),
                  ],
                ),
              ),
            );
          },
        );

      },
    );
  }
}
