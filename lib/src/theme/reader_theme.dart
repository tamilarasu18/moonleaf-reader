import 'package:flutter/material.dart';

/// The reading-surface palette modes a reader can choose between. Kept separate
/// from the app's overall light/dark theme so the reading page can be tuned
/// independently (a common e-reader expectation).
enum ReaderPalette { light, sepia, dark }

extension ReaderPaletteX on ReaderPalette {
  String get label => switch (this) {
        ReaderPalette.light => 'Light',
        ReaderPalette.sepia => 'Sepia',
        ReaderPalette.dark => 'Night',
      };

  IconData get icon => switch (this) {
        ReaderPalette.light => Icons.light_mode_outlined,
        ReaderPalette.sepia => Icons.wb_twilight_outlined,
        ReaderPalette.dark => Icons.dark_mode_outlined,
      };
}

/// Concrete colours for the reading surface derived from a [ReaderPalette].
class ReaderColors {
  const ReaderColors({
    required this.background,
    required this.surface,
    required this.text,
    required this.faint,
  });

  final Color background;
  final Color surface;
  final Color text;
  final Color faint;

  /// Builds the palette colours, optionally blending the background and surface
  /// toward a warm amber tint controlled by [warmth] (0.0 = neutral, 1.0 = max
  /// warmth). Text and faint colours are left untouched.
  static ReaderColors of(ReaderPalette palette, {double warmth = 0.0}) {
    // Base colours per palette (unchanged from before).
    const bases = {
      ReaderPalette.light: ReaderColors(
        background: Color(0xFFFCFBF9),
        surface: Color(0xFFF1F0EC),
        text: Color(0xFF1B1B1B),
        faint: Color(0xFF707070),
      ),
      ReaderPalette.sepia: ReaderColors(
        background: Color(0xFFF4ECD8),
        surface: Color(0xFFEADFC4),
        text: Color(0xFF5B4636),
        faint: Color(0xFF8A745B),
      ),
      ReaderPalette.dark: ReaderColors(
        background: Color(0xFF14141F),
        surface: Color(0xFF1E1E2C),
        text: Color(0xFFD8D6DE),
        faint: Color(0xFF8A8A99),
      ),
    };

    final base = bases[palette]!;
    if (warmth <= 0) return base;

    // Warm tint targets — slightly different per brightness so the overlay
    // looks natural in every mode.
    final warmTarget = palette == ReaderPalette.dark
        ? const Color(0xFF2A2218) // warm brown for dark
        : const Color(0xFFF5E6C8); // warm amber for light/sepia

    final w = warmth.clamp(0.0, 1.0) * 0.35; // cap the max blend to 35 %

    return ReaderColors(
      background: Color.lerp(base.background, warmTarget, w)!,
      surface: Color.lerp(base.surface, warmTarget, w)!,
      text: base.text,
      faint: base.faint,
    );
  }

  Brightness get brightness =>
      ThemeData.estimateBrightnessForColor(background);
}

/// The colour filter applied to a rendered PDF page so it adopts the active
/// reading palette: **Light** leaves the page untouched (full originality),
/// **Sepia** warms the paper to a cream tone, and **Night** inverts it into a
/// dark reading surface. Returns null when no filtering is needed.
ColorFilter? readerPageColorFilter(ReaderPalette palette) {
  switch (palette) {
    case ReaderPalette.light:
      return null;
    case ReaderPalette.sepia:
      // Multiply by a warm cream: white paper becomes sepia while dark text and
      // images keep their contrast.
      return const ColorFilter.mode(Color(0xFFF1E2C0), BlendMode.multiply);
    case ReaderPalette.dark:
      // Invert luminance so the white page reads as near-black with light text.
      return const ColorFilter.matrix(<double>[
        -1, 0, 0, 0, 255, //
        0, -1, 0, 0, 255, //
        0, 0, -1, 0, 255, //
        0, 0, 0, 1, 0, //
      ]);
  }
}
