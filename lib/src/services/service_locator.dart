import 'book_repository.dart';
import 'category_service.dart';
import 'highlight_service.dart';
import 'i_book_repository.dart';
import 'i_category_service.dart';
import 'i_highlight_service.dart';
import 'i_pdf_service.dart';
import 'i_preferences_service.dart';
import 'i_progress_service.dart';
import 'pdf_service.dart';
import 'preferences_service.dart';
import 'progress_service.dart';

/// Tiny composition root / dependency container.
///
/// All concrete wiring lives here and nowhere else: the rest of the app only
/// ever sees the abstract interfaces. Built once in `main()` and handed to the
/// widget tree, which exposes the services via `provider`.
class ServiceLocator {
  ServiceLocator._({
    required this.preferences,
    required this.books,
    required this.progress,
    required this.categories,
    required this.pdf,
    required this.highlights,
  });

  final IPreferencesService preferences;
  final IBookRepository books;
  final IProgressService progress;
  final ICategoryService categories;
  final IPdfService pdf;
  final IHighlightService highlights;

  static Future<ServiceLocator> initialize() async {
    final preferences = await PreferencesService.create();
    final pdfService = PdfService(preferences);
    return ServiceLocator._(
      preferences: preferences,
      books: BookRepository(pdfService: pdfService),
      progress: ProgressService(preferences),
      categories: CategoryService(preferences),
      pdf: pdfService,
      highlights: HighlightService(preferences),
    );
  }
}
