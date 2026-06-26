import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/book.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';
import 'book_cover.dart';

/// A genre bookshelf: category label, horizontal book scroll, and a decorative
/// shelf-edge bar beneath the books. Each book is slightly tilted for a
/// natural, lived-in feel.
class BookshelfRow extends StatelessWidget {
  const BookshelfRow({
    super.key,
    required this.category,
    required this.books,
    required this.onBookTap,
  });

  final String category;
  final List<Book> books;
  final void Function(Book) onBookTap;

  static const double _bookWidth = 110;
  static const double _bookHeight = 160;
  static const double _shelfBarHeight = 5;

  /// Map category names to icons for visual flair.
  static IconData _iconFor(String category) {
    switch (category.toLowerCase()) {
      case 'romance':
        return Icons.favorite_outline;
      case 'fantasy':
        return Icons.auto_awesome_outlined;
      case 'mystery':
        return Icons.search;
      case 'gothic':
        return Icons.castle_outlined;
      case 'adventure':
        return Icons.explore_outlined;
      default:
        return Icons.menu_book_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category label.
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.screenPadding,
            AppConstants.gapL,
            AppConstants.screenPadding,
            AppConstants.gapS,
          ),
          child: Row(
            children: [
              Icon(
                _iconFor(category),
                size: 18,
                color: AppColors.gold,
              ),
              const SizedBox(width: 8),
              Text(
                category,
                style: TextStyle(
                  fontFamily: AppConstants.fontReading,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        ),

        // Books row.
        SizedBox(
          height: _bookHeight + 12, // extra space for shadow
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.screenPadding,
            ),
            itemCount: books.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, i) {
              // Alternate tilt direction (±1.2°).
              final tiltAngle = (i.isEven ? 1.2 : -1.2) * math.pi / 180;

              return GestureDetector(
                onTap: () => onBookTap(books[i]),
                child: Transform.rotate(
                  angle: tiltAngle,
                  child: SizedBox(
                    width: _bookWidth,
                    height: _bookHeight,
                    child: BookCover(
                      book: books[i],
                      heroTag: 'shelf_${books[i].id}',
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Shelf edge decoration.
        Container(
          height: _shelfBarHeight,
          margin: const EdgeInsets.symmetric(
            horizontal: AppConstants.screenPadding,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      AppColors.shelfEdge.withValues(alpha: 0.5),
                      AppColors.shelfEdge.withValues(alpha: 0.15),
                    ]
                  : [
                      AppColors.shelfEdge.withValues(alpha: 0.7),
                      AppColors.shelfEdge.withValues(alpha: 0.25),
                    ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shelfShadow,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
