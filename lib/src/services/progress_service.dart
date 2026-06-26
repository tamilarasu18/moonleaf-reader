import 'dart:convert';

import '../utils/constants.dart';
import 'i_preferences_service.dart';
import 'i_progress_service.dart';

/// Stores reading progress as a JSON map persisted through
/// [IPreferencesService]. Depends on the abstraction, not on SharedPreferences.
///
/// Most-recently saved book ids are kept at the front of [_order] so the
/// "Continue reading" row can show the newest activity first.
class ProgressService implements IProgressService {
  ProgressService(this._prefs) {
    _load();
  }

  final IPreferencesService _prefs;
  final Map<String, int> _chapters = {};
  final List<String> _order = [];

  void _load() {
    final raw = _prefs.getString(PrefKeys.progress);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final entries = decoded['e'] as Map<String, dynamic>? ?? const {};
      final order = (decoded['o'] as List?)?.cast<String>() ?? const [];
      entries.forEach((k, v) => _chapters[k] = (v as num).toInt());
      _order
        ..clear()
        ..addAll(order.where(_chapters.containsKey));
    } catch (_) {
      _chapters.clear();
      _order.clear();
    }
  }

  Future<void> _persist() {
    final payload = jsonEncode({'e': _chapters, 'o': _order});
    return _prefs.setString(PrefKeys.progress, payload);
  }

  @override
  int chapterFor(String bookId) => _chapters[bookId] ?? 0;

  @override
  bool hasProgress(String bookId) => _chapters.containsKey(bookId);

  @override
  List<String> inProgressBookIds() => List.unmodifiable(_order);

  @override
  Future<void> save(String bookId, int chapterIndex) {
    _chapters[bookId] = chapterIndex;
    _order
      ..remove(bookId)
      ..insert(0, bookId);
    return _persist();
  }

  @override
  Future<void> clear(String bookId) {
    _chapters.remove(bookId);
    _order.remove(bookId);
    return _persist();
  }
}
