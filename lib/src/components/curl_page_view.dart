import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// ─── Controller ────────────────────────────────────────────────────────────────

/// Programmatic controller for [CurlPageView].
class CurlPageController {
  _CurlPageViewState? _state;

  void _attach(_CurlPageViewState s) => _state = s;
  void _detach() => _state = null;

  int get currentPage => _state?._currentPage ?? 0;

  /// Whether a curl animation is currently in progress.
  bool get isAnimating => _state?._isFlipping ?? false;

  void flipNext() => _state?._startAnimatedFlip(forward: true);
  void flipPrev() => _state?._startAnimatedFlip(forward: false);
  void goToPage(int index) => _state?._jumpToPage(index);
}

// ─── Widget ────────────────────────────────────────────────────────────────────

/// A scrollable page view with a realistic corner-based paper-curl page-turn
/// effect.
///
/// Pages are built lazily via [pageBuilder]. During a drag or animated flip the
/// widget uses a high-performance [CustomPainter] that composites pre-rendered
/// page snapshots — the revealed page, a gradient shadow, the still-flat
/// portion of the turning page, and a shaded/clipped back-face — to simulate a
/// physical corner page peel.
///
/// **Performance architecture:**
/// - Page widgets are **snapshot to `dart:ui.Image`** once before a flip starts.
/// - All curl rendering happens in [_CurlPainter] via direct canvas ops —
///   zero widget rebuilds during the animation.
/// - `AnimatedBuilder` is used instead of `setState` to drive repaints.
class CurlPageView extends StatefulWidget {
  const CurlPageView({
    super.key,
    required this.pageCount,
    required this.pageBuilder,
    this.controller,
    this.onPageChanged,
    this.backgroundColor = Colors.white,
    this.initialPage = 0,
    this.animationDuration = const Duration(milliseconds: 350),
    this.gesturesEnabled = true,
  });

  final int pageCount;
  final IndexedWidgetBuilder pageBuilder;
  final CurlPageController? controller;
  final ValueChanged<int>? onPageChanged;
  final Color backgroundColor;
  final int initialPage;
  final Duration animationDuration;

  /// When false, horizontal drag gestures for page-curl are disabled.
  /// Useful when a child widget (e.g. text selection overlay) needs to
  /// handle its own gestures without interference.
  final bool gesturesEnabled;

  @override
  State<CurlPageView> createState() => _CurlPageViewState();
}

// ─── State ─────────────────────────────────────────────────────────────────────

class _CurlPageViewState extends State<CurlPageView>
    with SingleTickerProviderStateMixin {
  late int _currentPage;
  late AnimationController _anim;

  int? _targetPage;
  bool _isForward = true;
  bool _isDragging = false;

  /// Whether a flip (drag or animation) is currently active.
  bool get _isFlipping => _targetPage != null;

  /// The corner the drag originated from. True = bottom corner, false = top.
  bool _fromBottom = true;

  // ── Snapshot cache ──────────────────────────────────────────────────────
  // Pre-rendered page images used by the CustomPainter during the flip.
  // These are captured once before the flip begins, so the painter never
  // touches the widget tree during animation frames.
  ui.Image? _currentPageSnapshot;
  ui.Image? _targetPageSnapshot;

  // Keys for the off-stage RepaintBoundary widgets used for snapshotting.
  final GlobalKey _currentBoundaryKey = GlobalKey();
  final GlobalKey _targetBoundaryKey = GlobalKey();

  // Whether we need to show the off-stage snapshot widgets.
  bool _needsSnapshot = false;
  int? _snapshotTargetPage;

  // ── Pre-cached adjacent page snapshots ──────────────────────────────────
  // After each page change, we eagerly snapshot the previous and next pages
  // so they're instantly available when a drag starts — zero delay.
  final Map<int, ui.Image> _adjacentCache = {};
  final GlobalKey _preCacheBoundaryKey = GlobalKey();
  int? _preCachingPage;
  bool _isPreCaching = false;

  // Cached layout size — captured once, not inside the animation loop.
  Size _pageSize = Size.zero;

  // ── Thresholds ───────────────────────────────────────────────────────────

  static const double _snapThreshold = 0.35;
  static const double _velocityThreshold = 500.0;

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage.clamp(0, widget.pageCount - 1);
    _anim = AnimationController(vsync: this)
      ..addStatusListener(_onAnimStatus);
    widget.controller?._attach(this);

    // Pre-cache adjacent pages after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preCacheAdjacentPages();
    });
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _anim.dispose();
    _currentPageSnapshot?.dispose();
    _targetPageSnapshot?.dispose();
    for (final img in _adjacentCache.values) {
      img.dispose();
    }
    _adjacentCache.clear();
    super.dispose();
  }

  @override
  void didUpdateWidget(CurlPageView old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?._detach();
      widget.controller?._attach(this);
    }
  }

  // ── Snapshot logic ──────────────────────────────────────────────────────

  /// Capture the current and target page widgets as `dart:ui.Image` bitmaps.
  /// This happens after one frame so the RepaintBoundary widgets are laid out.
  Future<void> _captureSnapshots() async {
    await Future<void>.delayed(Duration.zero); // wait for layout
    if (!mounted) return;

    final dpr = MediaQuery.of(context).devicePixelRatio;

    _currentPageSnapshot?.dispose();
    _currentPageSnapshot = null;
    _targetPageSnapshot?.dispose();
    _targetPageSnapshot = null;

    try {
      final currentBoundary = _currentBoundaryKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (currentBoundary != null) {
        _currentPageSnapshot = await currentBoundary.toImage(pixelRatio: dpr);
      }

      final targetBoundary = _targetBoundaryKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (targetBoundary != null) {
        _targetPageSnapshot = await targetBoundary.toImage(pixelRatio: dpr);
      }
    } catch (_) {
      // If snapshotting fails, the painter will just show a blank page.
    }
  }

  /// Try to use pre-cached snapshots first, falling back to live capture.
  /// Returns true if snapshots are ready (from cache), false if async capture
  /// was started and caller should wait.
  bool _tryUseCachedSnapshots(int targetPage) {
    // Snapshot the current page from the live widget.
    final dpr = MediaQuery.of(context).devicePixelRatio;
    try {
      final currentBoundary = _currentBoundaryKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (currentBoundary != null) {
        _currentPageSnapshot?.dispose();
        _currentPageSnapshot = currentBoundary.toImageSync(pixelRatio: dpr);
      }
    } catch (_) {
      // toImageSync may not be available; will fall back to async.
    }

    // Check if we have the target page pre-cached.
    final cached = _adjacentCache[targetPage];
    if (cached != null && _currentPageSnapshot != null) {
      _targetPageSnapshot?.dispose();
      _targetPageSnapshot = cached.clone();
      return true;
    }
    return false;
  }

  // ── Pre-caching adjacent pages ─────────────────────────────────────────

  /// Eagerly snapshot prev/next pages so the curl starts instantly on drag.
  void _preCacheAdjacentPages() {
    if (_isPreCaching || !mounted) return;

    // Determine which pages to pre-cache.
    final pagesToCache = <int>[];
    if (_currentPage + 1 < widget.pageCount &&
        !_adjacentCache.containsKey(_currentPage + 1)) {
      pagesToCache.add(_currentPage + 1);
    }
    if (_currentPage - 1 >= 0 &&
        !_adjacentCache.containsKey(_currentPage - 1)) {
      pagesToCache.add(_currentPage - 1);
    }

    if (pagesToCache.isEmpty) return;
    _preCacheSequentially(pagesToCache, 0);
  }

  /// Cache pages one at a time to avoid layout conflicts.
  void _preCacheSequentially(List<int> pages, int index) {
    if (index >= pages.length || !mounted || _isFlipping) return;
    _isPreCaching = true;
    _preCachingPage = pages[index];
    setState(() {}); // show the off-stage pre-cache widget

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _isFlipping) {
        _isPreCaching = false;
        _preCachingPage = null;
        return;
      }
      try {
        final boundary = _preCacheBoundaryKey.currentContext
            ?.findRenderObject() as RenderRepaintBoundary?;
        if (boundary != null) {
          final dpr = MediaQuery.of(context).devicePixelRatio;
          final image = await boundary.toImage(pixelRatio: dpr);
          // Dispose old cached image for this page if any.
          _adjacentCache[pages[index]]?.dispose();
          _adjacentCache[pages[index]] = image;
        }
      } catch (_) {}

      _preCachingPage = null;
      _isPreCaching = false;
      if (mounted) {
        setState(() {});
        // Continue with next page.
        _preCacheSequentially(pages, index + 1);
      }
    });
  }

  // ── Gesture handling ─────────────────────────────────────────────────────

  void _onDragStart(DragStartDetails details) {
    if (_anim.isAnimating) return;
    _isDragging = true;
    // Determine if drag starts from top or bottom half.
    final h = context.size?.height ?? 1;
    _fromBottom = details.localPosition.dy > h * 0.5;
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (!_isDragging) return;
    final delta = d.primaryDelta ?? 0;
    if (delta.abs() < 0.5 && _targetPage == null) return;
    final w = context.size?.width ?? 1;

    if (_targetPage == null) {
      final forward = delta < 0;
      final target = forward ? _currentPage + 1 : _currentPage - 1;
      if (target < 0 || target >= widget.pageCount) return;
      _isForward = forward;
      _targetPage = target;
      _snapshotTargetPage = target;

      // Try pre-cached snapshots first for instant curl start.
      if (_tryUseCachedSnapshots(target)) {
        // Snapshots ready — curl starts this frame with zero delay!
        _needsSnapshot = false;
        setState(() {});
      } else {
        // Fallback: capture asynchronously (2-3 frame delay).
        _needsSnapshot = true;
        setState(() {});
        _captureSnapshots().then((_) {
          if (mounted) {
            setState(() => _needsSnapshot = false);
          }
        });
      }
    }

    final dragDelta = _isForward ? -delta / w : delta / w;
    // Directly update animation controller value — no setState needed.
    _anim.value = (_anim.value + dragDelta).clamp(0.0, 1.0);
  }

  void _onDragEnd(DragEndDetails d) {
    if (!_isDragging || _targetPage == null) {
      _reset();
      return;
    }
    _isDragging = false;
    final v = d.primaryVelocity ?? 0;
    final vInDir = _isForward ? -v : v;
    final complete =
        _anim.value > _snapThreshold || vInDir > _velocityThreshold;
    _animateTo(complete ? 1.0 : 0.0);
  }

  // ── Programmatic control ─────────────────────────────────────────────────

  void _startAnimatedFlip({required bool forward}) {
    if (_anim.isAnimating) return;
    final target = forward ? _currentPage + 1 : _currentPage - 1;
    if (target < 0 || target >= widget.pageCount) return;
    _isForward = forward;
    _targetPage = target;
    _snapshotTargetPage = target;
    _fromBottom = true;
    _anim.value = 0.0;

    // Try pre-cached snapshots for instant start.
    if (_tryUseCachedSnapshots(target)) {
      _needsSnapshot = false;
      setState(() {});
      _animateTo(1.0);
    } else {
      _needsSnapshot = true;
      setState(() {});
      _captureSnapshots().then((_) {
        if (!mounted || _targetPage == null) return;
        setState(() => _needsSnapshot = false);
        _animateTo(1.0);
      });
    }
  }

  void _jumpToPage(int index) {
    final clamped = index.clamp(0, widget.pageCount - 1);
    if (clamped == _currentPage) return;
    setState(() {
      _currentPage = clamped;
      _reset();
    });
    widget.onPageChanged?.call(clamped);
  }

  // ── Animation helpers ────────────────────────────────────────────────────

  void _animateTo(double target) {
    final dist = (target - _anim.value).abs().clamp(0.1, 1.0);
    _anim.animateTo(
      target,
      duration: widget.animationDuration * dist,
      // easeOutBack gives a subtle springy overshoot that feels like
      // a physical page settling into place.
      curve: target >= 1.0 ? Curves.easeOutBack : Curves.easeOutCubic,
    );
  }

  void _onAnimStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (_anim.value > 0.5 && _targetPage != null) {
      _currentPage = _targetPage!;
      widget.onPageChanged?.call(_currentPage);
    }
    _reset();

    // Eagerly pre-cache adjacent pages for the new current page.
    // This runs after the flip settles, so the next flip starts instantly.
    _invalidateAdjacentCache();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preCacheAdjacentPages();
    });
  }

  void _reset() {
    _isDragging = false;
    _targetPage = null;
    _snapshotTargetPage = null;
    _needsSnapshot = false;
    _currentPageSnapshot?.dispose();
    _currentPageSnapshot = null;
    _targetPageSnapshot?.dispose();
    _targetPageSnapshot = null;
    if (!_anim.isAnimating) _anim.reset();
    setState(() {});
  }

  /// Clear cached pages that are no longer adjacent to the current page.
  void _invalidateAdjacentCache() {
    final keysToRemove = _adjacentCache.keys
        .where((k) => (k - _currentPage).abs() > 1)
        .toList();
    for (final k in keysToRemove) {
      _adjacentCache[k]?.dispose();
      _adjacentCache.remove(k);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, box) {
      // Cache the page size — used by the painter, captured outside the
      // animation loop so LayoutBuilder only re-runs on actual size changes.
      _pageSize = Size(box.maxWidth, box.maxHeight);

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: widget.gesturesEnabled ? _onDragStart : null,
        onHorizontalDragUpdate: widget.gesturesEnabled ? _onDragUpdate : null,
        onHorizontalDragEnd: widget.gesturesEnabled ? _onDragEnd : null,
        child: Stack(
          children: [
            // The static current page (always visible underneath).
            Positioned.fill(
              child: RepaintBoundary(
                key: _currentBoundaryKey,
                child: widget.pageBuilder(ctx, _currentPage),
              ),
            ),

            // Off-stage target page for snapshotting (only during capture).
            if (_needsSnapshot && _snapshotTargetPage != null)
              Positioned.fill(
                child: Offstage(
                  offstage: true,
                  child: RepaintBoundary(
                    key: _targetBoundaryKey,
                    child: widget.pageBuilder(ctx, _snapshotTargetPage!),
                  ),
                ),
              ),

            // Off-stage pre-cache widget for adjacent pages.
            if (_preCachingPage != null)
              Positioned.fill(
                child: Offstage(
                  offstage: true,
                  child: RepaintBoundary(
                    key: _preCacheBoundaryKey,
                    child: widget.pageBuilder(ctx, _preCachingPage!),
                  ),
                ),
              ),

            // The curl overlay — only when a flip is active and snapshots exist.
            if (_targetPage != null &&
                _currentPageSnapshot != null &&
                _targetPageSnapshot != null)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _anim,
                  builder: (_, _) {
                    return CustomPaint(
                      size: _pageSize,
                      painter: _CurlPainter(
                        progress: _anim.value,
                        currentPageImage: _currentPageSnapshot!,
                        targetPageImage: _targetPageSnapshot!,
                        isForward: _isForward,
                        fromBottom: _fromBottom,
                        backgroundColor: widget.backgroundColor,
                        dpr: MediaQuery.of(context).devicePixelRatio,
                      ),
                      isComplex: true,
                      willChange: true,
                    );
                  },
                ),
              ),
          ],
        ),
      );
    });
  }
}

// ─── CurlPainter ───────────────────────────────────────────────────────────────

/// High-performance canvas-based page curl renderer.
///
/// All fold geometry, clipping, shadows, and mirroring happen via direct
/// `Canvas` operations — **no widget rebuilds** during the animation.
class _CurlPainter extends CustomPainter {
  _CurlPainter({
    required this.progress,
    required this.currentPageImage,
    required this.targetPageImage,
    required this.isForward,
    required this.fromBottom,
    required this.backgroundColor,
    required this.dpr,
  });

  final double progress;
  final ui.Image currentPageImage;
  final ui.Image targetPageImage;
  final bool isForward;
  final bool fromBottom;
  final Color backgroundColor;
  final double dpr;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) {
      _drawImage(canvas, size, currentPageImage);
      return;
    }
    if (progress >= 1.0) {
      _drawImage(canvas, size, targetPageImage);
      return;
    }

    final w = size.width;
    final h = size.height;
    final t = progress;

    // ── Corner-based fold geometry ────────────────────────────────────────

    final anchorY = fromBottom ? h : 0.0;
    final anchorX = isForward ? w : 0.0;

    final dragX = isForward ? w * (1.0 - t * 1.2) : w * (t * 1.2);
    final dragY = fromBottom
        ? h - h * 0.25 * t
        : h * 0.25 * t;

    final midX = (anchorX + dragX) / 2;
    final midY = (anchorY + dragY) / 2;

    final dx = dragX - anchorX;
    final dy = dragY - anchorY;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 1) {
      _drawImage(canvas, size, currentPageImage);
      return;
    }

    // Normal to CP (fold line direction).
    final nx = -dy / len;
    final ny = dx / len;

    // Signed distance from fold line.
    double signedDist(Offset p) {
      return (p.dx - midX) * nx + (p.dy - midY) * ny;
    }

    // Page corners.
    final corners = [
      Offset(0, 0),
      Offset(w, 0),
      Offset(w, h),
      Offset(0, h),
    ];

    final anchorDist = signedDist(Offset(anchorX, anchorY));
    final flipSign = anchorDist >= 0 ? 1.0 : -1.0;

    // Build clip polygons.
    final stayClip = <Offset>[];
    final foldClip = <Offset>[];

    for (var i = 0; i < 4; i++) {
      final c = corners[i];
      final next = corners[(i + 1) % 4];
      final dC = signedDist(c) * flipSign;
      final dN = signedDist(next) * flipSign;

      if (dC >= 0) {
        foldClip.add(c);
      } else {
        stayClip.add(c);
      }

      if ((dC >= 0 && dN < 0) || (dC < 0 && dN >= 0)) {
        final tEdge = dC / (dC - dN);
        final ix = c.dx + tEdge * (next.dx - c.dx);
        final iy = c.dy + tEdge * (next.dy - c.dy);
        final intersection = Offset(ix, iy);
        stayClip.add(intersection);
        foldClip.add(intersection);
      }
    }

    // Mirror fold clip around fold line.
    final mirroredClip = foldClip.map((p) {
      final d = signedDist(p);
      return Offset(p.dx - 2 * d * nx, p.dy - 2 * d * ny);
    }).toList();

    final foldAngle = math.atan2(ny, nx);
    final shadowWidth = math.min(40.0, w * t * 0.15);

    // Source and destination rects for drawing images.
    final imgSrcCurrent = Rect.fromLTWH(
      0, 0,
      currentPageImage.width.toDouble(),
      currentPageImage.height.toDouble(),
    );
    final imgSrcTarget = Rect.fromLTWH(
      0, 0,
      targetPageImage.width.toDouble(),
      targetPageImage.height.toDouble(),
    );
    final dstRect = Offset.zero & size;

    // ① Draw revealed page (target) — fills the entire area underneath.
    canvas.save();
    canvas.drawImageRect(targetPageImage, imgSrcTarget, dstRect, Paint());
    canvas.restore();

    // ② Shadow on revealed page along the fold line.
    if (shadowWidth > 1) {
      _drawDiagonalShadow(canvas, size, midX, midY, nx, ny,
          shadowWidth, flipSign);
    }

    // ③ Current page — clipped to the un-folded "stay" region.
    if (stayClip.length >= 3) {
      canvas.save();
      canvas.clipPath(_pathFromPoints(stayClip));
      canvas.drawImageRect(currentPageImage, imgSrcCurrent, dstRect, Paint());
      canvas.restore();
    }

    // ④ Back-face of turning page (mirrored & clipped with tint).
    if (mirroredClip.length >= 3) {
      canvas.save();
      canvas.clipPath(_pathFromPoints(mirroredClip));

      // Apply mirror transform.
      final transform = Matrix4.identity()
        ..translateByDouble(midX, midY, 0, 1)
        ..rotateZ(foldAngle)
        ..scaleByDouble(-1.0, 1.0, 1.0, 1.0)
        ..rotateZ(-foldAngle)
        ..translateByDouble(-midX, -midY, 0, 1);
      canvas.transform(transform.storage);

      // Draw the current page image (mirrored = back face).
      final tintPaint = Paint()
        ..colorFilter = const ColorFilter.mode(
          Color.fromRGBO(0, 0, 0, 0.06),
          BlendMode.srcATop,
        );
      canvas.drawImageRect(
          currentPageImage, imgSrcCurrent, dstRect, tintPaint);
      canvas.restore();
    }

    // ⑤ Fold-edge highlight line.
    _drawFoldLine(canvas, size, midX, midY, nx, ny);

    // ⑥ Inner shadow on back-face.
    if (mirroredClip.length >= 3 && shadowWidth > 1) {
      canvas.save();
      canvas.clipPath(_pathFromPoints(mirroredClip));
      _drawDiagonalShadow(canvas, size, midX, midY, nx, ny,
          shadowWidth * 0.6, -flipSign);
      canvas.restore();
    }
  }

  void _drawImage(Canvas canvas, Size size, ui.Image image) {
    final src = Rect.fromLTWH(
        0, 0, image.width.toDouble(), image.height.toDouble());
    final dst = Offset.zero & size;
    canvas.drawImageRect(image, src, dst, Paint());
  }

  Path _pathFromPoints(List<Offset> points) {
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.close();
    return path;
  }

  void _drawDiagonalShadow(Canvas canvas, Size size, double midX,
      double midY, double nx, double ny, double shadowWidth, double flipSign) {
    final startX = midX;
    final startY = midY;
    final endX = midX - nx * flipSign * shadowWidth;
    final endY = midY - ny * flipSign * shadowWidth;

    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(startX, startY),
        Offset(endX, endY),
        [
          const Color.fromRGBO(0, 0, 0, 0.18),
          const Color.fromRGBO(0, 0, 0, 0.0),
        ],
      );
    canvas.drawRect(rect, paint);
  }

  void _drawFoldLine(Canvas canvas, Size size, double midX, double midY,
      double nx, double ny) {
    final ext = size.width + size.height;
    final p1 = Offset(midX + ny * ext, midY - nx * ext);
    final p2 = Offset(midX - ny * ext, midY + nx * ext);

    final paint = Paint()
      ..color = const Color.fromRGBO(0, 0, 0, 0.10)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(p1, p2, paint);
  }

  @override
  bool shouldRepaint(_CurlPainter old) =>
      progress != old.progress ||
      isForward != old.isForward ||
      fromBottom != old.fromBottom;
}
