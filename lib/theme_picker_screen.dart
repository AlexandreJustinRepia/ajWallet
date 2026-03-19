import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:uuid/uuid.dart';
import 'models/app_theme.dart';
import 'services/theme_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadFromState(ThemeService.themeNotifier.value.lightTheme);
  }

  void _loadFromState(AppTheme theme) {
    setState(() {
      _primary = Color(theme.primaryColor);
      _background = Color(theme.backgroundColor);
      _text = Color(theme.textColor);
      _card = Color(theme.cardColor);
      _income = Color(theme.incomeColor ?? (theme.isDark ? 0xFF3DA35D : 0xFF2D5A27));
      _expense = Color(theme.expenseColor ?? (theme.isDark ? 0xFFE63946 : 0xFF922B21));
    });
  }

  void _pickColor(String title, Color current, ValueChanged<Color> onSelected) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pick $title'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: current,
            onColorChanged: onSelected,
            enableAlpha: false,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  AppTheme _getCurrentThemeObj({String? overrideId, String? overrideName}) {
    final isDark = _background.computeLuminance() < 0.5;
    return AppTheme(
      id: overrideId ?? 'custom_preview_${DateTime.now().millisecondsSinceEpoch}',
      isDark: isDark,
      primaryColor: _primary.value,
      backgroundColor: _background.value,
      textColor: _text.value,
      cardColor: _card.value,
      incomeColor: _income.value,
      expenseColor: _expense.value,
      name: overrideName ?? 'Custom Settings',
    );
  }

  Future<void> _saveAsNewTheme() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Theme'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Theme Name (e.g., Cyberpunk)'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
        ],
      ),
    );

    if (name != null && name.trim().isNotEmpty) {
      final newTheme = _getCurrentThemeObj(overrideId: const Uuid().v4(), overrideName: name.trim());
      await ThemeService.saveCustomTheme(newTheme);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Theme "$name" saved!')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = _getCurrentThemeObj().toThemeData();

    return Theme(
      data: themeData,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Theme Settings'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.system, label: Text('System')),
                  ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                ],
                selected: {ThemeService.themeNotifier.value.themeMode},
                onSelectionChanged: (set) => ThemeService.setThemeMode(set.first),
              ),
            ),
          ),
        ),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SAVED PRESETS', style: themeData.textTheme.labelLarge?.copyWith(letterSpacing: 1.5)),
                    const SizedBox(height: 16),
                    _buildPresetsList(context),
                    const SizedBox(height: 32),

                    Text('CUSTOMIZE', style: themeData.textTheme.labelLarge?.copyWith(letterSpacing: 1.5)),
                    const SizedBox(height: 16),
                    _colorTile('Primary Color', _primary, (c) => setState(() => _primary = c)),
                    _colorTile('Background Color', _background, (c) => setState(() => _background = c)),
                    _colorTile('Text Color', _text, (c) => setState(() => _text = c)),
                    _colorTile('Card Color', _card, (c) => setState(() => _card = c)),
                    const Divider(height: 32),
                    _colorTile('Income / Success', _income, (c) => setState(() => _income = c)),
                    _colorTile('Expense / Error', _expense, (c) => setState(() => _expense = c)),
                    
                    const SizedBox(height: 32),
                    Text('LIVE PREVIEW', style: themeData.textTheme.labelLarge?.copyWith(letterSpacing: 1.5)),
                    const SizedBox(height: 16),
                    _buildPreviewCard(themeData),
                    const SizedBox(height: 40),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _saveAsNewTheme,
                            icon: const Icon(Icons.save),
                            label: const Text('Save Preset'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeData.colorScheme.primary,
                              foregroundColor: themeData.colorScheme.onPrimary,
                            ),
                            onPressed: () {
                              final current = _getCurrentThemeObj();
                              if (current.isDark) {
                                ThemeService.setDarkTheme(current);
                              } else {
                                ThemeService.setLightTheme(current);
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Applied as ${current.isDark ? 'Dark' : 'Light'} Theme')),
                              );
                            },
                            icon: const Icon(Icons.check),
                            label: const Text('Apply Global'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetsList(BuildContext context) {
    return ValueListenableBuilder<List<AppTheme>>(
      valueListenable: ThemeService.savedThemesNotifier,
      builder: (context, themes, _) {
        return SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: themes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final t = themes[index];
              return InkWell(
                onTap: () => _loadFromState(t),
                onLongPress: () {
                  if (t.id != 'default_light' && t.id != 'default_dark') {
                    showDialog(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Delete Preset?'),
                        content: Text('Remove "${t.name}"?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
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
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 100,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(t.cardColor),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Color(t.textColor).withOpacity(0.1)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _miniDot(Color(t.primaryColor)),
                          const SizedBox(width: 4),
                          _miniDot(Color(t.backgroundColor)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t.name,
                        style: TextStyle(color: Color(t.textColor), fontSize: 10, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _miniDot(Color c) {
    return Container(
      width: 16, height: 16,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.grey.withOpacity(0.5))),
    );
  }

  Widget _colorTile(String title, Color color, ValueChanged<Color> onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.withOpacity(0.3), width: 2),
        ),
      ),
      onTap: () => _pickColor(title, color, onTap),
    );
  }

  Widget _buildPreviewCard(ThemeData t) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: t.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: t.dividerColor),
        boxShadow: [
          BoxShadow(
            color: t.colorScheme.primary.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Balance', style: t.textTheme.labelLarge),
              Icon(Icons.more_horiz, color: t.textTheme.labelLarge?.color),
            ],
          ),
          const SizedBox(height: 8),
          Text('\$12,450.00', style: t.textTheme.headlineMedium),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: t.colorScheme.tertiary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_downward, color: t.colorScheme.tertiary, size: 16),
                      const SizedBox(width: 8),
                      Text('Income', style: TextStyle(color: t.colorScheme.tertiary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: t.colorScheme.error.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_upward, color: t.colorScheme.error, size: 16),
                      const SizedBox(width: 8),
                      Text('Expense', style: TextStyle(color: t.colorScheme.error, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: t.colorScheme.primary,
                foregroundColor: t.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {},
              child: const Text('Add Transaction'),
            ),
          )
        ],
      ),
    );
  }
}
