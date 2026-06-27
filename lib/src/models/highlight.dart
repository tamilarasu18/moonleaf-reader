import 'dart:ui';

/// A single text highlight annotation on a PDF page.
///
/// Stores the bounding rectangles of the highlighted text in **normalised
/// coordinates** (0 → 1 relative to page dimensions) so they are independent
/// of render resolution. The rects are painted by [HighlightOverlay].
class Highlight {
  const Highlight({
    required this.id,
    required this.bookId,
    required this.pageIndex,
    required this.rects,
    required this.text,
    required this.color,
    required this.createdAt,
  });

  /// Unique identifier (UUID-style).
  final String id;

  /// The book this highlight belongs to.
  final String bookId;

  /// 0-based PDF page number.
  final int pageIndex;

  /// Bounding boxes of the highlighted text in normalised page coordinates
  /// (each value between 0 and 1). Multiple rects cover multi-line selections.
  final List<Rect> rects;

  /// The plain-text content that was highlighted.
  final String text;

  /// The colour used for the highlight background.
  final HighlightColor color;

  /// When the highlight was created.
  final DateTime createdAt;

  // ── Serialisation ──────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookId': bookId,
        'pageIndex': pageIndex,
        'rects': rects
            .map((r) => {
                  'l': r.left,
                  't': r.top,
                  'r': r.right,
                  'b': r.bottom,
                })
            .toList(),
        'text': text,
        'color': color.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Highlight.fromJson(Map<String, dynamic> json) {
    return Highlight(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      pageIndex: json['pageIndex'] as int,
      rects: (json['rects'] as List)
          .map((r) => Rect.fromLTRB(
                (r['l'] as num).toDouble(),
                (r['t'] as num).toDouble(),
                (r['r'] as num).toDouble(),
                (r['b'] as num).toDouble(),
              ))
          .toList(),
      text: json['text'] as String,
      color: HighlightColor.values.firstWhere(
        (c) => c.name == json['color'],
        orElse: () => HighlightColor.yellow,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Highlight copyWith({HighlightColor? color}) => Highlight(
        id: id,
        bookId: bookId,
        pageIndex: pageIndex,
        rects: rects,
        text: text,
        color: color ?? this.color,
        createdAt: createdAt,
      );
}

/// Predefined highlight colours.
///
/// Each colour has a semi-transparent fill (for the overlay) and a slightly
/// more opaque version for selection feedback.
enum HighlightColor {
  yellow(Color(0x55FFEB3B)),
  green(Color(0x5566BB6A)),
  blue(Color(0x5542A5F5)),
  pink(Color(0x55EC407A)),
  orange(Color(0x55FFA726));

  const HighlightColor(this.value);

  /// The semi-transparent overlay colour.
  final Color value;

  /// A label for display purposes.
  String get label => switch (this) {
        HighlightColor.yellow => 'Yellow',
        HighlightColor.green => 'Green',
        HighlightColor.blue => 'Blue',
        HighlightColor.pink => 'Pink',
        HighlightColor.orange => 'Orange',
      };
}
