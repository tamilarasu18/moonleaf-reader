import 'package:flutter/foundation.dart';

import '../models/book.dart';
import '../models/chapter.dart';
import '../services/i_book_repository.dart';
import '../services/i_progress_service.dart';

/// ViewModel that drives the reading experience for a single book: which
/// chapter is showing, navigation between chapters, and persisting progress.
class ReaderViewModel extends ChangeNotifier {
  ReaderViewModel({
    required IBookRepository books,
    required IProgressService progress,
    required String bookId,
    int? startChapter,
  })  : _progress = progress,
        book = books.getById(bookId)! {
    _index = (startChapter ?? _progress.chapterFor(bookId))
        .clamp(0, book.chapterCount - 1);
    // Mark the book as started/visited so it appears in "Continue reading".
    _progress.save(book.id, _index);
  }

  final IProgressService _progress;
  final Book book;

  int _index = 0;

  int get chapterIndex => _index;
  Chapter get chapter => book.chapters[_index];
  int get chapterCount => book.chapterCount;

  bool get canGoPrevious => _index > 0;
  bool get canGoNext => _index < book.chapterCount - 1;

  /// 0–1 progress through the book by chapter position.
  double get progress =>
      book.chapterCount <= 1 ? 1 : _index / (book.chapterCount - 1);

  void goToChapter(int index) {
    final next = index.clamp(0, book.chapterCount - 1);
    if (next == _index) return;
    _index = next;
    _progress.save(book.id, _index);
    notifyListeners();
  }

  void next() => goToChapter(_index + 1);
  void previous() => goToChapter(_index - 1);
}
