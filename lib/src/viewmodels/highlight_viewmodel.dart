import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../models/highlight.dart';
import '../services/i_highlight_service.dart';

/// ViewModel for PDF text highlighting.
///
/// Manages highlight mode state, the active brush colour, and the list of
/// highlights for the currently visible page. Views call [loadPage] whenever
/// the reader navigates so the correct highlights are shown.
class HighlightViewModel extends ChangeNotifier {
  HighlightViewModel({
    required IHighlightService highlightService,
    required String bookId,
  })  : _service = highlightService,
        _bookId = bookId;

  final IHighlightService _service;
  final String _bookId;

  // ── State ────────────────────────────────────────────────────────────────

  bool _highlightMode = false;
  bool get highlightMode => _highlightMode;

  HighlightColor _selectedColor = HighlightColor.yellow;
  HighlightColor get selectedColor => _selectedColor;

  int _currentPage = 0;

  List<Highlight> _pageHighlights = [];
  List<Highlight> get pageHighlights => _pageHighlights;

  // ── Commands ─────────────────────────────────────────────────────────────

  void toggleHighlightMode() {
    _highlightMode = !_highlightMode;
    notifyListeners();
  }

  void disableHighlightMode() {
    if (!_highlightMode) return;
    _highlightMode = false;
    notifyListeners();
  }

  void setColor(HighlightColor color) {
    _selectedColor = color;
    notifyListeners();
  }

  /// Refresh the highlight list when the page changes.
  void loadPage(int pageIndex) {
    _currentPage = pageIndex;
    _pageHighlights = _service.getPageHighlights(_bookId, pageIndex);
    notifyListeners();
  }

  /// Add a new highlight from a text selection.
  Future<void> addHighlight({
    required int pageIndex,
    required List<Rect> rects,
    required String text,
  }) async {
    final highlight = Highlight(
      id: '${_bookId}_${pageIndex}_${DateTime.now().millisecondsSinceEpoch}',
      bookId: _bookId,
      pageIndex: pageIndex,
      rects: rects,
      text: text,
      color: _selectedColor,
      createdAt: DateTime.now(),
    );
    await _service.addHighlight(highlight);
    // Refresh if we're still on the same page.
    if (_currentPage == pageIndex) {
      _pageHighlights = _service.getPageHighlights(_bookId, pageIndex);
      notifyListeners();
    }
  }

  /// Remove a highlight by id.
  Future<void> removeHighlight(String highlightId) async {
    await _service.removeHighlight(_bookId, highlightId);
    _pageHighlights = _service.getPageHighlights(_bookId, _currentPage);
    notifyListeners();
  }

  /// Get highlights for any page (used by pageBuilder to overlay on non-current pages).
  List<Highlight> highlightsForPage(int pageIndex) {
    return _service.getPageHighlights(_bookId, pageIndex);
  }
}
