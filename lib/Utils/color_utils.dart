import 'package:flutter/material.dart';

/// Utility functions for color manipulation and conversion.
/// 
/// Provides color space conversions (RGB ↔ HSL), lightness adjustments,
/// and hex string parsing/generation. Used throughout the app for
/// dynamic color customization.

/// Converts an RGB Color to HSL (Hue, Saturation, Lightness) values.
/// 
/// Parameters:
///   color: The Color to convert
/// 
/// Returns: List containing [hue (0-360°), saturation (0-1), lightness (0-1)]
List<double> colorToHSL(Color color) {
  final r = color.r;
  final g = color.g;
  final b = color.b;
  
  final max = [r, g, b].reduce((a, b) => a > b ? a : b);
  final min = [r, g, b].reduce((a, b) => a < b ? a : b);
  final delta = max - min;
  
  double h = 0;
  double s = 0;
  double l = (max + min) / 2;
  
  if (delta != 0) {
    s = l > 0.5 ? delta / (2 - max - min) : delta / (max + min);
    
    if (max == r) {
      h = ((g - b) / delta + (g < b ? 6 : 0)) / 6;
    } else if (max == g) {
      h = ((b - r) / delta + 2) / 6;
    } else {
      h = ((r - g) / delta + 4) / 6;
    }
  }
  
  return [h * 360, s, l];
}

/// Converts HSL (Hue, Saturation, Lightness) values to an RGB Color.
/// 
/// Parameters:
///   h: Hue in degrees (0-360)
///   s: Saturation as decimal (0-1)
///   l: Lightness as decimal (0-1)
/// 
/// Returns: Color object with corresponding RGB values
Color hslToColor(double h, double s, double l) {
  h = h / 360;
  
  double hueToRgb(double p, double q, double t) {
    if (t < 0) t += 1;
    if (t > 1) t -= 1;
    if (t < 1/6) return p + (q - p) * 6 * t;
    if (t < 1/2) return q;
    if (t < 2/3) return p + (q - p) * (2/3 - t) * 6;
    return p;
  }
  
  double r, g, b;
  
  if (s == 0) {
    r = g = b = l;
  } else {
    final q = l < 0.5 ? l * (1 + s) : l + s - l * s;
    final p = 2 * l - q;
    r = hueToRgb(p, q, h + 1/3);
    g = hueToRgb(p, q, h);
    b = hueToRgb(p, q, h - 1/3);
  }
  
  return Color.fromARGB(
    255,
    (r * 255).round().clamp(0, 255),
    (g * 255).round().clamp(0, 255),
    (b * 255).round().clamp(0, 255),
  );
}

/// Applies a lightness offset to a color while preserving hue and saturation.
/// 
/// Parameters:
///   baseColor: The original color to adjust
///   lightnessOffset: Percentage points to adjust (-25 to +25)
///                    Negative values darken, positive values lighten
/// 
/// Returns: New Color with adjusted lightness
Color applyLightnessOffset(Color baseColor, int lightnessOffset) {
  final hsl = colorToHSL(baseColor);
  final newL = (hsl[2] + lightnessOffset / 100).clamp(0.0, 1.0);
  return hslToColor(hsl[0], hsl[1], newL);
}

/// Converts a hex string to a Color object.
/// 
/// Supports formats: "#RRGGBB" or "RRGGBB" (with or without hash prefix).
/// Returns the fallback color if parsing fails or value is null.
/// 
/// Parameters:
///   value: Hex string to parse (can be null)
///   fallback: Color to return if parsing fails
/// 
/// Returns: Parsed Color or fallback
Color colorFromHex(dynamic value, Color fallback) {
  if (value == null) return fallback;
  try {
    return Color(int.parse(value.toString().replaceFirst("#", "0xff")));
  } catch (e) {
    debugPrint('⚠️ Failed to parse color from hex: $value, using fallback');
    return fallback;
  }
}

/// Converts a Color to a hex string without the '#' prefix.
/// 
/// Parameters:
///   c: The Color to convert
/// 
/// Returns: Hex string in format "RRGGBB"
String colorToHex(Color c) {
  final r = (c.r * 255).round().toRadixString(16).padLeft(2, '0');
  final g = (c.g * 255).round().toRadixString(16).padLeft(2, '0');
  final b = (c.b * 255).round().toRadixString(16).padLeft(2, '0');
  return '$r$g$b';
}