import 'package:flutter/foundation.dart';

import '../models/book.dart';
import '../services/i_book_repository.dart';
import '../services/i_progress_service.dart';

/// ViewModel for the book detail screen: exposes the book and whether reading
/// is in progress so the action button can read "Start" vs "Continue".
class BookDetailViewModel extends ChangeNotifier {
  BookDetailViewModel({
    required Book book,
    required IBookRepository books,
    required IProgressService progress,
  })  : _book = book,
        _books = books,
        _progress = progress;

  Book _book;
  Book get book => _book;

  final IBookRepository _books;
  final IProgressService _progress;

  bool get isStarted => _progress.hasProgress(_book.id);

  int get currentChapter => _progress.chapterFor(_book.id);

  String get actionLabel => isStarted ? 'Continue reading' : 'Start reading';

  void resetProgress() {
    _progress.clear(_book.id);
    notifyListeners();
  }

  /// Reload the book from the repository (reflects category changes etc.)
  /// and notify listeners.
  void refresh() {
    final updated = _books.getById(_book.id);
    if (updated != null) _book = updated;
    notifyListeners();
  }
}
