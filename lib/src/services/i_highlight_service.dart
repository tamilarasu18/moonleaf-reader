import '../models/highlight.dart';

/// Abstraction for storing and retrieving PDF text highlights.
abstract class IHighlightService {
  /// All highlights for a given book.
  List<Highlight> getHighlights(String bookId);

  /// Highlights for a specific page of a book.
  List<Highlight> getPageHighlights(String bookId, int pageIndex);

  /// Persist a new highlight.
  Future<void> addHighlight(Highlight highlight);

  /// Remove a highlight by its unique id.
  Future<void> removeHighlight(String bookId, String highlightId);

  /// Remove every highlight for a book (e.g. when deleting the import).
  Future<void> removeAllForBook(String bookId);
}
