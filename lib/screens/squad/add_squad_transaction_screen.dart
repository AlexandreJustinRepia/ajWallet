import 'package:flutter/material.dart';
import '../../models/squad.dart';
import '../../models/squad_member.dart';
import '../../models/squad_transaction.dart';
import '../../models/wallet.dart';
import '../../services/database_service.dart';
import 'package:intl/intl.dart';
import '../../widgets/onboarding_overlay.dart';
import '../../services/attachment_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../widgets/image_gallery_viewer.dart';
import '../../widgets/calculator_input.dart';

class AddSquadTransactionScreen extends StatefulWidget {
  final Squad squad;
  final int accountKey;
  const AddSquadTransactionScreen({
    super.key,
    required this.squad,
    required this.accountKey,
  });

  @override
  State<AddSquadTransactionScreen> createState() =>
      _AddSquadTransactionScreenState();
}

class _AddSquadTransactionScreenState extends State<AddSquadTransactionScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  late List<SquadMember> _members;
  int? _payerKey;
  SplitType _splitType = SplitType.equal;
  final Map<int, double> _splits = {}; // memberKey -> value (amount or percent)
  final Set<int> _includedMembers = {};

  int? _selectedWalletKey;
  List<Wallet> _wallets = [];
  final List<String> _attachmentPaths = [];
  
  bool _isTutorialActive = false;
  final GlobalKey _helpKey = GlobalKey();
  final GlobalKey _detailsKey = GlobalKey();
  final GlobalKey _payerRowKey = GlobalKey();
  final GlobalKey _modeKey = GlobalKey();
  final GlobalKey _membersKey = GlobalKey();
  final GlobalKey _saveKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _members = DatabaseService.getSquadMembers(widget.squad.key as int);
    _wallets = DatabaseService.getWallets(widget.accountKey);

    // Default payer is "You" if found, else first member
    final you = _members.cast<SquadMember?>().firstWhere(
          (m) => m?.isYou ?? false,
          orElse: () => null,
        );
    _payerKey = you?.key as int? ?? _members.first.key as int?;

    // Default: everyone is included in equal split
    for (var m in _members) {
      _includedMembers.add(m.key as int);
    }
  }

  void _saveTransaction() async {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0;

    if (title.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid title and amount')),
      );
      return;
    }

    if (_payerKey == null) return;

    // Build the splits map and validate
    final Map<int, double> finalSplits = {};
    if (_splitType == SplitType.equal) {
      for (var id in _includedMembers) {
        finalSplits[id] = 0; // The logic in SquadService handles equal splitting
      }
    } else {
      double totalSplits = 0;
      for (var id in _includedMembers) {
        final val = _splits[id] ?? 0;
        finalSplits[id] = val;
        totalSplits += val;
      }

      if (_splitType == SplitType.amount && (totalSplits - amount).abs() > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Total splits (₱$totalSplits) must equal amount (₱$amount)')),
        );
        return;
      }
      if (_splitType == SplitType.percentage && (totalSplits - 100).abs() > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Total percentages must equal 100%')),
        );
        return;
      }
    }

    if (finalSplits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one member must be included in the split')),
      );
      return;
    }

    final tx = SquadTransaction(
      title: title,
      amount: amount,
      date: _selectedDate,
      squadKey: widget.squad.key as int,
      payerMemberKey: _payerKey!,
      splitType: _splitType,
      memberSplits: finalSplits,
      walletKey: _selectedWalletKey,
      attachmentPaths: _attachmentPaths,
    );

    await DatabaseService.saveSquadTransaction(tx);

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final payer = _members.firstWhere((m) => m.key == _payerKey);

    return OnboardingOverlay(
      visible: _isTutorialActive,
      onFinish: () => setState(() => _isTutorialActive = false),
      steps: [
        OnboardingStep(
          title: 'Split the Bill',
          description: 'Ready to split costs with your squad? This guide will show you how to record every detail.',
        ),
        OnboardingStep(
          targetKey: _helpKey,
          title: 'Need Help?',
          description: 'Tap this icon anytime to replay this tutorial and discover all splitting features.',
        ),
        OnboardingStep(
          targetKey: _detailsKey,
          title: 'What\'s the Occasion?',
          description: 'Give your transaction a title and enter the total amount spent by the group.',
        ),
        OnboardingStep(
          targetKey: _payerRowKey,
          title: 'Who Paid Upfront?',
          description: 'Select the squad member who settled the bill. You can also pick a wallet to automatically deduct the expense.',
        ),
        OnboardingStep(
          targetKey: _modeKey,
          title: 'Choose Split Mode',
          description: 'Divide equally among everyone, enter specific amounts, or split by percentage.',
        ),
        OnboardingStep(
          targetKey: _membersKey,
          title: 'Who\'s Involved?',
          description: 'Check the members who are part of this bill. Only included members will be part of the split.',
        ),
        OnboardingStep(
          targetKey: _saveKey,
          title: 'Finish & Save',
          description: 'Once everything is set, tap Add Transaction to update everyone\'s balances.',
        ),
      ],
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Split Bill'),
          actions: [
            IconButton(
              key: _helpKey,
              icon: const Icon(Icons.help_outline_rounded),
              onPressed: () => setState(() => _isTutorialActive = true),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Transaction Details
              _Section(
                key: _detailsKey,
                title: 'DETAILS',
                child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: _inputDecoration(theme, 'What is this for?'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  CalculatorInputField(
                    label: 'Amount',
                    initialValue: double.tryParse(_amountController.text),
                    onChanged: (val) {
                      setState(() {
                        _amountController.text = val.toStringAsFixed(2);
                        if (_amountController.text.endsWith('.00')) {
                          _amountController.text = _amountController.text.substring(0, _amountController.text.length - 3);
                        }
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Payer Selection
            _Section(
              key: _payerRowKey,
              title: 'WHO PAID?',
              child: Container(
                decoration: _cardDecoration(theme),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                    child: Text(payer.name[0].toUpperCase(), style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(payer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Tap to change payer'),
                  trailing: const Icon(Icons.arrow_drop_down),
                  onTap: _showPayerPicker,
                ),
              ),
            ),

            if (payer.isYou) ...[
              const SizedBox(height: 12),
              _Section(
                title: 'DEDUCT FROM WALLET (OPTIONAL)',
                child: Container(
                  decoration: _cardDecoration(theme),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedWalletKey,
                      isExpanded: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      hint: const Text('Select wallet', style: TextStyle(fontSize: 14)),
                      items: _wallets.map((w) => DropdownMenuItem(
                        value: w.key as int,
                        child: Text(w.name),
                      )).toList() ..add(const DropdownMenuItem(value: null, child: Text("Don't deduct from wallet"))),
                      onChanged: (val) => setState(() => _selectedWalletKey = val),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Split Type
            _Section(
              key: _modeKey,
              title: 'SPLIT MODE',
              child: Row(
                children: [
                  _SplitOption(
                    label: 'Equal',
                    isSelected: _splitType == SplitType.equal,
                    onTap: () => setState(() => _splitType = SplitType.equal),
                  ),
                  const SizedBox(width: 8),
                  _SplitOption(
                    label: 'Amount',
                    isSelected: _splitType == SplitType.amount,
                    onTap: () => setState(() => _splitType = SplitType.amount),
                  ),
                  const SizedBox(width: 8),
                  _SplitOption(
                    label: 'Percent',
                    isSelected: _splitType == SplitType.percentage,
                    onTap: () => setState(() => _splitType = SplitType.percentage),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Members List
            _Section(
              key: _membersKey,
              title: 'SPLIT AMONG',
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _members.length,
                itemBuilder: (context, index) {
                  final member = _members[index];
                  final mKey = member.key as int;
                  final isIncluded = _includedMembers.contains(mKey);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isIncluded ? theme.primaryColor.withValues(alpha: 0.05) : theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isIncluded ? theme.primaryColor : theme.dividerColor,
                        width: isIncluded ? 1.0 : 0.5,
                      ),
                    ),
                    child: ListTile(
                      leading: Checkbox(
                        value: isIncluded,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _includedMembers.add(mKey);
                            } else {
                              if (_includedMembers.length > 1) {
                                _includedMembers.remove(mKey);
                              }
                            }
                          });
                        },
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      title: Text(member.name, style: TextStyle(fontWeight: isIncluded ? FontWeight.bold : FontWeight.normal)),
                      trailing: _splitType == SplitType.equal 
                        ? null 
                        : isIncluded 
                          ? GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => CalculatorKeyboard(
                                    initialValue: (_splits[mKey] ?? 0).toString(),
                                    onChanged: (val) {
                                      setState(() {
                                        _splits[mKey] = double.tryParse(val) ?? 0;
                                      });
                                    },
                                  ),
                                );
                              },
                              child: Container(
                                width: 100,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      _splitType == SplitType.amount 
                                        ? '₱${(_splits[mKey] ?? 0).toStringAsFixed(_splits[mKey]! % 1 == 0 ? 0 : 2)}'
                                        : '${(_splits[mKey] ?? 0).toStringAsFixed(0)}%',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.calculate_outlined, size: 14, color: theme.primaryColor.withValues(alpha: 0.5)),
                                  ],
                                ),
                              ),
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),
            
            // Date Picker
            _Section(
              title: 'DATE',
              child: Container(
                decoration: _cardDecoration(theme),
                child: ListTile(
                  leading: const Icon(Icons.calendar_today_rounded),
                  title: Text(DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate)),
                  onTap: _showDatePicker,
                  trailing: const Icon(Icons.edit_outlined, size: 20),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Attachments Section
            _Section(
              title: 'ATTACHMENTS (OPTIONAL)',
              child: SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._attachmentPaths.asMap().entries.map((entry) {
                      final index = entry.key;
                      final path = entry.value;
                      return GestureDetector(
                        onTap: () => ImageGalleryViewer.show(context, _attachmentPaths, index),
                        child: Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            image: DecorationImage(image: FileImage(File(path)), fit: BoxFit.cover),
                            border: Border.all(color: theme.dividerColor, width: 0.5),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                right: 4,
                                top: 4,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => _attachmentPaths.remove(path));
                                    AttachmentService.deleteAttachment(path);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    GestureDetector(
                      onTap: () => _pickAttachment(),
                      child: Container(
                        width: 100,
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.dividerColor, width: 0.5),
                        ),
                        child: Icon(Icons.add_a_photo_rounded, color: theme.primaryColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24),
        child: ElevatedButton(
          key: _saveKey,
          onPressed: _saveTransaction,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text('Add Transaction', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    ),
  );
}

  void _showPayerPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Who paid?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _members.length,
                  itemBuilder: (context, index) {
                    final member = _members[index];
                    return ListTile(
                      leading: CircleAvatar(child: Text(member.name[0])),
                      title: Text(member.name),
                      selected: member.key == _payerKey,
                      onTap: () {
                        setState(() {
                          _payerKey = member.key as int;
                          // If payer is someone else, clear wallet selection
                          if (!member.isYou) _selectedWalletKey = null;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDatePicker() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  void _pickAttachment() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          const Text('Pick Attachment', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.camera_alt_rounded),
            title: const Text('Camera'),
            onTap: () async {
              Navigator.pop(context);
              final path = await AttachmentService.pickAndStoreImage(ImageSource.camera);
              if (path != null) setState(() => _attachmentPaths.add(path));
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded),
            title: const Text('Gallery'),
            onTap: () async {
              Navigator.pop(context);
              final path = await AttachmentService.pickAndStoreImage(ImageSource.gallery);
              if (path != null) setState(() => _attachmentPaths.add(path));
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(ThemeData theme, String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: theme.cardColor,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  BoxDecoration _cardDecoration(ThemeData theme) {
    return BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: theme.dividerColor, width: 0.5),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 1.5, fontWeight: FontWeight.w900, fontSize: 10, color: theme.textTheme.labelLarge?.color?.withValues(alpha:0.6))),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _SplitOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SplitOption({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? theme.primaryColor : theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? theme.primaryColor : theme.dividerColor, width: 0.5),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
