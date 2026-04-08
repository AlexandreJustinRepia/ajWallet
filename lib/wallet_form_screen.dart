import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'models/wallet.dart';
import 'widgets/calculator_input.dart';
import 'widgets/onboarding_overlay.dart';
import 'widgets/institution_selector.dart';

class WalletFormScreen extends StatefulWidget {
  final int accountKey;
  final Wallet? wallet; // If provided, we are editing
  final bool isTutorialMode;

  const WalletFormScreen({
    super.key, 
    required this.accountKey, 
    this.wallet,
    this.isTutorialMode = false,
  });

  @override
  State<WalletFormScreen> createState() => _WalletFormScreenState();
}

class _WalletFormScreenState extends State<WalletFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Tutorial Keys
  final GlobalKey _nameKey = GlobalKey();
  final GlobalKey _balanceKey = GlobalKey();
  final GlobalKey _typeKey = GlobalKey();
  final GlobalKey _excludeKey = GlobalKey();
  final GlobalKey _saveKey = GlobalKey();

  late TextEditingController _nameController;
  late TextEditingController _balanceController;
  late String _selectedType;
  late bool _isExcluded;
  String? _selectedIconPath;

  final List<String> _walletTypes = ['Wallet', 'Cash', 'Credit Card', 'Debit Card', 'ATM', 'E-Wallet', 'Bank', 'Savings', 'Others'];

  @override
  void initState() {
    super.initState();
    if (widget.isTutorialMode) {
      _nameController = TextEditingController(text: 'My Savings');
      _balanceController = TextEditingController(text: '5000.00');
      _selectedType = 'Bank';
      _isExcluded = true;
      _selectedIconPath = null;
    } else {
      _nameController = TextEditingController(text: widget.wallet?.name ?? '');
      _balanceController = TextEditingController(text: widget.wallet?.balance.toString() ?? '0');
      _selectedType = widget.wallet?.type ?? 'Wallet';
      _isExcluded = widget.wallet?.isExcluded ?? false;
      _selectedIconPath = widget.wallet?.iconPath;
    }
  }

  void _saveWallet() async {
    if (widget.isTutorialMode) return;
    if (_formKey.currentState!.validate()) {
      if (widget.wallet != null) {
        // Edit existing
        widget.wallet!.name = _nameController.text;
        widget.wallet!.balance = double.parse(_balanceController.text);
        widget.wallet!.type = _selectedType;
        widget.wallet!.isExcluded = _isExcluded;
        widget.wallet!.iconPath = _selectedIconPath;
        await DatabaseService.updateWallet(widget.wallet!);
      } else {
        // Create new
        final wallet = Wallet(
          name: _nameController.text,
          balance: double.parse(_balanceController.text),
          type: _selectedType,
          accountKey: widget.accountKey,
          isExcluded: _isExcluded,
          iconPath: _selectedIconPath,
        );
        await DatabaseService.saveWallet(wallet);
      }
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  void _showInstitutionSelector() async {
    final result = await showModalBottomSheet<Institution>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InstitutionSelector(),
    );

    if (result != null) {
      setState(() {
        _selectedIconPath = result.logoPath;
        if (_nameController.text.isEmpty) {
          _nameController.text = result.name;
        }
        _selectedType = result.category;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.wallet != null;

    final tutorialSteps = [
      OnboardingStep(
        targetKey: _nameKey,
        title: 'Wallet Name',
        description: 'Give your wallet a name (e.g., GCash, BPI, Cash).',
      ),
      OnboardingStep(
        targetKey: _balanceKey,
        title: 'Initial Balance',
        description: 'Enter your starting balance.',
      ),
      OnboardingStep(
        targetKey: _typeKey,
        title: 'Wallet Type',
        description: 'Choose the type of wallet (Cash, Bank, ATM, or Others).',
      ),
      OnboardingStep(
        targetKey: _excludeKey,
        title: 'Exclude from Balance',
        description: 'Exclude wallets that you can\'t currently spend.',
      ),
      OnboardingStep(
        targetKey: _excludeKey,
        title: 'Exclusion Effect',
        description: 'Excluded wallets won\'t be counted in your total balance.',
      ),
      OnboardingStep(
        targetKey: _excludeKey,
        title: 'Toggle Interaction',
        description: 'Turn it off anytime to include it back.',
      ),
      OnboardingStep(
        targetKey: _saveKey,
        title: 'Save Wallet',
        description: 'Save to create your new wallet.',
      ),
    ];

    return OnboardingOverlay(
      steps: tutorialSteps,
      visible: widget.isTutorialMode,
      onFinish: () {
        if (widget.isTutorialMode && mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(title: Text(isEditing ? 'Edit Wallet' : 'Add Wallet')),
        body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Institution', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              InkWell(
                onTap: _showInstitutionSelector,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.dividerColor, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: theme.dividerColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        clipBehavior: Clip.antiAlias,
                        alignment: Alignment.center,
                        child: _selectedIconPath != null
                            ? Padding(
                                padding: const EdgeInsets.all(10),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.asset(_selectedIconPath!, fit: BoxFit.contain),
                                ),
                              )
                            : Icon(Icons.account_balance_rounded, color: theme.primaryColor),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _selectedIconPath != null 
                              ? 'Change Institution'
                              : 'Select Bank or E-Wallet',
                          style: TextStyle(
                            color: _selectedIconPath != null ? null : theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: theme.dividerColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Wallet Name', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Container(
                key: _nameKey,
                child: TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'e.g., G-Cash, BDO, Cash',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Enter name' : null,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                key: _balanceKey,
                child: CalculatorInputField(
                  label: 'Balance',
                  initialValue: double.tryParse(_balanceController.text),
                  onChanged: (val) => setState(() => _balanceController.text = val.toStringAsFixed(2)),
                  validator: (value) => value == null || value.isEmpty ? 'Enter balance' : null,
                ),
              ),
              const SizedBox(height: 24),
              Text('Type', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Container(
                key: _typeKey,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _walletTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                  onChanged: (val) => setState(() => _selectedType = val!),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                key: _excludeKey,
                child: SwitchListTile(
                  title: const Text('Exclude from Total Balance'),
                  subtitle: const Text('This wallet\'s money will not be counted in your dashboard total.'),
                  value: _isExcluded,
                  onChanged: (val) => setState(() => _isExcluded = val),
                  activeThumbColor: theme.primaryColor,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                key: _saveKey,
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveWallet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(isEditing ? 'Update Wallet' : 'Save Wallet', style: TextStyle(color: theme.scaffoldBackgroundColor, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
