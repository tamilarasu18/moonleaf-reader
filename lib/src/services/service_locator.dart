import 'book_repository.dart';
import 'category_service.dart';
import 'i_book_repository.dart';
import 'i_category_service.dart';
import 'i_preferences_service.dart';
import 'i_progress_service.dart';
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
  });

  final IPreferencesService preferences;
  final IBookRepository books;
  final IProgressService progress;
  final ICategoryService categories;

  static Future<ServiceLocator> initialize() async {
    final preferences = await PreferencesService.create();
    return ServiceLocator._(
      preferences: preferences,
      books: BookRepository(),
      progress: ProgressService(preferences),
      categories: CategoryService(preferences),
    );
  }
}
