import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../components/page_turner.dart';
import '../../components/reader_footer.dart';
import '../../models/reader_settings.dart';

import '../../components/reader_settings_sheet.dart';
import '../../theme/reader_theme.dart';
import '../../utils/constants.dart';
import '../../utils/text_paginator.dart';
import '../../viewmodels/app_viewmodel.dart';
import '../../viewmodels/reader_viewmodel.dart';

/// The reading surface. Shows one page at a time, turned with the selected
/// flip animation ([PageTurner]). Body text scrolls within a page when large
/// font / line-height settings overflow the available height.
///
/// Progress persistence stays chapter-based via [ReaderViewModel].
class ReaderView extends StatefulWidget {
  const ReaderView({super.key});

  @override
  State<ReaderView> createState() => _ReaderViewState();
}

class _ReaderViewState extends State<ReaderView>
    with SingleTickerProviderStateMixin {
  static const EdgeInsets _pagePadding = EdgeInsets.fromLTRB(26, 14, 26, 14);

  // Tiny slack subtracted from each page's height budget so a page that fills
  // its box exactly can't trip a RenderFlex overflow on sub-pixel rounding
  // (the paginator already accounts for line height + leading).
  static const double _pageSafetyMargin = 2.0;

  final PageTurnerController _flip = PageTurnerController();

  // Pagination cache — recomputed only when the chapter, layout or text
  // settings change (palette is excluded: a colour change never alters line
  // breaks).
  String? _pageKey;
  List<String> _pages = const [''];

  // Footer / chapter-rollover bookkeeping.
  String _chapterKey = '';
  int _page = 0;
  bool _landOnLastPage = false;

  // ── Full-view (immersive) mode ──────────────────────────────────────────
  bool _isFullView = false;
  late final AnimationController _fullViewAnim;

  @override
  void initState() {
    super.initState();
    _fullViewAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
  }

  @override
  void dispose() {
    _fullViewAnim.dispose();
    // Restore system UI on exit in case we're in full-view mode.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleFullView() {
    setState(() => _isFullView = !_isFullView);
    if (_isFullView) {
      _fullViewAnim.forward();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      _fullViewAnim.reverse();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _showToc(ReaderViewModel vm) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text('Chapters',
                    style: Theme.of(sheetCtx).textTheme.titleLarge),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: vm.chapterCount,
                  itemBuilder: (_, i) {
                    final selected = i == vm.chapterIndex;
                    return ListTile(
                      selected: selected,
                      leading: Text('${i + 1}',
                          style: Theme.of(sheetCtx).textTheme.titleMedium),
                      title: Text(vm.book.chapters[i].title),
                      trailing: selected ? const Icon(Icons.bookmark) : null,
                      onTap: () {
                        vm.goToChapter(i);
                        Navigator.of(sheetCtx).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Measures the chapter heading block (big title + "Chapter x of y") so the
  /// first page reserves room for it.
  double _headingHeight(
    ReaderViewModel vm,
    double maxWidth,
    TextStyle titleStyle,
    TextStyle labelStyle,
    TextScaler scaler,
  ) {
    double measure(String text, TextStyle style) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout(maxWidth: maxWidth);
      final h = tp.height;
      tp.dispose();
      return h;
    }

    final title = measure(vm.chapter.title, titleStyle);
    final label = measure(
        'Chapter ${vm.chapterIndex + 1} of ${vm.chapterCount}', labelStyle);
    return title + 6 + label + 24; // gaps mirror the rendered Column below
  }

  List<String> _ensurePages({
    required ReaderViewModel vm,
    required double width,
    required double height,
    required TextStyle bodyStyle,
    required TextStyle titleStyle,
    required TextStyle labelStyle,
    required TextScaler scaler,
    required String layoutSig,
  }) {
    final key = '${vm.book.id}|${vm.chapterIndex}|$layoutSig';
    if (key != _pageKey) {
      _pageKey = key;
      final heading = _headingHeight(vm, width, titleStyle, labelStyle, scaler);
      // Pack pages to slightly less than the real box: TextPainter line metrics
      // and the live render can disagree by a sub-pixel (leading rounding, text
      // scaler, CurlPageView's own sizing), which otherwise surfaces as a tiny
      // RenderFlex overflow on an otherwise-full page.
      final pageHeight = height - _pageSafetyMargin;
      _pages = TextPaginator.paginate(
        text: vm.chapter.paragraphs.join('\n\n'),
        style: bodyStyle,
        maxWidth: width,
        firstPageHeight: math.max(pageHeight - heading, height * 0.25),
        otherPageHeight: pageHeight,
        textScaler: scaler,
      );
    }
    return _pages;
  }

  Widget _pageContent({
    required int index,
    required ReaderViewModel vm,
    required ReaderColors rc,
    required TextStyle bodyStyle,
    required TextStyle titleStyle,
    required TextStyle labelStyle,
  }) {
    return SizedBox.expand(
      child: ColoredBox(
        color: rc.background,
        child: Padding(
          padding: _pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (index == 0) ...[
                Text(vm.chapter.title, style: titleStyle),
                const SizedBox(height: 6),
                Text(
                    'Chapter ${vm.chapterIndex + 1} of ${vm.chapterCount}',
                    style: labelStyle),
                const SizedBox(height: 24),
              ],
              // Expanded + SingleChildScrollView lets the body scroll when
              // text overflows due to large font / line-height settings,
              // instead of triggering a RenderFlex overflow error.
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    _pages[index],
                    textAlign: TextAlign.justify,
                    style: bodyStyle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onNext(ReaderViewModel vm) {
    if (_page < _pages.length - 1) {
      _flip.nextPage();
    } else if (vm.canGoNext) {
      _landOnLastPage = false;
      vm.next();
    }
  }

  void _onPrevious(ReaderViewModel vm) {
    if (_page > 0) {
      _flip.previousPage();
    } else if (vm.canGoPrevious) {
      _landOnLastPage = true;
      vm.previous();
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppViewModel>().reader;
    final vm = context.watch<ReaderViewModel>();
    final rc = ReaderColors.of(settings.palette, warmth: settings.warmth);
    final isDark = rc.brightness == Brightness.dark;
    final scaler = MediaQuery.textScalerOf(context);

    final fontFamily =
        settings.serif ? AppConstants.fontReading : AppConstants.fontUi;
    final bodyStyle = TextStyle(
      color: rc.text,
      fontFamily: fontFamily,
      fontSize: settings.fontSize,
      height: settings.lineHeight,
    );
    final titleStyle = TextStyle(
      color: rc.text,
      fontFamily: AppConstants.fontReading,
      fontSize: settings.fontSize * 1.45,
      fontWeight: FontWeight.w600,
      height: 1.2,
    );
    final labelStyle = TextStyle(
      color: rc.faint,
      fontFamily: AppConstants.fontUi,
      fontSize: 13,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: rc.background,
        extendBodyBehindAppBar: true,
        appBar: _isFullView
            ? null
            : AppBar(
                backgroundColor: rc.background,
                foregroundColor: rc.text,
                iconTheme: IconThemeData(color: rc.text),
                actionsIconTheme: IconThemeData(color: rc.text),
                title: Text(
                  vm.book.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: rc.text,
                    fontFamily: AppConstants.fontReading,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                actions: [
                  IconButton(
                    tooltip: 'Full view',
                    icon: const Icon(Icons.fullscreen),
                    onPressed: _toggleFullView,
                  ),
                  IconButton(
                    tooltip: 'Chapters',
                    icon: const Icon(Icons.toc),
                    onPressed: () => _showToc(vm),
                  ),
                  IconButton(
                    tooltip: 'Display settings',
                    icon: const Icon(Icons.format_size),
                    onPressed: () => showReaderSettingsSheet(context),
                  ),
                ],
              ),
        body: OrientationBuilder(
          builder: (context, orientation) {
            return _buildPaginated(vm, rc, settings, bodyStyle, titleStyle,
                    labelStyle, scaler);
          },
        ),
      ),
    );
  }

  // ── Paginated layout (any orientation) ──────────────────────────────────

  Widget _buildPaginated(
    ReaderViewModel vm,
    ReaderColors rc,
    ReaderSettings settings,
    TextStyle bodyStyle,
    TextStyle titleStyle,
    TextStyle labelStyle,
    TextScaler scaler,
  ) {
    return Column(
      children: [
        // Spacer for the AppBar when not in full-view mode.
        if (!_isFullView)
          SizedBox(
            height: MediaQuery.of(context).padding.top + kToolbarHeight,
          ),
        Expanded(
          child: GestureDetector(
            // Tap the centre zone to toggle full-view mode.
            onTap: () {
              _toggleFullView();
            },
            behavior: HitTestBehavior.translucent,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth - _pagePadding.horizontal;
                final height = constraints.maxHeight - _pagePadding.vertical;

                // Layout signature that forces re-pagination.
                final layoutSig = '${width.round()}|${height.round()}|'
                    '${settings.fontSize}|${settings.lineHeight}|'
                    '${settings.serif}|${scaler.scale(1000).round()}';

                final pages = _ensurePages(
                  vm: vm,
                  width: width,
                  height: height,
                  bodyStyle: bodyStyle,
                  titleStyle: titleStyle,
                  labelStyle: labelStyle,
                  scaler: scaler,
                  layoutSig: layoutSig,
                );

                // Reset the visible page on chapter change.
                final chapterKey = '${vm.book.id}|${vm.chapterIndex}';
                if (chapterKey != _chapterKey) {
                  _chapterKey = chapterKey;
                  _page = _landOnLastPage ? pages.length - 1 : 0;
                  _landOnLastPage = false;
                }
                _page = _page.clamp(0, pages.length - 1);

                return PageTurner(
                  key: ValueKey(
                    '$chapterKey|$layoutSig|${settings.palette}'
                    '|${settings.warmth}|${settings.flipStyle}',
                  ),
                  style: settings.flipStyle,
                  controller: _flip,
                  backgroundColor: rc.background,
                  initialIndex: _page,
                  onPageChanged: (p) => setState(() => _page = p),
                  children: [
                    for (var i = 0; i < pages.length; i++)
                      RepaintBoundary(
                        child: _pageContent(
                          index: i,
                          vm: vm,
                          rc: rc,
                          bodyStyle: bodyStyle,
                          titleStyle: titleStyle,
                          labelStyle: labelStyle,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
        // Animated footer — slides down and fades out in full-view.
        AnimatedBuilder(
          animation: _fullViewAnim,
          builder: (context, child) {
            final t = _fullViewAnim.value;
            return ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: 1.0 - t,
                child: Opacity(
                  opacity: 1.0 - t,
                  child: child,
                ),
              ),
            );
          },
          child: _buildFooter(vm, rc),
        ),
      ],
    );
  }

  // ── Footer ──────────────────────────────────────────────────────────────

  Widget _buildFooter(ReaderViewModel vm, ReaderColors rc) {
    final label = 'Page ${_page + 1} of ${_pages.length}  ·  '
        'Chapter ${vm.chapterIndex + 1} of ${vm.chapterCount}';

    return ReaderFooter(
      colors: rc,
      progress: _displayProgress(vm),
      label: label,
      canPrevious: vm.chapterIndex > 0 || _page > 0,
      canNext: vm.canGoNext || _page < _pages.length - 1,
      onPrevious: () => _onPrevious(vm),
      onNext: () => _onNext(vm),
    );
  }

  double _displayProgress(ReaderViewModel vm) {
    final pageFraction =
        _pages.length <= 1 ? 1.0 : (_page + 1) / _pages.length;
    if (vm.chapterCount <= 1) return pageFraction;
    return ((vm.chapterIndex + pageFraction) / vm.chapterCount).clamp(0.0, 1.0);
  }
}
