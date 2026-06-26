/// A single chapter of a book. [body] is plain text with paragraphs separated
/// by a blank line. Pure data model — no Flutter or persistence concerns.
class Chapter {
  const Chapter({required this.title, required this.body});

  final String title;
  final String body;

  /// The chapter text split into clean, individually renderable paragraphs.
  List<String> get paragraphs => body
      .trim()
      .split(RegExp(r'\n\s*\n'))
      .map((p) => p.replaceAll(RegExp(r'[ \t]+'), ' ').trim())
      .where((p) => p.isNotEmpty)
      .toList();

  /// Rough reading time for this chapter at ~220 words per minute.
  int get readingMinutes {
    final words = body.trim().split(RegExp(r'\s+')).length;
    return (words / 220).ceil().clamp(1, 999);
  }
}
