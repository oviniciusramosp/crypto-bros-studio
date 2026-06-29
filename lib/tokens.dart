import 'package:flutter/material.dart';

/// Design tokens copied from the RN app so the Studio preview matches it.
/// Keep these in lock-step with the app's theme (src/theme/*) — there is no
/// automatic bridge between Expo/RN and Flutter, so this is a manual mirror.
class AppTokens {
  // Primary accent — Bitcoin Orange.
  static const Color bitcoinOrange = Color(0xFFF7931A);

  // Category colors (mirror src/theme).
  static const Color mercado = Color(0xFF3B82F6); // blue
  static const Color estudos = Color(0xFF8B5CF6); // purple
  static const Color altcoins = Color(0xFFF7931A); // orange
  static const Color trade = Color(0xFF22C55E); // green
  static const Color video = Color(0xFFEF4444); // red
  static const Color ath = Color(0xFFF59E0B); // gold/amber

  // Spacing scale (mirror src/theme/spacing).
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double screenHorizontalPadding = 16;

  // Typography — the app uses Inter. Bundle Inter in assets to render it here;
  // falls back to the platform sans-serif until then.
  static const String fontFamily = 'Inter';

  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color backgroundTertiary = Color(0xFFEFEFF2);
}
