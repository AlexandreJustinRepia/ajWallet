import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
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
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();
  
  List<Product> _catalog = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingItem?.name ?? '');
    _priceController = TextEditingController(text: widget.existingItem?.price.toString() ?? '');
    _quantityController = TextEditingController(text: widget.existingItem?.quantity.toString() ?? '1');
    _selectedCategory = widget.existingItem?.category ?? 'Food & Drinks';
    _imagePath = widget.existingItem?.imagePath;
    
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      
      if (image != null) {
        // Save image to local directory
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';
        final savedImage = await File(image.path).copy('${appDir.path}/$fileName');
        
        setState(() {
          _imagePath = savedImage.path;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_imagePath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _imagePath = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _viewImage() {
    if (_imagePath == null) return;
    final file = File(_imagePath!);
    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image file not found')),
      );
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
                    tag: _imagePath!,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = DatabaseService.getCategories(TransactionType.expense);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(widget.existingItem == null ? 'Add Item' : 'Edit Item', style: const TextStyle(fontWeight: FontWeight.bold)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image Picker & Preview
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  GestureDetector(
                    onTap: _imagePath != null ? _viewImage : _showImagePickerOptions,
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.dividerColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                      ),
                      child: _imagePath != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.file(File(_imagePath!), fit: BoxFit.cover),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.3)],
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.fullscreen_rounded, color: Colors.white, size: 32),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_rounded, size: 32, color: theme.primaryColor.withValues(alpha: 0.5)),
                                const SizedBox(height: 8),
                                Text('Add Item Photo', style: TextStyle(color: theme.primaryColor.withValues(alpha: 0.5), fontSize: 12)),
                              ],
                            ),
                    ),
                  ),
                  if (_imagePath != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        backgroundColor: theme.primaryColor,
                        radius: 18,
                        child: IconButton(
                          icon: const Icon(Icons.edit_rounded, size: 16, color: Colors.white),
                          onPressed: _showImagePickerOptions,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                  );
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: 'Price',
                        prefixText: '₱',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) => double.tryParse(value ?? '') == null ? 'Invalid' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Qty', style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color)),
                        const SizedBox(height: 4),
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  int current = int.tryParse(_quantityController.text) ?? 1;
                                  if (current > 1) {
                                    setState(() => _quantityController.text = (current - 1).toString());
                                  }
                                },
                                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                                child: const SizedBox(
                                  width: 32,
                                  height: 48,
                                  child: Icon(Icons.remove, size: 16),
                                ),
                              ),
                              VerticalDivider(width: 1, color: theme.dividerColor.withValues(alpha: 0.1)),
                              Expanded(
                                child: TextFormField(
                                  controller: _quantityController,
                                  textAlign: TextAlign.center,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  validator: (value) => int.tryParse(value ?? '') == null ? '!' : null,
                                ),
                              ),
                              VerticalDivider(width: 1, color: theme.dividerColor.withValues(alpha: 0.1)),
                              InkWell(
                                onTap: () {
                                  int current = int.tryParse(_quantityController.text) ?? 1;
                                  setState(() => _quantityController.text = (current + 1).toString());
                                },
                                borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
                                child: const SizedBox(
                                  width: 32,
                                  height: 48,
                                  child: Icon(Icons.add, size: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                isExpanded: true,
                key: ValueKey(_selectedCategory),
                initialValue: (categories.isNotEmpty) 
                    ? (categories.any((c) => c.name == _selectedCategory) ? _selectedCategory : categories.first.name)
                    : null,
                decoration: InputDecoration(
                  labelText: 'Category',
                  prefixIcon: const Icon(Icons.category_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
      if (widget.existingItem != null) {
        // Update existing item fields to keep it connected to Hive box
        widget.existingItem!.name = _nameController.text.trim();
        widget.existingItem!.price = double.parse(_priceController.text);
        widget.existingItem!.quantity = int.parse(_quantityController.text);
        widget.existingItem!.category = _selectedCategory;
        widget.existingItem!.imagePath = _imagePath;
        
        ShoppingService.updateShoppingItem(widget.existingItem!);
      } else {
        // Create new item
        final item = ShoppingItem(
          id: const Uuid().v4(),
          name: _nameController.text.trim(),
          price: double.parse(_priceController.text),
          quantity: int.parse(_quantityController.text),
          category: _selectedCategory,
          isBought: false,
          accountKey: widget.accountKey,
          createdAt: DateTime.now(),
          listId: widget.listId,
          imagePath: _imagePath,
        );
        ShoppingService.saveShoppingItem(item);
      }
      Navigator.pop(context, true);
    }
  }
}
