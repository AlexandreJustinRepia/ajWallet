import 'package:flutter/material.dart';
import '../../../services/balance_visibility_service.dart';
import '../../../widgets/animated_count_text.dart';

class HomeBalanceCard extends StatelessWidget {
  final double totalBalance;
  final bool isNetWorth;
  final bool showGlow;
  final ValueChanged<bool> onToggle;

  const HomeBalanceCard({
    super.key,
    required this.totalBalance,
    required this.isNetWorth,
    required this.showGlow,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.primaryColor;
    final contentColor = theme.colorScheme.onPrimary;

    return ValueListenableBuilder<bool>(
      valueListenable: BalanceVisibilityService.instance,
      builder: (context, isHidden, _) {
        return AnimatedScale(
          scale: showGlow ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: cardColor.withValues(alpha: showGlow ? 0.3 : 0.1),
                  blurRadius: showGlow ? 40 : 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardHeader(contentColor),
                const SizedBox(height: 24),
                _buildBalanceDisplay(theme, contentColor, isHidden),
                const SizedBox(height: 12),
                _buildLiveBadge(contentColor),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardHeader(Color contentColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isNetWorth ? 'TOTAL NET WORTH' : 'TOTAL BALANCE',
              style: TextStyle(
                color: contentColor.withValues(alpha: 0.5),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isNetWorth ? 'INCLUDES EXCLUDED WALLETS' : 'SPENDABLE BALANCE ONLY',
              style: TextStyle(
                color: contentColor.withValues(alpha: 0.3),
                fontSize: 8,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        Row(
          children: [
            // ── Eye toggle ───────────────────────────────────────────
            ValueListenableBuilder<bool>(
              valueListenable: BalanceVisibilityService.instance,
              builder: (context, isHidden, _) {
                return GestureDetector(
                  onTap: () => BalanceVisibilityService.instance.toggle(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: contentColor.withValues(alpha: isHidden ? 0.2 : 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: contentColor.withValues(alpha: isHidden ? 0.3 : 0.1),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      isHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: contentColor.withValues(alpha: isHidden ? 0.9 : 0.5),
                      size: 18,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            // ── Net worth toggle ─────────────────────────────────────
            GestureDetector(
              onTap: () => onToggle(!isNetWorth),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: contentColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: contentColor.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Icon(
                  isNetWorth ? Icons.account_balance_rounded : Icons.payments_rounded,
                  color: contentColor.withValues(alpha: 0.5),
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBalanceDisplay(ThemeData theme, Color contentColor, bool isHidden) {
    if (isHidden) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Text(
          '₱ ••••••',
          key: const ValueKey('hidden'),
          style: theme.textTheme.displayMedium?.copyWith(
            color: contentColor.withValues(alpha: 0.6),
            fontSize: 42,
            fontWeight: FontWeight.w800,
            letterSpacing: 4,
          ),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: AnimatedCountText(
        key: const ValueKey('visible'),
        value: totalBalance,
        prefix: '₱',
        style: theme.textTheme.displayMedium?.copyWith(
          color: contentColor,
          fontSize: 42,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        ),
      ),
    );
  }

  Widget _buildLiveBadge(Color contentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: contentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'LIVE UPDATES',
        style: TextStyle(
          color: contentColor.withValues(alpha: 0.4),
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
