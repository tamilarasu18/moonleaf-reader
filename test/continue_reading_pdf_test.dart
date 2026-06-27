import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moonleaf/src/components/continue_reading_card.dart';
import 'package:moonleaf/src/models/book.dart';

/// Regression test: an imported PDF (no chapters) can appear in "Continue
/// reading". The card must not index its empty chapter list / clamp(0, -1).
void main() {
  final pdfBook = Book(
    id: 'pdf_1',
    title: 'My Imported PDF',
    author: 'PDF Import',
    synopsis: 'Imported PDF document.',
    coverGradient: const [Color(0xFF333333), Color(0xFF777777)],
    chapters: const [],
    category: 'Imported',
    pdfPath: '/tmp/x.pdf',
  );

  testWidgets('ContinueReadingCard renders a chapterless PDF without crashing',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ContinueReadingCard(
            book: pdfBook,
            progress: 0,
            chapterIndex: 0,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('My Imported PDF'), findsWidgets);
    expect(find.text('PDF document'), findsOneWidget);
  });
}
