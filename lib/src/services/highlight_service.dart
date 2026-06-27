import 'dart:convert';

import '../models/highlight.dart';
import 'i_highlight_service.dart';
import 'i_preferences_service.dart';

/// Persists [Highlight] annotations as JSON through [IPreferencesService].
///
/// Storage key: `highlights_<bookId>` — one JSON array per book so lookups
/// are O(n) only over that book's highlights, not the entire store.
class HighlightService implements IHighlightService {
  HighlightService(this._prefs);

  final IPreferencesService _prefs;

  /// In-memory cache per book so we only deserialise once.
  final Map<String, List<Highlight>> _cache = {};

  // ── Private helpers ─────────────────────────────────────────────────────

  String _key(String bookId) => 'highlights_$bookId';

  List<Highlight> _load(String bookId) {
    if (_cache.containsKey(bookId)) return _cache[bookId]!;
    final raw = _prefs.getString(_key(bookId));
    if (raw == null || raw.isEmpty) {
      _cache[bookId] = [];
      return _cache[bookId]!;
    }
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => Highlight.fromJson(e as Map<String, dynamic>))
          .toList();
      _cache[bookId] = list;
    } catch (_) {
      _cache[bookId] = [];
    }
    return _cache[bookId]!;
  }

  Future<void> _persist(String bookId) {
    final list = _cache[bookId] ?? [];
    final json = jsonEncode(list.map((h) => h.toJson()).toList());
    return _prefs.setString(_key(bookId), json);
  }

  // ── IHighlightService ───────────────────────────────────────────────────

  @override
  List<Highlight> getHighlights(String bookId) => List.unmodifiable(_load(bookId));

  @override
  List<Highlight> getPageHighlights(String bookId, int pageIndex) =>
      _load(bookId).where((h) => h.pageIndex == pageIndex).toList();

  @override
  Future<void> addHighlight(Highlight highlight) {
    _load(highlight.bookId).add(highlight);
    return _persist(highlight.bookId);
  }

  @override
  Future<void> removeHighlight(String bookId, String highlightId) {
    _load(bookId).removeWhere((h) => h.id == highlightId);
    return _persist(bookId);
  }

  @override
  Future<void> removeAllForBook(String bookId) {
    _cache.remove(bookId);
    return _prefs.setString(_key(bookId), '[]');
  }
}
