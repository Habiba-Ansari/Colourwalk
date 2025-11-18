import 'dart:math';
import 'package:flutter/material.dart';

class DailyColorService {
  static final Random _random = Random();
  static List<Color> _usedColors = [];
  
  // Base colors to generate shades from
  static final List<Color> baseColors = [
    const Color(0xFFFF0000), // Red
    const Color(0xFF0000FF), // Blue
    const Color(0xFF00FF00), // Green
    const Color(0xFFFFFF00), // Yellow
    const Color(0xFFFFA500), // Orange
    const Color(0xFF800080), // Purple
    const Color(0xFFFFC0CB), // Pink
    const Color(0xFF008080), // Teal
    const Color(0xFF00FFFF), // Cyan
    const Color(0xFF00FF00), // Lime
    const Color(0xFF4B0082), // Indigo
    const Color(0xFFFFBF00), // Amber
    const Color(0xFFA52A2A), // Brown
    const Color(0xFFFF8C00), // Deep Orange
    const Color(0xFF87CEEB), // Light Blue
    const Color(0xFF90EE90), // Light Green
  ];

  // Generate random shade
  static Color _generateRandomShade() {
    Color baseColor = baseColors[_random.nextInt(baseColors.length)];
    
    // Generate random shade by adjusting RGB values
    int red = (baseColor.red + _random.nextInt(100) - 50).clamp(0, 255);
    int green = (baseColor.green + _random.nextInt(100) - 50).clamp(0, 255);
    int blue = (baseColor.blue + _random.nextInt(100) - 50).clamp(0, 255);
    
    return Color.fromRGBO(red, green, blue, 1.0);
  }

  // Get today's unique color
  static Color getTodaysColor() {
    final now = DateTime.now();
    
    // Use day-based random for consistent daily color
    final dailyRandom = Random(now.millisecondsSinceEpoch ~/ (1000 * 60 * 60 * 24));
    
    Color newColor;
    int attempts = 0;
    
    // Ensure color is not similar to recent ones
    do {
      newColor = _generateRandomShadeWithSeed(dailyRandom);
      attempts++;
    } while (_isColorTooSimilar(newColor) && attempts < 50);
    
    _updateUsedColors(newColor);
    return newColor;
  }

  // Generate color with specific random seed
  static Color _generateRandomShadeWithSeed(Random random) {
    Color baseColor = baseColors[random.nextInt(baseColors.length)];
    
    int red = (baseColor.red + random.nextInt(100) - 50).clamp(0, 255);
    int green = (baseColor.green + random.nextInt(100) - 50).clamp(0, 255);
    int blue = (baseColor.blue + random.nextInt(100) - 50).clamp(0, 255);
    
    return Color.fromRGBO(red, green, blue, 1.0);
  }

  // Check if color is too similar to recent ones
  static bool _isColorTooSimilar(Color newColor) {
    if (_usedColors.isEmpty) return false;
    
    for (Color usedColor in _usedColors) {
      if (_colorDistance(newColor, usedColor) < 100) {
        return true;
      }
    }
    return false;
  }

  // Calculate color distance (RGB space)
  static double _colorDistance(Color c1, Color c2) {
    return sqrt(
      pow(c1.red - c2.red, 2) +
      pow(c1.green - c2.green, 2) +
      pow(c1.blue - c2.blue, 2)
    );
  }

  // Keep track of recent colors (last 7 days)
  static void _updateUsedColors(Color newColor) {
    _usedColors.insert(0, newColor);
    if (_usedColors.length > 7) {
      _usedColors = _usedColors.sublist(0, 7);
    }
  }

  // Get border color (darker version)
  static Color getBorderColor(Color baseColor) {
    return Color.fromRGBO(
      (baseColor.red * 0.7).round().clamp(0, 255),
      (baseColor.green * 0.7).round().clamp(0, 255),
      (baseColor.blue * 0.7).round().clamp(0, 255),
      1.0,
    );
  }

  // Convert color to hex code for display
  static String getColorHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  // Get RGB values for display
  static String getColorRGB(Color color) {
    return 'RGB(${color.red}, ${color.green}, ${color.blue})';
  }
}