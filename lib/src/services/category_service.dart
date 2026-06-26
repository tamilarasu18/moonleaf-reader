import 'dart:convert';

import '../models/user_category.dart';
import '../utils/constants.dart';
import 'i_category_service.dart';
import 'i_preferences_service.dart';

/// Persists user-created categories as a JSON array through
/// [IPreferencesService]. Same proven pattern as [ProgressService].
class CategoryService implements ICategoryService {
  CategoryService(this._prefs) {
    _load();
  }

  final IPreferencesService _prefs;
  final List<UserCategory> _categories = [];

  // ── Persistence ───────────────────────────────────────────────────────

  void _load() {
    final raw = _prefs.getString(PrefKeys.userCategories);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List;
      _categories.addAll(
        list.map((e) => UserCategory.fromJson(e as Map<String, dynamic>)),
      );
    } catch (_) {
      _categories.clear();
    }
  }

  Future<void> _persist() {
    final payload = jsonEncode(_categories.map((c) => c.toJson()).toList());
    return _prefs.setString(PrefKeys.userCategories, payload);
  }

  // ── ICategoryService ──────────────────────────────────────────────────

  @override
  List<UserCategory> getAll() => List.unmodifiable(_categories);

  @override
  Future<void> create(String name) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _categories.add(UserCategory(id: id, name: name.trim()));
    return _persist();
  }

  @override
  Future<void> rename(String categoryId, String newName) {
    final idx = _categories.indexWhere((c) => c.id == categoryId);
    if (idx == -1) return Future.value();
    _categories[idx] = _categories[idx].copyWith(name: newName.trim());
    return _persist();
  }

  @override
  Future<void> delete(String categoryId) {
    _categories.removeWhere((c) => c.id == categoryId);
    return _persist();
  }

  @override
  Future<void> addBook(String categoryId, String bookId) {
    final idx = _categories.indexWhere((c) => c.id == categoryId);
    if (idx == -1) return Future.value();
    final cat = _categories[idx];
    if (cat.bookIds.contains(bookId)) return Future.value();
    _categories[idx] = cat.copyWith(bookIds: [...cat.bookIds, bookId]);
    return _persist();
  }

  @override
  Future<void> removeBook(String categoryId, String bookId) {
    final idx = _categories.indexWhere((c) => c.id == categoryId);
    if (idx == -1) return Future.value();
    final cat = _categories[idx];
    _categories[idx] = cat.copyWith(
      bookIds: cat.bookIds.where((id) => id != bookId).toList(),
    );
    return _persist();
  }
}
