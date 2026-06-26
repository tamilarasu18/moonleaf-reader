import 'package:flutter/material.dart';

import '../models/book.dart';
import '../utils/constants.dart';
import 'book_cover.dart';

/// A prominent "Continue Reading" spotlight card for the home page. Draws its
/// background gradient from the book's cover colours and shows the title,
/// author, and current chapter.
class ReadingSpotlight extends StatelessWidget {
  const ReadingSpotlight({
    super.key,
    required this.book,
    required this.chapterTitle,
    required this.onTap,
  });

  final Book book;
  final String chapterTitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Pull gradient colours from the book cover.
    final gradStart = book.coverGradient.first;
    final gradEnd = book.coverGradient.last;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.screenPadding,
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                gradStart.withValues(alpha: isDark ? 0.85 : 0.75),
                gradEnd.withValues(alpha: isDark ? 0.95 : 0.85),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: gradEnd.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Soft glassy overlay.
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: RadialGradient(
                      center: const Alignment(-0.6, -0.4),
                      radius: 1.4,
                      colors: [
                        Colors.white.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Content.
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Book cover thumbnail.
                    SizedBox(
                      width: 80,
                      child: AspectRatio(
                        aspectRatio: 2 / 3,
                        child: BookCover(book: book),
                      ),
                    ),
                    const SizedBox(width: 18),
                    // Book info.
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'CONTINUE READING',
                            style: TextStyle(
                              fontFamily: AppConstants.fontUi,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                              color: Colors.white.withValues(alpha: 0.65),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            book.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: AppConstants.fontReading,
                              fontSize: 19,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            book.author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppConstants.fontUi,
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.72),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Chapter badge.
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.bookmark_outline,
                                  size: 14,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    chapterTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: AppConstants.fontUi,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          Colors.white.withValues(alpha: 0.85),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Arrow hint.
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
