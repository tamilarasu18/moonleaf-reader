import 'package:flutter/painting.dart';

import 'chapter.dart';

/// A book in the Moonleaf library. Pure data model.
class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.synopsis,
    required this.coverGradient,
    required this.chapters,
    this.category = 'Classic',
    this.pdfPath,
    this.pageCount = 0,
  });

  final String id;
  final String title;
  final String author;
  final String synopsis;
  final String category;
  final List<Color> coverGradient;
  final List<Chapter> chapters;
  final String? pdfPath;

  /// Total number of pages (used for PDFs; 0 for chapter-based books).
  final int pageCount;

  /// Whether this book is a PDF import (vs a chapter-based text book).
  bool get isPdf => pdfPath != null;

  int get chapterCount => chapters.length;

  /// For chapter-based books, sum of chapter reading times.
  /// For PDFs, estimate ~2 minutes per page.
  int get totalReadingMinutes =>
      isPdf ? (pageCount * 2) : chapters.fold(0, (sum, c) => sum + c.readingMinutes);

  /// Initials shown as a decorative accent on the cover.
  String get initials {
    final words = title.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      return words.first.substring(0, 1).toUpperCase();
    }
    return (words.first.substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
  }
}
