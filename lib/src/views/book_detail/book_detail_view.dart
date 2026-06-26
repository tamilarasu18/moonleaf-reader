import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/add_to_category_sheet.dart';
import '../../components/book_cover.dart';
import '../../services/i_book_repository.dart';
import '../../services/i_category_service.dart';
import '../../services/i_progress_service.dart';
import '../../utils/constants.dart';
import '../../utils/extensions.dart';
import '../../viewmodels/book_detail_viewmodel.dart';
import '../../viewmodels/reader_viewmodel.dart';
import '../reader/reader_view.dart';

/// Detail screen for a single book: cover, blurb, chapter list and the
/// start/continue action. Bound to [BookDetailViewModel].
class BookDetailView extends StatelessWidget {
  const BookDetailView({super.key});

  Future<void> _openReader(BuildContext context, {int? chapter}) async {
    final detail = context.read<BookDetailViewModel>();
    await Navigator.of(context).push(
      fadeThroughRoute(
        ChangeNotifierProvider<ReaderViewModel>(
          create: (ctx) => ReaderViewModel(
            books: ctx.read<IBookRepository>(),
            progress: ctx.read<IProgressService>(),
            bookId: detail.book.id,
            startChapter: chapter,
          ),
          child: const ReaderView(),
        ),
      ),
    );
    if (context.mounted) context.read<BookDetailViewModel>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BookDetailViewModel>();
    final book = vm.book;

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (vm.isStarted)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'reset') vm.resetProgress();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'reset', child: Text('Reset progress')),
              ],
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppConstants.screenPadding,
          0,
          AppConstants.screenPadding,
          AppConstants.gapL,
        ),
        children: [
          Center(
            child: SizedBox(
              width: 158,
              child: AspectRatio(
                aspectRatio: 2 / 3,
                child: BookCover(book: book, heroTag: 'cover_${book.id}'),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.gapL),
          Text(
            book.title,
            textAlign: TextAlign.center,
            style: context.text.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            book.author,
            textAlign: TextAlign.center,
            style: context.text.titleMedium
                ?.copyWith(color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppConstants.gapM),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(icon: Icons.local_offer_outlined, label: book.category),
              _MetaChip(
                icon: Icons.menu_book_outlined,
                label: 'chapter'.plural(book.chapterCount),
              ),
              _MetaChip(
                icon: Icons.schedule_outlined,
                label: '${book.totalReadingMinutes} min',
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Add to collection button.
          Center(
            child: ActionChip(
              avatar: const Icon(Icons.library_add_outlined, size: 18),
              label: const Text('Add to collection'),
              onPressed: () {
                final catService = context.read<ICategoryService>();
                final allCats = catService.getAll();
                final memberCats = allCats
                    .where((c) => c.bookIds.contains(book.id))
                    .toList();
                showAddToCategorySheet(
                  context: context,
                  bookId: book.id,
                  allCategories: allCats,
                  memberCategories: memberCats,
                  onAdd: (catId) => catService.addBook(catId, book.id),
                  onRemove: (catId) =>
                      catService.removeBook(catId, book.id),
                  onCreate: (name) async {
                    await catService.create(name);
                    // Auto-add the book to the newly created category.
                    final updated = catService.getAll();
                    if (updated.isNotEmpty) {
                      await catService.addBook(
                        updated.last.id,
                        book.id,
                      );
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: AppConstants.gapL),
          Text('About', style: context.text.titleLarge),
          const SizedBox(height: AppConstants.gapS),
          Text(
            book.synopsis,
            style: context.text.bodyLarge?.copyWith(height: 1.5),
          ),
          const SizedBox(height: AppConstants.gapL),
          Text('Chapters', style: context.text.titleLarge),
          const SizedBox(height: AppConstants.gapXs),
          ...List.generate(book.chapterCount, (i) {
            final chapter = book.chapters[i];
            final isCurrent = vm.isStarted && vm.currentChapter == i;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: isCurrent
                    ? context.colors.secondary
                    : context.colors.surfaceContainerHighest,
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isCurrent
                        ? context.colors.onSecondary
                        : context.colors.onSurface,
                  ),
                ),
              ),
              title: Text(chapter.title),
              subtitle: Text('${chapter.readingMinutes} min read'),
              trailing: isCurrent
                  ? Icon(Icons.bookmark, color: context.colors.secondary, size: 20)
                  : null,
              onTap: () => _openReader(context, chapter: i),
            );
          }),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppConstants.screenPadding,
          0,
          AppConstants.screenPadding,
          AppConstants.gapM,
        ),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _openReader(context),
            icon: const Icon(Icons.auto_stories_outlined),
            label: Text(vm.actionLabel),
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: context.colors.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(label, style: context.text.labelMedium),
        ],
      ),
    );
  }
}
