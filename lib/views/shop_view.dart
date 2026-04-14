import 'package:flutter/material.dart';
import '../services/session_service.dart';
import '../services/theme_service.dart';
import '../services/card_skin_service.dart';
import '../models/app_theme.dart';
import '../widgets/animated_count_text.dart';
import '../widgets/card_decorator.dart';
import '../widgets/gamification_counter.dart';
import '../services/user_profile_service.dart';
import '../services/gamification_service.dart';

class ShopView extends StatefulWidget {
  const ShopView({super.key});

  @override
  State<ShopView> createState() => _ShopViewState();
}

class _ShopViewState extends State<ShopView> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final premiumThemes = ThemeService.premiumThemes;
    final themePrices = ThemeService.premiumThemePrices;
    final premiumSkins = CardSkinService.premiumSkins;
    
    final profile = UserProfileService.profile;
    final currentCoins = GamificationService.generateGlobalProfile().coins;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
              child: GamificationCounter(
                value: currentCoins,
                color: Colors.amber,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
                icon: Icons.monetization_on_rounded,
              ),
            ),
          ],
          bottom: TabBar(
            indicatorColor: theme.primaryColor,
            labelColor: theme.primaryColor,
            unselectedLabelColor: theme.textTheme.bodyMedium?.color?.withValues(alpha:0.5),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Themes'),
              Tab(text: 'Card Skins'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // THEMES TAB
            ValueListenableBuilder<ThemeState>(
              valueListenable: ThemeService.themeNotifier,
              builder: (context, themeState, _) {
                final isPlatformDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
                final isCurrentlyDark = themeState.themeMode == ThemeMode.dark || (themeState.themeMode == ThemeMode.system && isPlatformDark);
                final activeThemeId = isCurrentlyDark ? themeState.darkTheme.id : themeState.lightTheme.id;

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: premiumThemes.length,
                  itemBuilder: (context, index) {
                    final t = premiumThemes[index];
                    final isUnlocked = profile.unlockedThemeIds.contains(t.id);
                    final isEquipped = activeThemeId == t.id;
                    final price = ThemeService.premiumThemePrices[t.id] ?? 999;
                    final canAfford = currentCoins >= price;

                    return _buildThemeCard(context, t, price, isUnlocked, isEquipped, canAfford);
                  },
                );
              },
            ),
            
            // CARD SKINS TAB
            ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: premiumSkins.length,
              itemBuilder: (context, index) {
                final s = premiumSkins[index];
                final price = s.price;
                
                final isUnlocked = profile.unlockedCardSkinIds.contains(s.id);
                final isEquipped = profile.activeCardSkinId == s.id;
                final canAfford = currentCoins >= price;

                return _buildSkinCard(context, s, price, isUnlocked, isEquipped, canAfford);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context, AppTheme t, int price, bool isUnlocked, bool isEquipped, bool canAfford) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: CardDecorator(
        child: Container(
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
                    onPressed: isEquipped ? null : () {
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
                      backgroundColor: isEquipped ? theme.cardColor : theme.primaryColor,
                      foregroundColor: isEquipped ? theme.primaryColor : theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isEquipped ? BorderSide(color: theme.primaryColor) : BorderSide.none,
                      ),
                    ),
                    child: Text(isEquipped ? 'Current' : 'Apply'),
                  )
                else
                  ElevatedButton(
                    onPressed: canAfford ? () => _confirmPurchase(context, t.name, t.id, price, false) : null,
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
    )));
  }

  Widget _buildSkinCard(BuildContext context, CardSkin s, int price, bool isUnlocked, bool isEquipped, bool canAfford) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: CardDecorator(
        child: Container(
          decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isEquipped 
              ? theme.primaryColor 
              : (isUnlocked ? theme.dividerColor : theme.dividerColor.withValues(alpha:0.3)),
          width: isEquipped ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Skin Preview Area
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark 
                ? theme.scaffoldBackgroundColor 
                : Colors.grey[100],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Stack(
              children: [
                Center(
                  child: Container(
                    width: 160,
                    height: 80,
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha:0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        const Center(
                          child: Icon(Icons.credit_card_rounded, color: Colors.grey, size: 24),
                        ),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: SkinPainter(skinId: s.id),
                          ),
                        ),
                      ],
                    ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                      const SizedBox(height: 4),
                      Text(
                        s.description,
                        style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha:0.7), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                if (isUnlocked)
                  ElevatedButton(
                    onPressed: () {
                      final profile = UserProfileService.profile;
                      profile.activeCardSkinId = isEquipped ? null : s.id;
                      UserProfileService.saveProfile();
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEquipped ? theme.cardColor : theme.primaryColor,
                      foregroundColor: isEquipped ? theme.colorScheme.error : theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isEquipped ? BorderSide(color: theme.colorScheme.error) : BorderSide.none,
                      ),
                    ),
                    child: Text(isEquipped ? 'Unequip' : 'Equip'),
                  )
                else
                  ElevatedButton(
                    onPressed: canAfford ? () => _confirmPurchase(context, s.name, s.id, price, true) : null,
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
          ],
        ),
      ),
    ],
  ),
)));
  }

  void _confirmPurchase(BuildContext context, String name, String id, int price, bool isSkin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Purchase'),
        content: Text('Unlock "$name" for $price coins?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final profile = UserProfileService.profile;
              profile.spentCoins += price;

              if (isSkin) {
                if (!profile.unlockedCardSkinIds.contains(id)) {
                  profile.unlockedCardSkinIds.add(id);
                }
              } else {
                if (!profile.unlockedThemeIds.contains(id)) {
                  profile.unlockedThemeIds.add(id);
                }
              }
              await UserProfileService.saveProfile();
              setState(() {});

              if (context.mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Congratulations! You unlocked $name!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
