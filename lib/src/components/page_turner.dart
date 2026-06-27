import 'package:flutter/material.dart';

import 'curl_page_view.dart';

/// The visual transition used when turning a page in the reader.
enum PageFlipStyle {
  curl,
  slide,
  fade,
  none;

  String get label => switch (this) {
        PageFlipStyle.curl => 'Curl',
        PageFlipStyle.slide => 'Slide',
        PageFlipStyle.fade => 'Fade',
        PageFlipStyle.none => 'None',
      };

  IconData get icon => switch (this) {
        PageFlipStyle.curl => Icons.auto_stories,
        PageFlipStyle.slide => Icons.swipe,
        PageFlipStyle.fade => Icons.blur_on,
        PageFlipStyle.none => Icons.flash_on,
      };
}

/// A unified page-turner that delegates to the right transition engine based
/// on [style]. All modes expose the same [PageTurnerController] API so the
/// rest of the reader doesn't care which animation is active.
class PageTurner extends StatefulWidget {
  const PageTurner({
    super.key,
    required this.style,
    required this.controller,
    required this.backgroundColor,
    required this.initialIndex,
    required this.onPageChanged,
    required this.children,
  });

  final PageFlipStyle style;
  final PageTurnerController controller;
  final Color backgroundColor;
  final int initialIndex;
  final ValueChanged<int> onPageChanged;
  final List<Widget> children;

  @override
  State<PageTurner> createState() => _PageTurnerState();
}

class _PageTurnerState extends State<PageTurner> {
  // Curl mode delegate.
  late CurlPageController _curlCtrl;

  // Slide mode delegate.
  late PageController _pageCtrl;

  // Fade / None mode state.
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    widget.controller._attach(this);
    _curlCtrl = CurlPageController();
    _pageCtrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  // ── Controller API ──────────────────────────────────────────────────────

  void _next() {
    if (_currentIndex >= widget.children.length - 1) return;
    switch (widget.style) {
      case PageFlipStyle.curl:
        _curlCtrl.flipNext();
      case PageFlipStyle.slide:
        _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      case PageFlipStyle.fade:
        setState(() => _currentIndex++);
        widget.onPageChanged(_currentIndex);
      case PageFlipStyle.none:
        setState(() => _currentIndex++);
        widget.onPageChanged(_currentIndex);
    }
  }

  void _previous() {
    if (_currentIndex <= 0) return;
    switch (widget.style) {
      case PageFlipStyle.curl:
        _curlCtrl.flipPrev();
      case PageFlipStyle.slide:
        _pageCtrl.previousPage(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      case PageFlipStyle.fade:
        setState(() => _currentIndex--);
        widget.onPageChanged(_currentIndex);
      case PageFlipStyle.none:
        setState(() => _currentIndex--);
        widget.onPageChanged(_currentIndex);
    }
  }

  // ── Builders ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return switch (widget.style) {
      PageFlipStyle.curl => _buildCurl(),
      PageFlipStyle.slide => _buildSlide(),
      PageFlipStyle.fade => _buildFade(),
      PageFlipStyle.none => _buildNone(),
    };
  }

  Widget _buildCurl() {
    return CurlPageView(
      key: ValueKey('curl_${widget.children.length}'),
      controller: _curlCtrl,
      backgroundColor: widget.backgroundColor,
      initialPage: widget.initialIndex,
      pageCount: widget.children.length,
      pageBuilder: (_, i) => widget.children[i],
      onPageChanged: (p) {
        _currentIndex = p;
        widget.onPageChanged(p);
      },
    );
  }

  Widget _buildSlide() {
    return PageView.builder(
      controller: _pageCtrl,
      physics: const ClampingScrollPhysics(),
      itemCount: widget.children.length,
      onPageChanged: (p) {
        _currentIndex = p;
        widget.onPageChanged(p);
      },
      itemBuilder: (_, i) => widget.children[i],
    );
  }

  Widget _buildFade() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      child: KeyedSubtree(
        key: ValueKey('fade_page_$_currentIndex'),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: (d) => _handleSwipe(d),
          child: widget.children[_currentIndex],
        ),
      ),
    );
  }

  Widget _buildNone() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (d) => _handleSwipe(d),
      child: KeyedSubtree(
        key: ValueKey('none_page_$_currentIndex'),
        child: widget.children[_currentIndex],
      ),
    );
  }

  void _handleSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -200) {
      _next();
    } else if (velocity > 200) {
      _previous();
    }
  }
}

/// A thin controller the reader holds onto. Works regardless of which
/// [PageFlipStyle] is active.
class PageTurnerController {
  _PageTurnerState? _state;

  void _attach(_PageTurnerState state) => _state = state;

  void nextPage() => _state?._next();
  void previousPage() => _state?._previous();
}
