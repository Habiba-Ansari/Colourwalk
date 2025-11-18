import 'package:palette_generator/palette_generator.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ColorDetectionService {
  // Convert Color to HSL
  static HSLColor colorToHsl(Color color) {
    return HSLColor.fromColor(color);
  }

  // Check if image contains today's color (loose matching)
  static Future<bool> doesImageContainColor(
    File imageFile, 
    Color todaysColor, {
    double hueTolerance = 30.0, // Accept colors within ±30° hue
    double minSaturation = 0.2, // Minimum 20% saturation
    double minProminence = 0.1, // Color should be at least 10% prominent
  }) async {
    try {
      // Generate color palette from image
      final PaletteGenerator paletteGenerator =
          await PaletteGenerator.fromImageProvider(
        FileImage(imageFile),
        maximumColorCount: 6, // Analyze top 6 colors
      );

      // Get today's color in HSL
      final HSLColor targetHsl = colorToHsl(todaysColor);
      final double targetHue = targetHsl.hue;

      // Check each prominent color in the image
      for (var paletteColor in paletteGenerator.colors) {
        final HSLColor imageColorHsl = colorToHsl(paletteColor); // Remove .color
        
        // Calculate hue difference (handling hue wrap-around 360°)
        double hueDifference = (imageColorHsl.hue - targetHue).abs();
        if (hueDifference > 180) {
          hueDifference = 360 - hueDifference;
        }

        // Check if this color matches today's color family
        if (hueDifference <= hueTolerance &&
            imageColorHsl.saturation >= minSaturation &&
            imageColorHsl.lightness <= 0.9 && // Not too close to white
            imageColorHsl.lightness >= 0.1) { // Not too close to black
          
          if (kDebugMode) {
            debugPrint('✅ Color match found! '
                'Target: ${targetHue.toStringAsFixed(1)}° '
                'Found: ${imageColorHsl.hue.toStringAsFixed(1)}° '
                'Diff: ${hueDifference.toStringAsFixed(1)}°');
          }
          
          return true;
        }
      }

      if (kDebugMode) {
        debugPrint('❌ No color match found for today\'s color');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error in color detection: $e');
      }
      return false; // If detection fails, assume no match
    }
  }

  // Get color name from hue (for debugging)
  static String getColorName(double hue) {
    if (hue < 15 || hue > 345) return 'Red';
    if (hue < 45) return 'Orange';
    if (hue < 90) return 'Yellow';
    if (hue < 150) return 'Green';
    if (hue < 210) return 'Cyan';
    if (hue < 270) return 'Blue';
    if (hue < 330) return 'Purple';
    return 'Pink';
  }
}