import '../models/book.dart';

/// Provides access to the book catalogue. Today it serves bundled sample
/// books; tomorrow an implementation could load EPUBs from disk or a backend
/// — callers (ViewModels) won't change (Open/Closed + Dependency Inversion).
abstract interface class IBookRepository {
  /// All books available in the library (sample + imported).
  List<Book> getAll();

  /// Look up a single book by id, or null if not found.
  Book? getById(String id);

  /// Add a dynamically imported book (e.g. PDF) to the in-memory catalogue.
  void addBook(Book book);

  /// Remove a book from the in-memory catalogue.
  void removeBook(String id);

  /// Reload imported books from services.
  void refresh();
}
