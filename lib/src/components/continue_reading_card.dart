import 'package:flutter/material.dart';

import '../models/book.dart';
import '../utils/constants.dart';
import '../utils/extensions.dart';
import 'book_cover.dart';

/// Horizontal card for the "Continue reading" row: a small cover, the title,
/// the current chapter and a progress bar.
class ContinueReadingCard extends StatelessWidget {
  const ContinueReadingCard({
    super.key,
    required this.book,
    required this.progress,
    required this.chapterIndex,
    required this.onTap,
  });

  final Book book;
  final double progress;
  final int chapterIndex;
  final VoidCallback onTap;

  /// Imported PDFs have no chapters, so show a simple label instead of indexing
  /// an empty chapter list.
  String get _subtitle {
    if (book.chapters.isEmpty) return book.isPdf ? 'PDF document' : '';
    return book.chapters[chapterIndex.clamp(0, book.chapterCount - 1)].title;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 290,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  child: AspectRatio(
                    aspectRatio: 2 / 3,
                    child: BookCover(book: book),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleMedium
                            ?.copyWith(fontFamily: AppConstants.fontReading),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
