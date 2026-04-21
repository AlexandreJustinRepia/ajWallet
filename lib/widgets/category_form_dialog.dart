import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/transaction_model.dart';
import 'icon_picker_dialog.dart';

class CategoryFormDialog extends StatefulWidget {
  final Category? existingCategory;
  final TransactionType initialType;

  const CategoryFormDialog({
    super.key,
    this.existingCategory,
    required this.initialType,
  });

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _keywordsController;
  late TransactionType _selectedType;

  late IconData _selectedIcon;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingCategory?.name ?? '');
    _keywordsController = TextEditingController(
      text: widget.existingCategory?.keywords?.join(', ') ?? '',
    );
    _selectedType = widget.existingCategory?.type ?? widget.initialType;

    _selectedIcon = widget.existingCategory != null
        ? widget.existingCategory!.icon
        : Icons.category;
  }

  void _pickIcon() async {
    final IconData? picked = await showDialog<IconData>(
      context: context,
      builder: (context) => IconPickerDialog(selectedIcon: _selectedIcon),
    );
    if (picked != null) {
      setState(() => _selectedIcon = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.existingCategory != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Category' : 'New Category'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Picker
              InkWell(
                onTap: _pickIcon,
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
                  ),
                  child: Icon(_selectedIcon, size: 40, color: theme.primaryColor),
                ),
              ),
              const SizedBox(height: 8),
              Text('Tap to change icon', style: theme.textTheme.labelSmall),
              const SizedBox(height: 24),

              // Name Input
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Category Name',
                  hintText: 'e.g. Groceries, Gym, Salary',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Type Selector
              Row(
                children: [
                   Expanded(
                    child: _typeOption(
                      'Expense', 
                      TransactionType.expense, 
                      const Color(0xFFC62828)
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _typeOption(
                      'Income', 
                      TransactionType.income, 
                      const Color(0xFF2E7D32)
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Keywords Input
              TextFormField(
                controller: _keywordsController,
                decoration: InputDecoration(
                  labelText: 'Auto-Categorize Keywords',
                  hintText: 'e.g. jollibee, mcdo, burger (comma separated)',
                  helperText: 'Descriptions containing these words will auto-select this category.',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
              ),

            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final category = Category(
                name: _nameController.text.trim(),
                iconCode: _selectedIcon.codePoint,
                type: _selectedType,
                isDefault: widget.existingCategory?.isDefault ?? false,
                keywords: _keywordsController.text
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList(),
              );
              Navigator.pop(context, category);

            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            foregroundColor: theme.scaffoldBackgroundColor,
          ),
          child: Text(isEditing ? 'Update' : 'Create'),
        ),
      ],
    );
  }

  Widget _typeOption(String label, TransactionType type, Color color) {
    final isSelected = _selectedType == type;
    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? color : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
