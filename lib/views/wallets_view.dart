import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/wallet.dart';
import '../wallet_details_screen.dart';

class WalletsView extends StatelessWidget {
  final VoidCallback onRefresh;
  const WalletsView({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final account = DatabaseService.getLatestAccount();
    final theme = Theme.of(context);
    final wallets = account != null
        ? DatabaseService.getWallets(account.key as int)
        : <Wallet>[];

    if (wallets.isEmpty) {
      return Center(
        child: Text('Vault is empty', style: theme.textTheme.bodyMedium),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: wallets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final wallet = wallets[index];
        return _WalletCard(wallet: wallet, onRefresh: onRefresh);
      },
    );
  }
}

class _WalletCard extends StatelessWidget {
  final Wallet wallet;
  final VoidCallback onRefresh;

  const _WalletCard({required this.wallet, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExcluded = wallet.isExcluded;
    final accentColor =
        isExcluded ? theme.colorScheme.error : theme.primaryColor;

    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WalletDetailsScreen(wallet: wallet),
          ),
        );
        onRefresh();
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isExcluded
                ? theme.colorScheme.error.withOpacity(0.5)
                : theme.dividerColor,
            width: isExcluded ? 2 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.07),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getWalletIcon(wallet.type),
                color: accentColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wallet.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      decoration:
                          isExcluded ? TextDecoration.lineThrough : null,
                      decorationColor: theme.colorScheme.error,
                      color: isExcluded
                          ? theme.colorScheme.error.withOpacity(0.7)
                          : null,
                    ),
                  ),
                  Text(
                    isExcluded ? 'Excluded from Liquidity' : wallet.type,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: isExcluded
                          ? theme.colorScheme.error.withOpacity(0.5)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '₱${wallet.balance.toStringAsFixed(2)}',
              style: theme.textTheme.titleLarge?.copyWith(
                color: isExcluded
                    ? theme.colorScheme.error.withOpacity(0.5)
                    : null,
                decoration: isExcluded ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getWalletIcon(String type) {
    switch (type) {
      case 'ATM':
        return Icons.credit_card_rounded;
      case 'Bank':
        return Icons.account_balance_rounded;
      case 'E-Wallet':
        return Icons.account_balance_wallet_rounded;
      case 'Savings':
        return Icons.savings_rounded;
      default:
        return Icons.wallet_rounded;
    }
  }
}
