import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../components/page_turner.dart';
import '../../models/reader_settings.dart';

import '../../components/reader_settings_sheet.dart';
import '../../theme/reader_theme.dart';
import '../../utils/constants.dart';
import '../../utils/text_paginator.dart';
import '../../viewmodels/app_viewmodel.dart';
import '../../viewmodels/reader_viewmodel.dart';

/// The reading surface. Supports three layout modes:
///
///  • **Portrait single-page** — one page at a time, turned with the selected
///    flip animation ([PageTurner]).
///  • **Portrait dual-page** — two pages side-by-side (book spread), each
///    paginated to half the available width.
///  • **Landscape scroll** — the full chapter text in a vertical
///    [SingleChildScrollView] so no content is clipped by the narrow height.
///
/// Progress persistence stays chapter-based via [ReaderViewModel].
class ReaderView extends StatefulWidget {
  const ReaderView({super.key});

  @override
  State<ReaderView> createState() => _ReaderViewState();
}

class _ReaderViewState extends State<ReaderView> {
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
      // scaler, page_flip's own sizing), which otherwise surfaces as a tiny
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

  // ── Dual-page helpers ───────────────────────────────────────────────────

  void _onNextDual(ReaderViewModel vm) {
    final step = 2;
    if (_page + step < _pages.length) {
      // Advance the pair by 2.
      setState(() => _page += step);
    } else if (vm.canGoNext) {
      _landOnLastPage = false;
      vm.next();
    }
  }

  void _onPreviousDual(ReaderViewModel vm) {
    if (_page >= 2) {
      setState(() => _page -= 2);
    } else if (_page > 0) {
      setState(() => _page = 0);
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
        appBar: AppBar(
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

  // ── Paginated layout (single or dual, any orientation) ──────────────────

  Widget _buildPaginated(
    ReaderViewModel vm,
    ReaderColors rc,
    ReaderSettings settings,
    TextStyle bodyStyle,
    TextStyle titleStyle,
    TextStyle labelStyle,
    TextScaler scaler,
  ) {
    final isDual = settings.pageColumns == 2;

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // For dual-page, each column gets half the width minus a gap.
              final columnWidth = isDual
                  ? (constraints.maxWidth / 2) - _pagePadding.horizontal
                  : constraints.maxWidth - _pagePadding.horizontal;
              final height = constraints.maxHeight - _pagePadding.vertical;

              // Layout signature that forces re-pagination.
              final layoutSig = '${columnWidth.round()}|${height.round()}|'
                  '${settings.fontSize}|${settings.lineHeight}|'
                  '${settings.serif}|${scaler.scale(1000).round()}|'
                  '${settings.pageColumns}';

              final pages = _ensurePages(
                vm: vm,
                width: columnWidth,
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
                // For dual-page, snap to even page index.
                if (isDual && _page.isOdd && _page > 0) _page--;
              }
              _page = _page.clamp(0, pages.length - 1);

              if (isDual) {
                return _buildDualPageSpread(
                  pages: pages,
                  vm: vm,
                  rc: rc,
                  bodyStyle: bodyStyle,
                  titleStyle: titleStyle,
                  labelStyle: labelStyle,
                  chapterKey: chapterKey,
                  layoutSig: layoutSig,
                  settings: settings,
                );
              }

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
                    _pageContent(
                      index: i,
                      vm: vm,
                      rc: rc,
                      bodyStyle: bodyStyle,
                      titleStyle: titleStyle,
                      labelStyle: labelStyle,
                    ),
                ],
              );
            },
          ),
        ),
        _buildFooter(vm, rc, isDual),
      ],
    );
  }

  // ── Dual-page spread ────────────────────────────────────────────────────

  Widget _buildDualPageSpread({
    required List<String> pages,
    required ReaderViewModel vm,
    required ReaderColors rc,
    required TextStyle bodyStyle,
    required TextStyle titleStyle,
    required TextStyle labelStyle,
    required String chapterKey,
    required String layoutSig,
    required ReaderSettings settings,
  }) {
    final leftIdx = _page;
    final rightIdx = _page + 1 < pages.length ? _page + 1 : null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v < -200) {
          _onNextDual(vm);
        } else if (v > 200) {
          _onPreviousDual(vm);
        }
      },
      child: Row(
        children: [
          // Left page.
          Expanded(
            child: _pageContent(
              index: leftIdx,
              vm: vm,
              rc: rc,
              bodyStyle: bodyStyle,
              titleStyle: titleStyle,
              labelStyle: labelStyle,
            ),
          ),
          // Thin divider between pages.
          Container(
            width: 1,
            color: rc.faint.withValues(alpha: 0.18),
          ),
          // Right page (or empty).
          Expanded(
            child: rightIdx != null
                ? _pageContent(
                    index: rightIdx,
                    vm: vm,
                    rc: rc,
                    bodyStyle: bodyStyle,
                    titleStyle: titleStyle,
                    labelStyle: labelStyle,
                  )
                : ColoredBox(color: rc.background, child: const SizedBox.expand()),
          ),
        ],
      ),
    );
  }

  // ── Footer ──────────────────────────────────────────────────────────────

  Widget _buildFooter(ReaderViewModel vm, ReaderColors rc, bool isDual) {
    final String label;
    if (isDual) {
      final rightIdx = _page + 1 < _pages.length ? _page + 1 : null;
      final pageLabel = rightIdx != null
          ? 'Pages ${_page + 1}–${rightIdx + 1} of ${_pages.length}'
          : 'Page ${_page + 1} of ${_pages.length}';
      label = '$pageLabel  ·  '
          'Chapter ${vm.chapterIndex + 1} of ${vm.chapterCount}';
    } else {
      label = 'Page ${_page + 1} of ${_pages.length}  ·  '
          'Chapter ${vm.chapterIndex + 1} of ${vm.chapterCount}';
    }

    return _ReaderFooter(
      colors: rc,
      progress: _displayProgress(vm),
      label: label,
      canPrevious: vm.chapterIndex > 0 || _page > 0,
      canNext: vm.canGoNext || _page < _pages.length - 1,
      onPrevious: isDual ? () => _onPreviousDual(vm) : () => _onPrevious(vm),
      onNext: isDual ? () => _onNextDual(vm) : () => _onNext(vm),
    );
  }

  double _displayProgress(ReaderViewModel vm) {
    final pageFraction =
        _pages.length <= 1 ? 1.0 : (_page + 1) / _pages.length;
    if (vm.chapterCount <= 1) return pageFraction;
    return ((vm.chapterIndex + pageFraction) / vm.chapterCount).clamp(0.0, 1.0);
  }
}

class _ReaderFooter extends StatelessWidget {
  const _ReaderFooter({
    required this.colors,
    required this.progress,
    required this.label,
    required this.canPrevious,
    required this.canNext,
    required this.onPrevious,
    required this.onNext,
  });

  final ReaderColors colors;
  final double progress;
  final String label;
  final bool canPrevious;
  final bool canNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.surface,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              backgroundColor: colors.surface,
              color: const Color(0xFFE6BE72),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    color: colors.text,
                    disabledColor: colors.faint.withValues(alpha: 0.4),
                    onPressed: canPrevious ? onPrevious : null,
                  ),
                  Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.faint, fontSize: 13),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    color: colors.text,
                    disabledColor: colors.faint.withValues(alpha: 0.4),
                    onPressed: canNext ? onNext : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
