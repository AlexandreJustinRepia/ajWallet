import 'package:flutter/material.dart';

class ColorUtils {
  /// Computes luminance and determines if white or black text provides better contrast
  /// based on standard WCAG contrast ratios.
  static Color getContrastColor(Color background) {
    // WCAG formula standard threshold
    return background.computeLuminance() > 0.179 ? Colors.black : Colors.white;
  }

  /// Calculates the contrast ratio between two colors (1.0 to 21.0)
  static double getContrastRatio(Color color1, Color color2) {
    double l1 = color1.computeLuminance();
    double l2 = color2.computeLuminance();
    
    double lightest = l1 > l2 ? l1 : l2;
    double darkest = l1 < l2 ? l1 : l2;
    
    return (lightest + 0.05) / (darkest + 0.05);
  }

  /// Checks if the contrast ratio meets WCAG AA standards for normal text (minimum 4.5:1)
  static bool hasSufficientContrast(Color foreground, Color background) {
    return getContrastRatio(foreground, background) >= 4.5;
  }

  /// Auto-adjusts a foreground color to ensure it meets contrast requirements against a background.
  /// If it fails, it falls back to black or white.
  static Color ensureContrast(Color foreground, Color background) {
    if (hasSufficientContrast(foreground, background)) {
      return foreground;
    }
    return getContrastColor(background);
  }

  /// Derives a surface variant color by blending the background with the primary color
  static Color getSurfaceVariant(Color background, Color primary) {
    final isLight = background.computeLuminance() > 0.5;
    return Color.alphaBlend(
      primary.withOpacity(isLight ? 0.08 : 0.15),
      background,
    );
  }

  /// Derives an outline color
  static Color getOutlineColor(Color background, Color textColor) {
    return textColor.withOpacity(0.2);
  }
}
