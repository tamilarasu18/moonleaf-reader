import 'package:flutter/widgets.dart';

/// App-wide constants. Keeping these in one place avoids magic numbers/strings
/// scattered across the codebase (Single Responsibility for configuration).
class AppConstants {
  AppConstants._();

  static const String appName = 'Moonleaf';
  static const String tagline = 'Turn the page by moonlight';

  /// Font family names — must match the `fonts:` entries in pubspec.yaml.
  static const String fontUi = 'Inter';
  static const String fontReading = 'Lora';

  // Spacing scale.
  static const double gapXs = 4;
  static const double gapS = 8;
  static const double gapM = 16;
  static const double gapL = 24;
  static const double gapXl = 32;

  static const double screenPadding = 20;
  static const double cardRadius = 18;

  // Splash timing.
  static const Duration splashHold = Duration(milliseconds: 2200);
  static const Duration splashAnim = Duration(milliseconds: 1400);

  // Reader settings bounds.
  static const double minFontSize = 14;
  static const double maxFontSize = 30;
  static const double minLineHeight = 1.3;
  static const double maxLineHeight = 2.2;
}

/// Preference keys, isolated so persistence wiring stays consistent.
class PrefKeys {
  PrefKeys._();
  static const String themeMode = 'app_theme_mode';
  static const String readerPalette = 'reader_palette';
  static const String fontSize = 'reader_font_size';
  static const String lineHeight = 'reader_line_height';
  static const String serif = 'reader_serif';
  static const String warmth = 'reader_warmth';
  static const String flipStyle = 'reader_flip_style';
  static const String userCategories = 'user_categories';
  static const String importedPdfs = 'imported_pdfs';
  static const String progress = 'reading_progress';
}

/// Standard page transition used across the app.
PageRouteBuilder<T> fadeThroughRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
