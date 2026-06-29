import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens extracted 1:1 from the RN app (src/theme/*.ts) so the preview
/// matches the app exactly. Dark mode (the app's default in screenshots).
class AppTokens {
  // Accent — the REAL value from colors.ts (ACCENT_ORANGE), not the stale doc value.
  static const accent = Color(0xFFF15B24);

  // Dark mode colors (darkColors in colors.ts)
  static const bg = Color(0xFF000000);
  static const surface = Color(0xFF1A1A1A);
  static const text = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFA1A1AA); // gray.400
  static const textTertiary = Color(0xFF71717A); // gray.500
  static const border = Color(0xFF27272A); // gray.800
  static const calloutBg = Color(0xFF2F2F2F); // Notion callout default (dark)
  static const codeHeaderBg = Color(0x0DFFFFFF); // rgba(255,255,255,0.05)
  static const codeBodyBg = Color(0x08FFFFFF); // rgba(255,255,255,0.03)
  static const inlineCodeBg = Color(0x1AFFFFFF); // rgba(255,255,255,0.1)
  // Link underline at reduced opacity (RichText.tsx): rgba(247,147,26,0.45) dark
  static const linkUnderline = Color(0x73F7931A);
  static const todoChecked = Color(0xFF22C55E);

  // Spacing scale (spacing.ts)
  static const xs = 4.0, sm = 8.0, md = 16.0, lg = 24.0, xl = 32.0;
  static const screenPadding = 24.0; // SCREEN_HORIZONTAL_PADDING = spacing.lg
  static const phoneWidth = 393.0; // iPhone 17 logical width
  static const radiusMd = 8.0;
  static const radiusXs = 4.0;

  // Inter (the app uses Inter Variable). google_fonts provides Inter.
  static TextStyle inter({
    required double size,
    required double lineHeight,
    FontWeight weight = FontWeight.w400,
    Color color = text,
    bool italic = false,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        height: lineHeight / size,
        fontWeight: weight,
        color: color,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      );

  // --- legacy aliases used by editor chrome / chart block / publish ---
  static const bitcoinOrange = accent;
  static const textPrimary = text;
  static const backgroundTertiary = Color(0xFF18181B);
  static const fontFamily = 'Inter';
}
