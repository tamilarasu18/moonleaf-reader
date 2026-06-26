import 'package:flutter/material.dart';

import '../models/book.dart';
import '../utils/constants.dart';

/// A stylised book cover generated from the book's gradient + title. Fills its
/// parent, so wrap it in a sized box / aspect ratio (covers are 2:3).
class BookCover extends StatelessWidget {
  const BookCover({super.key, required this.book, this.heroTag});

  final Book book;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);

    Widget cover = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: book.coverGradient,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Spine highlight.
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 6,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          // Watermark initials.
          Positioned(
            right: 6,
            top: 2,
            child: Text(
              book.initials,
              style: TextStyle(
                fontFamily: AppConstants.fontReading,
                fontSize: 66,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
          ),
          // Title + author.
          Positioned(
            left: 12,
            right: 10,
            bottom: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppConstants.fontReading,
                    color: Colors.white,
                    fontSize: 14.5,
                    height: 1.15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  book.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppConstants.fontUi,
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (heroTag != null) {
      cover = Hero(tag: heroTag!, child: cover);
    }
    return cover;
  }
}
