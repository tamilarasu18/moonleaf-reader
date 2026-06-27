import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../models/highlight.dart';

/// Callback when user confirms a text selection for highlighting.
typedef OnHighlightConfirmed = void Function(
    List<ui.Rect> normalisedRects, String text);

/// Handles long-press text selection on a PDF page.
///
/// Uses `pdfrx`'s [PdfPage.loadText] to extract character positions,
/// then allows the user to drag to select a range of characters. When the user
/// lifts their finger, a "Highlight" action button appears.
///
/// All rects are converted to **normalised coordinates** (0 → 1) before
/// being passed to the callback so they're resolution-independent.
class PdfTextSelectionOverlay extends StatefulWidget {
  const PdfTextSelectionOverlay({
    super.key,
    required this.page,
    required this.pageIndex,
    required this.selectedColor,
    required this.onHighlightConfirmed,
  });

  final PdfPage page;
  final int pageIndex;
  final HighlightColor selectedColor;
  final OnHighlightConfirmed onHighlightConfirmed;

  @override
  State<PdfTextSelectionOverlay> createState() =>
      _PdfTextSelectionOverlayState();
}

class _PdfTextSelectionOverlayState extends State<PdfTextSelectionOverlay> {
  PdfPageRawText? _rawText;
  bool _loading = true;

  // Selection state (character indices into fullText).
  int? _startCharIndex;
  int? _endCharIndex;
  bool _isDragging = false;
  bool _selectionComplete = false;

  @override
  void initState() {
    super.initState();
    _loadText();
  }

  @override
  void didUpdateWidget(PdfTextSelectionOverlay old) {
    super.didUpdateWidget(old);
    if (old.pageIndex != widget.pageIndex) {
      _clearSelection();
      _loadText();
    }
  }

  Future<void> _loadText() async {
    setState(() => _loading = true);
    try {
      final text = await widget.page.loadText();
      if (mounted) {
        setState(() {
          _rawText = text;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _clearSelection() {
    setState(() {
      _startCharIndex = null;
      _endCharIndex = null;
      _isDragging = false;
      _selectionComplete = false;
    });
  }

  /// Find the nearest character to a local position.
  int? _findNearestChar(Offset localPosition, Size size) {
    final text = _rawText;
    if (text == null || text.charRects.isEmpty) return null;

    final pageW = widget.page.width;
    final pageH = widget.page.height;

    // Convert local position to PDF page coordinates.
    final pdfX = (localPosition.dx / size.width) * pageW;
    final pdfY = (localPosition.dy / size.height) * pageH;

    double bestDist = double.infinity;
    int bestIndex = -1;

    for (var i = 0; i < text.charRects.length; i++) {
      final r = text.charRects[i];
      // PdfRect has left, top, right, bottom in PDF coords.
      final cx = (r.left + r.right) / 2;
      final cy = (r.top + r.bottom) / 2;

      final dist = (pdfX - cx) * (pdfX - cx) + (pdfY - cy) * (pdfY - cy);
      if (dist < bestDist) {
        bestDist = dist;
        bestIndex = i;
      }
    }

    // Only match if within a reasonable distance (5% of page dimension).
    final threshold = pageW * 0.05;
    if (math.sqrt(bestDist) > threshold) return null;
    return bestIndex;
  }

  /// Expand selection to word boundaries for a nicer UX.
  int _expandToWordStart(int index) {
    final text = _rawText?.fullText ?? '';
    while (index > 0 && text[index - 1] != ' ' && text[index - 1] != '\n') {
      index--;
    }
    return index;
  }

  int _expandToWordEnd(int index) {
    final text = _rawText?.fullText ?? '';
    while (index < text.length - 1 &&
        text[index + 1] != ' ' &&
        text[index + 1] != '\n') {
      index++;
    }
    return index;
  }

  void _onLongPressStart(LongPressStartDetails details) {
    final size = context.size;
    if (size == null) return;

    final index = _findNearestChar(details.localPosition, size);
    if (index == null) return;

    // Select the whole word on long-press start.
    setState(() {
      _startCharIndex = _expandToWordStart(index);
      _endCharIndex = _expandToWordEnd(index);
      _isDragging = true;
      _selectionComplete = false;
    });
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!_isDragging) return;
    final size = context.size;
    if (size == null) return;

    final index = _findNearestChar(details.localPosition, size);
    if (index != null) {
      setState(() => _endCharIndex = _expandToWordEnd(index));
    }
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (!_isDragging) return;
    setState(() {
      _isDragging = false;
      _selectionComplete =
          _startCharIndex != null && _endCharIndex != null;
    });
  }

  void _confirmHighlight() {
    final text = _rawText;
    if (text == null || _startCharIndex == null || _endCharIndex == null) {
      return;
    }

    final lo = math.min(_startCharIndex!, _endCharIndex!);
    final hi = math.max(_startCharIndex!, _endCharIndex!);

    final pageW = widget.page.width;
    final pageH = widget.page.height;

    // Group characters into line-level bounding rects for cleaner highlights.
    final rects = _buildLineRects(text, lo, hi, pageW, pageH);
    final selectedText = text.fullText.substring(
      lo.clamp(0, text.fullText.length),
      (hi + 1).clamp(0, text.fullText.length),
    );

    widget.onHighlightConfirmed(rects, selectedText);
    _clearSelection();
  }

  /// Merge per-character rects into line-level bounding boxes (normalised 0..1).
  List<ui.Rect> _buildLineRects(
    PdfPageRawText text,
    int lo,
    int hi,
    double pageW,
    double pageH,
  ) {
    if (lo >= text.charRects.length) return [];
    final clampedHi = math.min(hi, text.charRects.length - 1);

    final result = <ui.Rect>[];
    double lineLeft = double.infinity;
    double lineTop = double.infinity;
    double lineRight = double.negativeInfinity;
    double lineBottom = double.negativeInfinity;
    double? lastBottom;

    for (var i = lo; i <= clampedHi; i++) {
      final r = text.charRects[i];
      // Detect line break: if top changes significantly, flush current line.
      if (lastBottom != null && (r.top - lastBottom).abs() > (r.bottom - r.top) * 0.5) {
        if (lineRight > lineLeft) {
          result.add(ui.Rect.fromLTRB(
            lineLeft / pageW,
            lineTop / pageH,
            lineRight / pageW,
            lineBottom / pageH,
          ));
        }
        lineLeft = double.infinity;
        lineTop = double.infinity;
        lineRight = double.negativeInfinity;
        lineBottom = double.negativeInfinity;
      }
      lineLeft = math.min(lineLeft, r.left);
      lineTop = math.min(lineTop, r.top);
      lineRight = math.max(lineRight, r.right);
      lineBottom = math.max(lineBottom, r.bottom);
      lastBottom = r.bottom;
    }

    // Flush last line.
    if (lineRight > lineLeft) {
      result.add(ui.Rect.fromLTRB(
        lineLeft / pageW,
        lineTop / pageH,
        lineRight / pageW,
        lineBottom / pageH,
      ));
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPressStart: _onLongPressStart,
      onLongPressMoveUpdate: _onLongPressMoveUpdate,
      onLongPressEnd: _onLongPressEnd,
      child: Stack(
        children: [
          // Draw selection highlight preview.
          if (_startCharIndex != null && _endCharIndex != null && _rawText != null)
            Positioned.fill(
              child: CustomPaint(
                painter: _CharSelectionPainter(
                  rawText: _rawText!,
                  startIndex: _startCharIndex!,
                  endIndex: _endCharIndex!,
                  color: widget.selectedColor.value.withValues(alpha: 0.4),
                  pageWidth: widget.page.width,
                  pageHeight: widget.page.height,
                ),
              ),
            ),

          // "Highlight" action button after selection.
          if (_selectionComplete)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: _HighlightActionButton(
                  color: widget.selectedColor,
                  onHighlight: _confirmHighlight,
                  onCancel: _clearSelection,
                ),
              ),
            ),

          // Loading indicator for text extraction.
          if (_loading)
            Positioned(
              top: 8,
              right: 8,
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.grey.withValues(alpha: 0.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Selection preview painter ──────────────────────────────────────────────

class _CharSelectionPainter extends CustomPainter {
  _CharSelectionPainter({
    required this.rawText,
    required this.startIndex,
    required this.endIndex,
    required this.color,
    required this.pageWidth,
    required this.pageHeight,
  });

  final PdfPageRawText rawText;
  final int startIndex;
  final int endIndex;
  final Color color;
  final double pageWidth;
  final double pageHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final lo = math.min(startIndex, endIndex);
    final hi = math.min(math.max(startIndex, endIndex), rawText.charRects.length - 1);

    for (var i = lo; i <= hi; i++) {
      final r = rawText.charRects[i];
      final rect = ui.Rect.fromLTRB(
        (r.left / pageWidth) * size.width,
        (r.top / pageHeight) * size.height,
        (r.right / pageWidth) * size.width,
        (r.bottom / pageHeight) * size.height,
      );
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_CharSelectionPainter old) =>
      startIndex != old.startIndex || endIndex != old.endIndex;
}

// ─── Action button after selection ──────────────────────────────────────────

class _HighlightActionButton extends StatelessWidget {
  const _HighlightActionButton({
    required this.color,
    required this.onHighlight,
    required this.onCancel,
  });

  final HighlightColor color;
  final VoidCallback onHighlight;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Highlight button.
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onHighlight,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(24),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: color.value.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Highlight',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Container(
            width: 1,
            height: 24,
            color: Colors.white.withValues(alpha: 0.2),
          ),

          // Cancel button.
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onCancel,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(24),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.white70,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
