import 'package:flutter/material.dart';

/// SLAP brand colors and sticky note palette
class SlapColors {
  SlapColors._();

  // Brand Colors
  static const Color primary = Color(0xFFFF6B35);      // Energetic Orange
  static const Color secondary = Color(0xFF004E89);    // Deep Blue
  static const Color accent = Color(0xFFFFD166);       // Warm Yellow
  static const Color success = Color(0xFF06D6A0);      // Mint Green
  static const Color error = Color(0xFFEF476F);        // Coral Pink

  // Sticky Note Colors
  static const List<Color> noteColors = [
    Color(0xFFFFFFE0),  // Light Yellow (default)
    Color(0xFFFFB6C1),  // Light Pink
    Color(0xFF90EE90),  // Light Green
    Color(0xFFADD8E6),  // Light Blue
    Color(0xFFDDA0DD),  // Plum
    Color(0xFFFFDAB9),  // Peach
    Color(0xFFE6E6FA),  // Lavender
    Color(0xFFF0E68C),  // Khaki
  ];

  // Sticky Note Color Hex Strings (for database)
  static const List<String> noteColorHex = [
    'FFFFE0',  // Light Yellow
    'FFB6C1',  // Light Pink
    '90EE90',  // Light Green
    'ADD8E6',  // Light Blue
    'DDA0DD',  // Plum
    'FFDAB9',  // Peach
    'E6E6FA',  // Lavender
    'F0E68C',  // Khaki
  ];

  /// Parse hex color string to Color
  static Color fromHex(String hexColor) {
    final hex = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  /// Convert Color to hex string
  static String toHex(Color color) {
    return color.value.toRadixString(16).substring(2).toUpperCase();
  }
}
