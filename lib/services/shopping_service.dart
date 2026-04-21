import 'database_service.dart';
import '../models/shopping_item.dart';
import '../models/product.dart';
import '../models/transaction_model.dart';
import '../models/shopping_list.dart';

class ShoppingService {

  // --- Shopping List Operations ---

  static List<ShoppingList> getShoppingLists(int accountKey) {
    return DatabaseService.shoppingListListenable.value.values
        .where((list) => list.accountKey == accountKey)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<void> saveShoppingList(ShoppingList list) async {
    await DatabaseService.shoppingListListenable.value.add(list);
  }

  static Future<void> deleteShoppingList(ShoppingList list) async {
    // Also delete all items in this list
    final items = DatabaseService.shoppingItemBox.values.where((i) => i.listId == list.id).toList();
    for (var item in items) {
      await item.delete();
    }
    await list.delete();
  }

  // --- Shopping Item Operations ---

  static List<ShoppingItem> getShoppingItems(int accountKey, {String? listId}) {
    var query = DatabaseService.shoppingItemBox.values
        .where((item) => item.accountKey == accountKey);
    
    if (listId != null) {
      query = query.where((item) => item.listId == listId);
    }

    return query.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }


  static Future<void> saveShoppingItem(ShoppingItem item) async {
    await DatabaseService.shoppingItemBox.add(item);
    
    // Automatically update or add to product catalog
    await _updateProductCatalog(item);
  }

  static Future<void> updateShoppingItem(ShoppingItem item) async {
    await item.save();
    await _updateProductCatalog(item);
  }

  static Future<void> deleteShoppingItem(ShoppingItem item) async {
    await item.delete();
  }

  static Future<void> toggleBought(ShoppingItem item) async {
    item.isBought = !item.isBought;
    await item.save();
  }

  // --- Product Catalog Operations ---

  static List<Product> getProductCatalog(int accountKey) {
    return DatabaseService.productCatalogBox.values
        .where((p) => p.accountKey == accountKey)
        .toList();
  }

  static Future<void> _updateProductCatalog(ShoppingItem item) async {
    final catalog = DatabaseService.productCatalogBox;
    
    // Check if product exists in catalog
    final existingIndex = catalog.values.cast<Product>().toList().indexWhere(
      (p) => p.name.toLowerCase() == item.name.toLowerCase() && p.accountKey == item.accountKey
    );

    if (existingIndex != -1) {
      final existingProduct = catalog.getAt(existingIndex)!;
      existingProduct.lastPrice = item.price;
      existingProduct.defaultCategory = item.category;
      await existingProduct.save();
    } else {
      await catalog.add(Product(
        name: item.name,
        lastPrice: item.price,
        defaultCategory: item.category,
        accountKey: item.accountKey,
      ));
    }
  }

  // --- Budget Integration ---

  static double calculateCurrentMonthlySpent(int accountKey, String category) {
    final now = DateTime.now();
    return DatabaseService.getAllTransactions()
        .where((t) => 
            t.accountKey == accountKey && 
            t.category == category &&
            t.type == TransactionType.expense &&
            t.date.month == now.month &&
            t.date.year == now.year)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  static double getBudgetLimit(int accountKey, String category) {
    final now = DateTime.now();
    final budget = DatabaseService.getBudgetForCategory(accountKey, category, now.month, now.year);
    return budget?.amountLimit ?? 0.0;
  }

  static double getShoppingTotalForCategory(int accountKey, String category) {
    return getShoppingItems(accountKey)
        .where((item) => item.category == category && !item.isBought)
        .fold(0.0, (sum, item) => sum + item.total);
  }

  /// Returns total anticipated spend (Spent + Unbought Shopping Items) vs Budget Limit
  static Map<String, double> getBudgetImpact(int accountKey, String category) {
    final spent = calculateCurrentMonthlySpent(accountKey, category);
    final shoppingTotal = getShoppingTotalForCategory(accountKey, category);
    final limit = getBudgetLimit(accountKey, category);
    
    return {
      'spent': spent,
      'shoppingTotal': shoppingTotal,
      'limit': limit,
      'totalAnticipated': spent + shoppingTotal,
      'remaining': limit > 0 ? (limit - (spent + shoppingTotal)) : 0.0,
    };
  }

  /// Gets exactly how much is left in budget, subtracting both transactions AND existing shopping items
  static double getRemainingBudget(int accountKey, String category) {
    final impact = getBudgetImpact(accountKey, category);
    if (impact['limit']! <= 0) return -1; // No budget set
    return impact['limit']! - (impact['spent']! + impact['shoppingTotal']!);
  }

  // --- Settlement Logic ---

  /// Converts all bought items in a list into a single (or multiple) transactions
  /// and marks the list as settled.
  static Future<void> settleList(ShoppingList list, int walletKey) async {
    final itemsToSettle = getShoppingItems(list.accountKey, listId: list.id)
        .where((item) => item.isBought && item.linkedTransactionKey == null)
        .toList();

    if (itemsToSettle.isEmpty) return;

    // We can either create one bundled transaction or individual ones.
    // User asked: "display it on transaction"
    // Bundling is usually cleaner for groceries.
    double total = itemsToSettle.fold(0.0, (sum, item) => sum + item.total);
    
    final transaction = Transaction(
      title: 'Shopping: ${list.name}',
      amount: total,
      date: DateTime.now(),
      category: itemsToSettle.first.category, // Use first item's category as primary
      description: itemsToSettle.map((i) => "${i.quantity}x ${i.name}").join(", "),
      type: TransactionType.expense,
      accountKey: list.accountKey,
      walletKey: walletKey,
    );

    final txKey = await DatabaseService.saveTransaction(transaction);

    // Link items to this transaction
    for (var item in itemsToSettle) {
      item.linkedTransactionKey = txKey;
      await item.save();
    }

    list.isSettled = true;
    list.totalAmount = total;
    list.linkedTransactionKey = txKey; // Store the key for later reversal
    await list.save();
  }

  /// Safely reverses a settlement by deleting the associated transaction
  /// and unlinking all items.
  static Future<void> unsettleList(ShoppingList list) async {
    if (!list.isSettled || list.linkedTransactionKey == null) return;

    // 1. Delete the transaction
    await DatabaseService.deleteTransactionByKey(list.linkedTransactionKey!);

    // 2. Unlink items
    final items = getShoppingItems(list.accountKey, listId: list.id);
    for (var item in items) {
      if (item.linkedTransactionKey == list.linkedTransactionKey) {
        item.linkedTransactionKey = null;
        await item.save();
      }
    }

    // 3. Update list state
    list.isSettled = false;
    list.linkedTransactionKey = null;
    list.totalAmount = 0;
    await list.save();
  }
}



