import 'package:flutter/foundation.dart';

import '../models/book.dart';
import '../models/user_category.dart';
import '../services/i_book_repository.dart';
import '../services/i_category_service.dart';
import '../services/i_pdf_service.dart';
import '../services/i_progress_service.dart';

/// ViewModel for the library screen. Combines the catalogue with reading
/// progress and user-created categories to power the home page.
class LibraryViewModel extends ChangeNotifier {
  LibraryViewModel({
    required IBookRepository books,
    required IProgressService progress,
    required ICategoryService categories,
    required IPdfService pdf,
  })  : _books = books,
        _progress = progress,
        _categories = categories,
        _pdf = pdf {
    refresh();
  }

  final IBookRepository _books;
  final IProgressService _progress;
  final ICategoryService _categories;
  final IPdfService _pdf;

  List<Book> _allBooks = const [];
  List<Book> _continueReading = const [];

  List<Book> get allBooks => _allBooks;
  List<Book> get continueReading => _continueReading;
  bool get hasContinueReading => _continueReading.isNotEmpty;

  /// Re-reads progress and categories (call when returning from the reader).
  void refresh() {
    _books.refresh();
    _allBooks = _books.getAll();
    _continueReading = _progress
        .inProgressBookIds()
        .map(_books.getById)
        .whereType<Book>()
        .toList();
    notifyListeners();
  }

  /// Progress through [book] as a 0–1 fraction, based on chapter position.
  double progressFor(Book book) {
    if (!_progress.hasProgress(book.id) || book.chapterCount <= 1) return 0;
    return (_progress.chapterFor(book.id) / (book.chapterCount - 1))
        .clamp(0.0, 1.0);
  }

  bool isStarted(Book book) => _progress.hasProgress(book.id);

  /// Last-read chapter index for [book] (0 if not started).
  int chapterIndexFor(Book book) => _progress.chapterFor(book.id);

  // ── Genre helpers ───────────────────────────────────────────────────────

  /// Books grouped by their [Book.category] for genre shelves.
  Map<String, List<Book>> get booksByCategory {
    final map = <String, List<Book>>{};
    for (final b in _allBooks) {
      map.putIfAbsent(b.category, () => []).add(b);
    }
    return map;
  }

  /// Sorted unique category names.
  List<String> get categories {
    final cats = _allBooks.map((b) => b.category).toSet().toList()..sort();
    return cats;
  }

  /// The most recently read book (for the spotlight), or the first book.
  Book? get featuredBook {
    if (_continueReading.isNotEmpty) return _continueReading.first;
    if (_allBooks.isNotEmpty) return _allBooks.first;
    return null;
  }

  // ── User categories ─────────────────────────────────────────────────────

  /// All user-created categories.
  List<UserCategory> get userCategories => _categories.getAll();

  /// Whether the user has created any custom categories.
  bool get hasUserCategories => _categories.getAll().isNotEmpty;

  /// Resolve a user category's bookIds to actual [Book] objects.
  List<Book> booksForUserCategory(UserCategory cat) {
    return cat.bookIds
        .map(_books.getById)
        .whereType<Book>()
        .toList();
  }

  /// Check which user categories a book belongs to.
  List<UserCategory> categoriesForBook(String bookId) {
    return _categories
        .getAll()
        .where((c) => c.bookIds.contains(bookId))
        .toList();
  }

  /// Create a new user category.
  Future<void> createCategory(String name) async {
    await _categories.create(name);
    notifyListeners();
  }

  /// Rename an existing user category.
  Future<void> renameCategory(String categoryId, String newName) async {
    await _categories.rename(categoryId, newName);
    notifyListeners();
  }

  /// Delete a user category.
  Future<void> deleteCategory(String categoryId) async {
    await _categories.delete(categoryId);
    notifyListeners();
  }

  /// Add a book to a user category.
  Future<void> addBookToCategory(String categoryId, String bookId) async {
    await _categories.addBook(categoryId, bookId);
    notifyListeners();
  }

  /// Remove a book from a user category.
  Future<void> removeBookFromCategory(
      String categoryId, String bookId) async {
    await _categories.removeBook(categoryId, bookId);
    notifyListeners();
  }

  // ── PDF Imports ────────────────────────────────────────────────────────

  /// Import a PDF and add it to the library.
  Future<void> importPdf(String path) async {
    final book = await _pdf.import(path);
    _books.addBook(book);
    refresh();
  }

  /// Delete an imported PDF book.
  Future<void> deletePdf(String bookId) async {
    await _pdf.delete(bookId);
    _books.removeBook(bookId);
    // Also remove from any categories.
    for (final cat in categoriesForBook(bookId)) {
      await _categories.removeBook(cat.id, bookId);
    }
    // And from reading progress.
    await _progress.clear(bookId);
    refresh();
  }
}
