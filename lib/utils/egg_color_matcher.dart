import 'package:flutter/material.dart';
import '../models/chicken.dart';

/// Returns the display colour swatch for an egg colour category.
Color eggColorSwatch(String category) {
  switch (category) {
    case 'white':
      return const Color(0xFFFFFDF5);
    case 'cream':
      return const Color(0xFFF5E6C8);
    case 'light_brown':
      return const Color(0xFFD4A96A);
    case 'medium_brown':
      return const Color(0xFFB07742);
    case 'dark_brown':
      return const Color(0xFF7A4A1E);
    case 'speckled_brown':
      return const Color(0xFFC08050);
    case 'blue':
      return const Color(0xFFB0C8D8);
    case 'blue_green':
      return const Color(0xFF8FBDAD);
    case 'pink':
      return const Color(0xFFEDC4BC);
    case 'olive':
      return const Color(0xFF7A8A3A);
    case 'green':
      return const Color(0xFF7DB87D);
    case 'unknown':
    default:
      return Colors.grey.shade300;
  }
}

/// Returns a contrast colour for text on the swatch.
Color eggColorTextColor(String category) {
  final bg = eggColorSwatch(category);
  final luminance = bg.computeLuminance();
  return luminance > 0.5 ? Colors.black87 : Colors.white;
}

/// Matches a Claude-returned egg_color_category to chickens.
///
/// Returns:
///   - Empty list → no match → leave as "Unknown"
///   - 1 item → auto-select
///   - 2+ items → prompt user to choose
List<Chicken> matchChickensByEggColor(
    List<Chicken> allChickens, String eggColorCategory) {
  return allChickens
      .where((c) =>
          c.isActive && c.eggColorCategory == eggColorCategory)
      .toList();
}
