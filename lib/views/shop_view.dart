import 'package:flutter/material.dart';
import '../services/session_service.dart';
import '../services/theme_service.dart';
import '../models/app_theme.dart';
import '../widgets/animated_count_text.dart';

class ShopView extends StatefulWidget {
  final int currentCoins;
  final List<String> unlockedIds;
  final Function(int spent, String unlockedId) onPurchase;

  const ShopView({
    super.key,
    required this.currentCoins,
    required this.unlockedIds,
    required this.onPurchase,
  });

  @override
  State<ShopView> createState() => _ShopViewState();
}

class _ShopViewState extends State<ShopView> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final premiumThemes = ThemeService.premiumThemes;
    final prices = ThemeService.premiumThemePrices;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Rewards Shop', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha:0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.withValues(alpha:0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on_rounded, color: Colors.amber, size: 18),
                const SizedBox(width: 6),
                Text(
                  '${widget.currentCoins}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: premiumThemes.length,
        itemBuilder: (context, index) {
          final t = premiumThemes[index];
          final price = prices[t.id] ?? 0;
          final isUnlocked = widget.unlockedIds.contains(t.id);
          final canAfford = widget.currentCoins >= price;

          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isUnlocked 
                    ? theme.primaryColor.withValues(alpha:0.3) 
                    : theme.dividerColor,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Preview Area
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(t.backgroundColor),
                        Color(t.cardColor),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 60,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Color(t.primaryColor),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 40,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Color(t.textColor).withValues(alpha:0.5),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isUnlocked)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha:0.8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text('OWNED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                          Text(
                            t.isDark ? 'Dark Theme' : 'Light Theme',
                            style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha:0.5), fontSize: 12),
                          ),
                        ],
                      ),
                      if (isUnlocked)
                        ElevatedButton(
                          onPressed: () {
                            ThemeService.setThemeMode(t.isDark ? ThemeMode.dark : ThemeMode.light);
                            if (t.isDark) {
                              ThemeService.setDarkTheme(t);
                            } else {
                              ThemeService.setLightTheme(t);
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Theme "${t.name}" applied!')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Apply'),
                        )
                      else
                        ElevatedButton(
                          onPressed: canAfford ? () => _confirmPurchase(context, t, price) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            disabledBackgroundColor: Colors.grey.withValues(alpha:0.2),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.monetization_on_rounded, size: 16),
                              const SizedBox(width: 6),
                              Text('$price'),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmPurchase(BuildContext context, AppTheme t, int price) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Purchase'),
        content: Text('Unlock "${t.name}" for $price coins?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onPurchase(price, t.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Congratulations! You unlocked ${t.name}!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
