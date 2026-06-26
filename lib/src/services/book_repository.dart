import '../data/sample_books.dart';
import '../models/book.dart';
import 'i_book_repository.dart';

/// In-memory repository backed by the bundled public-domain sample books.
///
/// Replace/extend this with a real source (local EPUB import, an API, etc.)
/// without changing any ViewModel — they depend only on [IBookRepository].
class BookRepository implements IBookRepository {
  BookRepository({List<Book>? books}) : _books = books ?? sampleBooks;

  final List<Book> _books;

  @override
  List<Book> getAll() => List.unmodifiable(_books);

  @override
  Book? getById(String id) {
    for (final book in _books) {
      if (book.id == id) return book;
    }
    return null;
  }
}
