import '../models/book.dart';
import 'i_book_repository.dart';
import 'i_pdf_service.dart';

/// In-memory repository serving only imported PDFs.
///
/// Replace/extend this with a real source (local EPUB import, an API, etc.)
/// without changing any ViewModel — they depend only on [IBookRepository].
class BookRepository implements IBookRepository {
  BookRepository({
    List<Book>? books,
    required IPdfService pdfService,
  })  : _seedBooks = books ?? const [],
        _pdfService = pdfService {
    _rebuildList();
  }

  final List<Book> _seedBooks;
  final IPdfService _pdfService;
  List<Book> _allBooks = [];

  void _rebuildList() {
    _allBooks = [..._seedBooks, ..._pdfService.getImportedBooks()];
  }

  @override
  List<Book> getAll() => List.unmodifiable(_allBooks);

  @override
  Book? getById(String id) {
    for (final book in _allBooks) {
      if (book.id == id) return book;
    }
    return null;
  }

  @override
  void addBook(Book book) {
    _allBooks.add(book);
  }

  @override
  void removeBook(String id) {
    _allBooks.removeWhere((b) => b.id == id);
  }

  @override
  void refresh() {
    _rebuildList();
  }
}
