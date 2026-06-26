/// Tracks each reader's place in a book (the last chapter they were on).
/// Small, focused interface (Interface Segregation): just reading progress.
abstract interface class IProgressService {
  /// Last-read chapter index for [bookId] (0 if never opened).
  int chapterFor(String bookId);

  bool hasProgress(String bookId);

  /// Ids of books the reader has started, most-recent first.
  List<String> inProgressBookIds();

  Future<void> save(String bookId, int chapterIndex);

  Future<void> clear(String bookId);
}
