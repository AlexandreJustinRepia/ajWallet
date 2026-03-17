import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
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

  @override
  void initState() {
    super.initState();
    final current = ThemeService.themeNotifier.value;
    _primary = Color(current.primaryColor);
    _background = Color(current.backgroundColor);
    _text = Color(current.textColor);
    _card = Color(current.cardColor);
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

  AppTheme _getCurrentThemeObj() {
    return AppTheme(
      primaryColor: _primary.value,
      backgroundColor: _background.value,
      textColor: _text.value,
      cardColor: _card.value,
      name: 'Custom',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Theme Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Predefined Themes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                _themeButton('Light', AppTheme.light()),
                const SizedBox(width: 12),
                _themeButton('Dark', AppTheme.dark()),
              ],
            ),
            const SizedBox(height: 32),
            const Text('Custom Theme', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _colorTile('Primary Color', _primary, (c) => setState(() => _primary = c)),
            _colorTile('Background Color', _background, (c) => setState(() => _background = c)),
            _colorTile('Text Color', _text, (c) => setState(() => _text = c)),
            _colorTile('Card Color', _card, (c) => setState(() => _card = c)),
            const SizedBox(height: 40),
            const Text('Preview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Theme(
              data: _getCurrentThemeObj().toThemeData(),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    Text('Text Preview', style: TextStyle(color: _text, fontSize: 18)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(backgroundColor: _primary),
                      child: const Text('Button', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => ThemeService.setTheme(_getCurrentThemeObj()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Apply Theme', style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _themeButton(String label, AppTheme theme) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            _primary = Color(theme.primaryColor);
            _background = Color(theme.backgroundColor);
            _text = Color(theme.textColor);
            _card = Color(theme.cardColor);
          });
          ThemeService.setTheme(theme);
        },
        child: Text(label),
      ),
    );
  }

  Widget _colorTile(String title, Color color, ValueChanged<Color> onTap) {
    return ListTile(
      title: Text(title),
      trailing: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey),
        ),
      ),
      onTap: () => _pickColor(title, color, onTap),
    );
  }
}
