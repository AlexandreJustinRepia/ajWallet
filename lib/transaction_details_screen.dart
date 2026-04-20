import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/transaction_model.dart';
import 'services/database_service.dart';
import 'add_transaction_screen.dart';
import 'widgets/onboarding_overlay.dart';
import 'dart:io';

class TransactionDetailsScreen extends StatefulWidget {
  final Transaction transaction;
  final List<OnboardingStep>? tutorialSteps;
  final GlobalKey? editKey;
  final GlobalKey? deleteKey;

  const TransactionDetailsScreen({
    super.key, 
    required this.transaction,
    this.tutorialSteps,
    this.editKey,
    this.deleteKey,
  });

  @override
  State<TransactionDetailsScreen> createState() => _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  final GlobalKey _localEditKey = GlobalKey();
  final GlobalKey _localDeleteKey = GlobalKey();
  bool _showTutorial = false;

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: const Text('This action cannot be undone. Are you sure you want to remove this record from your vault?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await DatabaseService.deleteTransaction(widget.transaction);
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context, true); // Return to previous screen with refresh flag
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = widget.transaction.type == TransactionType.income;
    final isTransfer = widget.transaction.type == TransactionType.transfer;
    final displayColor = widget.transaction.typeColor;
  
    final List<OnboardingStep> activeSteps;
    final bool isTutorialActive;

    if (widget.tutorialSteps != null) {
      activeSteps = widget.tutorialSteps!;
      isTutorialActive = true;
    } else if (_showTutorial) {
      activeSteps = [
        OnboardingStep(
          targetKey: widget.editKey ?? _localEditKey,
          title: 'Edit Transaction',
          description: 'Tap here to modify the transaction details.',
        ),
        OnboardingStep(
          targetKey: widget.deleteKey ?? _localDeleteKey,
          title: 'Delete Transaction',
          description: 'Tap here to permanently remove this transaction from your records.',
        ),
      ];
      isTutorialActive = true;
    } else {
      activeSteps = [];
      isTutorialActive = false;
    }

    final content = Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Transaction Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => setState(() => _showTutorial = true),
          ),
          IconButton(
            key: widget.editKey ?? _localEditKey,
            icon: const Icon(Icons.edit_rounded),
            onPressed: () async {
              if (widget.tutorialSteps != null) return; // Disable during tutorial
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddTransactionScreen(
                    accountKey: widget.transaction.accountKey,
                    existingTransaction: widget.transaction,
                  ),
                ),
              );
              if (result == true && context.mounted) {
                Navigator.pop(context, true);
              }
            },
          ),
          IconButton(
            key: widget.deleteKey ?? _localDeleteKey,
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            onPressed: () {
              if (widget.tutorialSteps != null) return; // Disable during tutorial
              _confirmDelete(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Amount Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: theme.dividerColor, width: 0.5),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: displayColor.withValues(alpha:0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isTransfer 
                        ? Icons.swap_horiz_rounded 
                        : (isIncome ? Icons.south_west_rounded : Icons.north_east_rounded),
                      color: displayColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '${isIncome ? '+' : (isTransfer ? '' : '-')} ₱${widget.transaction.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: displayColor,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.transaction.type.name.toUpperCase(),
                    style: TextStyle(
                      letterSpacing: 2,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha:0.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Details List
            _InfoRow(
              icon: Icons.category_rounded,
              label: 'Category',
              value: widget.transaction.category,
              theme: theme,
            ),
            const Divider(),
            _InfoRow(
              icon: Icons.calendar_today_rounded,
              label: 'Date',
              value: DateFormat('EEEE, MMM dd, yyyy').format(widget.transaction.date),
              theme: theme,
            ),
            _InfoRow(
              icon: Icons.access_time_rounded,
              label: 'Time',
              value: DateFormat('hh:mm a').format(widget.transaction.date),
              theme: theme,
            ),
            const Divider(),
            _InfoRow(
              icon: Icons.account_balance_wallet_rounded,
              label: isTransfer ? 'From Wallet' : 'Wallet',
              value: _getWalletName(widget.transaction.walletKey),
              theme: theme,
            ),
            if (isTransfer)
              _InfoRow(
                icon: Icons.arrow_forward_rounded,
                label: 'To Wallet',
                value: _getWalletName(widget.transaction.toWalletKey),
                theme: theme,
              ),
            if (widget.transaction.charge != null && widget.transaction.charge! > 0)
              _InfoRow(
                icon: Icons.receipt_long_rounded,
                label: 'Service Fee',
                value: '₱${widget.transaction.charge!.toStringAsFixed(2)}',
                theme: theme,
              ),
            const Divider(),
            if (widget.transaction.description.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _InfoLabel(label: 'Description', theme: theme),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.dividerColor, width: 0.5),
                    ),
                    child: Text(
                      widget.transaction.description,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            
            if (widget.transaction.attachmentPaths != null && widget.transaction.attachmentPaths!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _InfoLabel(label: 'Attachments', theme: theme),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.transaction.attachmentPaths!.length,
                      itemBuilder: (context, index) {
                        final path = widget.transaction.attachmentPaths![index];
                        return GestureDetector(
                          onTap: () => _showFullScreenImage(context, path),
                          child: Container(
                            width: 120,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              image: DecorationImage(image: FileImage(File(path)), fit: BoxFit.cover),
                              border: Border.all(color: theme.dividerColor, width: 0.5),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );

    return OnboardingOverlay(
      steps: activeSteps,
      visible: isTutorialActive,
      onFinish: () {
        if (widget.tutorialSteps != null) {
          Navigator.pop(context);
        } else {
          setState(() => _showTutorial = false);
        }
      },
      child: content,
    );
  }

  void _showFullScreenImage(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(child: Image.file(File(path), fit: BoxFit.contain)),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getWalletName(int? key) {
    if (key == null) return 'Unknown';
    final wallet = DatabaseService.getWalletByKey(key);
    return wallet?.name ?? 'Unknown';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;

  const _InfoRow({required this.icon, required this.label, required this.value, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.dividerColor.withValues(alpha:0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: theme.primaryColor),
          ),
          const SizedBox(width: 16),
          _InfoLabel(label: label, theme: theme),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _InfoLabel extends StatelessWidget {
  final String label;
  final ThemeData theme;

  const _InfoLabel({required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: theme.textTheme.bodyMedium?.color?.withValues(alpha:0.5),
      ),
    );
  }
}
