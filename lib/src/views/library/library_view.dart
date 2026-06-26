import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/bookshelf_row.dart';
import '../../components/manage_categories_sheet.dart';
import '../../components/moon_logo.dart';
import '../../components/reading_spotlight.dart';
import '../../models/book.dart';
import '../../services/i_progress_service.dart';
import '../../utils/constants.dart';
import '../../utils/extensions.dart';
import '../../viewmodels/book_detail_viewmodel.dart';
import '../../viewmodels/library_viewmodel.dart';
import '../book_detail/book_detail_view.dart';

/// The library home page: an animated hero header, a continue-reading spotlight,
/// genre bookshelves with decorative shelf edges, and the full library grid.
class LibraryView extends StatefulWidget {
  const LibraryView({super.key});

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView>
    with TickerProviderStateMixin {
  // ── Animations ────────────────────────────────────────────────────────────

  late final AnimationController _entranceCtrl;
  late final AnimationController _floatCtrl;

  // Entrance sub-animations (staggered).
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _spotlightFade;
  late final Animation<double> _spotlightScale;
  late final Animation<double> _shelvesFade;
  late final Animation<Offset> _shelvesSlide;

  // Floating logo animation.
  late final Animation<double> _floatOffset;

  @override
  void initState() {
    super.initState();

    // Master entrance controller (1200ms total for staggered children).
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Header: 0% → 40%.
    _headerFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(_headerFade);

    // Spotlight: 15% → 55%.
    _spotlightFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.15, 0.55, curve: Curves.easeOutCubic),
    );
    _spotlightScale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.15, 0.55, curve: Curves.easeOutBack),
      ),
    );

    // Shelves: 30% → 70%.
    _shelvesFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.30, 0.70, curve: Curves.easeOutCubic),
    );
    _shelvesSlide = Tween<Offset>(
      begin: const Offset(0.08, 0),
      end: Offset.zero,
    ).animate(_shelvesFade);

    // Logo floating bob (infinite loop).
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _floatOffset = Tween<double>(begin: -3, end: 3).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  // ── Navigation ──────────────────────────────────────────────────────────

  Future<void> _openBook(BuildContext context, Book book) async {
    await Navigator.of(context).push(
      fadeThroughRoute(
        ChangeNotifierProvider<BookDetailViewModel>(
          create: (ctx) => BookDetailViewModel(
            book: book,
            progress: ctx.read<IProgressService>(),
          ),
          child: const BookDetailView(),
        ),
      ),
    );
    if (context.mounted) context.read<LibraryViewModel>().refresh();
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Consumer<LibraryViewModel>(
        builder: (context, vm, _) {
          final byCategory = vm.booksByCategory;
          final cats = vm.categories;

          return CustomScrollView(
            slivers: [
              // 1. Hero header.
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _headerFade,
                  child: SlideTransition(
                    position: _headerSlide,
                    child: _buildHeader(context, vm),
                  ),
                ),
              ),

              // 2. Continue Reading spotlight.
              if (vm.hasContinueReading)
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _spotlightFade,
                    child: ScaleTransition(
                      scale: _spotlightScale,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: AppConstants.gapM,
                        ),
                        child: _buildSpotlight(context, vm),
                      ),
                    ),
                  ),
                ),

              // 3. Genre shelves.
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _shelvesFade,
                  child: SlideTransition(
                    position: _shelvesSlide,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final cat in cats)
                          BookshelfRow(
                            category: cat,
                            books: byCategory[cat]!,
                            onBookTap: (book) => _openBook(context, book),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // 3b. User-created collection shelves.
              if (vm.hasUserCategories)
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _shelvesFade,
                    child: SlideTransition(
                      position: _shelvesSlide,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final uCat in vm.userCategories)
                            if (vm.booksForUserCategory(uCat).isNotEmpty)
                              BookshelfRow(
                                category: uCat.name,
                                books: vm.booksForUserCategory(uCat),
                                onBookTap: (book) =>
                                    _openBook(context, book),
                              ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Bottom padding.
              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, LibraryViewModel vm) {
    final greeting = _timeGreeting();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.screenPadding,
        AppConstants.gapL,
        AppConstants.screenPadding,
        AppConstants.gapXs,
      ),
      child: Row(
        children: [
          // Floating animated logo.
          AnimatedBuilder(
            animation: _floatOffset,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, _floatOffset.value),
              child: child,
            ),
            child: const MoonLogo(size: 52),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: TextStyle(
                    fontFamily: AppConstants.fontReading,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: context.colors.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${vm.allBooks.length} books in your library',
                  style: TextStyle(
                    fontFamily: AppConstants.fontUi,
                    fontSize: 13.5,
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Manage collections button.
          IconButton(
            icon: const Icon(Icons.library_add_outlined),
            tooltip: 'Manage collections',
            onPressed: () => showManageCategoriesSheet(context),
          ),
        ],
      ),
    );
  }

  // ── Spotlight ───────────────────────────────────────────────────────────

  Widget _buildSpotlight(BuildContext context, LibraryViewModel vm) {
    final book = vm.continueReading.first;
    final chapterIdx = vm.chapterIndexFor(book);
    final chapter = book.chapters[chapterIdx.clamp(0, book.chapterCount - 1)];

    return ReadingSpotlight(
      book: book,
      chapterTitle: chapter.title,
      onTap: () => _openBook(context, book),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  String _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
