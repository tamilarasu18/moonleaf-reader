import 'package:flutter/widgets.dart';

/// Splits a block of plain text into page-sized chunks that each fit within the
/// given width/height for a particular [TextStyle].
///
/// Pure layout helper (no business logic — same role as [extensions]). The text
/// is laid out **once** with a [TextPainter] and the resulting line metrics are
/// walked to find break points, so pagination is exact for any font size /
/// line height and costs a single layout pass per call — cheap enough to keep
/// page turns lag-free.
class TextPaginator {
  const TextPaginator._();

  /// Returns the page slices of [text]. The first page is allowed
  /// [firstPageHeight] of vertical space (e.g. less, to make room for a chapter
  /// heading) and every subsequent page [otherPageHeight].
  static List<String> paginate({
    required String text,
    required TextStyle style,
    required double maxWidth,
    required double firstPageHeight,
    required double otherPageHeight,
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return const [''];
    if (maxWidth <= 0 || otherPageHeight <= 0) return [trimmed];

    final painter = TextPainter(
      text: TextSpan(text: trimmed, style: style),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout(maxWidth: maxWidth);

    try {
      final lines = painter.computeLineMetrics();
      if (lines.length <= 1) return [trimmed];

      final pages = <String>[];
      var pageStart = 0; // char offset of the current page's first character
      var pageTop = 0.0; // top of the current page's first line box, in px
      var pageStartLine = 0; // line index the current page started on
      var limit = firstPageHeight > 0 ? firstPageHeight : otherPageHeight;

      // Lines stack contiguously, so the running top of line i's box is the sum
      // of the heights of every line before it. We measure against the line's
      // *full* box height ([LineMetrics.height], which includes the leading) so
      // the budget matches what actually renders — `baseline ± ascent/descent`
      // omits the half-leading and lets a page overrun its box by a few pixels.
      var lineTop = 0.0;
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final lineBottom = lineTop + line.height;

        // Break *before* line i once it would spill past the page's budget, but
        // never produce an empty page (keep at least one line per page).
        if (i > pageStartLine && lineBottom - pageTop > limit) {
          final glyphTop = line.baseline - line.ascent;
          final breakOffset =
              painter.getPositionForOffset(Offset(0, glyphTop + 1)).offset;
          if (breakOffset > pageStart) {
            pages.add(trimmed.substring(pageStart, breakOffset).trim());
            pageStart = breakOffset;
            pageTop = lineTop;
            pageStartLine = i;
            limit = otherPageHeight;
          }
        }
        lineTop = lineBottom;
      }

      pages.add(trimmed.substring(pageStart).trim());
      return pages.where((p) => p.isNotEmpty).toList(growable: false);
    } finally {
      painter.dispose();
    }
  }
}
