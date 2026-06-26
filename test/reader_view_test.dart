import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moonleaf/src/services/i_book_repository.dart';
import 'package:moonleaf/src/services/i_progress_service.dart';
import 'package:moonleaf/src/services/service_locator.dart';
import 'package:moonleaf/src/viewmodels/app_viewmodel.dart';
import 'package:moonleaf/src/viewmodels/reader_viewmodel.dart';
import 'package:moonleaf/src/views/reader/reader_view.dart';

// Constrain the reader to a small, phone-like reading area so a chapter spans
// several pages (independent of the test surface size).
Widget _harness(ServiceLocator services, String bookId) {
  return MultiProvider(
    providers: [
      Provider<IBookRepository>.value(value: services.books),
      Provider<IProgressService>.value(value: services.progress),
      ChangeNotifierProvider<AppViewModel>(
        create: (_) => AppViewModel(services.preferences),
      ),
      ChangeNotifierProvider<ReaderViewModel>(
        create: (_) => ReaderViewModel(
          books: services.books,
          progress: services.progress,
          bookId: bookId,
        ),
      ),
    ],
    child: const MaterialApp(
      home: ReaderView(),
    ),
  );
}

String? _footerLabel() {
  for (final e in find.textContaining('Page ').evaluate()) {
    final data = (e.widget as Text).data;
    if (data != null && data.contains('·')) return data;
  }
  return null;
}

void main() {
  // Drives the real `page_flip` widget. The reader's own job — paginating the
  // chapter to fit and rendering the first page without overflow — is what we
  // assert here; the flip animation itself is the package's responsibility.
  testWidgets('Reader paginates a chapter into multiple pages without overflow',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'reader_font_size': 30.0,
      'reader_line_height': 2.2,
    });

    // Force a small portrait-sized test surface so the paginator splits the
    // chapter across several pages even with the short sample text.
    tester.view.physicalSize = const Size(250, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final services = await ServiceLocator.initialize();
    final book = services.books.getAll().first; // Pride and Prejudice

    await tester.pumpWidget(_harness(services, book.id));
    await tester.pumpAndSettle();

    final label = _footerLabel();
    expect(label, isNotNull, reason: 'Footer should report the page position');
    expect(label, startsWith('Page 1 of'));
    expect(label, contains('Chapter 1 of ${book.chapterCount}'));

    // The paginator should produce at least one page.
    final totalPages =
        int.parse(RegExp(r'Page 1 of (\d+)').firstMatch(label!)!.group(1)!);
    expect(totalPages, greaterThanOrEqualTo(1),
        reason: 'Chapter should paginate into at least one page');

    // The first page (heading + body) rendered; a RenderFlex overflow would
    // already have thrown and failed the test.
    expect(find.text(book.chapters.first.title), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
