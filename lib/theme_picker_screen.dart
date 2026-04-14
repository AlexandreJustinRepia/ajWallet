import 'package:flutter/material.dart';
import 'models/app_theme.dart';
import 'services/theme_service.dart';
import 'views/shop_view.dart';
import 'services/user_profile_service.dart';
import 'widgets/card_decorator.dart';
import 'services/card_skin_service.dart';

class ThemePickerScreen extends StatefulWidget {
  const ThemePickerScreen({super.key});

  @override
  State<ThemePickerScreen> createState() => _ThemePickerScreenState();
}

class _ThemePickerScreenState extends State<ThemePickerScreen> {
  late Color _primary;
  late Color _background;
  late Color _text;
  late Color _card;
  late Color _income;
  late Color _expense;

  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      _loadActiveTheme();
    }
  }

  void _loadActiveTheme() {
    final state = ThemeService.themeNotifier.value;
    final mode = state.themeMode;
    bool isDark = false;
    if (mode == ThemeMode.dark) {
      isDark = true;
    } else if (mode == ThemeMode.light) {
      isDark = false;
    } else {
      isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
    _loadFromState(isDark ? state.darkTheme : state.lightTheme);
  }

  void _loadFromState(AppTheme theme) {
    setState(() {
      _primary = Color(theme.primaryColor);
      _background = Color(theme.backgroundColor);
      _text = Color(theme.textColor);
      _card = Color(theme.cardColor);
      _income = Color(
        theme.incomeColor ?? (theme.isDark ? 0xFF3DA35D : 0xFF2D5A27),
      );
      _expense = Color(
        theme.expenseColor ?? (theme.isDark ? 0xFFE63946 : 0xFF922B21),
      );
    });
  }

  void _applyTheme(AppTheme theme) {
    if (theme.isDark) {
      ThemeService.setDarkTheme(theme);
      ThemeService.setThemeMode(ThemeMode.dark);
    } else {
      ThemeService.setLightTheme(theme);
      ThemeService.setThemeMode(ThemeMode.light);
    }
    _loadFromState(theme);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Applied "${theme.name}" as ${theme.isDark ? 'Dark' : 'Light'} Palette',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  AppTheme _getCurrentThemeObj({String? overrideId, String? overrideName}) {
    final isDark = _background.computeLuminance() < 0.5;
    return AppTheme(
      id:
          overrideId ??
          'custom_preview_${DateTime.now().millisecondsSinceEpoch}',
      isDark: isDark,
      primaryColor: _primary.toARGB32(),
      backgroundColor: _background.toARGB32(),
      textColor: _text.toARGB32(),
      cardColor: _card.toARGB32(),
      incomeColor: _income.toARGB32(),
      expenseColor: _expense.toARGB32(),
      name: overrideName ?? 'Custom Lab Look',
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeTheme = Theme.of(context);
    final themeData = _getCurrentThemeObj().toThemeData();

    return Theme(
      data: themeData,
      child: Scaffold(
        backgroundColor: activeTheme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'Theme Settings',
            style: TextStyle(color: activeTheme.colorScheme.onSurface),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: activeTheme.colorScheme.onSurface,
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          physics: const BouncingScrollPhysics(),
          children: [
            _buildSectionHeader(
              'PRESET PALETTES',
              Icons.palette_rounded,
              activeTheme,
            ),
            const SizedBox(height: 16),
            _buildPresetsGrid(context, activeTheme),

            const SizedBox(height: 40),
            _buildSectionHeader(
              'EXCLUSIVE THEMES',
              Icons.stars_rounded,
              activeTheme,
            ),
            const SizedBox(height: 16),
            _buildPremiumGrid(context, activeTheme),

            const SizedBox(height: 40),
            _buildSectionHeader(
              'CARD BORDERS',
              Icons.auto_awesome_mosaic_rounded,
              activeTheme,
            ),
            const SizedBox(height: 16),
            _buildSkinsGrid(context, activeTheme),

            const SizedBox(height: 40),
            _buildSectionHeader(
              'LAB PREVIEW',
              Icons.remove_red_eye_rounded,
              activeTheme,
            ),
            const SizedBox(height: 16),
            _buildPreviewCard(
              themeData,
            ), // Keep preview card using the new themeData

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ThemeData theme) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildPresetsGrid(BuildContext context, ThemeData theme) {
    return ValueListenableBuilder<ThemeState>(
      valueListenable: ThemeService.themeNotifier,
      builder: (context, themeState, _) {
        return ValueListenableBuilder<List<AppTheme>>(
          valueListenable: ThemeService.savedThemesNotifier,
          builder: (context, themes, _) {
            final isPlatformDark =
                MediaQuery.of(context).platformBrightness == Brightness.dark;
            final isCurrentlyDark =
                themeState.themeMode == ThemeMode.dark ||
                (themeState.themeMode == ThemeMode.system && isPlatformDark);
            final activeThemeId = isCurrentlyDark
                ? themeState.darkTheme.id
                : themeState.lightTheme.id;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: themes
                  .map((t) => _buildPresetItem(t, t.id == activeThemeId))
                  .toList(),
            );
          },
        );
      },
    );
  }

  Widget _buildPremiumGrid(BuildContext context, ThemeData theme) {
    final profile = UserProfileService.profile;
    final unlockedIds = profile.unlockedThemeIds;
    final premiumThemes = ThemeService.premiumThemes;

    return ValueListenableBuilder<ThemeState>(
      valueListenable: ThemeService.themeNotifier,
      builder: (context, themeState, _) {
        final isPlatformDark =
            MediaQuery.of(context).platformBrightness == Brightness.dark;
        final isCurrentlyDark =
            themeState.themeMode == ThemeMode.dark ||
            (themeState.themeMode == ThemeMode.system && isPlatformDark);
        final activeThemeId = isCurrentlyDark
            ? themeState.darkTheme.id
            : themeState.lightTheme.id;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: premiumThemes
              .map(
                (t) => _buildPresetItem(
                  t,
                  t.id == activeThemeId,
                  isPremium: true,
                  isLocked: !unlockedIds.contains(t.id),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildPresetItem(
    AppTheme t,
    bool isSelected, {
    bool isPremium = false,
    bool isLocked = false,
  }) {
    return InkWell(
      onTap: () {
        if (isLocked) {
          _showShopPrompt(t);
        } else {
          _applyTheme(t);
        }
      },
      onLongPress: () {
        if (t.id != 'default_light' && t.id != 'default_dark') {
          _showDeleteDialog(t);
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: (MediaQuery.of(context).size.width - 60) / 2,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(t.cardColor),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Color(t.primaryColor)
                : Color(t.textColor).withValues(alpha: 0.1),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Color(t.primaryColor).withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _miniDot(Color(t.primaryColor)),
                    const SizedBox(width: 8),
                    _miniDot(Color(t.backgroundColor)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  t.name,
                  style: TextStyle(
                    color: Color(t.textColor),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  t.isDark ? 'Dark Palette' : 'Light Palette',
                  style: TextStyle(
                    color: Color(t.textColor).withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            if (isSelected)
              Positioned(
                top: -8,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Color(t.primaryColor),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 12,
                    color: t.isDark ? Colors.black : Colors.white,
                  ),
                ),
              ),
            if (isLocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.lock_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showShopPrompt(AppTheme t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${t.name} is Locked'),
        content: const Text(
          'You need to unlock this theme in the Rewards Shop.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ShopView()),
              ).then((_) {
                setState(() {}); // Refresh screen in case they bought it
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
            child: const Text('Go to Shop'),
          ),
        ],
      ),
    );
  }

  Widget _buildSkinsGrid(BuildContext context, ThemeData theme) {
    final profile = UserProfileService.profile;
    final unlockedIds = profile.unlockedCardSkinIds;
    final activeSkinId = profile.activeCardSkinId;
    final skins = CardSkinService.premiumSkins;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: skins
          .map((s) => _buildSkinItem(
              s, 
              s.id == activeSkinId, 
              isLocked: !unlockedIds.contains(s.id)
            ))
          .toList(),
    );
  }

  Widget _buildSkinItem(CardSkin s, bool isEquipped, {bool isLocked = false}) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: () {
        if (isLocked) {
          _showSkinShopPrompt(s);
        } else {
          final profile = UserProfileService.profile;
          profile.activeCardSkinId = isEquipped ? null : s.id;
          UserProfileService.saveProfile();
          setState(() {});
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
          width: (MediaQuery.of(context).size.width - 60) / 2,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isEquipped
                  ? theme.primaryColor
                  : theme.dividerColor.withValues(alpha: 0.1),
              width: isEquipped ? 2.0 : 1.0,
            ),
            boxShadow: [
              if (isEquipped)
                BoxShadow(
                  color: theme.primaryColor.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  Container(
                    height: 40,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor.withValues(alpha:0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        const Center(child: Icon(Icons.credit_card_rounded, size: 16, color: Colors.grey)),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: SkinPainter(skinId: s.id),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    s.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    isEquipped ? 'Equipped' : (isLocked ? 'Locked' : 'Available'),
                    style: TextStyle(
                      color: (isEquipped ? theme.primaryColor : theme.textTheme.bodyMedium?.color)?.withValues(alpha: 0.5),
                      fontSize: 9,
                      fontWeight: isEquipped ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              if (isEquipped)
                Positioned(
                  top: -8,
                  right: -8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              if (isLocked)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Icon(Icons.lock_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ),
            ],
          ),
        ),
    );
  }

  void _showSkinShopPrompt(CardSkin s) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${s.name} is Locked'),
        content: const Text('You need to unlock this border in the Rewards Shop.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ShopView(),
                ),
              ).then((_) {
                 setState(() {}); 
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
            child: const Text('Go to Shop'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(AppTheme t) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Preset?'),
        content: Text('Remove "${t.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ThemeService.deleteCustomTheme(t);
              Navigator.pop(c);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _miniDot(Color c) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: c,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildPreviewCard(ThemeData t) {
    return CardDecorator(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: t.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: t.dividerColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: t.primaryColor.withValues(alpha: 0.05),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Available Balance',
                  style: t.textTheme.labelLarge?.copyWith(letterSpacing: 1),
                ),
                Icon(
                  Icons.shield_moon_outlined,
                  color: t.primaryColor,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '\$12,450.00',
              style: t.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _previewChip('Income', t.colorScheme.tertiary, Icons.add, t),
                const SizedBox(width: 12),
                _previewChip('Spent', t.colorScheme.error, Icons.remove, t),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: t.primaryColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  'Simulated Action',
                  style: TextStyle(
                    color: t.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewChip(String label, Color color, IconData icon, ThemeData t) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
