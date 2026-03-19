import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/goal.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class AddGoalScreen extends StatefulWidget {
  final int accountKey;
  const AddGoalScreen({super.key, required this.accountKey});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  DateTime? _targetDate;
  Color _selectedColor = Colors.green;

  void _saveGoal() async {
    if (_formKey.currentState!.validate()) {
      final goal = Goal(
        name: _nameController.text.trim(),
        targetAmount: double.parse(_targetController.text),
        savedAmount: 0.0,
        accountKey: widget.accountKey,
        targetDate: _targetDate,
        colorValue: _selectedColor.value,
      );

      await DatabaseService.saveGoal(goal);
      if (mounted) Navigator.pop(context, true);
    }
  }

  void _pickColor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: BlockPicker(
          pickerColor: _selectedColor,
          onColorChanged: (color) => setState(() => _selectedColor = color),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
        ],
      ),
    );
  }

  void _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (date != null) {
      setState(() => _targetDate = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('New Savings Goal'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Goal Name', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'e.g. New Car, Vacation',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Enter a name' : null,
              ),
              const SizedBox(height: 24),
              Text('Target Amount', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _targetController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixText: "₱ ",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Enter amount';
                  if (double.tryParse(val) == null) return 'Invalid amount';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Target Date (Optional)', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: theme.dividerColor),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 20),
                                const SizedBox(width: 12),
                                Text(_targetDate == null ? 'Select Date' : DateFormat('MMM dd, yyyy').format(_targetDate!)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Color', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickColor,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: _selectedColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.dividerColor, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _saveGoal,
                  child: Text('Save Goal', style: TextStyle(color: theme.scaffoldBackgroundColor, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
