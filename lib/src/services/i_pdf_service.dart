import '../models/book.dart';

/// Abstraction for importing and managing PDF files (Dependency Inversion).
abstract interface class IPdfService {
  /// Import a PDF from the given source file path. Returns the new [Book].
  Future<Book> import(String sourcePath);

  /// All imported PDF books (metadata only — the file lives on disk).
  List<Book> getImportedBooks();

  /// Delete an imported PDF (removes the file and its metadata).
  Future<void> delete(String bookId);
}
