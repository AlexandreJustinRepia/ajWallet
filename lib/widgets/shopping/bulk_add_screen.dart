import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../models/shopping_item.dart';
import '../../services/shopping_service.dart';
import '../../services/database_service.dart';

class BulkAddItemsScreen extends StatefulWidget {
  final int accountKey;
  final String listId;
  final String listName;

  const BulkAddItemsScreen({
    super.key,
    required this.accountKey,
    required this.listId,
    required this.listName,
  });

  @override
  State<BulkAddItemsScreen> createState() => _BulkAddItemsScreenState();
}

class _BulkAddItemsScreenState extends State<BulkAddItemsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  String _selectedCategory = 'Food & Drinks';
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();
  
  List<ShoppingItem> _sessionItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  Future<void> _loadDrafts() async {
    final drafts = DatabaseService.shoppingDraftBox.values
        .where((item) => item.listId == widget.listId && item.accountKey == widget.accountKey)
        .toList();
    
    setState(() {
      _sessionItems = drafts;
      _isLoading = false;
    });
  }

  Future<void> _saveDrafts() async {
    final box = DatabaseService.shoppingDraftBox;
    // Clear old drafts for this list first
    final keysToDelete = box.keys.where((key) {
      final item = box.get(key);
      return item?.listId == widget.listId;
    }).toList();
    
    await box.deleteAll(keysToDelete);
    
    // Add current session items
    for (var item in _sessionItems) {
      await box.add(item);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _addItemToSession() {
    if (_formKey.currentState!.validate()) {
      final newItem = ShoppingItem(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        price: double.tryParse(_priceController.text) ?? 0.0,
        quantity: int.tryParse(_quantityController.text) ?? 1,
        category: _selectedCategory,
        listId: widget.listId,
        accountKey: widget.accountKey,
        createdAt: DateTime.now(),
        imagePath: _imagePath,
      );

      setState(() {
        _sessionItems.insert(0, newItem);
        // Clear form
        _nameController.clear();
        _priceController.clear();
        _quantityController.text = '1';
        _imagePath = null;
      });
      
      _saveDrafts();
    }
  }

  void _removeItem(int index) {
    setState(() {
      _sessionItems.removeAt(index);
    });
    _saveDrafts();
  }

  Future<void> _saveAll() async {
    if (_sessionItems.isEmpty) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isLoading = true);
    
    for (var item in _sessionItems) {
      // Clone the item to avoid HiveError: "The same instance of an HiveObject cannot be stored in two different boxes"
      final freshItem = ShoppingItem.fromMap(item.toMap());
      await ShoppingService.saveShoppingItem(freshItem);
    }

    // Clear drafts
    final box = DatabaseService.shoppingDraftBox;
    final keysToDelete = box.keys.where((key) {
      final item = box.get(key);
      return item?.listId == widget.listId;
    }).toList();
    await box.deleteAll(keysToDelete);

    if (mounted) {
      Navigator.pop(context, true);
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Add Multiple Items', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(widget.listName, style: theme.textTheme.bodySmall),
          ],
        ),
        actions: [
          if (_sessionItems.isNotEmpty)
            TextButton(
              onPressed: _saveAll,
              child: const Text('SAVE ALL', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // Entry Form
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildEntryForm(theme),
              ),
              
              const Divider(height: 1),
              
              // Added Items Preview
              Expanded(
                child: _sessionItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_basket_outlined, size: 64, color: theme.dividerColor),
                            const SizedBox(height: 16),
                            Text('No items added yet', style: theme.textTheme.bodyLarge?.copyWith(color: theme.dividerColor)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _sessionItems.length,
                        itemBuilder: (context, index) {
                          final item = _sessionItems[index];
                          return _buildItemPreview(item, index, theme);
                        },
                      ),
              ),
            ],
          ),
      bottomNavigationBar: _sessionItems.isEmpty ? null : SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _saveAll,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Text('Save ${_sessionItems.length} Items to List', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ),
    );
  }

  Widget _buildEntryForm(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Item Name (e.g. Milk)',
                        prefixIcon: const Icon(Icons.shopping_bag_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Price',
                        prefixText: '₱',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      ),
                      items: ShoppingItem.categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 80,
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'Qty',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildImageButton(theme),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addItemToSession,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Add to Batch'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageButton(ThemeData theme) {
    return InkWell(
      onTap: () => _pickImage(ImageSource.camera),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _imagePath != null ? Colors.green.withValues(alpha: 0.1) : theme.dividerColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _imagePath != null ? Colors.green : Colors.transparent),
        ),
        child: Icon(
          _imagePath != null ? Icons.check_circle : Icons.camera_alt_outlined,
          color: _imagePath != null ? Colors.green : theme.primaryColor,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildItemPreview(ShoppingItem item, int index, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        leading: item.imagePath != null 
          ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(item.imagePath!), width: 40, height: 40, fit: BoxFit.cover))
          : CircleAvatar(backgroundColor: theme.primaryColor.withValues(alpha: 0.1), child: Icon(Icons.shopping_bag, color: theme.primaryColor, size: 20)),
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${item.quantity}x • ${item.category}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('₱${item.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              onPressed: () => _removeItem(index),
            ),
          ],
        ),
      ),
    );
  }
}
