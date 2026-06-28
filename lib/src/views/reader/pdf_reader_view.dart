import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';

import '../../components/curl_page_view.dart';
import '../../components/highlight_color_picker.dart';
import '../../components/highlight_overlay.dart';
import '../../components/reader_footer.dart';
import '../../components/text_selection_overlay.dart';
import '../../models/book.dart';
import '../../models/reader_settings.dart';
import '../../theme/reader_theme.dart';
import '../../utils/constants.dart';
import '../../viewmodels/app_viewmodel.dart';
import '../../viewmodels/highlight_viewmodel.dart';
import '../../viewmodels/pdf_reader_viewmodel.dart';

/// Immersive PDF reader with raster-rendered pages and corner-fold page curl.
///
/// Each PDF page is **pre-rendered to a `dart:ui.Image`** (raster bitmap) so
/// that page-curl animations operate on GPU-friendly flat images instead of
/// live widget trees — resulting in a silky-smooth, turnable-page-quality
/// reading experience.
///
/// Features:
/// - Tap center (60%) → toggle chrome (app bar + footer)
/// - Tap left 20% → previous page
/// - Tap right 20% → next page
/// - Drag from corner → diagonal corner-fold page curl
/// - Slider footer for quick page scrubbing
class PdfReaderView extends StatefulWidget {
  const PdfReaderView({super.key, required this.book});

  final Book book;

  @override
  State<PdfReaderView> createState() => _PdfReaderViewState();
}

class _PdfReaderViewState extends State<PdfReaderView>
    with SingleTickerProviderStateMixin {
  final CurlPageController _curlController = CurlPageController();
  PdfDocument? _doc;
  bool _failed = false;

  // ── Raster page cache ──────────────────────────────────────────────────
  /// Pre-rendered raster images for each PDF page.
  final Map<int, ui.Image> _pageImages = {};

  /// Pages currently being rendered (to avoid duplicate work).
  final Set<int> _rendering = {};

  // ── Immersive mode ─────────────────────────────────────────────────────
  bool _chromeVisible = false;
  late final AnimationController _chromeAnim;

  static const double _tapEdgeFraction = 0.20;

  @override
  void initState() {
    super.initState();
    _chromeAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _open();
  }

  Future<void> _open() async {
    try {
      await pdfrxFlutterInitialize();
      final doc = await PdfDocument.openFile(widget.book.pdfPath!);
      if (!mounted) {
        await doc.dispose();
        return;
      }
      setState(() => _doc = doc);
      context.read<PdfReaderViewModel>().setPageCount(doc.pages.length);

      // Pre-render the first few pages for instant display.
      final startPage = context.read<PdfReaderViewModel>().page;
      _preRenderAround(startPage);

      // Load highlights for the initial page so existing highlights appear.
      context.read<HighlightViewModel>().loadPage(startPage);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  /// Pre-render pages around [center] (current ±2) for smooth flipping.
  void _preRenderAround(int center) {
    final doc = _doc;
    if (doc == null) return;
    for (var i = center - 1; i <= center + 2; i++) {
      if (i >= 0 && i < doc.pages.length) {
        _renderPage(i);
      }
    }
  }

  /// Render a single PDF page to a `dart:ui.Image` at screen resolution.
  Future<void> _renderPage(int index) async {
    final doc = _doc;
    if (doc == null || _pageImages.containsKey(index) || _rendering.contains(index)) {
      return;
    }
    _rendering.add(index);

    try {
      final page = doc.pages[index];

      // Render at 2x device pixel ratio for crisp text on high-DPI screens.
      final dpr = MediaQuery.of(context).devicePixelRatio;
      final screenWidth = MediaQuery.of(context).size.width;
      final scale = (screenWidth * dpr) / page.width;
      final renderWidth = (page.width * scale).round();
      final renderHeight = (page.height * scale).round();

      final pdfImage = await page.render(
        fullWidth: renderWidth.toDouble(),
        fullHeight: renderHeight.toDouble(),
        width: renderWidth,
        height: renderHeight,
        backgroundColor: 0xFFFFFFFF,
      );

      if (pdfImage != null && mounted) {
        final uiImage = await pdfImage.createImage();
        pdfImage.dispose();
        if (mounted) {
          // Store the image immediately, but only call setState if no curl
          // animation is in progress — this prevents mid-flip widget tree
          // rebuilds that cause jank.
          _pageImages[index] = uiImage;
          if (!_curlController.isAnimating) {
            setState(() {});
          }
        }
      }
    } catch (_) {
      // Silently skip — the page will fall back to the widget renderer.
    } finally {
      _rendering.remove(index);
    }
  }

  @override
  void dispose() {
    _chromeAnim.dispose();
    // Dispose all cached raster images.
    for (final img in _pageImages.values) {
      img.dispose();
    }
    _pageImages.clear();
    _doc?.dispose();
    super.dispose();
  }

  // ── Chrome toggle ──────────────────────────────────────────────────────

  void _toggleChrome() {
    setState(() => _chromeVisible = !_chromeVisible);
    if (_chromeVisible) {
      _chromeAnim.forward();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      _chromeAnim.reverse();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  // ── Tap-zone handler ───────────────────────────────────────────────────

  void _onTapUp(TapUpDetails details) {
    // Don't handle edge-tap navigation when in highlight mode.
    final hlVm = context.read<HighlightViewModel>();
    if (hlVm.highlightMode) return;

    final width = context.size?.width ?? 1;
    final x = details.localPosition.dx;

    if (x < width * _tapEdgeFraction) {
      _curlController.flipPrev();
    } else if (x > width * (1 - _tapEdgeFraction)) {
      _curlController.flipNext();
    } else {
      _toggleChrome();
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!widget.book.isPdf) {
      return const Scaffold(
        body: Center(child: Text('Error: Not a PDF book.')),
      );
    }

    final settings = context.watch<AppViewModel>().reader;
    final rc = ReaderColors.of(settings.palette, warmth: settings.warmth);
    final isDark = rc.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: rc.background,
        extendBodyBehindAppBar: true,
        appBar: _chromeVisible ? _buildAppBar(rc, settings) : null,
        body: Stack(
          children: [
            Positioned.fill(
              child: Selector<HighlightViewModel, bool>(
                selector: (_, vm) => vm.highlightMode,
                builder: (_, inHighlightMode, _) {
                  return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    // Disable tap navigation when in highlight mode so it
                    // doesn't compete with the text-selection long-press.
                    onTapUp: inHighlightMode ? null : _onTapUp,
                    child: _buildBody(
                      settings.palette,
                      rc,
                      highlightMode: inHighlightMode,
                    ),
                  );
                },
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildAnimatedFooter(rc),
            ),
            // Color picker bar — shown when highlight mode is active.
            Positioned(
              top: MediaQuery.of(context).padding.top + (_chromeVisible ? kToolbarHeight : 12),
              left: 0,
              right: 0,
              child: Consumer<HighlightViewModel>(
                builder: (_, hlVm, _) {
                  if (!hlVm.highlightMode) return const SizedBox.shrink();
                  return Center(
                    child: HighlightColorPicker(
                      selectedColor: hlVm.selectedColor,
                      onColorSelected: hlVm.setColor,
                      onClose: hlVm.disableHighlightMode,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── App bar ────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(ReaderColors rc, ReaderSettings settings) {
    return AppBar(
      backgroundColor: rc.background.withValues(alpha: 0.92),
      foregroundColor: rc.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: rc.text),
      title: Text(
        widget.book.title,
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
        // Highlight toggle.
        Consumer<HighlightViewModel>(
          builder: (_, hlVm, _) => IconButton(
            tooltip: hlVm.highlightMode ? 'Exit highlight mode' : 'Highlight text',
            icon: Icon(
              hlVm.highlightMode
                  ? Icons.edit_off_rounded
                  : Icons.edit_rounded,
              color: hlVm.highlightMode
                  ? hlVm.selectedColor.value.withValues(alpha: 1.0)
                  : rc.text,
            ),
            onPressed: hlVm.toggleHighlightMode,
          ),
        ),
        IconButton(
          tooltip: 'Reading theme: ${settings.palette.label}',
          icon: Icon(settings.palette.icon),
          onPressed: () {
            const palettes = ReaderPalette.values;
            final next =
                palettes[(settings.palette.index + 1) % palettes.length];
            context.read<AppViewModel>().setPalette(next);
          },
        ),
      ],
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────

  Widget _buildBody(
    ReaderPalette palette,
    ReaderColors rc, {
    bool highlightMode = false,
  }) {
    if (_failed) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: rc.faint),
              const SizedBox(height: 16),
              Text(
                'Sorry — this PDF could not be opened.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: rc.text,
                  fontFamily: AppConstants.fontReading,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final doc = _doc;
    if (doc == null) {
      return _buildLoading(rc);
    }

    final pageCount = doc.pages.length;
    final filter = readerPageColorFilter(palette);

    // When highlight mode is active, prevent CurlPageView's horizontal drag
    // recogniser from stealing gestures from the text-selection long-press.
    return CurlPageView(
      controller: _curlController,
      pageCount: pageCount,
      initialPage: context.read<PdfReaderViewModel>().page,
      backgroundColor: rc.background,
      gesturesEnabled: !highlightMode,
      onPageChanged: (page) {
        context.read<PdfReaderViewModel>().goToPage(page);
        context.read<HighlightViewModel>().loadPage(page);
        // Pre-render surrounding pages when the user navigates.
        _preRenderAround(page);
      },
      pageBuilder: (_, i) {
        // Use the pre-rendered raster image if available.
        final rasterImage = _pageImages[i];

        Widget pageWidget;
        if (rasterImage != null) {
          // GPU-friendly raster image — silky smooth during curl.
          pageWidget = RawImage(
            image: rasterImage,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
          );
        } else {
          // Fallback: live widget (triggers async render for next time).
          _renderPage(i);
          pageWidget = PdfPageView(
            document: doc,
            pageNumber: i + 1,
            alignment: Alignment.center,
            backgroundColor: rc.background,
          );
        }

        return Container(
          color: rc.background,
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Base page widget with optional color filter.
                filter == null
                    ? pageWidget
                    : ColorFiltered(colorFilter: filter, child: pageWidget),

                // Highlight overlay — draws saved highlights on top.
                // Stable key prevents Flutter from misidentifying this
                // widget when the text-selection sibling appears/disappears.
                Consumer<HighlightViewModel>(
                  key: const ValueKey('highlight_overlay'),
                  builder: (_, hlVm, _) {
                    final highlights = hlVm.highlightsForPage(i);
                    return HighlightOverlay(highlights: highlights);
                  },
                ),

                // Text selection overlay — only when highlight mode is active.
                Consumer<HighlightViewModel>(
                  key: const ValueKey('text_selection'),
                  builder: (_, hlVm, _) {
                    if (!hlVm.highlightMode || i >= doc.pages.length) {
                      return const SizedBox.shrink();
                    }
                    return PdfTextSelectionOverlay(
                      page: doc.pages[i],
                      pageIndex: i,
                      selectedColor: hlVm.selectedColor,
                      onHighlightConfirmed: (rects, text) {
                        hlVm.addHighlight(
                          pageIndex: i,
                          rects: rects,
                          text: text,
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Elegant loading state ──────────────────────────────────────────────

  Widget _buildLoading(ReaderColors rc) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.85, end: 1.0),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeInOut,
            builder: (_, scale, child) => Transform.scale(
              scale: scale,
              child: child,
            ),
            onEnd: () {},
            child: Icon(
              Icons.auto_stories_rounded,
              size: 52,
              color: rc.faint.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Opening…',
            style: TextStyle(
              color: rc.faint,
              fontFamily: AppConstants.fontReading,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Animated footer ────────────────────────────────────────────────────

  Widget _buildAnimatedFooter(ReaderColors rc) {
    return AnimatedBuilder(
      animation: _chromeAnim,
      builder: (context, child) {
        final t = CurvedAnimation(
          parent: _chromeAnim,
          curve: Curves.easeOutCubic,
        ).value;
        return Transform.translate(
          offset: Offset(0, (1 - t) * 80),
          child: Opacity(
            opacity: t,
            child: child,
          ),
        );
      },
      child: Consumer<PdfReaderViewModel>(
        builder: (_, vm, _) {
          final pageCount = vm.pageCount;
          return ReaderFooter(
            colors: rc,
            progress: pageCount <= 1 ? 1.0 : (vm.page + 1) / pageCount,
            label: 'Page ${vm.page + 1} of $pageCount',
            canPrevious: vm.page > 0,
            canNext: vm.page < pageCount - 1,
            onPrevious: _curlController.flipPrev,
            onNext: _curlController.flipNext,
            totalPages: pageCount,
            currentPage: vm.page,
            onPageScrub: (page) {
              _curlController.goToPage(page);
              vm.goToPage(page);
            },
          );
        },
      ),
    );
  }
}
