import '../components/page_turner.dart';
import '../theme/reader_theme.dart';

/// Immutable value object describing how the reading surface should look.
/// Being immutable + [copyWith] makes state changes explicit and testable.
class ReaderSettings {
  const ReaderSettings({
    this.palette = ReaderPalette.sepia,
    this.fontSize = 19,
    this.lineHeight = 1.6,
    this.serif = true,
    this.warmth = 0.0,
    this.flipStyle = PageFlipStyle.curl,
    this.pageColumns = 1,
  });

  final ReaderPalette palette;
  final double fontSize;
  final double lineHeight;
  final bool serif;

  /// Background warmth overlay, 0.0 (neutral) to 1.0 (max warm tint).
  final double warmth;

  /// The page-turn animation used in the reader.
  final PageFlipStyle flipStyle;

  /// Number of page columns in portrait mode (1 = single, 2 = dual spread).
  final int pageColumns;

  ReaderSettings copyWith({
    ReaderPalette? palette,
    double? fontSize,
    double? lineHeight,
    bool? serif,
    double? warmth,
    PageFlipStyle? flipStyle,
    int? pageColumns,
  }) {
    return ReaderSettings(
      palette: palette ?? this.palette,
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      serif: serif ?? this.serif,
      warmth: warmth ?? this.warmth,
      flipStyle: flipStyle ?? this.flipStyle,
      pageColumns: pageColumns ?? this.pageColumns,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ReaderSettings &&
      other.palette == palette &&
      other.fontSize == fontSize &&
      other.lineHeight == lineHeight &&
      other.serif == serif &&
      other.warmth == warmth &&
      other.flipStyle == flipStyle &&
      other.pageColumns == pageColumns;

  @override
  int get hashCode => Object.hash(
      palette, fontSize, lineHeight, serif, warmth, flipStyle, pageColumns);
}
