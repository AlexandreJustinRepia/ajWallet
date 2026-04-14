import 'package:flutter/material.dart';
import '../../../services/gamification_service.dart';
import '../../../widgets/gamification_counter.dart';
import './gamification_sheet.dart';

class HomeHeader extends StatelessWidget {
  final String name;
  final GamificationProfile profile;

  const HomeHeader({
    super.key,
    required this.name,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good Day,',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        GamingBadge(
          profile: profile,
          onTap: () => _showGamificationSheet(context, profile, theme),
        ),
      ],
    );
  }

  void _showGamificationSheet(
    BuildContext context,
    GamificationProfile profile,
    ThemeData theme,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GamificationSheet(
        profile: profile,
        theme: theme,
        growthEmoji: _getGrowthEmoji(profile.streakDays),
      ),
    );
  }

  String _getGrowthEmoji(int days) {
    if (days >= 7) return '🌳';
    if (days >= 4) return '🌿';
    return '🌱';
  }
}

class GamingBadge extends StatefulWidget {
  final GamificationProfile profile;
  final VoidCallback onTap;

  const GamingBadge({super.key, required this.profile, required this.onTap});

  @override
  State<GamingBadge> createState() => _GamingBadgeState();
}

class _GamingBadgeState extends State<GamingBadge> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final profile = widget.profile;
    
    final primaryColor = colorScheme.primary;
    final onPrimaryColor = colorScheme.onPrimary;
    final secondaryColor = colorScheme.secondary;
    final growthColor = colorScheme.tertiary;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor.withValues(alpha: isDark ? 0.15 : 0.08),
                primaryColor.withValues(alpha: isDark ? 0.05 : 0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: primaryColor.withValues(alpha: isDark ? 0.3 : 0.15),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildProgressCircle(profile, primaryColor, onPrimaryColor),
              const SizedBox(width: 10),
              _buildBadgeInfo(profile, primaryColor, secondaryColor, growthColor, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCircle(GamificationProfile profile, Color primary, Color onPrimary) {
    return SizedBox(
      width: 42,
      height: 42,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: profile.progressToNextLevel),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => CircularProgressIndicator(
              value: value,
              strokeWidth: 3,
              backgroundColor: primary.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(primary),
            ),
          ),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${profile.level}',
                style: TextStyle(color: onPrimary, fontWeight: FontWeight.w900, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeInfo(GamificationProfile profile, Color primary, Color secondary, Color growth, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text('LVL ', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4))),
            Text('${profile.level}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: primary)),
            const SizedBox(width: 4),
            Icon(Icons.shield_rounded, size: 10, color: secondary.withValues(alpha: 0.6)),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            GamificationCounter(
              value: profile.coins,
              color: Colors.amber,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.amber),
              icon: Icons.monetization_on_rounded,
            ),
            const SizedBox(width: 8),
            Text('${profile.streakDays}d', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: growth)),
          ],
        ),
      ],
    );
  }
}
