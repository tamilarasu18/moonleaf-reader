import 'package:flutter/foundation.dart';

import '../models/book.dart';
import '../services/i_progress_service.dart';

/// Drives the PDF reading experience for a single imported book: the current
/// page and persisting the reader's place. The page index is stored in the same
/// per-book progress slot as text books (so PDFs also surface in "Continue
/// reading"). Depends only on the [IProgressService] abstraction.
class PdfReaderViewModel extends ChangeNotifier {
  PdfReaderViewModel({
    required IProgressService progress,
    required this.book,
  }) : _progress = progress {
    _page = _progress.chapterFor(book.id);
    // Mark the book as started/visited so it appears in "Continue reading".
    _progress.save(book.id, _page);
  }

  final IProgressService _progress;
  final Book book;

  int _page = 0;
  int _pageCount = 0;

  int get page => _page;
  int get pageCount => _pageCount;

  /// Called once the document is open and the real page count is known.
  void setPageCount(int count) {
    _pageCount = count;
    final clamped = count > 0 ? _page.clamp(0, count - 1) : 0;
    if (clamped != _page) {
      _page = clamped;
      _progress.save(book.id, _page);
    }
    notifyListeners();
  }

  void goToPage(int index) {
    final clamped = _pageCount > 0 ? index.clamp(0, _pageCount - 1) : index;
    if (clamped == _page) return;
    _page = clamped;
    _progress.save(book.id, _page);
    notifyListeners();
  }
}
