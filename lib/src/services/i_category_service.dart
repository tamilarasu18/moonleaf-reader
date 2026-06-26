import '../models/user_category.dart';

/// Abstraction for managing user-created categories (Dependency Inversion).
///
/// ViewModels depend on this interface; the concrete [CategoryService] handles
/// persistence through [IPreferencesService].
abstract interface class ICategoryService {
  /// All user-created categories.
  List<UserCategory> getAll();

  /// Create a new category with the given [name].
  Future<void> create(String name);

  /// Rename an existing category.
  Future<void> rename(String categoryId, String newName);

  /// Delete a category entirely.
  Future<void> delete(String categoryId);

  /// Add a book to a category.
  Future<void> addBook(String categoryId, String bookId);

  /// Remove a book from a category.
  Future<void> removeBook(String categoryId, String bookId);
}
