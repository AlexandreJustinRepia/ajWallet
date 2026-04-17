import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/goal.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../widgets/calculator_input.dart';
import '../widgets/onboarding_overlay.dart';
import 'package:hive/hive.dart';

class AddGoalScreen extends StatefulWidget {
  final int accountKey;
  final bool isTutorialMode;
  const AddGoalScreen({super.key, required this.accountKey, this.isTutorialMode = false});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  DateTime? _targetDate;
  Color _selectedColor = Colors.green;

  final GlobalKey _nameKey = GlobalKey();
  final GlobalKey _targetKey = GlobalKey();
  final GlobalKey _saveKey = GlobalKey();
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    if (widget.isTutorialMode) {
      _nameController.text = 'Vacation';
      _targetController.text = '10000';
    }
    _checkTutorial();
  }

  void _checkTutorial() async {
    final box = await Hive.openBox('settings');
    final hasSeen = box.get('has_seen_goal_tutorial', defaultValue: false);
    if (!hasSeen) {
      if (mounted) setState(() => _showTutorial = true);
    }
  }

  void _markTutorialSeen() async {
    final box = await Hive.openBox('settings');
    await box.put('has_seen_goal_tutorial', true);
  }

  void _saveGoal() async {
    if (_formKey.currentState!.validate()) {
      final goal = Goal(
        name: _nameController.text.trim(),
        targetAmount: double.parse(_targetController.text),
        savedAmount: 0.0,
        accountKey: widget.accountKey,
        targetDate: _targetDate,
        colorValue: _selectedColor.toARGB32(),
      );

      await DatabaseService.saveGoal(goal);
      if (mounted) Navigator.pop(context, true);
    }
  }

  void _scrollTo(GlobalKey key) {
    final currentContext = key.currentContext;
    if (currentContext != null) {
      Scrollable.ensureVisible(
        currentContext,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        alignment: 0.5,
      );
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
    return OnboardingOverlay(
      visible: widget.isTutorialMode || _showTutorial,
      steps: [
        OnboardingStep(
          targetKey: _nameKey,
          title: 'Goal Name',
          description: 'Name your goal.',
          onStepEnter: () => _scrollTo(_nameKey),
        ),
        OnboardingStep(
          targetKey: _targetKey,
          title: 'Target Amount',
          description: 'Set how much you want to save.',
          onStepEnter: () => _scrollTo(_targetKey),
        ),
        OnboardingStep(
          targetKey: _saveKey,
          title: 'Save Goal',
          description: 'Create your savings goal.',
          onStepEnter: () => _scrollTo(_saveKey),
        ),
      ],
      onFinish: () {
        _markTutorialSeen();
        if (widget.isTutorialMode) {
          if (mounted) Navigator.pop(context);
        } else {
          setState(() => _showTutorial = false);
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('New Savings Goal'), 
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () => setState(() => _showTutorial = true),
            ),
          ],
        ),
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
                key: _nameKey,
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'e.g. New Car, Vacation',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Enter a name' : null,
              ),
              const SizedBox(height: 24),
              CalculatorInputField(
                key: _targetKey,
                label: 'Target Amount',
                initialValue: double.tryParse(_targetController.text),
                onChanged: (val) => setState(() => _targetController.text = val.toStringAsFixed(2)),
                validator: (val) {
                  if (val == null || val == '0' || val.isEmpty) return 'Enter amount';
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
                  key: _saveKey,
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
    ));
  }
}
