import 'package:flutter/foundation.dart';

import '../models/book.dart';
import '../services/i_progress_service.dart';

/// ViewModel for the book detail screen: exposes the book and whether reading
/// is in progress so the action button can read "Start" vs "Continue".
class BookDetailViewModel extends ChangeNotifier {
  BookDetailViewModel({
    required this.book,
    required IProgressService progress,
  }) : _progress = progress;

  final Book book;
  final IProgressService _progress;

  bool get isStarted => _progress.hasProgress(book.id);

  int get currentChapter => _progress.chapterFor(book.id);

  String get actionLabel => isStarted ? 'Continue reading' : 'Start reading';

  void resetProgress() {
    _progress.clear(book.id);
    notifyListeners();
  }

  /// Call when coming back from the reader so the button label refreshes.
  void refresh() => notifyListeners();
}
