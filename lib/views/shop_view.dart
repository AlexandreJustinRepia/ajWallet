import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../services/card_skin_service.dart';
import '../services/tree_skin_service.dart';
import '../models/app_theme.dart';
import '../models/tree_skin.dart';

import '../widgets/card_decorator.dart';
import '../widgets/gamification_counter.dart';
import '../services/user_profile_service.dart';
import '../services/gamification_service.dart';
import '../widgets/animated_tree.dart';

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

    final premiumSkins = CardSkinService.premiumSkins;

    final profile = UserProfileService.profile;
    final currentCoins = GamificationService.generateGlobalProfile().coins;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text(
            'Rewards Shop',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          centerTitle: true,
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: GamificationCounter(
                value: currentCoins,
                color: Colors.amber,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
                icon: Icons.monetization_on_rounded,
              ),
            ),
          ],
          bottom: TabBar(
            indicatorColor: theme.primaryColor,
            labelColor: theme.primaryColor,
            unselectedLabelColor: theme.textTheme.bodyMedium?.color?.withValues(
              alpha: 0.5,
            ),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Themes'),
              Tab(text: 'Cards'),
              Tab(text: 'Trees'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // THEMES TAB
            ValueListenableBuilder<ThemeState>(
              valueListenable: ThemeService.themeNotifier,
              builder: (context, themeState, _) {
                final isPlatformDark =
                    MediaQuery.of(context).platformBrightness ==
                    Brightness.dark;
                final isCurrentlyDark =
                    themeState.themeMode == ThemeMode.dark ||
                    (themeState.themeMode == ThemeMode.system &&
                        isPlatformDark);
                final activeThemeId = isCurrentlyDark
                    ? themeState.darkTheme.id
                    : themeState.lightTheme.id;

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: premiumThemes.length,
                  itemBuilder: (context, index) {
                    final t = premiumThemes[index];
                    final isUnlocked = profile.unlockedThemeIds.contains(t.id);
                    final isEquipped = activeThemeId == t.id;
                    final price = ThemeService.premiumThemePrices[t.id] ?? 999;
                    final canAfford = currentCoins >= price;

                    return _buildThemeCard(
                      context,
                      t,
                      price,
                      isUnlocked,
                      isEquipped,
                      canAfford,
                    );
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

                return _buildSkinCard(
                  context,
                  s,
                  price,
                  isUnlocked,
                  isEquipped,
                  canAfford,
                );
              },
            ),

            // TREE SKINS TAB
            ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: TreeSkinService.allSkins.length,
              itemBuilder: (context, index) {
                final s = TreeSkinService.allSkins[index];
                final price = s.price;

                final isUnlocked = profile.unlockedTreeSkinIds.contains(s.id);
                final isEquipped = profile.activeTreeSkinId == s.id;
                final canAfford = currentCoins >= price;

                return _buildTreeSkinCard(
                  context,
                  s,
                  price,
                  isUnlocked,
                  isEquipped,
                  canAfford,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCard(
    BuildContext context,
    AppTheme t,
    int price,
    bool isUnlocked,
    bool isEquipped,
    bool canAfford,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isUnlocked
                ? theme.primaryColor.withValues(alpha: 0.3)
                : theme.dividerColor,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
                  colors: [Color(t.backgroundColor), Color(t.cardColor)],
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
                            color: Color(t.textColor).withValues(alpha: 0.5),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'OWNED',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
                      Text(
                        t.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        t.isDark ? 'Dark Theme' : 'Light Theme',
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color?.withValues(
                            alpha: 0.5,
                          ),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (isUnlocked)
                    ElevatedButton(
                      onPressed: isEquipped
                          ? null
                          : () {
                              ThemeService.setThemeMode(
                                t.isDark ? ThemeMode.dark : ThemeMode.light,
                              );
                              if (t.isDark) {
                                ThemeService.setDarkTheme(t);
                              } else {
                                ThemeService.setLightTheme(t);
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Theme "${t.name}" applied!'),
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isEquipped
                            ? theme.cardColor
                            : theme.primaryColor,
                        foregroundColor: isEquipped
                            ? theme.primaryColor
                            : theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isEquipped
                              ? BorderSide(color: theme.primaryColor)
                              : BorderSide.none,
                        ),
                      ),
                      child: Text(isEquipped ? 'Current' : 'Apply'),
                    )
                  else
                    ElevatedButton(
                      onPressed: canAfford
                          ? () => _confirmPurchase(
                              context,
                              t.name,
                              t.id,
                              price,
                              ItemType.theme,
                            )
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey.withValues(
                          alpha: 0.2,
                        ),
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
      ),
    );
  }

  Widget _buildSkinCard(
    BuildContext context,
    CardSkin s,
    int price,
    bool isUnlocked,
    bool isEquipped,
    bool canAfford,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isEquipped
                ? theme.primaryColor
                : (isUnlocked
                      ? theme.dividerColor
                      : theme.dividerColor.withValues(alpha: 0.3)),
            width: isEquipped ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
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
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          const Center(
                            child: Icon(
                              Icons.credit_card_rounded,
                              color: Colors.grey,
                              size: 24,
                            ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'OWNED',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
                            Text(
                              s.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              s.description,
                              style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
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
                            backgroundColor: isEquipped
                                ? theme.cardColor
                                : theme.primaryColor,
                            foregroundColor: isEquipped
                                ? theme.colorScheme.error
                                : theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: isEquipped
                                  ? BorderSide(color: theme.colorScheme.error)
                                  : BorderSide.none,
                            ),
                          ),
                          child: Text(isEquipped ? 'Unequip' : 'Equip'),
                        )
                      else
                        ElevatedButton(
                          onPressed: canAfford
                              ? () => _confirmPurchase(
                                  context,
                                  s.name,
                                  s.id,
                                  price,
                                  ItemType.cardSkin,
                                )
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            disabledBackgroundColor: Colors.grey.withValues(
                              alpha: 0.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.monetization_on_rounded,
                                size: 16,
                              ),
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
      ),
    );
  }

  Widget _buildTreeSkinCard(
    BuildContext context,
    TreeSkin s,
    int price,
    bool isUnlocked,
    bool isEquipped,
    bool canAfford,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isEquipped
                ? theme.primaryColor
                : (isUnlocked
                      ? theme.dividerColor
                      : theme.dividerColor.withValues(alpha: 0.3)),
            width: isEquipped ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? theme.scaffoldBackgroundColor
                    : Colors.grey[100],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Stack(
                children: [
                  // Actual animated tree preview
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      child: Center(
                        child: AnimatedTree(
                          balance:
                              2000, // Fixed high balance for a healthy preview
                          overrideSkinId: s.id,
                          height: 140,
                          margin: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),

                  // Live Preview Button Overlay
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () => _showTreePreview(context, s),
                      icon: const Icon(Icons.visibility),
                      label: const Text('Live View'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor.withValues(
                          alpha: 0.6,
                        ), // More transparent to see the tree behind
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),

                  if (isUnlocked)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'OWNED',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
                            Text(
                              s.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              s.description,
                              style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (isUnlocked)
                        ElevatedButton(
                          onPressed: isEquipped
                              ? null
                              : () {
                                  final profile = UserProfileService.profile;
                                  profile.activeTreeSkinId = s.id;
                                  UserProfileService.saveProfile();
                                  setState(() {});
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isEquipped
                                ? theme.cardColor
                                : theme.primaryColor,
                            foregroundColor: isEquipped
                                ? theme.primaryColor
                                : theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: isEquipped
                                  ? BorderSide(color: theme.primaryColor)
                                  : BorderSide.none,
                            ),
                          ),
                          child: Text(isEquipped ? 'Active' : 'Equip'),
                        )
                      else
                        ElevatedButton(
                          onPressed: canAfford
                              ? () => _confirmPurchase(
                                  context,
                                  s.name,
                                  s.id,
                                  price,
                                  ItemType.treeSkin,
                                )
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            disabledBackgroundColor: Colors.grey.withValues(
                              alpha: 0.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.monetization_on_rounded,
                                size: 16,
                              ),
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
      ),
    );
  }

  void _showTreePreview(BuildContext context, TreeSkin skin) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          height: 450,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          skin.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Live Preview',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    bottom: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Center(
                      child: AnimatedTree(
                        balance: 1500, // Balance above threshold for growth
                        overrideSkinId: skin.id,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmPurchase(
    BuildContext context,
    String name,
    String id,
    int price,
    ItemType type,
  ) {
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

              switch (type) {
                case ItemType.theme:
                  if (!profile.unlockedThemeIds.contains(id)) {
                    profile.unlockedThemeIds.add(id);
                  }
                  break;
                case ItemType.cardSkin:
                  if (!profile.unlockedCardSkinIds.contains(id)) {
                    profile.unlockedCardSkinIds.add(id);
                  }
                  break;
                case ItemType.treeSkin:
                  if (!profile.unlockedTreeSkinIds.contains(id)) {
                    profile.unlockedTreeSkinIds.add(id);
                  }
                  break;
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

enum ItemType { theme, cardSkin, treeSkin }
