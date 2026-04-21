import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/shopping_item.dart';
import '../../models/product.dart';
import '../../services/shopping_service.dart';
import '../../services/database_service.dart';
import '../../models/transaction_model.dart';



class AddShoppingItemDialog extends StatefulWidget {
  final int accountKey;
  final String? listId;
  final ShoppingItem? existingItem;


  const AddShoppingItemDialog({
    super.key,
    required this.accountKey,
    this.listId,
    this.existingItem,
  });


  @override
  State<AddShoppingItemDialog> createState() => _AddShoppingItemDialogState();
}

class _AddShoppingItemDialogState extends State<AddShoppingItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  String _selectedCategory = 'Food & Drinks';
  
  List<Product> _catalog = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingItem?.name ?? '');
    _priceController = TextEditingController(text: widget.existingItem?.price.toString() ?? '');
    _quantityController = TextEditingController(text: widget.existingItem?.quantity.toString() ?? '1');
    _selectedCategory = widget.existingItem?.category ?? 'Food & Drinks';
    
    _catalog = ShoppingService.getProductCatalog(widget.accountKey);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _onProductSelected(Product product) {
    setState(() {
      _nameController.text = product.name;
      _priceController.text = product.lastPrice.toString();
      _selectedCategory = product.defaultCategory;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = DatabaseService.getCategories(TransactionType.expense); // Fetch expense categories only

    return AlertDialog(
      title: Text(widget.existingItem == null ? 'Add Item' : 'Edit Item'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Product Name with Autocomplete
              Autocomplete<Product>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') {
                    return const Iterable<Product>.empty();
                  }
                  return _catalog.where((Product option) {
                    return option.name.toLowerCase().contains(textEditingValue.text.toLowerCase());
                  });
                },
                displayStringForOption: (Product option) => option.name,
                onSelected: _onProductSelected,
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  // Initialize controller text if we're editing
                  if (controller.text.isEmpty && _nameController.text.isNotEmpty) {
                    controller.text = _nameController.text;
                  }

                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    onChanged: (val) => _nameController.text = val,
                    decoration: InputDecoration(
                      labelText: 'Product Name',
                      hintText: 'e.g. Eggs, Soap',
                      prefixIcon: const Icon(Icons.shopping_basket_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                  );
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  // Price
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: 'Price',
                        prefixText: '₱',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) => double.tryParse(value ?? '') == null ? 'Invalid' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Quantity
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: 'Qty',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => int.tryParse(value ?? '') == null ? 'Invalid' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Category Selector
              DropdownButtonFormField<String>(
                isExpanded: true,
                key: ValueKey(_selectedCategory),
                initialValue: (categories.isNotEmpty) 
                    ? (categories.any((c) => c.name == _selectedCategory) ? _selectedCategory : categories.first.name)
                    : null,
                decoration: InputDecoration(
                  labelText: 'Category',
                  prefixIcon: const Icon(Icons.category_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: categories.isEmpty 
                  ? [const DropdownMenuItem(value: 'Others', child: Text('Others'))]
                  : categories.map((c) {
                    double remaining = -1;
                    try {
                      remaining = ShoppingService.getRemainingBudget(widget.accountKey, c.name);
                    } catch (e) {
                      debugPrint('Error calculating budget for ${c.name}: $e');
                    }
                    final budgetLabel = remaining == -1 ? '' : ' (₱${remaining.toStringAsFixed(0)} left)';
                    
                    return DropdownMenuItem(
                      value: c.name,
                      child: Row(
                        children: [
                          Icon(c.icon, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(c.name + budgetLabel, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    );
                  }).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
              ),
              
              const SizedBox(height: 12),
              _buildBudgetWarning(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            foregroundColor: theme.scaffoldBackgroundColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(widget.existingItem == null ? 'Add to List' : 'Update'),
        ),
      ],
    );
  }

  Widget _buildBudgetWarning() {
    final price = double.tryParse(_priceController.text) ?? 0.0;
    final qty = int.tryParse(_quantityController.text) ?? 1;
    final itemTotal = price * qty;
    
    final impact = ShoppingService.getBudgetImpact(widget.accountKey, _selectedCategory);
    final limit = impact['limit']!;
    final anticipated = impact['totalAnticipated']! + (widget.existingItem == null ? itemTotal : (itemTotal - widget.existingItem!.total));

    final remainingAfter = limit - anticipated;

    if (limit > 0) {
      if (anticipated > limit) {
        return _buildAlertBox(
          '⚠️ This will exceed your $_selectedCategory budget by ₱${(anticipated - limit).toStringAsFixed(2)}',
          Colors.red,
        );
      } else if (remainingAfter <= 500 && remainingAfter > 0) {
        return _buildAlertBox(
          '💡 You\'ll only have ₱${remainingAfter.toStringAsFixed(0)} left for your $_selectedCategory budget.',
          Colors.orange,
        );
      }
    }
    return const SizedBox.shrink();
  }

  Widget _buildAlertBox(String message, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(message.startsWith('⚠️') ? Icons.warning_amber_rounded : Icons.lightbulb_outline_rounded, 
               color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }


  void _submit() {
    if (_formKey.currentState!.validate()) {
      final item = ShoppingItem(
        id: widget.existingItem?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text),
        quantity: int.parse(_quantityController.text),
        category: _selectedCategory,
        isBought: widget.existingItem?.isBought ?? false,
        accountKey: widget.accountKey,
        createdAt: widget.existingItem?.createdAt ?? DateTime.now(),
        listId: widget.existingItem?.listId ?? widget.listId,
        linkedTransactionKey: widget.existingItem?.linkedTransactionKey,
      );


      if (widget.existingItem != null) {
        ShoppingService.updateShoppingItem(item);
      } else {
        ShoppingService.saveShoppingItem(item);
      }
      Navigator.pop(context, true);
    }
  }
}
